import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/presentation/controllers/active_profile_controller.dart';
import '../data/care_api.dart';
import '../data/care_notifications.dart';
import '../domain/care_models.dart';

/// Records of one kind for the active profile; refetched when the profile changes.
final careRecordsProvider = FutureProvider.autoDispose.family<List<CareRecord>, CareKind>((ref, kind) {
  ref.watch(activeProfileControllerProvider.select((s) => s.activeProfileId));
  return ref.watch(careApiProvider).list(kind);
});

final medicationsProvider = FutureProvider.autoDispose<List<Medication>>((ref) async {
  final records = await ref.watch(careRecordsProvider(CareKind.medication).future);
  return records.map(Medication.new).toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
});

/// Intakes logged for one medication (newest first).
final intakesProvider = FutureProvider.autoDispose.family<List<CareRecord>, String>((ref, medicationId) {
  ref.watch(activeProfileControllerProvider.select((s) => s.activeProfileId));
  return ref.watch(careApiProvider).list(CareKind.medicationIntake, parentId: medicationId);
});

final careDocumentsProvider = FutureProvider.autoDispose<List<CareDocument>>((ref) {
  ref.watch(activeProfileControllerProvider.select((s) => s.activeProfileId));
  return ref.watch(careApiProvider).documents();
});

final careDocumentProvider = FutureProvider.autoDispose.family<CareDocument, String>((ref, id) {
  return ref.watch(careApiProvider).document(id);
});

final careDocumentFileProvider = FutureProvider.autoDispose.family<Uint8List, String>((ref, id) {
  return ref.watch(careApiProvider).file(id);
});

final careActionsProvider = Provider<CareActions>((ref) => CareActions(ref));

/// Mutations: call the API, refresh the lists and re-arm local reminders.
class CareActions {
  CareActions(this._ref);
  final Ref _ref;

  CareApi get _api => _ref.read(careApiProvider);

  Future<CareRecord> save(CareKind kind, Map<String, dynamic> data, {String? id}) async {
    final record = id == null ? await _api.create(kind, data) : await _api.update(id, data);
    _refresh(kind);
    return record;
  }

  Future<void> delete(CareKind kind, String id) async {
    await _api.delete(id);
    _refresh(kind);
  }

  Future<void> logIntake(Medication med, DateTime scheduledFor, IntakeAction action) async {
    await _api.logIntake(med.id, scheduledFor, action);
    _ref.invalidate(intakesProvider(med.id));
    _ref.invalidate(careRecordsProvider(CareKind.medication));
  }

  Future<CareDocument> upload({
    required DocumentKind kind,
    required String mime,
    required Uint8List bytes,
    required bool read,
    String? title,
  }) async {
    final doc = await _api.upload(kind: kind, mime: mime, bytes: bytes, read: read, title: title);
    _ref.invalidate(careDocumentsProvider);
    return doc;
  }

  Future<CareDocument> review(String id, Map<String, dynamic> body) async {
    final doc = await _api.review(id, body);
    _ref.invalidate(careDocumentsProvider);
    _ref.invalidate(careDocumentProvider(id));
    return doc;
  }

  Future<CareDocument> reprocess(String id) async {
    final doc = await _api.reprocess(id);
    _ref.invalidate(careDocumentsProvider);
    _ref.invalidate(careDocumentProvider(id));
    return doc;
  }

  Future<void> deleteDocument(String id) async {
    await _api.deleteDocument(id);
    _ref.invalidate(careDocumentsProvider);
  }

  void _refresh(CareKind kind) {
    _ref.invalidate(careRecordsProvider(kind));
    if (kind != CareKind.allergy) rescheduleReminders();
  }

  /// Re-arms medication, appointment and booster reminders of the active profile.
  Future<void> rescheduleReminders() async {
    try {
      final results = await Future.wait([
        _api.list(CareKind.medication),
        _api.list(CareKind.appointment),
        _api.list(CareKind.vaccineDose),
      ]);
      await _ref.read(careNotificationServiceProvider).reschedule(
            medications: results[0].map(Medication.new).toList(),
            appointments: results[1],
            vaccineDoses: results[2],
          );
    } catch (_) {
      // Offline: reminders already armed stay as they are.
    }
  }
}

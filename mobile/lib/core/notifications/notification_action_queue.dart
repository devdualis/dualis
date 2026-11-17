import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// What a notification button asked for while the app may have been closed.
enum PendingNotificationActionKind { water, medicationTaken }

/// One button tap waiting to be applied by the main isolate.
///
/// Holds only ids, amounts and times: never a medication, vaccine or specialty
/// name, never a place and never free text (LGPD; these files outlive the
/// notification).
@immutable
class PendingNotificationAction {
  const PendingNotificationAction({
    required this.id,
    required this.kind,
    required this.at,
    this.amountMl,
    this.medicationId,
    this.scheduledFor,
  });

  final String id;
  final PendingNotificationActionKind kind;
  final DateTime at;
  final int? amountMl;
  final String? medicationId;
  final DateTime? scheduledFor;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        'at': at.toUtc().toIso8601String(),
        if (amountMl != null) 'amountMl': amountMl,
        if (medicationId != null) 'medicationId': medicationId,
        if (scheduledFor != null)
          'scheduledFor': scheduledFor!.toUtc().toIso8601String(),
      };

  /// Null when [json] is not a valid entry.
  static PendingNotificationAction? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final kindName = json['kind'];
    final at = DateTime.tryParse('${json['at']}');
    if (id is! String || id.isEmpty || kindName is! String || at == null) {
      return null;
    }
    PendingNotificationActionKind? kind;
    for (final value in PendingNotificationActionKind.values) {
      if (value.name == kindName) kind = value;
    }
    if (kind == null) return null;
    final amount = json['amountMl'];
    final medicationId = json['medicationId'];
    final scheduledFor = json['scheduledFor'] is String
        ? DateTime.tryParse(json['scheduledFor'] as String)
        : null;
    return PendingNotificationAction(
      id: id,
      kind: kind,
      at: at,
      amountMl: amount is int ? amount : null,
      medicationId: medicationId is String ? medicationId : null,
      scheduledFor: scheduledFor,
    );
  }
}

/// Persisted queue shared by the background notification engine (writer) and
/// the main isolate (drain).
abstract class NotificationActionQueue {
  Future<void> add(PendingNotificationAction action);

  /// Oldest first.
  Future<List<PendingNotificationAction>> list();

  Future<void> remove(String id);

  Future<void> clear();

  /// App language, so the background engine (which has no Riverpod state)
  /// builds snoozed notifications in the same language.
  Future<void> saveLanguageCode(String languageCode);

  Future<String?> readLanguageCode();
}

class InMemoryNotificationActionQueue implements NotificationActionQueue {
  final Map<String, PendingNotificationAction> _entries =
      <String, PendingNotificationAction>{};
  String? _languageCode;

  @override
  Future<void> add(PendingNotificationAction action) async {
    _entries[action.id] = action;
  }

  @override
  Future<List<PendingNotificationAction>> list() async =>
      _entries.values.toList()..sort((a, b) => a.at.compareTo(b.at));

  @override
  Future<void> remove(String id) async {
    _entries.remove(id);
  }

  @override
  Future<void> clear() async => _entries.clear();

  @override
  Future<void> saveLanguageCode(String languageCode) async {
    _languageCode = languageCode;
  }

  @override
  Future<String?> readLanguageCode() async => _languageCode;
}

/// One JSON file per action under `<app support>/notification_actions`.
///
/// Each file is written to a temp name and renamed, so the background engine
/// and the main isolate never read a half-written entry or race on one file.
class FileNotificationActionQueue implements NotificationActionQueue {
  FileNotificationActionQueue({Future<Directory> Function()? directory})
      : _directory = directory ?? _defaultDirectory;

  static const String _folder = 'notification_actions';
  static const String _languageFile = 'language';

  final Future<Directory> Function() _directory;

  static Future<Directory> _defaultDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/$_folder');
  }

  Future<Directory> _dir() async {
    final dir = await _directory();
    await dir.create(recursive: true);
    return dir;
  }

  static bool _safeId(String id) => RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id);

  @override
  Future<void> add(PendingNotificationAction action) async {
    if (!_safeId(action.id)) return;
    try {
      final dir = await _dir();
      final tmp = File('${dir.path}/${action.id}.tmp');
      await tmp.writeAsString(jsonEncode(action.toJson()), flush: true);
      await tmp.rename('${dir.path}/${action.id}.json');
    } catch (e) {
      debugPrint('Could not queue notification action: $e');
    }
  }

  @override
  Future<List<PendingNotificationAction>> list() async {
    final entries = <PendingNotificationAction>[];
    try {
      final dir = await _dir();
      await for (final entity in dir.list()) {
        if (entity is! File || !entity.path.endsWith('.json')) continue;
        try {
          final entry =
              PendingNotificationAction.fromJson(jsonDecode(await entity.readAsString()));
          if (entry != null) entries.add(entry);
        } catch (_) {
          // Corrupt or half-deleted file: skip it, never block the others.
        }
      }
    } catch (e) {
      debugPrint('Could not read notification actions: $e');
    }
    entries.sort((a, b) => a.at.compareTo(b.at));
    return entries;
  }

  @override
  Future<void> remove(String id) async {
    if (!_safeId(id)) return;
    try {
      final dir = await _dir();
      final file = File('${dir.path}/$id.json');
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Could not remove notification action: $e');
    }
  }

  @override
  Future<void> clear() async {
    try {
      final dir = await _dir();
      await for (final entity in dir.list()) {
        if (entity is File &&
            (entity.path.endsWith('.json') || entity.path.endsWith('.tmp'))) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Could not clear notification actions: $e');
    }
  }

  @override
  Future<void> saveLanguageCode(String languageCode) async {
    try {
      final dir = await _dir();
      await File('${dir.path}/$_languageFile').writeAsString(languageCode);
    } catch (e) {
      debugPrint('Could not store notification language: $e');
    }
  }

  @override
  Future<String?> readLanguageCode() async {
    try {
      final dir = await _dir();
      final file = File('${dir.path}/$_languageFile');
      if (!await file.exists()) return null;
      final code = (await file.readAsString()).trim();
      return code.isEmpty ? null : code;
    } catch (_) {
      return null;
    }
  }
}

enum DrainOutcome {
  /// Applied: remove the entry.
  done,

  /// Try again on the next drain (no user yet, offline, server error).
  retry,

  /// Can never be applied (rejected by the server, unknown kind): remove it.
  drop,
}

/// Applies queued notification actions in order. Pure policy: the [handle]
/// callback decides what each entry becomes.
class NotificationActionDrain {
  NotificationActionDrain(
    this.queue, {
    required this.handle,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  static const Duration maxAge = Duration(days: 7);

  final NotificationActionQueue queue;
  final Future<DrainOutcome> Function(PendingNotificationAction action) handle;
  final DateTime Function() _clock;

  /// Returns how many entries were applied ([DrainOutcome.done]).
  Future<int> drain() async {
    final entries = await queue.list();
    if (entries.isEmpty) return 0;
    final now = _clock();
    var done = 0;
    for (final entry in entries) {
      if (now.difference(entry.at) > maxAge) {
        await queue.remove(entry.id);
        continue;
      }
      DrainOutcome outcome;
      try {
        outcome = await handle(entry);
      } catch (e) {
        debugPrint('Notification action not applied yet: $e');
        outcome = DrainOutcome.retry;
      }
      switch (outcome) {
        case DrainOutcome.done:
          done++;
          await queue.remove(entry.id);
        case DrainOutcome.drop:
          await queue.remove(entry.id);
        case DrainOutcome.retry:
          break;
      }
    }
    return done;
  }
}

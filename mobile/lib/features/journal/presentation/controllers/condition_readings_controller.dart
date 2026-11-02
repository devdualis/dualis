import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/controllers/active_profile_controller.dart';
import '../../data/journal_repository.dart';
import '../../domain/journal_models.dart';

/// Days of readings shown in a condition's history.
const int conditionReadingsDays = 90;

/// Readings of one condition (by condition id) for the active profile,
/// newest first, with the readings still waiting in the outbox. Refetched when
/// the profile changes; `ref.invalidate` refreshes it after a save or sync.
final conditionReadingsProvider = FutureProvider.autoDispose
    .family<ConditionReadingsHistory, String>((ref, conditionId) {
  ref.watch(activeProfileControllerProvider.select((s) => s.activeProfileId));
  return ref
      .watch(journalRepositoryProvider)
      .conditionReadings(conditionId, days: conditionReadingsDays);
});

/// Readings of one local day, newest first.
@immutable
class ReadingsDay {
  /// Local midnight of the day.
  final DateTime day;
  final List<ConditionReading> readings;

  const ReadingsDay(this.day, this.readings);
}

/// Splits readings by local day: newest day first, newest reading first
/// inside a day. Values are kept as typed; nothing is summed or compared.
List<ReadingsDay> readingsByDay(List<ConditionReading> readings) {
  final sorted = [...readings]
    ..sort((a, b) => b.measuredAt.compareTo(a.measuredAt));
  final days = <ReadingsDay>[];
  for (final r in sorted) {
    final local = r.measuredAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (days.isNotEmpty && days.last.day == day) {
      days.last.readings.add(r);
    } else {
      days.add(ReadingsDay(day, [r]));
    }
  }
  return days;
}

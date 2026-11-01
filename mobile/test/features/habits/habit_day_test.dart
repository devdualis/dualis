import 'package:dualis_mobile/features/habits/domain/models/habit_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HabitDay JSON round-trip and contract v2.2', () {
    test('serializes and deserializes full HabitDay matching contract', () {
      final json = {
        'day': '2026-10-31',
        'sleepQuality': 'bem',
        'sleepHours': '7_8',
        'moved': true,
        'movementMinutes': '30_60',
        'period': true,
      };

      final habit = HabitDay.fromJson(json);

      expect(habit.day, equals('2026-10-31'));
      expect(habit.sleepQuality, equals(HabitSleepQuality.bem));
      expect(habit.sleepHours, equals(HabitSleepHours.hours7To8));
      expect(habit.moved, isTrue);
      expect(habit.movementMinutes, equals(HabitMovementMinutes.minutes30To60));
      expect(habit.period, isTrue);

      final outJson = habit.toJson();
      expect(outJson['day'], equals('2026-10-31'));
      expect(outJson['sleepQuality'], equals('bem'));
      expect(outJson['sleepHours'], equals('7_8'));
      expect(outJson['moved'], isTrue);
      expect(outJson['movementMinutes'], equals('30_60'));
      expect(outJson['period'], isTrue);
    });

    test('toPutPayload matches contract PUT /v1/habits/:day schema', () {
      const habit = HabitDay(
        day: '2026-10-30',
        sleepQuality: HabitSleepQuality.mal,
        sleepHours: HabitSleepHours.menos5,
        moved: false,
        movementMinutes: null,
        period: false,
      );

      final payload = habit.toPutPayload();
      expect(payload['sleepQuality'], equals('mal'));
      expect(payload['sleepHours'], equals('menos_5'));
      expect(payload['moved'], isFalse);
      expect(payload['movementMinutes'], isNull);
      expect(payload['period'], isFalse);
      // 'day' is path param, not in PUT payload
      expect(payload.containsKey('day'), isFalse);
    });

    test('handles null and empty optional fields safely', () {
      final json = {
        'day': '2026-10-31',
      };

      final habit = HabitDay.fromJson(json);
      expect(habit.day, equals('2026-10-31'));
      expect(habit.sleepQuality, isNull);
      expect(habit.sleepHours, isNull);
      expect(habit.moved, isNull);
      expect(habit.movementMinutes, isNull);
      expect(habit.period, isNull);
      expect(habit.isEmpty, isTrue);

      final payload = habit.toPutPayload();
      expect(payload['sleepQuality'], isNull);
      expect(payload['sleepHours'], isNull);
      expect(payload['moved'], isNull);
      expect(payload['movementMinutes'], isNull);
      expect(payload['period'], isNull);
    });

    test('copyWith works correctly', () {
      const habit = HabitDay(
        day: '2026-10-31',
        sleepQuality: HabitSleepQuality.regular,
      );

      final updated = habit.copyWith(
        sleepQuality: HabitSleepQuality.bem,
        moved: true,
        movementMinutes: HabitMovementMinutes.ate15,
      );

      expect(updated.day, equals('2026-10-31'));
      expect(updated.sleepQuality, equals(HabitSleepQuality.bem));
      expect(updated.moved, isTrue);
      expect(updated.movementMinutes, equals(HabitMovementMinutes.ate15));
      expect(updated.isEmpty, isFalse);
    });
  });
}

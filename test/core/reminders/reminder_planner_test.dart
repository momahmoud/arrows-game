import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_escape/core/reminders/reminder_planner.dart';

void main() {
  final now = DateTime(2026, 6, 10, 18, 30);

  test('a short ladder: day 1, day 3, day 7, then nothing', () {
    final plans = ReminderPlanner.plan(now: now);
    expect(plans.map((p) => p.kind), ReminderKind.values);
    expect(
      plans.map((p) => p.when.difference(DateTime(2026, 6, 10)).inDays),
      [1, 3, 7],
    );
  });

  test('at most one reminder a day', () {
    final days = ReminderPlanner.plan(
      now: now,
    ).map((p) => DateTime(p.when.year, p.when.month, p.when.day)).toSet();
    expect(days, hasLength(3));
  });

  test('at the hour the player usually plays', () {
    final plans = ReminderPlanner.plan(now: now, usualHour: 15);
    expect(plans.map((p) => p.when.hour).toSet(), {15});
  });

  test('uses an evening default until the habit is known', () {
    final plans = ReminderPlanner.plan(now: now);
    expect(plans.first.when.hour, ReminderPlanner.defaultHour);
  });

  test('never in the small hours or too late', () {
    for (var hour = 0; hour < 24; hour++) {
      final plans = ReminderPlanner.plan(now: now, usualHour: hour);
      for (final plan in plans) {
        expect(plan.when.hour, greaterThanOrEqualTo(ReminderPlanner.earliestHour));
        expect(plan.when.hour, lessThanOrEqualTo(ReminderPlanner.latestHour));
      }
    }
  });

  test('always in the future, across a month end', () {
    final lateJune = DateTime(2026, 6, 29, 23, 50);
    final plans = ReminderPlanner.plan(now: lateJune, usualHour: 23);
    expect(plans.every((p) => p.when.isAfter(lateJune)), isTrue);
    expect(plans.first.when, DateTime(2026, 6, 30, 21));
    expect(plans.last.when, DateTime(2026, 7, 6, 21));
  });

  test('ids are stable per kind so planning again replaces them', () {
    final a = ReminderPlanner.plan(now: now).map((p) => p.id).toList();
    final b = ReminderPlanner.plan(
      now: now.add(const Duration(days: 4)),
    ).map((p) => p.id).toList();
    expect(a, b);
    expect(a.toSet(), hasLength(3));
  });

  test('the wording variant rotates', () {
    final variants = {
      for (var d = 1; d <= 6; d++)
        ReminderPlanner.plan(now: DateTime(2026, 6, d, 12)).first.variant,
    };
    expect(variants.length, greaterThan(1));
    expect(variants.every((v) => v >= 0 && v < 3), isTrue);
  });
}

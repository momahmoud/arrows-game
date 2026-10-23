/// Which reminder in the ladder.
enum ReminderKind {
  /// The day after the player left: the daily gift is waiting.
  next,

  /// Three days away: a warm "we miss you".
  comeBack,

  /// A week away: the last one. Nothing is sent after it.
  lastCall,
}

class ReminderPlan {
  const ReminderPlan({
    required this.kind,
    required this.when,
    required this.variant,
  });

  final ReminderKind kind;
  final DateTime when;

  /// Which wording to use, so the same text isn't sent every time.
  final int variant;

  /// Stable per kind, so planning again replaces the earlier reminder.
  int get id => 7100 + kind.index;
}

/// Decides when reminders go out. Pure, so the rules can be tested.
///
/// The rules, from what works for retention without annoying people:
/// - One reminder a day at most, and a short ladder (day 1, 3, 7) that then
///   stops, so a player who has gone is not pestered forever.
/// - At the time of day the player usually plays, never in the small hours:
///   the hour is kept between [earliestHour] and [latestHour].
/// - The caller plans when the player leaves and cancels when they return,
///   so a reminder never arrives for something already done.
class ReminderPlanner {
  const ReminderPlanner._();

  static const int earliestHour = 10;
  static const int latestHour = 21;

  /// Used until the player's own habit is known.
  static const int defaultHour = 19;

  static const List<int> ladderDays = [1, 3, 7];

  static List<ReminderPlan> plan({required DateTime now, int? usualHour}) {
    final hour = (usualHour ?? defaultHour).clamp(earliestHour, latestHour);
    return [
      for (var i = 0; i < ladderDays.length; i++)
        ReminderPlan(
          kind: ReminderKind.values[i],
          when: DateTime(
            now.year,
            now.month,
            now.day + ladderDays[i],
            hour,
          ),
          variant: (now.day + i) % 3,
        ),
    ];
  }
}

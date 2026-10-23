import '../../core/constants.dart';
import 'level_quality.dart';

/// What a normal level is for in the campaign's pacing.
///
/// Roles are a plan, not a mechanic: they decide which composition a level
/// gets and which measured properties a generated board must have.
enum LevelRole {
  /// Ordinary level. Any legal tap is safe; difficulty is spotting what is free.
  standard,

  /// First level where tapping in the wrong order can strand an arrow.
  teaching,

  /// Order matters: consuming a direction dot early can deadlock the board.
  puzzle,

  /// Smaller, more open board that gives the player a rest.
  breather,
}

class CampaignRoles {
  CampaignRoles._();

  /// Sits before the first boss with a dead end (boss 42).
  static const int teachingLevel = 33;

  /// First level that may be a puzzle or a breather.
  static const int firstPacedLevel = 40;

  static LevelRole roleFor(int level) {
    if (AppConstants.levelTypeFor(level) != LevelType.normal) {
      return LevelRole.standard;
    }
    if (level == teachingLevel) return LevelRole.teaching;
    if (level < firstPacedLevel) return LevelRole.standard;
    if (level % 12 == 9) return LevelRole.breather;
    if (level % 8 == 5) return LevelRole.puzzle;
    return LevelRole.standard;
  }

  /// Fewest dependency rounds a standard board may have at [level].
  /// Grows with the level so the late campaign does not plateau.
  static int minPeelRounds(int level) {
    if (level <= 20) return 0;
    if (level <= 100) return 7;
    return 9 + ((level - 100) * 0.0165).round();
  }

  /// Reasons [profile] does not fit the role of [level]. Empty means it fits.
  static List<String> issues(int level, LevelQualityProfile profile) {
    final role = roleFor(level);
    final out = <String>[];
    final peelFloor = minPeelRounds(level);
    final openingShare =
        profile.unitCount == 0 ? 0.0 : profile.openingMoves / profile.unitCount;

    // Replaces the old absolute "opening moves" cap, which the shipped campaign
    // never met. The audit checklist asks for at most 40% free at the start.
    if (role != LevelRole.breather && level > 8 && openingShare > 0.40) {
      out.add('ROLE: opening share ${openingShare.toStringAsFixed(2)} > 0.40');
    }

    switch (role) {
      case LevelRole.standard:
        if (profile.deadEndRate > 0) {
          out.add('ROLE: standard level has dead ends '
              '(${profile.deadEndRate.toStringAsFixed(2)})');
        }
        if (profile.peelRounds < peelFloor) {
          out.add('ROLE: ${profile.peelRounds} peel rounds < $peelFloor');
        }
      case LevelRole.teaching:
        if (profile.deadEndRate < 0.05 || profile.deadEndRate > 0.60) {
          out.add('ROLE: teaching dead-end rate '
              '${profile.deadEndRate.toStringAsFixed(2)} outside 0.05-0.60');
        }
        if (profile.directionalDots < 1) {
          out.add('ROLE: teaching level has no direction dot');
        }
      case LevelRole.puzzle:
        if (profile.deadEndRate < 0.10 || profile.deadEndRate > 0.85) {
          out.add('ROLE: puzzle dead-end rate '
              '${profile.deadEndRate.toStringAsFixed(2)} outside 0.10-0.85');
        }
        if (profile.directionalDots < 2) {
          out.add('ROLE: puzzle has ${profile.directionalDots} direction dots');
        }
        if (profile.peelRounds < (peelFloor * 0.8).floor()) {
          out.add('ROLE: puzzle ${profile.peelRounds} peel rounds too shallow');
        }
      case LevelRole.breather:
        if (profile.deadEndRate > 0) {
          out.add('ROLE: breather has dead ends');
        }
        if (openingShare < 0.18) {
          out.add('ROLE: breather opening share '
              '${openingShare.toStringAsFixed(2)} < 0.18');
        }
        if (profile.trapRate > 0.80) {
          out.add('ROLE: breather trap rate '
              '${profile.trapRate.toStringAsFixed(2)} > 0.80');
        }
    }
    return out;
  }
}

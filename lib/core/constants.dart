import 'package:flutter/foundation.dart';


// Core game constants
class AppConstants {
  AppConstants._();

  /// Shape lab entry in Settings (debug/profile builds only unless overridden).
  static const bool enableShapePreview =
      bool.fromEnvironment('ENABLE_SHAPE_PREVIEW', defaultValue: false) ||
          !kReleaseMode;

  /// Dev-only first-500 candidate playtest hub. Requires an explicit
  /// `--dart-define=ENABLE_FIRST500_PLAYTEST=true` and is never available in
  /// release builds. Does not register candidate binaries as assets.
  static const bool enableFirst500Playtest =
      bool.fromEnvironment('ENABLE_FIRST500_PLAYTEST', defaultValue: false) &&
          !kReleaseMode;

  /// Host path to the integrated candidate binary for the playtest hub.
  /// Default matches the documented build output; override when the file is
  /// copied elsewhere (e.g. device storage).
  static const String first500PlaytestBinPath = String.fromEnvironment(
    'FIRST500_PLAYTEST_BIN',
    defaultValue: 'build/candidates/first_500_quality/levels_candidate.bin',
  );

  // App identity
  static const String appName = 'Arrow Escape';
  static const String packageId = 'com.arrows.fluxylabs';

  // Grid sizes (see [gridSizeForLevel]):
  // • Tutorial: 10×10
  // • Normal:   15×15 at level 4 → 24×24 by level 19, then 25×25 → 35×35
  // • Boss/God: 27×27 at first cycle → 40×40 by ~cycle 20
  // Level type cadence is owned only by [levelTypeFor].
  static const int startingGridSize = 10;
  static const int maxGridSize = 40;
  static const int tutorialLevels = 3;
  static const int totalLevels = 1000;

  // Lives
  static const int maxLives = 3;

  /// Starting inventory per power-up (hint, eraser, wand, ruler).
  static const int powerUpsPerLevel = 1;
  static const int powerUpsPerRewardedAd = 1;

  // Ads: LevelPlay mediation. AdMob and Unity Ads are networks inside it,
  // set up in the LevelPlay dashboard (Setup > SDK Networks), not here.
  // App key and ad unit IDs come from that dashboard (Android app).
  // An empty app key means ads are off; the game still works.
  static const String levelPlayAppKey = '286ca4efd';
  static const String levelPlayBannerAdUnitId = 'sibs2o1d0gngzb37';
  static const String levelPlayInterstitialAdUnitId = '5q0xyhjkd52uiqkb';
  static const String levelPlayRewardedAdUnitId = 'cvmcsr21tsam329j';

  /// True when LevelPlay can be initialised.
  static const bool adsConfigured = levelPlayAppKey != '';

  static const int interstitialEveryNLevels = 4;

  /// First level that can show a full-screen break ad, then every other level.
  static const int interstitialStartLevel = 5;
  static const int interstitialLevelInterval = 2;

  /// Leaving a level can show an ad, but not again until this time has passed.
  static const Duration interstitialLeaveCooldown = Duration(seconds: 40);

  // Animation durations
  static const Duration arrowSlideDuration = Duration(milliseconds: 220);
  // arrowExitDuration is now dynamic (based on path length) — this is the base
  static const Duration arrowExitDuration = Duration(milliseconds: 400);
  static const Duration arrowShakeDuration = Duration(milliseconds: 400);
  static const Duration levelCompleteDuration = Duration(milliseconds: 200);

  // Scoring
  static const int baseScore = 100;
  static const int bonusPerRemainingLife = 50;
  static const int bossBonus = 200;
  static const int godBonus = 500;

  // Streak milestones
  static const int streakMilestone1 = 7;
  static const int streakMilestone2 = 30;
  static const int streakMilestone3 = 100;

  /// How many boss levels have occurred up to and including [level].
  static int bossCycleCount(int level) {
    if (level <= tutorialLevels) return 0;
    int count = 0;
    for (int l = tutorialLevels + 1; l <= level; l++) {
      if (levelTypeFor(l) == LevelType.boss) count++;
    }
    return count;
  }

  /// How many god levels have occurred up to and including [level].
  static int godCycleCount(int level) {
    if (level <= tutorialLevels) return 0;
    int count = 0;
    for (int l = tutorialLevels + 1; l <= level; l++) {
      if (levelTypeFor(l) == LevelType.god) count++;
    }
    return count;
  }

  /// Grid size for a given level number.
  ///   Tutorial :  10×10 (fixed small canvas for guidance)
  ///   Normal   :  15×15 minimum at level 4, ramps to 24×24 at level 19
  ///               25×25 minimum at level 20, ramps to 35×35 at level 500
  ///   Boss     :  27×27 minimum at 1st cycle, ramps to 40×40 at cycle ~20
  ///   God      :  27×27 minimum at 1st cycle, ramps to 40×40 at cycle ~20
  static int gridSizeForLevel(int level) {
    if (level <= tutorialLevels) return 10;

    final type = levelTypeFor(level);

    if (type == LevelType.boss) {
      // Scale 27 → 40 over ~20 boss cycles, then hold at 40.
      final cycle = bossCycleCount(level);
      final raw = 27 + ((cycle - 1) * (13.0 / 19.0)).round();
      return raw.clamp(27, 40);
    }

    if (type == LevelType.god) {
      // Scale 27 → 40 over ~20 god cycles, then hold at 40.
      final cycle = godCycleCount(level);
      final raw = 27 + ((cycle - 1) * (13.0 / 19.0)).round();
      return raw.clamp(27, 40);
    }

    // Normal levels:
    if (level < 20) {
      // Level 4 to 19: min 15, scale gently up to 24.
      final raw = 15 + ((level - 4) * (9.0 / 15.0)).round();
      return raw.clamp(15, 24);
    } else {
      // Level 20+: min 25, scale up to 35.
      final raw = 25 + ((level - 20) * (10.0 / 480.0)).round();
      return raw.clamp(25, 35);
    }
  }

  /// Returns the level type: tutorial, god, boss, or normal.
  ///
  /// Post-tutorial pattern repeats every 7 levels:
  ///   [N, N, N, Boss, N, N, God]
  ///   pos 1-3 → Normal
  ///   pos 4   → Boss
  ///   pos 5-6 → Normal
  ///   pos 7   → God
  static LevelType levelTypeFor(int level) {
    if (level <= tutorialLevels) return LevelType.tutorial;
    // position within the 7-level cycle (1-indexed)
    final pos = ((level - tutorialLevels - 1) % 7) + 1;
    if (pos == 7) return LevelType.god;
    if (pos == 4) return LevelType.boss;
    return LevelType.normal;
  }

  /// Clean standalone helper: true when n is a boss level.
  static bool isBossLevel(int n) => levelTypeFor(n) == LevelType.boss;

  /// True for god levels.
  static bool isGodLevel(int n) => levelTypeFor(n) == LevelType.god;

  /// True only on streak beats worth a banner, not on every exit.
  static bool isComboMilestone(int combo) =>
      combo == 3 ||
      combo == 6 ||
      combo == 10 ||
      (combo >= 15 && combo % 5 == 0);

  /// How tightly board cells sit. 1 fills the play area; lower pulls each row
  /// and column closer together. Arrow thickness is kept the same.
  static const double boardCellSpacing = 0.9;

  /// Cells across the shorter side of the play area. Every level uses this
  /// cell size, so arrow thickness and heads stay the same from level to level.
  /// The play area is whatever remains after safe areas, the HUD, and the
  /// booster dock. 9 is about a third larger than 12 before that inset; with
  /// the stage margin the board reads roughly a quarter larger, and boards
  /// that would overflow still shrink to fit.
  static const double arrowCellSpan = 9;

  /// Canvas scale factor: higher scale factor zooms in default game canvas area.
  static double canvasScaleForType(LevelType type) {
    switch (type) {
      case LevelType.god:
        return 0.97;
      case LevelType.boss:
        return 0.97;
      default:
        return 1.2;
    }
  }
}

enum LevelType {
  tutorial,
  normal,
  boss,
  god;

  String get label {
    switch (this) {
      case LevelType.tutorial:
        return 'Tutorial';
      case LevelType.normal:
        return '';
      case LevelType.boss:
        return 'Boss';
      case LevelType.god:
        return 'God';
    }
  }

  bool get isSpecial => this == LevelType.boss || this == LevelType.god;
}

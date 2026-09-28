import '../core/constants.dart';
import '../game/game_state.dart';

/// One slice of the daily lucky wheel.
class WheelSlice {
  final String label;
  final int coins;
  final PowerUpType? powerUp;
  final bool heart;

  const WheelSlice({
    required this.label,
    this.coins = 0,
    this.powerUp,
    this.heart = false,
  });
}

/// Coins and a power-up from a level-10 chest.
class ChestReward {
  final int level;
  final int coins;
  final PowerUpType powerUp;

  const ChestReward({
    required this.level,
    required this.coins,
    required this.powerUp,
  });
}

class AchievementDef {
  final String id;
  final String title;
  final String description;
  final bool Function(AchievementSnapshot stats) unlocked;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

class AchievementSnapshot {
  final int hintFreeClears;
  final int perfectClears;
  final int bossesCleared;
  final int godsCleared;
  final int shapesCollected;
  final int streakDays;
  final int highestLevel;
  final int lifetimeCoins;

  const AchievementSnapshot({
    required this.hintFreeClears,
    required this.perfectClears,
    required this.bossesCleared,
    required this.godsCleared,
    required this.shapesCollected,
    required this.streakDays,
    required this.highestLevel,
    required this.lifetimeCoins,
  });
}

/// Pure progression math shared by the repository, dialogs, and tests.
class MetaRules {
  MetaRules._();

  static const int chestEvery = 10;

  static int popupScore(int combo) => 10 * combo.clamp(1, 12);

  /// 3 stars: no hearts lost and no power-ups.
  /// 2 stars: at most one heart and one power-up.
  /// 1 star: the board still cleared.
  static int calculateStars({
    required int livesLost,
    required int powerUpsUsed,
  }) {
    if (livesLost <= 0 && powerUpsUsed <= 0) return 3;
    if (livesLost <= 1 && powerUpsUsed <= 1) return 2;
    return 1;
  }

  static int powerUpCost(PowerUpType type) {
    switch (type) {
      case PowerUpType.hint:
        return 80;
      case PowerUpType.eraser:
        return 120;
      case PowerUpType.wand:
        return 160;
      case PowerUpType.ruler:
        return 100;
    }
  }

  static int get heartCost => AppConstants.heartRefillCoinCost;

  static bool isChestLevel(int level) => level > 0 && level % chestEvery == 0;

  static ChestReward chestFor(int level) {
    final tier = level ~/ chestEvery;
    return ChestReward(
      level: level,
      coins: 60 + tier * 20,
      powerUp: PowerUpType.values[tier % PowerUpType.values.length],
    );
  }

  /// Same calendar day always maps to the same mid-game level.
  static int dailyLevel(DateTime day) {
    final seed = day.year * 1000 + day.month * 40 + day.day;
    return 12 + (seed.abs() % 60);
  }

  /// Later streak days pay more.
  static int dailyCoinReward(int streakDays) => 30 + streakDays.clamp(1, 30) * 20;

  static const wheel = <WheelSlice>[
    WheelSlice(label: '50', coins: 50),
    WheelSlice(label: '100', coins: 100),
    WheelSlice(label: 'Hint', powerUp: PowerUpType.hint),
    WheelSlice(label: 'Heart', heart: true),
    WheelSlice(label: '200', coins: 200),
    WheelSlice(label: 'Eraser', powerUp: PowerUpType.eraser),
    WheelSlice(label: 'Wand', powerUp: PowerUpType.wand),
    WheelSlice(label: 'Ruler', powerUp: PowerUpType.ruler),
  ];

  static final achievements = <AchievementDef>[
    AchievementDef(
      id: 'first_clear',
      title: 'First Escape',
      description: 'Clear a level',
      unlocked: (s) => s.highestLevel > 1,
    ),
    AchievementDef(
      id: 'hintless_50',
      title: 'No Hints Needed',
      description: 'Clear 50 levels without a hint',
      unlocked: (s) => s.hintFreeClears >= 50,
    ),
    AchievementDef(
      id: 'perfect_10',
      title: 'Flawless',
      description: 'Earn 3 stars on 10 levels',
      unlocked: (s) => s.perfectClears >= 10,
    ),
    AchievementDef(
      id: 'boss',
      title: 'Boss Breaker',
      description: 'Clear a boss level',
      unlocked: (s) => s.bossesCleared >= 1,
    ),
    AchievementDef(
      id: 'god',
      title: 'Godslayer',
      description: 'Clear a god level',
      unlocked: (s) => s.godsCleared >= 1,
    ),
    AchievementDef(
      id: 'collector',
      title: 'Curator',
      description: 'Uncover 10 shapes',
      unlocked: (s) => s.shapesCollected >= 10,
    ),
    AchievementDef(
      id: 'streak_7',
      title: 'Week of Arrows',
      description: 'Keep a 7-day streak',
      unlocked: (s) => s.streakDays >= 7,
    ),
    AchievementDef(
      id: 'coins_500',
      title: 'Coin Purse',
      description: 'Earn 500 coins',
      unlocked: (s) => s.lifetimeCoins >= 500,
    ),
  ];
}

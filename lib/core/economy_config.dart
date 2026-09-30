import 'constants.dart';

/// Every coin amount, price, and reward limit in one place.
///
/// Store prices are not here. Those come from the platform for the product
/// ids below. This file only says how many coins a completed purchase grants.
class EconomyConfig {
  EconomyConfig._();

  // ── Earning ───────────────────────────────────────────────────────────────
  static const int normalClear = 5;

  /// Total for a perfect clear, not an extra on top of [normalClear].
  static const int perfectClear = 7;

  /// Total for a boss or god level, perfect or not.
  static const int specialClear = 10;

  static const int dailyChallenge = 15;

  /// Total for a perfect daily challenge, not an extra on top of 15.
  static const int dailyChallengePerfect = 20;

  static const List<int> loginRewards = [5, 5, 10, 10, 15, 15, 25];

  static const int rewardedAdCoins = 25;
  static const Duration rewardedAdCooldown = Duration(minutes: 5);

  // ── Spending ──────────────────────────────────────────────────────────────
  static const int hintCost = 25;
  static const int rulerCost = 30;
  static const int eraserCost = 40;
  static const int wandCost = 60;

  /// One explicit purchase restores all hearts, up to [AppConstants.maxLives].
  static const int heartRefillCost = 30;

  // ── Store product ids (prices come from the store, not from here) ────────
  static const String removeAdsId = 'remove_ads';
  static const String coins1000Id = 'coins_1000';
  static const String coins5000Id = 'coins_5000';
  static const String coins10000Id = 'coins_10000';

  static const Map<String, int> storeCoinPacks = {
    coins1000Id: 1000,
    coins5000Id: 5000,
    coins10000Id: 10000,
  };

  /// Coins for one first clear. Replays pay nothing.
  /// A daily challenge uses [dailyChallengeCoins] instead.
  static int levelCoins({
    required LevelType type,
    required bool perfect,
  }) {
    if (type == LevelType.boss || type == LevelType.god) return specialClear;
    return perfect ? perfectClear : normalClear;
  }

  static int dailyChallengeCoins({required bool perfect}) =>
      perfect ? dailyChallengePerfect : dailyChallenge;

  /// [day] is 1–7. Values outside that wrap into the cycle.
  static int loginCoins(int day) {
    if (loginRewards.isEmpty) return 0;
    final index = (day - 1) % loginRewards.length;
    return loginRewards[index < 0 ? 0 : index];
  }

  static int? storeCoins(String productId) => storeCoinPacks[productId];

  static bool isRemoveAds(String productId) => productId == removeAdsId;
}

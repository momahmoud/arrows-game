import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/level.dart';
import '../../core/board_style.dart';
import '../../core/constants.dart';
import '../../core/economy_config.dart';
import '../../core/audio_manager.dart';
import '../../game/game_state.dart';
import '../meta_rules.dart';

class ProgressRepository extends ChangeNotifier {
  final SharedPreferences? _prefs;

  // ── State fields ────────────────────────────────────────────────────────────
  int _lives = AppConstants.maxLives;
  int _currentLevel = 1;
  int _highestUnlockedLevel = 1;
  int _totalScore = 0;
  int _coins = 0;

  // Streak
  int _streakDays = 0;
  DateTime? _lastPlayedDate;

  // Level results
  final Map<int, LevelResult> _levelResults = {};

  // Settings
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _vibrationEnabled = true;
  ThemeMode _themeMode = ThemeMode.system;
  String? _languageCode; // null = follow device

  // 40x40 warning state
  bool _hasSeen40x40Warning = false;

  // Zoom hint state
  bool _hasSeenZoomHint = false;

  // Demo Mode
  bool _isDemoMode = false;

  final Map<PowerUpType, int> _bonusPowerUps = {};
  final Set<String> _shapes = {};
  final Set<String> _ownedCosmetics = {};
  final Set<int> _hintFreeLevels = {};
  final Set<int> _perfectLevels = {};
  final Set<int> _bossLevels = {};
  final Set<int> _godLevels = {};
  final Set<int> _claimedChests = {};
  final Set<String> _playedDays = {};
  ArrowSkin _arrowSkin = ArrowSkin.classic;
  BoardTheme _boardTheme = BoardTheme.classic;
  String? _lastWheelDay;
  String? _lastDailyClaim;
  String? _lastLoginClaim;
  int _loginCycleDay = 0;
  DateTime? _lastRewardedCoinAt;
  bool _adsRemoved = false;
  final Set<String> _storeTransactions = {};
  int _lifetimeCoins = 0;

  // ── Getters ──────────────────────────────────────────────────────────────────
  bool get isDemoMode => _isDemoMode;
  int get lives => _isDemoMode ? 999 : _lives;
  int get maxLives => AppConstants.maxLives;
  int get currentLevel => _currentLevel;
  int get highestUnlockedLevel =>
      _isDemoMode ? AppConstants.totalLevels : _highestUnlockedLevel;
  int get totalScore => _totalScore;
  int get coins => _coins;
  int get streakDays => _streakDays;
  DateTime? get lastPlayedDate => _lastPlayedDate;
  bool get hasLives => _isDemoMode ? true : _lives > 0;
  bool get livesAreFull => _isDemoMode ? true : _lives >= AppConstants.maxLives;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  ThemeMode get themeMode => _themeMode;
  String? get languageCode => _languageCode;
  Locale? get locale => _languageCode == null ? null : Locale(_languageCode!);
  bool get hasSeen40x40Warning => _hasSeen40x40Warning;
  bool get hasSeenZoomHint => _hasSeenZoomHint;

  ArrowSkin get arrowSkin => _arrowSkin;
  BoardTheme get boardTheme => _boardTheme;
  int get lifetimeCoins => _lifetimeCoins;
  int get unlockedShapeCount => _shapes.length;
  Set<String> get playedDays => Set.unmodifiable(_playedDays);
  bool get canSpinWheel => _lastWheelDay != _dayKey(DateTime.now());
  bool get dailyClaimedToday => _lastDailyClaim == _dayKey(DateTime.now());
  bool get adsRemoved => _adsRemoved;
  bool get canAffordHeartRefill =>
      !livesAreFull && canAfford(EconomyConfig.heartRefillCost);

  /// Next login gift, 1–7, if it has not been claimed today.
  int? get pendingLoginDay {
    final today = _dayKey(DateTime.now());
    if (_lastLoginClaim == today) return null;
    return _nextLoginDay();
  }

  bool get canClaimRewardedCoins {
    final at = _lastRewardedCoinAt;
    if (at == null) return true;
    return DateTime.now().difference(at) >= EconomyConfig.rewardedAdCooldown;
  }

  int bonusPowerUp(PowerUpType type) => _bonusPowerUps[type] ?? 0;
  bool hasShape(MaskShape shape) => _shapes.contains(shape.name);

  AchievementSnapshot get achievementSnapshot => AchievementSnapshot(
        hintFreeClears: _hintFreeLevels.length,
        perfectClears: _perfectLevels.length,
        bossesCleared: _bossLevels.length,
        godsCleared: _godLevels.length,
        shapesCollected: _shapes.length,
        streakDays: _streakDays,
        highestLevel: _highestUnlockedLevel,
        lifetimeCoins: _lifetimeCoins,
      );

  int getStarsForLevel(int level) => _levelResults[level]?.stars ?? 0;

  bool isLevelUnlocked(int level) {
    if (_isDemoMode) return true;
    return level <= _highestUnlockedLevel;
  }

  void toggleDemoMode() {
    _isDemoMode = !_isDemoMode;
    notifyListeners();
  }

  bool isLevelCompleted(int level) => _levelResults.containsKey(level);

  ProgressRepository([this._prefs]) {
    _load();
  }

  // ── Load / Save ──────────────────────────────────────────────────────────────

  void _load() {
    if (_prefs == null) return;
    try {
      _lives = (_prefs!.getInt('lives') ?? AppConstants.maxLives)
          .clamp(0, AppConstants.maxLives);
      _currentLevel = _prefs!.getInt('currentLevel') ?? 1;
      _highestUnlockedLevel = _prefs!.getInt('highestUnlockedLevel') ?? 1;
      _totalScore = _prefs!.getInt('totalScore') ?? 0;
      _coins = (_prefs!.getInt('coins') ?? 0).clamp(0, 1 << 30);
      _streakDays = _prefs!.getInt('streakDays') ?? 0;

      _soundEnabled = _prefs!.getBool('soundEnabled') ?? true;
      _musicEnabled = _prefs!.getBool('musicEnabled') ?? true;
      _vibrationEnabled = _prefs!.getBool('vibrationEnabled') ?? true;
      _hasSeen40x40Warning = _prefs!.getBool('hasSeen40x40Warning') ?? false;
      _hasSeenZoomHint = _prefs!.getBool('hasSeenZoomHint') ?? false;

      final themeStr = _prefs!.getString('themeMode') ?? 'system';
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.name == themeStr,
        orElse: () => ThemeMode.system,
      );
      _languageCode = _prefs!.getString('languageCode');

      // Synchronize to AudioManager
      AudioManager.instance.setSoundEnabled(_soundEnabled);
      AudioManager.instance.setMusicEnabled(_musicEnabled);

      final lastPlayedStr = _prefs!.getString('lastPlayedDate');
      if (lastPlayedStr != null) {
        _lastPlayedDate = DateTime.tryParse(lastPlayedStr);
      }

      _lifetimeCoins = _prefs!.getInt('lifetimeCoins') ?? _coins;
      if (_lifetimeCoins < _coins) _lifetimeCoins = _coins;
      _lastWheelDay = _prefs!.getString('lastWheelDay');
      _lastDailyClaim = _prefs!.getString('lastDailyClaim');
      _lastLoginClaim = _prefs!.getString('lastLoginClaim');
      _loginCycleDay = _prefs!.getInt('loginCycleDay') ?? 0;
      _adsRemoved = _prefs!.getBool('adsRemoved') ?? false;
      final rewardedAt = _prefs!.getString('lastRewardedCoinAt');
      if (rewardedAt != null) {
        _lastRewardedCoinAt = DateTime.tryParse(rewardedAt);
      }
      _storeTransactions.addAll(_stringSet('storeTransactions'));
      _arrowSkin =
          _enumByName(ArrowSkin.values, _prefs!.getString('arrowSkin'));
      _boardTheme =
          _enumByName(BoardTheme.values, _prefs!.getString('boardTheme'));
      _shapes.addAll(_stringSet('shapes'));
      _ownedCosmetics.addAll(_stringSet('ownedCosmetics'));
      _playedDays.addAll(_stringSet('playedDays'));
      _hintFreeLevels.addAll(_intSet('hintFreeLevels'));
      _perfectLevels.addAll(_intSet('perfectLevels'));
      _bossLevels.addAll(_intSet('bossLevels'));
      _godLevels.addAll(_intSet('godLevels'));
      _claimedChests.addAll(_intSet('claimedChests'));
      final bonusJson = _prefs!.getString('bonusPowerUps');
      if (bonusJson != null) {
        final map = jsonDecode(bonusJson) as Map<String, dynamic>;
        for (final type in PowerUpType.values) {
          final n = map[type.name];
          if (n is int && n > 0) _bonusPowerUps[type] = n;
        }
      }

      final resultsJson = _prefs!.getString('levelResults');
      if (resultsJson != null) {
        final Map<String, dynamic> map = jsonDecode(resultsJson);
        for (final entry in map.entries) {
          final level = int.tryParse(entry.key);
          if (level != null) {
            _levelResults[level] =
                LevelResult.fromJson(entry.value as Map<String, dynamic>);
          }
        }
      }

      // Check streak
      _updateStreak();
    } catch (e) {
      debugPrint('Error loading progress from SharedPreferences: $e');
    }
  }

  Future<void> _save() async {
    if (_prefs == null) return;
    try {
      await Future.wait([
        _prefs!.setInt('lives', _lives),
        _prefs!.setInt('currentLevel', _currentLevel),
        _prefs!.setInt('highestUnlockedLevel', _highestUnlockedLevel),
        _prefs!.setInt('totalScore', _totalScore),
        _prefs!.setInt('coins', _coins),
        _prefs!.setInt('lifetimeCoins', _lifetimeCoins),
        _prefs!.setInt('streakDays', _streakDays),
        _prefs!.setString('arrowSkin', _arrowSkin.name),
        _prefs!.setString('boardTheme', _boardTheme.name),
        _prefs!.setString('shapes', jsonEncode(_shapes.toList())),
        _prefs!
            .setString('ownedCosmetics', jsonEncode(_ownedCosmetics.toList())),
        _prefs!.setString('playedDays', jsonEncode(_playedDays.toList())),
        _prefs!
            .setString('hintFreeLevels', jsonEncode(_hintFreeLevels.toList())),
        _prefs!.setString('perfectLevels', jsonEncode(_perfectLevels.toList())),
        _prefs!.setString('bossLevels', jsonEncode(_bossLevels.toList())),
        _prefs!.setString('godLevels', jsonEncode(_godLevels.toList())),
        _prefs!.setString('claimedChests', jsonEncode(_claimedChests.toList())),
        _prefs!.setString(
          'bonusPowerUps',
          jsonEncode(
              {for (final e in _bonusPowerUps.entries) e.key.name: e.value}),
        ),
        if (_lastWheelDay != null)
          _prefs!.setString('lastWheelDay', _lastWheelDay!),
        if (_lastDailyClaim != null)
          _prefs!.setString('lastDailyClaim', _lastDailyClaim!),
        if (_lastLoginClaim != null)
          _prefs!.setString('lastLoginClaim', _lastLoginClaim!),
        _prefs!.setInt('loginCycleDay', _loginCycleDay),
        _prefs!.setBool('adsRemoved', _adsRemoved),
        _prefs!.setString(
            'storeTransactions', jsonEncode(_storeTransactions.toList())),
        if (_lastRewardedCoinAt != null)
          _prefs!.setString(
              'lastRewardedCoinAt', _lastRewardedCoinAt!.toIso8601String()),
        if (_lastPlayedDate != null)
          _prefs!
              .setString('lastPlayedDate', _lastPlayedDate!.toIso8601String()),
      ]);
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }

    // Save level results
    if (_prefs != null) {
      final Map<String, dynamic> resultsMap = {};
      for (final entry in _levelResults.entries) {
        resultsMap[entry.key.toString()] = entry.value.toJson();
      }
      await _prefs?.setString('levelResults', jsonEncode(resultsMap));
    }
  }

  // ── Lives — restored only via rewarded ad or level restart ─────────────────

  /// Called by GameState when player makes a wrong move.
  /// NOTE: Lives are NOT decremented from here — GameState manages lives
  /// during gameplay. This method is for external persistence (e.g. continue).
  Future<void> restoreLives({int amount = AppConstants.maxLives}) async {
    _lives = (_lives + amount).clamp(0, AppConstants.maxLives);
    await _save();
    notifyListeners();
  }

  /// Reset lives to full — called when player restarts a level.
  Future<void> resetLivesToFull() async {
    _lives = AppConstants.maxLives;
    await _save();
    notifyListeners();
  }

  // ── Streak ───────────────────────────────────────────────────────────────────

  void _updateStreak() {
    if (_lastPlayedDate == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastPlayed = DateTime(
      _lastPlayedDate!.year,
      _lastPlayedDate!.month,
      _lastPlayedDate!.day,
    );
    final diff = today.difference(lastPlayed).inDays;
    if (diff > 1) {
      // Streak broken
      _streakDays = 0;
      _save();
    }
  }

  Future<void> recordDailyPlay() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastPlayedDate != null) {
      final lastPlayed = DateTime(
        _lastPlayedDate!.year,
        _lastPlayedDate!.month,
        _lastPlayedDate!.day,
      );
      final diff = today.difference(lastPlayed).inDays;
      if (diff == 0) return; // Already recorded today
      if (diff == 1) {
        _streakDays++; // Consecutive day
      } else {
        _streakDays = 1; // Restart streak
      }
    } else {
      _streakDays = 1;
    }

    _lastPlayedDate = now;
    _playedDays.add(_dayKey(now));
    await _save();
    notifyListeners();
  }

  Future<void> protectStreak() async {
    // Called after watching a rewarded ad on streak break
    _lastPlayedDate = DateTime.now();
    await _save();
    notifyListeners();
  }

  // ── Level Progress ────────────────────────────────────────────────────────────

  /// Records the clear. Coins are paid once: the daily reward on a daily
  /// run, otherwise the first-clear reward. A replay updates stars only.
  Future<int> recordLevelComplete(
    LevelResult result, {
    required LevelType levelType,
    required bool perfect,
    required bool daily,
  }) async {
    final firstClear = !_levelResults.containsKey(result.levelNumber);
    final existing = _levelResults[result.levelNumber];
    if (existing == null || result.stars > existing.stars) {
      _levelResults[result.levelNumber] = result;
    }
    var granted = 0;
    if (daily) {
      granted = claimDailyChallenge(perfect: perfect);
    } else if (firstClear) {
      granted = EconomyConfig.levelCoins(type: levelType, perfect: perfect);
      _grantCoins(granted);
    }
    _totalScore += result.score;
    _currentLevel = result.levelNumber + 1;
    if (_currentLevel > _highestUnlockedLevel) {
      _highestUnlockedLevel = _currentLevel;
    }
    await _save();
    notifyListeners();
    return granted;
  }

  Future<void> setCurrentLevel(int level) async {
    _currentLevel = level;
    await _save();
    notifyListeners();
  }

  bool canAfford(int amount) => amount > 0 && _coins >= amount;

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _grantCoins(amount);
    await _save();
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (amount <= 0 || _coins < amount) return false;
    _coins -= amount;
    _save();
    notifyListeners();
    return true;
  }

  /// +25 after a completed rewarded ad. Returns 0 when the cooldown is open
  /// or the callback is a duplicate inside that window.
  int claimRewardedCoins() {
    if (!canClaimRewardedCoins) return 0;
    _lastRewardedCoinAt = DateTime.now();
    _grantCoins(EconomyConfig.rewardedAdCoins);
    _save();
    notifyListeners();
    return EconomyConfig.rewardedAdCoins;
  }

  // ── Settings Setters ─────────────────────────────────────────────────────────

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    AudioManager.instance.setSoundEnabled(value);
    await _prefs?.setBool('soundEnabled', value);
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    AudioManager.instance.setMusicEnabled(value);
    await _prefs?.setBool('musicEnabled', value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await _prefs?.setBool('vibrationEnabled', value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    await _prefs?.setString('themeMode', value.name);
    notifyListeners();
  }

  /// Pass null to follow the device language.
  Future<void> setLanguageCode(String? code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    if (code == null) {
      await _prefs?.remove('languageCode');
    } else {
      await _prefs?.setString('languageCode', code);
    }
    notifyListeners();
  }

  Future<void> setHasSeen40x40Warning(bool value) async {
    _hasSeen40x40Warning = value;
    await _prefs?.setBool('hasSeen40x40Warning', value);
    notifyListeners();
  }

  Future<void> setHasSeenZoomHint(bool value) async {
    _hasSeenZoomHint = value;
    await _prefs?.setBool('hasSeenZoomHint', value);
    notifyListeners();
  }

  // ── Star rating calculator ────────────────────────────────────────────────────
  static int calculateStars({
    required int livesLost,
    required int powerUpsUsed,
  }) =>
      MetaRules.calculateStars(
        livesLost: livesLost,
        powerUpsUsed: powerUpsUsed,
      );

  void _grantCoins(int amount) {
    if (amount <= 0) return;
    _coins += amount;
    _lifetimeCoins += amount;
  }

  String _dayKey(DateTime day) => '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  Set<String> _stringSet(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return {};
    final list = jsonDecode(raw);
    if (list is! List) return {};
    return list.map((e) => e.toString()).toSet();
  }

  Set<int> _intSet(String key) {
    return _stringSet(key).map(int.tryParse).whereType<int>().toSet();
  }

  T _enumByName<T extends Enum>(List<T> values, String? name) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return values.first;
  }

  void unlockShape(MaskShape shape) {
    if (_shapes.add(shape.name)) {
      _save();
      notifyListeners();
    }
  }

  void noteHintFreeClear(int level) => _noteLevel(_hintFreeLevels, level);

  void notePerfectClear(int level) => _noteLevel(_perfectLevels, level);

  void noteBossClear(int level) => _noteLevel(_bossLevels, level);

  void noteGodClear(int level) => _noteLevel(_godLevels, level);

  void _noteLevel(Set<int> bucket, int level) {
    if (bucket.add(level)) {
      _save();
      notifyListeners();
    }
  }

  void spendBonusPowerUp(PowerUpType type) {
    final left = bonusPowerUp(type);
    if (left <= 0) return;
    _bonusPowerUps[type] = left - 1;
    _save();
    notifyListeners();
  }

  void addBonusPowerUp(PowerUpType type, [int amount = 1]) {
    if (amount <= 0) return;
    _bonusPowerUps[type] = bonusPowerUp(type) + amount;
    _save();
    notifyListeners();
  }

  bool buyPowerUp(PowerUpType type) {
    if (!spendCoins(MetaRules.powerUpCost(type))) return false;
    addBonusPowerUp(type, 1);
    return true;
  }

  /// Pays for a full heart bar. Refuses when the saved hearts are already full.
  bool refillHearts() {
    if (livesAreFull) return false;
    return payHeartRefill();
  }

  /// Charges the refill price and sets saved hearts to 3.
  /// Used from a failed attempt, where the board hearts are empty even if
  /// the saved counter is already full.
  bool payHeartRefill() {
    if (!spendCoins(EconomyConfig.heartRefillCost)) return false;
    _lives = AppConstants.maxLives;
    _save();
    notifyListeners();
    return true;
  }

  bool buyHeart() => refillHearts();

  ChestReward? claimChest(int level) {
    if (!MetaRules.isChestLevel(level) || !_claimedChests.add(level)) {
      return null;
    }
    final reward = MetaRules.chestFor(level);
    _grantCoins(reward.coins);
    _bonusPowerUps[reward.powerUp] = bonusPowerUp(reward.powerUp) + 1;
    _save();
    notifyListeners();
    return reward;
  }

  int claimDailyChallenge({bool perfect = false}) {
    final today = _dayKey(DateTime.now());
    if (_lastDailyClaim == today) return 0;
    _lastDailyClaim = today;
    final reward = EconomyConfig.dailyChallengeCoins(perfect: perfect);
    _grantCoins(reward);
    _save();
    notifyListeners();
    return reward;
  }

  int _nextLoginDay() {
    final today = _dayKey(DateTime.now());
    if (_lastLoginClaim == null) return 1;
    final last = DateTime.tryParse(_lastLoginClaim!);
    if (last == null) return 1;
    final lastDay = DateTime(last.year, last.month, last.day);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final gap = todayDate.difference(lastDay).inDays;
    if (_lastLoginClaim == today || gap <= 0) return _loginCycleDay;
    if (gap == 1) {
      return _loginCycleDay >= EconomyConfig.loginRewards.length
          ? 1
          : _loginCycleDay + 1;
    }
    return 1;
  }

  /// Once per local calendar day. Missing a day starts the cycle again.
  int claimLoginReward() {
    if (_lastLoginClaim == _dayKey(DateTime.now())) return 0;
    final day = _nextLoginDay();
    final reward = EconomyConfig.loginCoins(day);
    _loginCycleDay = day;
    _lastLoginClaim = _dayKey(DateTime.now());
    _grantCoins(reward);
    _save();
    notifyListeners();
    return reward;
  }

  /// Grants a store purchase once per [transactionId]. Returns coins added.
  /// An empty or unknown purchase adds nothing. Cancelled purchases never
  /// reach this method.
  int grantStorePurchase({
    required String productId,
    required String transactionId,
  }) {
    if (transactionId.isEmpty) return 0;
    if (!_storeTransactions.add(transactionId)) return 0;
    if (EconomyConfig.isRemoveAds(productId)) {
      _adsRemoved = true;
      _save();
      notifyListeners();
      return 0;
    }
    final coins = EconomyConfig.storeCoins(productId);
    if (coins == null || coins <= 0) {
      _storeTransactions.remove(transactionId);
      return 0;
    }
    _grantCoins(coins);
    _save();
    notifyListeners();
    return coins;
  }

  WheelSlice? spinWheel(int index) {
    if (!canSpinWheel || index < 0 || index >= MetaRules.wheel.length) {
      return null;
    }
    final slice = MetaRules.wheel[index];
    _lastWheelDay = _dayKey(DateTime.now());
    _grantCoins(slice.coins);
    final powerUp = slice.powerUp;
    if (powerUp != null) {
      _bonusPowerUps[powerUp] = bonusPowerUp(powerUp) + 1;
    }
    if (slice.heart && _lives < AppConstants.maxLives) {
      _lives++;
    }
    _save();
    notifyListeners();
    return slice;
  }

  bool ownsCosmetic(String id) {
    if (id == BoardStyle.skinId(ArrowSkin.classic) ||
        id == BoardStyle.themeId(BoardTheme.classic)) {
      return true;
    }
    if (_ownedCosmetics.contains(id)) return true;
    final offer = BoardStyle.offerById(id);
    if (offer == null) return false;
    return BoardStyle.unlockedByProgress(offer, _highestUnlockedLevel);
  }

  bool isCosmeticEquipped(CosmeticOffer offer) {
    if (offer.skin != null) return _arrowSkin == offer.skin;
    if (offer.theme != null) return _boardTheme == offer.theme;
    return false;
  }

  bool equipCosmetic(String id) {
    if (!ownsCosmetic(id)) return false;
    final offer = BoardStyle.offerById(id);
    if (offer == null) return false;
    if (offer.skin != null) _arrowSkin = offer.skin!;
    if (offer.theme != null) _boardTheme = offer.theme!;
    _save();
    notifyListeners();
    return true;
  }

  bool buyCosmetic(String id) {
    if (ownsCosmetic(id)) return equipCosmetic(id);
    final offer = BoardStyle.offerById(id);
    if (offer == null || !spendCoins(offer.coinCost)) return false;
    _ownedCosmetics.add(id);
    return equipCosmetic(id);
  }
}

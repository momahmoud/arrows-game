import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/models/arrow.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:arrow_escape/data/repositories/progress_repository.dart';
import 'package:arrow_escape/game/game_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameState _gameState() => GameState(
      level: LevelModel(
        levelNumber: 10,
        gridSize: 5,
        arrows: const [],
        patternName: 'test',
        difficulty: Difficulty.easy,
      ),
      onLevelComplete: () {},
      onGameOver: () {},
      onLifeLost: () {},
      onDeadlock: () {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('per-level power-ups', () {
    test('each level starts with its own allotment', () {
      final gs = _gameState();
      for (final t in PowerUpType.values) {
        expect(gs.powerUpCount(t), AppConstants.powerUpsPerLevel);
      }
    });

    test('consume stops at zero and add refills', () {
      final gs = _gameState();
      for (var i = 0; i < AppConstants.powerUpsPerLevel; i++) {
        expect(gs.consumePowerUp(PowerUpType.hint), isTrue);
      }
      expect(gs.consumePowerUp(PowerUpType.hint), isFalse);
      expect(gs.powerUpCount(PowerUpType.hint), 0);

      gs.addPowerUp(PowerUpType.hint, 2);
      expect(gs.powerUpCount(PowerUpType.hint), 2);
      expect(gs.powerUpCount(PowerUpType.wand), AppConstants.powerUpsPerLevel);
    });

    test('restarting the level restores the allotment', () {
      final gs = _gameState();
      gs.consumePowerUp(PowerUpType.ruler);
      gs.resetLevel();
      expect(gs.powerUpCount(PowerUpType.ruler), AppConstants.powerUpsPerLevel);
    });

    test('a new level does not inherit the previous level usage', () {
      final first = _gameState()..consumePowerUp(PowerUpType.eraser);
      expect(first.powerUpCount(PowerUpType.eraser),
          AppConstants.powerUpsPerLevel - 1);
      expect(_gameState().powerUpCount(PowerUpType.eraser),
          AppConstants.powerUpsPerLevel);
    });
  });

  group('eraser', () {
    // Two arrows facing each other on one row: each blocks the other.
    GameState blockedPair() => GameState(
          level: LevelModel(
            levelNumber: 10,
            gridSize: 5,
            arrows: [
              ArrowModel(
                  id: 'a',
                  row: 2,
                  col: 1,
                  direction: ArrowDirection.right,
                  path: [
                    [2, 1],
                    [2, 0]
                  ]),
              ArrowModel(
                  id: 'b',
                  row: 2,
                  col: 3,
                  direction: ArrowDirection.left,
                  path: [
                    [2, 3],
                    [2, 4]
                  ]),
            ],
            patternName: 'test',
            difficulty: Difficulty.easy,
          ),
          onLevelComplete: () {},
          onGameOver: () {},
          onLifeLost: () {},
          onDeadlock: () {},
        );

    test('armed eraser removes the tapped arrow even when blocked', () {
      final gs = blockedPair();
      expect(gs.isArrowBlocked('a'), isTrue);

      gs.setEraserArmed(true);
      expect(gs.tapArrow('a'), TapResult.erased);
      expect(gs.isEraserArmed, isFalse);
      expect(gs.powerUpCount(PowerUpType.eraser),
          AppConstants.powerUpsPerLevel - 1);
      expect(gs.lives, AppConstants.maxLives);
      expect(gs.movesUsed, 0);

      gs.handleArrowExitCompleted('a');
      expect(gs.arrows.map((a) => a.id), ['b']);
      expect(gs.isArrowBlocked('b'), isFalse);
    });

    test('without arming, tapping a blocked arrow costs a life', () {
      final gs = blockedPair();
      expect(gs.tapArrow('a'), TapResult.blocked);
      expect(gs.lives, AppConstants.maxLives - 1);
      expect(
          gs.powerUpCount(PowerUpType.eraser), AppConstants.powerUpsPerLevel);
    });

    test('armed eraser with no charges does nothing', () {
      final gs = blockedPair();
      while (gs.consumePowerUp(PowerUpType.eraser)) {}
      gs.setEraserArmed(true);
      expect(gs.tapArrow('a'), TapResult.ignored);
      expect(gs.arrows.length, 2);
    });

    test('restarting disarms the eraser', () {
      final gs = blockedPair()..setEraserArmed(true);
      gs.resetLevel();
      expect(gs.isEraserArmed, isFalse);
    });
  });

  group('hearts', () {
    test('refillLives restores all hearts', () {
      final gs = _gameState();
      gs.refillLives();
      expect(gs.lives, AppConstants.maxLives);
      expect(gs.isGameOver, isFalse);
    });
  });

  group('coins', () {
    setUp(() => SharedPreferences.setMockInitialValues({'coins': 250}));

    test('spendCoins deducts when affordable', () async {
      final repo = ProgressRepository(await SharedPreferences.getInstance());
      expect(repo.spendCoins(AppConstants.heartRefillCoinCost), isTrue);
      expect(repo.coins, 250 - AppConstants.heartRefillCoinCost);
    });

    test('spendCoins refuses when balance is too low', () async {
      final repo = ProgressRepository(await SharedPreferences.getInstance());
      repo.spendCoins(AppConstants.heartRefillCoinCost);
      final before = repo.coins;
      expect(repo.spendCoins(AppConstants.heartRefillCoinCost), isFalse);
      expect(repo.coins, before);
    });
  });
}

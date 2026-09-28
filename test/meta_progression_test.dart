import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/meta_rules.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:arrow_escape/data/repositories/progress_repository.dart';
import 'package:arrow_escape/data/shape_catalog.dart';
import 'package:arrow_escape/game/game_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameState _state({
  Map<PowerUpType, int>? starting,
  void Function(PowerUpType type)? onBonus,
}) {
  return GameState(
    level: LevelModel(
      levelNumber: 4,
      gridSize: 4,
      arrows: const [],
      patternName: 'test',
      difficulty: Difficulty.easy,
    ),
    onLevelComplete: () {},
    onGameOver: () {},
    onLifeLost: () {},
    onDeadlock: () {},
    startingPowerUps: starting,
    onBonusPowerUpUsed: onBonus,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('stars', () {
    test('full hearts and no power-ups is 3 stars', () {
      expect(
        MetaRules.calculateStars(livesLost: 0, powerUpsUsed: 0),
        3,
      );
    });

    test('one heart or one power-up is 2 stars', () {
      expect(MetaRules.calculateStars(livesLost: 1, powerUpsUsed: 0), 2);
      expect(MetaRules.calculateStars(livesLost: 0, powerUpsUsed: 1), 2);
    });

    test('heavier losses drop to 1 star', () {
      expect(MetaRules.calculateStars(livesLost: 2, powerUpsUsed: 0), 1);
      expect(MetaRules.calculateStars(livesLost: 0, powerUpsUsed: 2), 1);
    });
  });

  group('chest and daily', () {
    test('every 10th level is a chest with a rising coin payout', () {
      expect(MetaRules.isChestLevel(10), isTrue);
      expect(MetaRules.isChestLevel(11), isFalse);
      final first = MetaRules.chestFor(10);
      final later = MetaRules.chestFor(40);
      expect(later.coins, greaterThan(first.coins));
    });

    test('the same calendar day always picks the same level', () {
      final day = DateTime(2026, 9, 28);
      expect(MetaRules.dailyLevel(day), MetaRules.dailyLevel(day));
      expect(MetaRules.dailyLevel(day), inInclusiveRange(12, 71));
    });

    test('daily coins climb with the streak', () {
      expect(
        MetaRules.dailyCoinReward(7),
        greaterThan(MetaRules.dailyCoinReward(1)),
      );
    });
  });

  group('bonus inventory', () {
    test('free charges are spent before banked power-ups', () {
      final spent = <PowerUpType>[];
      final gs = _state(
        starting: {
          for (final type in PowerUpType.values)
            type: AppConstants.powerUpsPerLevel +
                (type == PowerUpType.hint ? 1 : 0),
        },
        onBonus: spent.add,
      );

      for (var i = 0; i < AppConstants.powerUpsPerLevel; i++) {
        expect(gs.consumePowerUp(PowerUpType.hint), isTrue);
      }
      expect(spent, isEmpty);
      expect(gs.consumePowerUp(PowerUpType.hint), isTrue);
      expect(spent, [PowerUpType.hint]);
      expect(gs.hintsUsed, AppConstants.powerUpsPerLevel + 1);
    });
  });

  group('progress meta', () {
    late ProgressRepository progress;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      progress = ProgressRepository(prefs);
    });

    test('chest, shape, and hint-free clear are recorded once', () async {
      expect(progress.claimChest(10), isNotNull);
      expect(progress.claimChest(10), isNull);
      expect(progress.bonusPowerUp(MetaRules.chestFor(10).powerUp), 1);

      progress.unlockShape(MaskShape.castle);
      progress.unlockShape(MaskShape.castle);
      expect(progress.hasShape(MaskShape.castle), isTrue);
      expect(progress.unlockedShapeCount, 1);
      expect(ShapeCatalog.displayName(MaskShape.seaTurtle), 'Sea Turtle');
      expect(
        ShapeCatalog.categoryOf(MaskShape.castle),
        ShapeCategory.objects,
      );

      progress.noteHintFreeClear(3);
      progress.noteHintFreeClear(3);
      expect(progress.achievementSnapshot.hintFreeClears, 1);
    });

    test('shop purchase spends coins and stocks a power-up', () async {
      await progress.addCoins(MetaRules.powerUpCost(PowerUpType.hint));
      expect(progress.buyPowerUp(PowerUpType.hint), isTrue);
      expect(progress.bonusPowerUp(PowerUpType.hint), 1);
      expect(progress.coins, 0);
      expect(progress.buyPowerUp(PowerUpType.hint), isFalse);
    });

    test('hintless achievement unlocks at 50 unique clears', () {
      final locked = MetaRules.achievements
          .firstWhere((a) => a.id == 'hintless_50')
          .unlocked(const AchievementSnapshot(
            hintFreeClears: 49,
            perfectClears: 0,
            bossesCleared: 0,
            godsCleared: 0,
            shapesCollected: 0,
            streakDays: 0,
            highestLevel: 1,
            lifetimeCoins: 0,
          ));
      final open = MetaRules.achievements
          .firstWhere((a) => a.id == 'hintless_50')
          .unlocked(const AchievementSnapshot(
            hintFreeClears: 50,
            perfectClears: 0,
            bossesCleared: 0,
            godsCleared: 0,
            shapesCollected: 0,
            streakDays: 0,
            highestLevel: 1,
            lifetimeCoins: 0,
          ));
      expect(locked, isFalse);
      expect(open, isTrue);
    });
  });
}

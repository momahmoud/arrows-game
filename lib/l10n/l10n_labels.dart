import '../core/constants.dart';
import '../data/meta_rules.dart';
import '../data/models/level.dart';
import '../data/shape_catalog.dart';
import '../game/game_state.dart';
import 'generated/app_localizations.dart';

/// Localized names for domain enums and ids that live outside the widget tree.
extension L10nLabels on AppLocalizations {
  String difficulty(Difficulty d) {
    switch (d) {
      case Difficulty.tutorial:
        return difficultyTutorial;
      case Difficulty.easy:
        return difficultyEasy;
      case Difficulty.medium:
        return difficultyMedium;
      case Difficulty.hard:
        return difficultyHard;
      case Difficulty.expert:
        return difficultyExpert;
      case Difficulty.master:
        return difficultyMaster;
      case Difficulty.legend:
        return difficultyLegend;
    }
  }

  String levelType(LevelType type) {
    switch (type) {
      case LevelType.tutorial:
        return levelTypeTutorial;
      case LevelType.normal:
        return '';
      case LevelType.boss:
        return levelTypeBoss;
      case LevelType.god:
        return levelTypeGod;
    }
  }

  String powerUp(PowerUpType type) {
    switch (type) {
      case PowerUpType.hint:
        return powerUpHint;
      case PowerUpType.eraser:
        return powerUpEraser;
      case PowerUpType.wand:
        return powerUpWand;
      case PowerUpType.ruler:
        return powerUpRuler;
    }
  }

  String shapeCategory(ShapeCategory category) {
    switch (category) {
      case ShapeCategory.geometric:
        return categoryShapes;
      case ShapeCategory.animals:
        return categoryAnimals;
      case ShapeCategory.nature:
        return categoryNature;
      case ShapeCategory.food:
        return categoryFood;
      case ShapeCategory.objects:
        return categoryObjects;
      case ShapeCategory.music:
        return categoryMusic;
      case ShapeCategory.characters:
        return categoryCharacters;
    }
  }

  String shapeName(MaskShape shape) =>
      ShapeCatalog.displayName(shape, languageCode: localeName);

  String achievementTitle(AchievementDef a) => switch (a.id) {
        'first_clear' => achFirstClearTitle,
        'hintless_50' => achHintless50Title,
        'perfect_10' => achPerfect10Title,
        'boss' => achBossTitle,
        'god' => achGodTitle,
        'collector' => achCollectorTitle,
        'streak_7' => achStreak7Title,
        'coins_500' => achCoins500Title,
        _ => a.title,
      };

  String achievementDescription(AchievementDef a) => switch (a.id) {
        'first_clear' => achFirstClearDesc,
        'hintless_50' => achHintless50Desc,
        'perfect_10' => achPerfect10Desc,
        'boss' => achBossDesc,
        'god' => achGodDesc,
        'collector' => achCollectorDesc,
        'streak_7' => achStreak7Desc,
        'coins_500' => achCoins500Desc,
        _ => a.description,
      };

  String cosmeticName(String id, String fallback) => switch (id) {
        'skin_classic' => skinClassicName,
        'skin_neon' => skinNeonName,
        'skin_wood' => skinWoodName,
        'skin_candy' => skinCandyName,
        'skin_space' => skinSpaceName,
        'theme_classic' => themeClassicName,
        'theme_neon' => themeNeonName,
        'theme_wood' => themeWoodName,
        'theme_candy' => themeCandyName,
        'theme_space' => themeSpaceName,
        _ => fallback,
      };

  String cosmeticBlurb(String id, String fallback) => switch (id) {
        'skin_classic' => skinClassicBlurb,
        'skin_neon' => skinNeonBlurb,
        'skin_wood' => skinWoodBlurb,
        'skin_candy' => skinCandyBlurb,
        'skin_space' => skinSpaceBlurb,
        'theme_classic' => themeClassicBlurb,
        'theme_neon' => themeNeonBlurb,
        'theme_wood' => themeWoodBlurb,
        'theme_candy' => themeCandyBlurb,
        'theme_space' => themeSpaceBlurb,
        _ => fallback,
      };

  /// Short label painted on the wheel face.
  String wheelSliceLabel(WheelSlice slice) {
    if (slice.powerUp != null) return powerUp(slice.powerUp!);
    if (slice.heart) return heart;
    return '${slice.coins}';
  }

  /// Full prize wording for the result line.
  String wheelPrize(WheelSlice slice) {
    if (slice.coins > 0) return coinsAmount(slice.coins);
    return wheelSliceLabel(slice);
  }

  List<String> get normalLoadingMessages => loadingMessagesNormal.split('|');
  List<String> get bossLoadingMessages => loadingMessagesBoss.split('|');
  List<String> get godLoadingMessages => loadingMessagesGod.split('|');
}

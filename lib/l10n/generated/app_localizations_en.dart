// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Arrow Escape';

  @override
  String get splashTagline => 'Slide. Clear. Conquer.';

  @override
  String get splashLoadingAssets => 'Loading assets…';

  @override
  String get splashGeneratingLevels => 'Generating levels…';

  @override
  String get splashAlmostReady => 'Almost ready…';

  @override
  String levelNumber(int number) {
    return 'Level $number';
  }

  @override
  String get mainMenu => 'Main Menu';

  @override
  String get backToMenu => 'Back to Menu';

  @override
  String get restartLevel => 'Restart Level';

  @override
  String get settings => 'Settings';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get backgroundMusic => 'Background Music';

  @override
  String get hapticFeedback => 'Haptic Feedback';

  @override
  String get vibration => 'Vibration';

  @override
  String get themeMode => 'Theme Mode';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get shapePreview => 'Shape preview';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get rateApp => 'Rate the App';

  @override
  String get outOfLives => 'Out of Lives!';

  @override
  String get outOfTime => 'Out of Time!';

  @override
  String get getOneMoreLife => 'Get 1 More Life & Continue';

  @override
  String get watchAdForLife => 'Watch an ad to get 1 more life';

  @override
  String get watchAdForLifeContinue =>
      'Watch an ad to get 1 more life and continue';

  @override
  String watchAdForTime(int seconds) {
    return 'Watch an ad to get +$seconds seconds and continue';
  }

  @override
  String getMoreTime(int seconds) {
    return 'Get +$seconds Seconds & Continue';
  }

  @override
  String get adNotCompletedRestartLevel =>
      'Ad not completed. Try watching again or restart level.';

  @override
  String get adNotCompletedRestart =>
      'Ad not completed. Try watching again or restart.';

  @override
  String startOverWithLives(int count) {
    return 'Start over with $count lives';
  }

  @override
  String get loadingAd => 'Loading Ad...';

  @override
  String refillHearts(int cost) {
    return 'Refill Hearts · $cost coins';
  }

  @override
  String needCoins(int cost, int coins) {
    return 'Need $cost coins (you have $coins)';
  }

  @override
  String get difficultyTutorial => 'Tutorial';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyExpert => 'Expert';

  @override
  String get difficultyMaster => 'Master';

  @override
  String get difficultyLegend => 'Legend';

  @override
  String get difficultySuperHard => 'Super Hard';

  @override
  String levelLocked(int level) {
    return 'Level $level is locked!';
  }

  @override
  String get playNow => 'Play Now';

  @override
  String get loading => 'Loading…';

  @override
  String levelWithDifficulty(int level, String difficulty) {
    return 'Level $level • $difficulty';
  }

  @override
  String get selectLevel => 'Select Level';

  @override
  String get navAlbum => 'Album';

  @override
  String get navDaily => 'Daily';

  @override
  String get navShop => 'Shop';

  @override
  String get navWheel => 'Wheel';

  @override
  String get navAwards => 'Awards';

  @override
  String get shapeAlbum => 'Shape Album';

  @override
  String shapesUncovered(int count) {
    return '$count uncovered';
  }

  @override
  String get categoryShapes => 'Shapes';

  @override
  String get categoryAnimals => 'Animals';

  @override
  String get categoryNature => 'Nature';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryObjects => 'Objects';

  @override
  String get categoryMusic => 'Music';

  @override
  String get categoryCharacters => 'Characters';

  @override
  String get dailyChallenge => 'Daily Challenge';

  @override
  String dayStreak(int days) {
    return '$days-day streak';
  }

  @override
  String get dailyClaimed => 'Today’s reward is already claimed';

  @override
  String dailyGoal(int level, int reward) {
    return 'Clear level $level for +$reward coins';
  }

  @override
  String get comeBackTomorrow => 'Come back tomorrow';

  @override
  String get playTodaysLevel => 'Play today’s level';

  @override
  String get dailyRewardsInfo =>
      'Rewards climb with your streak, up to day 30.';

  @override
  String get shop => 'Shop';

  @override
  String get shopPowerUps => 'Power-ups';

  @override
  String ownedExtra(int count) {
    return 'Owned $count extra';
  }

  @override
  String get buy => 'Buy';

  @override
  String get shopHearts => 'Hearts';

  @override
  String get heart => 'Heart';

  @override
  String get heartsFull => 'Hearts are full';

  @override
  String get arrowSkins => 'Arrow skins';

  @override
  String get boardThemes => 'Board themes';

  @override
  String get equipped => 'Equipped';

  @override
  String get unlockedByProgress => 'Unlocked by progress';

  @override
  String orReachLevel(int level) {
    return 'Or reach level $level';
  }

  @override
  String get equippedShort => 'On';

  @override
  String get equip => 'Equip';

  @override
  String get notEnoughCoins => 'Not enough coins';

  @override
  String get powerUpHint => 'Hint';

  @override
  String get powerUpEraser => 'Eraser';

  @override
  String get powerUpWand => 'Magic wand';

  @override
  String get powerUpRuler => 'Ruler';

  @override
  String get skinClassicName => 'Classic arrows';

  @override
  String get skinClassicBlurb => 'The original ink';

  @override
  String get skinNeonName => 'Neon arrows';

  @override
  String get skinNeonBlurb => 'Glow-stick colors';

  @override
  String get skinWoodName => 'Wood arrows';

  @override
  String get skinWoodBlurb => 'Carved timber';

  @override
  String get skinCandyName => 'Candy arrows';

  @override
  String get skinCandyBlurb => 'Sugar-bright';

  @override
  String get skinSpaceName => 'Space arrows';

  @override
  String get skinSpaceBlurb => 'Deep-orbit glow';

  @override
  String get themeClassicName => 'Classic board';

  @override
  String get themeClassicBlurb => 'Quiet paper';

  @override
  String get themeNeonName => 'Neon board';

  @override
  String get themeNeonBlurb => 'Night-market grid';

  @override
  String get themeWoodName => 'Wood board';

  @override
  String get themeWoodBlurb => 'Warm tabletop';

  @override
  String get themeCandyName => 'Candy board';

  @override
  String get themeCandyBlurb => 'Pastel sugar';

  @override
  String get themeSpaceName => 'Space board';

  @override
  String get themeSpaceBlurb => 'Starfield';

  @override
  String get luckyWheel => 'Lucky Wheel';

  @override
  String get freeSpinToday => 'One free spin today';

  @override
  String get spunToday => 'Spun for today';

  @override
  String youWon(String prize) {
    return 'You won $prize';
  }

  @override
  String get spin => 'Spin';

  @override
  String coinsAmount(int count) {
    return '$count coins';
  }

  @override
  String get achievements => 'Achievements';

  @override
  String get achFirstClearTitle => 'First Escape';

  @override
  String get achFirstClearDesc => 'Clear a level';

  @override
  String get achHintless50Title => 'No Hints Needed';

  @override
  String get achHintless50Desc => 'Clear 50 levels without a hint';

  @override
  String get achPerfect10Title => 'Flawless';

  @override
  String get achPerfect10Desc => 'Earn 3 stars on 10 levels';

  @override
  String get achBossTitle => 'Boss Breaker';

  @override
  String get achBossDesc => 'Clear a boss level';

  @override
  String get achGodTitle => 'Godslayer';

  @override
  String get achGodDesc => 'Clear a god level';

  @override
  String get achCollectorTitle => 'Curator';

  @override
  String get achCollectorDesc => 'Uncover 10 shapes';

  @override
  String get achStreak7Title => 'Week of Arrows';

  @override
  String get achStreak7Desc => 'Keep a 7-day streak';

  @override
  String get achCoins500Title => 'Coin Purse';

  @override
  String get achCoins500Desc => 'Earn 500 coins';

  @override
  String get levelTypeTutorial => 'Tutorial';

  @override
  String get levelTypeBoss => 'Boss';

  @override
  String get levelTypeGod => 'God';

  @override
  String get godMode => 'God Mode';

  @override
  String get bossLevel => 'BOSS LEVEL';

  @override
  String get godLevel => 'GOD LEVEL';

  @override
  String get bossTagline => 'A bigger silhouette awaits';

  @override
  String get godTagline => 'One mistake echoes';

  @override
  String get daysLabel => 'days';

  @override
  String get comboPerfect => 'Perfect!';

  @override
  String get tapAnArrow => 'Tap an arrow';

  @override
  String powerUpsAdded(int count) {
    return '+$count added';
  }

  @override
  String get noHintsLeft => 'No hints left';

  @override
  String get noHintAvailable => 'No hint available';

  @override
  String get noErasersLeft => 'No erasers left';

  @override
  String get tapArrowToErase => 'Tap an arrow to erase it';

  @override
  String get noWandsLeft => 'No magic wands left';

  @override
  String get noWandMove => 'No clear move for wand';

  @override
  String get noRulersLeft => 'No rulers left';

  @override
  String get deadlockOptions => 'Deadlock Options';

  @override
  String get tutorialHowToPlayTitle => 'How to Play';

  @override
  String get tutorialHowToPlayBody =>
      'Arrows slide in the direction they point. Tap an arrow to make it escape the grid! Arrows cannot pass through other arrows, so plan their escape order carefully.';

  @override
  String get tutorialPairedTitle => 'Color Paired Arrows';

  @override
  String get tutorialPairedBody =>
      'Arrows with matching colors are paired together! Tap on either arrow in the pair, and both will slide out together simultaneously. Make sure both exit paths are clear!';

  @override
  String get tutorialDeflectorTitle => 'Deflector Dots';

  @override
  String get tutorialDeflectorBody =>
      'Gold deflector dots change the direction of exiting arrows! Trace the exit path through the deflector dots to make sure the arrow escapes successfully.';

  @override
  String get zoomHint => 'Pinch to zoom in or out to see small arrows easily!';

  @override
  String get massiveGridTitle => 'Massive Grid Alert!';

  @override
  String get massiveGridBody =>
      'You are about to play a massive 40×40 level! On grids of this size, deadlocks (where all remaining arrows are blocked) are very common.\n\nBe extremely careful about your tap order. If you get stuck, look out for the Deadlock dialog to restart!';

  @override
  String get gotIt => 'Got It!';

  @override
  String tutorialStep(String step) {
    return 'TUTORIAL STEP $step';
  }

  @override
  String get startTutorial => 'Start Tutorial';

  @override
  String get pairBadge => 'PAIR';

  @override
  String get levelComplete => 'Level Complete!';

  @override
  String dailyBonus(int amount) {
    return 'Daily +$amount';
  }

  @override
  String chestReward(int coins, String powerUp) {
    return 'Chest +$coins coins · $powerUp';
  }

  @override
  String get finishedGameTitle => 'You Finished the Game!';

  @override
  String finishedGameBody(int total) {
    return 'Congratulations! You\'ve solved all $total challenges. Stay tuned for more levels coming soon!';
  }

  @override
  String get nextLevel => 'Next Level';

  @override
  String get doubleCoins => 'Double Coins';

  @override
  String get deadlockTitle => 'Deadlock Reached!';

  @override
  String get deadlockBody =>
      'All remaining arrows are blocked. This can happen if they are cleared in the wrong sequence.\n\n💡 Hint: Try to trace the paths and see which arrows must escape first to clear the way for others!';

  @override
  String get inspectBoard => 'Inspect Board';

  @override
  String get resumeGame => 'Resume Game';

  @override
  String get loadingMessagesNormal =>
      'Generating puzzle…|Placing arrows…|Shuffling the grid…|Building your challenge…|Crafting the layout…';

  @override
  String get loadingMessagesBoss =>
      'Cooking devil sauce…|Summoning the beast…|Sharpening the claws…|Brewing chaos in a cauldron…|Waking the dungeon keeper…|Forging traps from darkness…|Stirring the dark arts…|Luring the monster out…|Preparing your punishment…|Cranking up the difficulty…';

  @override
  String get loadingMessagesGod =>
      'Consulting the ancient scrolls…|Aligning the stars…|Channelling cosmic energy…|Weaving reality into knots…|Asking the oracle for a riddle…|Distilling the essence of madness…|Folding space and time…|Summoning the elder puzzle gods…|Rewriting the laws of physics…|Manifesting pure enlightenment…';
}

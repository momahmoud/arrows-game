import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrow Escape'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Slide. Clear. Conquer.'**
  String get splashTagline;

  /// No description provided for @splashLoadingAssets.
  ///
  /// In en, this message translates to:
  /// **'Loading assets…'**
  String get splashLoadingAssets;

  /// No description provided for @splashGeneratingLevels.
  ///
  /// In en, this message translates to:
  /// **'Generating levels…'**
  String get splashGeneratingLevels;

  /// No description provided for @splashAlmostReady.
  ///
  /// In en, this message translates to:
  /// **'Almost ready…'**
  String get splashAlmostReady;

  /// No description provided for @levelNumber.
  ///
  /// In en, this message translates to:
  /// **'Level {number}'**
  String levelNumber(int number);

  /// No description provided for @mainMenu.
  ///
  /// In en, this message translates to:
  /// **'Main Menu'**
  String get mainMenu;

  /// No description provided for @backToMenu.
  ///
  /// In en, this message translates to:
  /// **'Back to Menu'**
  String get backToMenu;

  /// No description provided for @restartLevel.
  ///
  /// In en, this message translates to:
  /// **'Restart Level'**
  String get restartLevel;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @backgroundMusic.
  ///
  /// In en, this message translates to:
  /// **'Background Music'**
  String get backgroundMusic;

  /// No description provided for @hapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get hapticFeedback;

  /// No description provided for @vibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get vibration;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @shapePreview.
  ///
  /// In en, this message translates to:
  /// **'Shape preview'**
  String get shapePreview;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the App'**
  String get rateApp;

  /// No description provided for @outOfLives.
  ///
  /// In en, this message translates to:
  /// **'Out of Lives!'**
  String get outOfLives;

  /// No description provided for @outOfTime.
  ///
  /// In en, this message translates to:
  /// **'Out of Time!'**
  String get outOfTime;

  /// No description provided for @getOneMoreLife.
  ///
  /// In en, this message translates to:
  /// **'Get 1 More Life & Continue'**
  String get getOneMoreLife;

  /// No description provided for @watchAdForLife.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to get 1 more life'**
  String get watchAdForLife;

  /// No description provided for @watchAdForLifeContinue.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to get 1 more life and continue'**
  String get watchAdForLifeContinue;

  /// No description provided for @watchAdForTime.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to get +{seconds} seconds and continue'**
  String watchAdForTime(int seconds);

  /// No description provided for @getMoreTime.
  ///
  /// In en, this message translates to:
  /// **'Get +{seconds} Seconds & Continue'**
  String getMoreTime(int seconds);

  /// No description provided for @adNotCompletedRestartLevel.
  ///
  /// In en, this message translates to:
  /// **'Ad not completed. Try watching again or restart level.'**
  String get adNotCompletedRestartLevel;

  /// No description provided for @adNotCompletedRestart.
  ///
  /// In en, this message translates to:
  /// **'Ad not completed. Try watching again or restart.'**
  String get adNotCompletedRestart;

  /// No description provided for @startOverWithLives.
  ///
  /// In en, this message translates to:
  /// **'Start over with {count} lives'**
  String startOverWithLives(int count);

  /// No description provided for @loadingAd.
  ///
  /// In en, this message translates to:
  /// **'Loading Ad...'**
  String get loadingAd;

  /// No description provided for @refillHearts.
  ///
  /// In en, this message translates to:
  /// **'Refill Hearts · {cost} coins'**
  String refillHearts(int cost);

  /// No description provided for @needCoins.
  ///
  /// In en, this message translates to:
  /// **'Need {cost} coins (you have {coins})'**
  String needCoins(int cost, int coins);

  /// No description provided for @difficultyTutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get difficultyTutorial;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @difficultyExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get difficultyExpert;

  /// No description provided for @difficultyMaster.
  ///
  /// In en, this message translates to:
  /// **'Master'**
  String get difficultyMaster;

  /// No description provided for @difficultyLegend.
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get difficultyLegend;

  /// No description provided for @difficultySuperHard.
  ///
  /// In en, this message translates to:
  /// **'Super Hard'**
  String get difficultySuperHard;

  /// No description provided for @levelLocked.
  ///
  /// In en, this message translates to:
  /// **'Level {level} is locked!'**
  String levelLocked(int level);

  /// No description provided for @playNow.
  ///
  /// In en, this message translates to:
  /// **'Play Now'**
  String get playNow;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @levelWithDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Level {level} • {difficulty}'**
  String levelWithDifficulty(int level, String difficulty);

  /// No description provided for @selectLevel.
  ///
  /// In en, this message translates to:
  /// **'Select Level'**
  String get selectLevel;

  /// No description provided for @navAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get navAlbum;

  /// No description provided for @navDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get navDaily;

  /// No description provided for @navShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get navShop;

  /// No description provided for @navWheel.
  ///
  /// In en, this message translates to:
  /// **'Wheel'**
  String get navWheel;

  /// No description provided for @navAwards.
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get navAwards;

  /// No description provided for @shapeAlbum.
  ///
  /// In en, this message translates to:
  /// **'Shape Album'**
  String get shapeAlbum;

  /// No description provided for @shapesUncovered.
  ///
  /// In en, this message translates to:
  /// **'{count} uncovered'**
  String shapesUncovered(int count);

  /// No description provided for @categoryShapes.
  ///
  /// In en, this message translates to:
  /// **'Shapes'**
  String get categoryShapes;

  /// No description provided for @categoryAnimals.
  ///
  /// In en, this message translates to:
  /// **'Animals'**
  String get categoryAnimals;

  /// No description provided for @categoryNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get categoryNature;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryObjects.
  ///
  /// In en, this message translates to:
  /// **'Objects'**
  String get categoryObjects;

  /// No description provided for @categoryMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get categoryMusic;

  /// No description provided for @categoryCharacters.
  ///
  /// In en, this message translates to:
  /// **'Characters'**
  String get categoryCharacters;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallenge;

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak'**
  String dayStreak(int days);

  /// No description provided for @dailyClaimed.
  ///
  /// In en, this message translates to:
  /// **'Today’s reward is already claimed'**
  String get dailyClaimed;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Clear level {level} for +{reward} coins'**
  String dailyGoal(int level, int reward);

  /// No description provided for @comeBackTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow'**
  String get comeBackTomorrow;

  /// No description provided for @playTodaysLevel.
  ///
  /// In en, this message translates to:
  /// **'Play today’s level'**
  String get playTodaysLevel;

  /// No description provided for @dailyRewardsInfo.
  ///
  /// In en, this message translates to:
  /// **'Rewards climb with your streak, up to day 30.'**
  String get dailyRewardsInfo;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @shopPowerUps.
  ///
  /// In en, this message translates to:
  /// **'Power-ups'**
  String get shopPowerUps;

  /// No description provided for @ownedExtra.
  ///
  /// In en, this message translates to:
  /// **'Owned {count} extra'**
  String ownedExtra(int count);

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @shopHearts.
  ///
  /// In en, this message translates to:
  /// **'Hearts'**
  String get shopHearts;

  /// No description provided for @heart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get heart;

  /// No description provided for @heartsFull.
  ///
  /// In en, this message translates to:
  /// **'Hearts are full'**
  String get heartsFull;

  /// No description provided for @arrowSkins.
  ///
  /// In en, this message translates to:
  /// **'Arrow skins'**
  String get arrowSkins;

  /// No description provided for @boardThemes.
  ///
  /// In en, this message translates to:
  /// **'Board themes'**
  String get boardThemes;

  /// No description provided for @equipped.
  ///
  /// In en, this message translates to:
  /// **'Equipped'**
  String get equipped;

  /// No description provided for @unlockedByProgress.
  ///
  /// In en, this message translates to:
  /// **'Unlocked by progress'**
  String get unlockedByProgress;

  /// No description provided for @orReachLevel.
  ///
  /// In en, this message translates to:
  /// **'Or reach level {level}'**
  String orReachLevel(int level);

  /// No description provided for @equippedShort.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get equippedShort;

  /// No description provided for @equip.
  ///
  /// In en, this message translates to:
  /// **'Equip'**
  String get equip;

  /// No description provided for @notEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins'**
  String get notEnoughCoins;

  /// No description provided for @powerUpHint.
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get powerUpHint;

  /// No description provided for @powerUpEraser.
  ///
  /// In en, this message translates to:
  /// **'Eraser'**
  String get powerUpEraser;

  /// No description provided for @powerUpWand.
  ///
  /// In en, this message translates to:
  /// **'Magic wand'**
  String get powerUpWand;

  /// No description provided for @powerUpRuler.
  ///
  /// In en, this message translates to:
  /// **'Ruler'**
  String get powerUpRuler;

  /// No description provided for @skinClassicName.
  ///
  /// In en, this message translates to:
  /// **'Classic arrows'**
  String get skinClassicName;

  /// No description provided for @skinClassicBlurb.
  ///
  /// In en, this message translates to:
  /// **'The original ink'**
  String get skinClassicBlurb;

  /// No description provided for @skinNeonName.
  ///
  /// In en, this message translates to:
  /// **'Neon arrows'**
  String get skinNeonName;

  /// No description provided for @skinNeonBlurb.
  ///
  /// In en, this message translates to:
  /// **'Glow-stick colors'**
  String get skinNeonBlurb;

  /// No description provided for @skinWoodName.
  ///
  /// In en, this message translates to:
  /// **'Wood arrows'**
  String get skinWoodName;

  /// No description provided for @skinWoodBlurb.
  ///
  /// In en, this message translates to:
  /// **'Carved timber'**
  String get skinWoodBlurb;

  /// No description provided for @skinCandyName.
  ///
  /// In en, this message translates to:
  /// **'Candy arrows'**
  String get skinCandyName;

  /// No description provided for @skinCandyBlurb.
  ///
  /// In en, this message translates to:
  /// **'Sugar-bright'**
  String get skinCandyBlurb;

  /// No description provided for @skinSpaceName.
  ///
  /// In en, this message translates to:
  /// **'Space arrows'**
  String get skinSpaceName;

  /// No description provided for @skinSpaceBlurb.
  ///
  /// In en, this message translates to:
  /// **'Deep-orbit glow'**
  String get skinSpaceBlurb;

  /// No description provided for @themeClassicName.
  ///
  /// In en, this message translates to:
  /// **'Classic board'**
  String get themeClassicName;

  /// No description provided for @themeClassicBlurb.
  ///
  /// In en, this message translates to:
  /// **'Quiet paper'**
  String get themeClassicBlurb;

  /// No description provided for @themeNeonName.
  ///
  /// In en, this message translates to:
  /// **'Neon board'**
  String get themeNeonName;

  /// No description provided for @themeNeonBlurb.
  ///
  /// In en, this message translates to:
  /// **'Night-market grid'**
  String get themeNeonBlurb;

  /// No description provided for @themeWoodName.
  ///
  /// In en, this message translates to:
  /// **'Wood board'**
  String get themeWoodName;

  /// No description provided for @themeWoodBlurb.
  ///
  /// In en, this message translates to:
  /// **'Warm tabletop'**
  String get themeWoodBlurb;

  /// No description provided for @themeCandyName.
  ///
  /// In en, this message translates to:
  /// **'Candy board'**
  String get themeCandyName;

  /// No description provided for @themeCandyBlurb.
  ///
  /// In en, this message translates to:
  /// **'Pastel sugar'**
  String get themeCandyBlurb;

  /// No description provided for @themeSpaceName.
  ///
  /// In en, this message translates to:
  /// **'Space board'**
  String get themeSpaceName;

  /// No description provided for @themeSpaceBlurb.
  ///
  /// In en, this message translates to:
  /// **'Starfield'**
  String get themeSpaceBlurb;

  /// No description provided for @luckyWheel.
  ///
  /// In en, this message translates to:
  /// **'Lucky Wheel'**
  String get luckyWheel;

  /// No description provided for @freeSpinToday.
  ///
  /// In en, this message translates to:
  /// **'One free spin today'**
  String get freeSpinToday;

  /// No description provided for @spunToday.
  ///
  /// In en, this message translates to:
  /// **'Spun for today'**
  String get spunToday;

  /// No description provided for @youWon.
  ///
  /// In en, this message translates to:
  /// **'You won {prize}'**
  String youWon(String prize);

  /// No description provided for @spin.
  ///
  /// In en, this message translates to:
  /// **'Spin'**
  String get spin;

  /// No description provided for @coinsAmount.
  ///
  /// In en, this message translates to:
  /// **'{count} coins'**
  String coinsAmount(int count);

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @achFirstClearTitle.
  ///
  /// In en, this message translates to:
  /// **'First Escape'**
  String get achFirstClearTitle;

  /// No description provided for @achFirstClearDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear a level'**
  String get achFirstClearDesc;

  /// No description provided for @achHintless50Title.
  ///
  /// In en, this message translates to:
  /// **'No Hints Needed'**
  String get achHintless50Title;

  /// No description provided for @achHintless50Desc.
  ///
  /// In en, this message translates to:
  /// **'Clear 50 levels without a hint'**
  String get achHintless50Desc;

  /// No description provided for @achPerfect10Title.
  ///
  /// In en, this message translates to:
  /// **'Flawless'**
  String get achPerfect10Title;

  /// No description provided for @achPerfect10Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn 3 stars on 10 levels'**
  String get achPerfect10Desc;

  /// No description provided for @achBossTitle.
  ///
  /// In en, this message translates to:
  /// **'Boss Breaker'**
  String get achBossTitle;

  /// No description provided for @achBossDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear a boss level'**
  String get achBossDesc;

  /// No description provided for @achGodTitle.
  ///
  /// In en, this message translates to:
  /// **'Godslayer'**
  String get achGodTitle;

  /// No description provided for @achGodDesc.
  ///
  /// In en, this message translates to:
  /// **'Clear a god level'**
  String get achGodDesc;

  /// No description provided for @achCollectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Curator'**
  String get achCollectorTitle;

  /// No description provided for @achCollectorDesc.
  ///
  /// In en, this message translates to:
  /// **'Uncover 10 shapes'**
  String get achCollectorDesc;

  /// No description provided for @achStreak7Title.
  ///
  /// In en, this message translates to:
  /// **'Week of Arrows'**
  String get achStreak7Title;

  /// No description provided for @achStreak7Desc.
  ///
  /// In en, this message translates to:
  /// **'Keep a 7-day streak'**
  String get achStreak7Desc;

  /// No description provided for @achCoins500Title.
  ///
  /// In en, this message translates to:
  /// **'Coin Purse'**
  String get achCoins500Title;

  /// No description provided for @achCoins500Desc.
  ///
  /// In en, this message translates to:
  /// **'Earn 500 coins'**
  String get achCoins500Desc;

  /// No description provided for @levelTypeTutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial'**
  String get levelTypeTutorial;

  /// No description provided for @levelTypeBoss.
  ///
  /// In en, this message translates to:
  /// **'Boss'**
  String get levelTypeBoss;

  /// No description provided for @levelTypeGod.
  ///
  /// In en, this message translates to:
  /// **'God'**
  String get levelTypeGod;

  /// No description provided for @godMode.
  ///
  /// In en, this message translates to:
  /// **'God Mode'**
  String get godMode;

  /// No description provided for @bossLevel.
  ///
  /// In en, this message translates to:
  /// **'BOSS LEVEL'**
  String get bossLevel;

  /// No description provided for @godLevel.
  ///
  /// In en, this message translates to:
  /// **'GOD LEVEL'**
  String get godLevel;

  /// No description provided for @bossTagline.
  ///
  /// In en, this message translates to:
  /// **'A bigger silhouette awaits'**
  String get bossTagline;

  /// No description provided for @godTagline.
  ///
  /// In en, this message translates to:
  /// **'One mistake echoes'**
  String get godTagline;

  /// No description provided for @daysLabel.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysLabel;

  /// No description provided for @comboPerfect.
  ///
  /// In en, this message translates to:
  /// **'Perfect!'**
  String get comboPerfect;

  /// No description provided for @tapAnArrow.
  ///
  /// In en, this message translates to:
  /// **'Tap an arrow'**
  String get tapAnArrow;

  /// No description provided for @powerUpsAdded.
  ///
  /// In en, this message translates to:
  /// **'+{count} added'**
  String powerUpsAdded(int count);

  /// No description provided for @noHintsLeft.
  ///
  /// In en, this message translates to:
  /// **'No hints left'**
  String get noHintsLeft;

  /// No description provided for @noHintAvailable.
  ///
  /// In en, this message translates to:
  /// **'No hint available'**
  String get noHintAvailable;

  /// No description provided for @noErasersLeft.
  ///
  /// In en, this message translates to:
  /// **'No erasers left'**
  String get noErasersLeft;

  /// No description provided for @tapArrowToErase.
  ///
  /// In en, this message translates to:
  /// **'Tap an arrow to erase it'**
  String get tapArrowToErase;

  /// No description provided for @noWandsLeft.
  ///
  /// In en, this message translates to:
  /// **'No magic wands left'**
  String get noWandsLeft;

  /// No description provided for @noWandMove.
  ///
  /// In en, this message translates to:
  /// **'No clear move for wand'**
  String get noWandMove;

  /// No description provided for @noRulersLeft.
  ///
  /// In en, this message translates to:
  /// **'No rulers left'**
  String get noRulersLeft;

  /// No description provided for @deadlockOptions.
  ///
  /// In en, this message translates to:
  /// **'Deadlock Options'**
  String get deadlockOptions;

  /// No description provided for @tutorialHowToPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'How to Play'**
  String get tutorialHowToPlayTitle;

  /// No description provided for @tutorialHowToPlayBody.
  ///
  /// In en, this message translates to:
  /// **'Arrows slide in the direction they point. Tap an arrow to make it escape the grid! Arrows cannot pass through other arrows, so plan their escape order carefully.'**
  String get tutorialHowToPlayBody;

  /// No description provided for @tutorialPairedTitle.
  ///
  /// In en, this message translates to:
  /// **'Color Paired Arrows'**
  String get tutorialPairedTitle;

  /// No description provided for @tutorialPairedBody.
  ///
  /// In en, this message translates to:
  /// **'Arrows with matching colors are paired together! Tap on either arrow in the pair, and both will slide out together simultaneously. Make sure both exit paths are clear!'**
  String get tutorialPairedBody;

  /// No description provided for @tutorialDeflectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Deflector Dots'**
  String get tutorialDeflectorTitle;

  /// No description provided for @tutorialDeflectorBody.
  ///
  /// In en, this message translates to:
  /// **'Gold deflector dots change the direction of exiting arrows! Trace the exit path through the deflector dots to make sure the arrow escapes successfully.'**
  String get tutorialDeflectorBody;

  /// No description provided for @zoomHint.
  ///
  /// In en, this message translates to:
  /// **'Pinch to zoom in or out to see small arrows easily!'**
  String get zoomHint;

  /// No description provided for @massiveGridTitle.
  ///
  /// In en, this message translates to:
  /// **'Massive Grid Alert!'**
  String get massiveGridTitle;

  /// No description provided for @massiveGridBody.
  ///
  /// In en, this message translates to:
  /// **'You are about to play a massive 40×40 level! On grids of this size, deadlocks (where all remaining arrows are blocked) are very common.\n\nBe extremely careful about your tap order. If you get stuck, look out for the Deadlock dialog to restart!'**
  String get massiveGridBody;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It!'**
  String get gotIt;

  /// No description provided for @tutorialStep.
  ///
  /// In en, this message translates to:
  /// **'TUTORIAL STEP {step}'**
  String tutorialStep(String step);

  /// No description provided for @startTutorial.
  ///
  /// In en, this message translates to:
  /// **'Start Tutorial'**
  String get startTutorial;

  /// No description provided for @pairBadge.
  ///
  /// In en, this message translates to:
  /// **'PAIR'**
  String get pairBadge;

  /// No description provided for @levelComplete.
  ///
  /// In en, this message translates to:
  /// **'Level Complete!'**
  String get levelComplete;

  /// No description provided for @dailyBonus.
  ///
  /// In en, this message translates to:
  /// **'Daily +{amount}'**
  String dailyBonus(int amount);

  /// No description provided for @chestReward.
  ///
  /// In en, this message translates to:
  /// **'Chest +{coins} coins · {powerUp}'**
  String chestReward(int coins, String powerUp);

  /// No description provided for @finishedGameTitle.
  ///
  /// In en, this message translates to:
  /// **'You Finished the Game!'**
  String get finishedGameTitle;

  /// No description provided for @finishedGameBody.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You\'ve solved all {total} challenges. Stay tuned for more levels coming soon!'**
  String finishedGameBody(int total);

  /// No description provided for @nextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next Level'**
  String get nextLevel;

  /// No description provided for @doubleCoins.
  ///
  /// In en, this message translates to:
  /// **'Double Coins'**
  String get doubleCoins;

  /// No description provided for @deadlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Deadlock Reached!'**
  String get deadlockTitle;

  /// No description provided for @deadlockBody.
  ///
  /// In en, this message translates to:
  /// **'All remaining arrows are blocked. This can happen if they are cleared in the wrong sequence.\n\n💡 Hint: Try to trace the paths and see which arrows must escape first to clear the way for others!'**
  String get deadlockBody;

  /// No description provided for @inspectBoard.
  ///
  /// In en, this message translates to:
  /// **'Inspect Board'**
  String get inspectBoard;

  /// No description provided for @resumeGame.
  ///
  /// In en, this message translates to:
  /// **'Resume Game'**
  String get resumeGame;

  /// No description provided for @loadingMessagesNormal.
  ///
  /// In en, this message translates to:
  /// **'Generating puzzle…|Placing arrows…|Shuffling the grid…|Building your challenge…|Crafting the layout…'**
  String get loadingMessagesNormal;

  /// No description provided for @loadingMessagesBoss.
  ///
  /// In en, this message translates to:
  /// **'Cooking devil sauce…|Summoning the beast…|Sharpening the claws…|Brewing chaos in a cauldron…|Waking the dungeon keeper…|Forging traps from darkness…|Stirring the dark arts…|Luring the monster out…|Preparing your punishment…|Cranking up the difficulty…'**
  String get loadingMessagesBoss;

  /// No description provided for @loadingMessagesGod.
  ///
  /// In en, this message translates to:
  /// **'Consulting the ancient scrolls…|Aligning the stars…|Channelling cosmic energy…|Weaving reality into knots…|Asking the oracle for a riddle…|Distilling the essence of madness…|Folding space and time…|Summoning the elder puzzle gods…|Rewriting the laws of physics…|Manifesting pure enlightenment…'**
  String get loadingMessagesGod;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'هروب الأسهم';

  @override
  String get splashTagline => 'اسحب. امسح. انتصر.';

  @override
  String get splashLoadingAssets => 'جارٍ تحميل الموارد…';

  @override
  String get splashGeneratingLevels => 'جارٍ تجهيز المراحل…';

  @override
  String get splashAlmostReady => 'أوشكنا على الانتهاء…';

  @override
  String levelNumber(int number) {
    return 'المرحلة $number';
  }

  @override
  String get mainMenu => 'القائمة الرئيسية';

  @override
  String get backToMenu => 'العودة إلى القائمة';

  @override
  String get restartLevel => 'إعادة المرحلة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get soundEffects => 'المؤثرات الصوتية';

  @override
  String get backgroundMusic => 'الموسيقى الخلفية';

  @override
  String get hapticFeedback => 'الاهتزاز عند اللمس';

  @override
  String get vibration => 'الاهتزاز';

  @override
  String get themeMode => 'المظهر';

  @override
  String get themeSystem => 'تلقائي';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'لغة الجهاز';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get shapePreview => 'معاينة الأشكال';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get rateApp => 'قيّم التطبيق';

  @override
  String get outOfLives => 'نفدت القلوب!';

  @override
  String get outOfTime => 'انتهى الوقت!';

  @override
  String get getOneMoreLife => 'احصل على قلب إضافي وتابع';

  @override
  String get watchAdForLife => 'شاهد إعلانًا لتحصل على قلب إضافي';

  @override
  String get watchAdForLifeContinue =>
      'شاهد إعلانًا لتحصل على قلب إضافي وتتابع';

  @override
  String watchAdForTime(int seconds) {
    return 'شاهد إعلانًا لتحصل على $seconds ثانية إضافية وتتابع';
  }

  @override
  String getMoreTime(int seconds) {
    return 'احصل على $seconds ثانية إضافية وتابع';
  }

  @override
  String get adNotCompletedRestartLevel =>
      'لم يكتمل الإعلان. حاول المشاهدة مجددًا أو أعد المرحلة.';

  @override
  String get adNotCompletedRestart =>
      'لم يكتمل الإعلان. حاول المشاهدة مجددًا أو ابدأ من جديد.';

  @override
  String startOverWithLives(int count) {
    return 'ابدأ من جديد بـ $count قلوب';
  }

  @override
  String get loadingAd => 'جارٍ تحميل الإعلان...';

  @override
  String refillHearts(int cost) {
    return 'املأ القلوب · $cost عملة';
  }

  @override
  String needCoins(int cost, int coins) {
    return 'تحتاج $cost عملة (لديك $coins)';
  }

  @override
  String get difficultyTutorial => 'تعليمي';

  @override
  String get difficultyEasy => 'سهل';

  @override
  String get difficultyMedium => 'متوسط';

  @override
  String get difficultyHard => 'صعب';

  @override
  String get difficultyExpert => 'خبير';

  @override
  String get difficultyMaster => 'محترف';

  @override
  String get difficultyLegend => 'أسطورة';

  @override
  String get difficultySuperHard => 'صعب جدًا';

  @override
  String levelLocked(int level) {
    return 'المرحلة $level مقفلة!';
  }

  @override
  String get playNow => 'العب الآن';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String levelWithDifficulty(int level, String difficulty) {
    return 'المرحلة $level • $difficulty';
  }

  @override
  String get selectLevel => 'اختر المرحلة';

  @override
  String get navAlbum => 'الألبوم';

  @override
  String get navDaily => 'اليومي';

  @override
  String get navShop => 'المتجر';

  @override
  String get navWheel => 'العجلة';

  @override
  String get navAwards => 'الجوائز';

  @override
  String get shapeAlbum => 'ألبوم الأشكال';

  @override
  String shapesUncovered(int count) {
    return 'تم كشف $count';
  }

  @override
  String get categoryShapes => 'أشكال';

  @override
  String get categoryAnimals => 'حيوانات';

  @override
  String get categoryNature => 'طبيعة';

  @override
  String get categoryFood => 'طعام';

  @override
  String get categoryObjects => 'أشياء';

  @override
  String get categoryMusic => 'موسيقى';

  @override
  String get categoryCharacters => 'شخصيات';

  @override
  String get dailyChallenge => 'التحدي اليومي';

  @override
  String dayStreak(int days) {
    return 'سلسلة $days يوم';
  }

  @override
  String get dailyClaimed => 'استلمت مكافأة اليوم بالفعل';

  @override
  String dailyGoal(int level, int reward) {
    return 'أكمل المرحلة $level لتربح $reward عملة';
  }

  @override
  String get comeBackTomorrow => 'عد غدًا';

  @override
  String get playTodaysLevel => 'العب مرحلة اليوم';

  @override
  String get dailyRewardsInfo =>
      'محاولة واحدة في اليوم. الإكمال المثالي يمنح أكثر.';

  @override
  String get shop => 'المتجر';

  @override
  String get shopPowerUps => 'المعززات';

  @override
  String ownedExtra(int count) {
    return 'لديك $count إضافية';
  }

  @override
  String get buy => 'شراء';

  @override
  String get shopHearts => 'القلوب';

  @override
  String get heart => 'قلب';

  @override
  String get heartsFull => 'القلوب ممتلئة';

  @override
  String get arrowSkins => 'أشكال الأسهم';

  @override
  String get boardThemes => 'سمات اللوحة';

  @override
  String get equipped => 'مُفعّل';

  @override
  String get unlockedByProgress => 'مفتوح بالتقدم';

  @override
  String orReachLevel(int level) {
    return 'أو صل إلى المرحلة $level';
  }

  @override
  String get equippedShort => 'مفعّل';

  @override
  String get equip => 'تفعيل';

  @override
  String get notEnoughCoins => 'لا تملك عملات كافية';

  @override
  String get powerUpHint => 'تلميح';

  @override
  String get powerUpEraser => 'ممحاة';

  @override
  String get powerUpWand => 'عصا سحرية';

  @override
  String get powerUpRuler => 'مسطرة';

  @override
  String get skinClassicName => 'أسهم كلاسيكية';

  @override
  String get skinClassicBlurb => 'الحبر الأصلي';

  @override
  String get skinNeonName => 'أسهم نيون';

  @override
  String get skinNeonBlurb => 'ألوان متوهجة';

  @override
  String get skinWoodName => 'أسهم خشبية';

  @override
  String get skinWoodBlurb => 'خشب منحوت';

  @override
  String get skinCandyName => 'أسهم الحلوى';

  @override
  String get skinCandyBlurb => 'زاهية كالسكر';

  @override
  String get skinSpaceName => 'أسهم الفضاء';

  @override
  String get skinSpaceBlurb => 'توهج المدار البعيد';

  @override
  String get themeClassicName => 'لوحة كلاسيكية';

  @override
  String get themeClassicBlurb => 'ورق هادئ';

  @override
  String get themeNeonName => 'لوحة نيون';

  @override
  String get themeNeonBlurb => 'شبكة سوق الليل';

  @override
  String get themeWoodName => 'لوحة خشبية';

  @override
  String get themeWoodBlurb => 'طاولة دافئة';

  @override
  String get themeCandyName => 'لوحة الحلوى';

  @override
  String get themeCandyBlurb => 'سكر بألوان هادئة';

  @override
  String get themeSpaceName => 'لوحة الفضاء';

  @override
  String get themeSpaceBlurb => 'حقل النجوم';

  @override
  String get luckyWheel => 'عجلة الحظ';

  @override
  String get freeSpinToday => 'دورة مجانية واحدة اليوم';

  @override
  String get spunToday => 'استخدمت دورة اليوم';

  @override
  String youWon(String prize) {
    return 'ربحت $prize';
  }

  @override
  String get spin => 'دوّر';

  @override
  String coinsAmount(int count) {
    return '$count عملة';
  }

  @override
  String get achievements => 'الإنجازات';

  @override
  String get achFirstClearTitle => 'الهروب الأول';

  @override
  String get achFirstClearDesc => 'أكمل مرحلة';

  @override
  String get achHintless50Title => 'بلا تلميحات';

  @override
  String get achHintless50Desc => 'أكمل 50 مرحلة دون تلميح';

  @override
  String get achPerfect10Title => 'بلا أخطاء';

  @override
  String get achPerfect10Desc => 'احصل على 3 نجوم في 10 مراحل';

  @override
  String get achBossTitle => 'قاهر الزعماء';

  @override
  String get achBossDesc => 'أكمل مرحلة زعيم';

  @override
  String get achGodTitle => 'قاهر الأساطير';

  @override
  String get achGodDesc => 'أكمل مرحلة أسطورية';

  @override
  String get achCollectorTitle => 'جامع الأشكال';

  @override
  String get achCollectorDesc => 'اكشف 10 أشكال';

  @override
  String get achStreak7Title => 'أسبوع الأسهم';

  @override
  String get achStreak7Desc => 'حافظ على سلسلة 7 أيام';

  @override
  String get achCoins500Title => 'محفظة العملات';

  @override
  String get achCoins500Desc => 'اجمع 500 عملة';

  @override
  String get levelTypeTutorial => 'تعليمي';

  @override
  String get levelTypeBoss => 'زعيم';

  @override
  String get levelTypeGod => 'أسطوري';

  @override
  String get godMode => 'وضع الأساطير';

  @override
  String get bossLevel => 'مرحلة زعيم';

  @override
  String get godLevel => 'مرحلة أسطورية';

  @override
  String get bossTagline => 'شكل أكبر بانتظارك';

  @override
  String get godTagline => 'خطأ واحد يتردد صداه';

  @override
  String get daysLabel => 'يوم';

  @override
  String get comboPerfect => 'مثالي!';

  @override
  String get tapAnArrow => 'اضغط على سهم';

  @override
  String powerUpsAdded(int count) {
    return 'تمت إضافة $count';
  }

  @override
  String get noHintsLeft => 'لا توجد تلميحات متبقية';

  @override
  String get noHintAvailable => 'لا يوجد تلميح متاح';

  @override
  String get noErasersLeft => 'لا توجد ممحاة متبقية';

  @override
  String get tapArrowToErase => 'اضغط على سهم لمسحه';

  @override
  String get noWandsLeft => 'لا توجد عصي سحرية متبقية';

  @override
  String get noWandMove => 'لا توجد حركة متاحة للعصا';

  @override
  String get noRulersLeft => 'لا توجد مساطر متبقية';

  @override
  String get deadlockOptions => 'خيارات الانسداد';

  @override
  String get tutorialHowToPlayTitle => 'طريقة اللعب';

  @override
  String get tutorialHowToPlayBody =>
      'تنزلق الأسهم في الاتجاه الذي تشير إليه. اضغط على سهم ليهرب من الشبكة! لا يمكن للأسهم المرور عبر أسهم أخرى، لذا خطط لترتيب هروبها بعناية.';

  @override
  String get tutorialPairedTitle => 'الأسهم المزدوجة بالألوان';

  @override
  String get tutorialPairedBody =>
      'الأسهم ذات الألوان المتطابقة مرتبطة معًا! اضغط على أيٍّ منهما وسينزلقان للخارج في الوقت نفسه. تأكد أن طريقي الخروج خاليان!';

  @override
  String get tutorialDeflectorTitle => 'نقاط التوجيه';

  @override
  String get tutorialDeflectorBody =>
      'نقاط التوجيه الذهبية تغيّر اتجاه الأسهم الخارجة! تتبّع مسار الخروج عبر نقاط التوجيه لتتأكد أن السهم سيهرب بنجاح.';

  @override
  String get zoomHint =>
      'باعد أو قرّب إصبعيك للتكبير والتصغير ورؤية الأسهم الصغيرة بسهولة!';

  @override
  String get massiveGridTitle => 'تنبيه: شبكة ضخمة!';

  @override
  String get massiveGridBody =>
      'أنت على وشك لعب مرحلة ضخمة بحجم 40×40! في الشبكات بهذا الحجم يكثر الانسداد (عندما تُحجب كل الأسهم المتبقية).\n\nانتبه جيدًا لترتيب ضغطاتك. إذا علقت، ستظهر لك نافذة الانسداد لإعادة المرحلة!';

  @override
  String get gotIt => 'فهمت!';

  @override
  String tutorialStep(String step) {
    return 'خطوة تعليمية $step';
  }

  @override
  String get startTutorial => 'ابدأ الشرح';

  @override
  String get pairBadge => 'زوج';

  @override
  String get levelComplete => 'اكتملت المرحلة!';

  @override
  String dailyBonus(int amount) {
    return 'مكافأة يومية +$amount';
  }

  @override
  String chestReward(int coins, String powerUp) {
    return 'صندوق +$coins عملة · $powerUp';
  }

  @override
  String get finishedGameTitle => 'لقد أنهيت اللعبة!';

  @override
  String finishedGameBody(int total) {
    return 'تهانينا! لقد حللت جميع التحديات الـ $total. ترقّب المزيد من المراحل قريبًا!';
  }

  @override
  String get nextLevel => 'المرحلة التالية';

  @override
  String get doubleCoins => 'مضاعفة العملات';

  @override
  String watchAdCoins(int amount) {
    return 'شاهد إعلانًا ← +$amount عملة';
  }

  @override
  String loginReward(int day, int amount) {
    return 'اليوم $day · +$amount';
  }

  @override
  String get claim => 'استلم';

  @override
  String get deadlockTitle => 'وصلت إلى طريق مسدود!';

  @override
  String get deadlockBody =>
      'كل الأسهم المتبقية محجوبة. قد يحدث هذا إذا أُزيلت بترتيب خاطئ.\n\n💡 تلميح: تتبّع المسارات لتعرف أي الأسهم يجب أن تهرب أولًا لتفسح الطريق لغيرها!';

  @override
  String get inspectBoard => 'تفحّص اللوحة';

  @override
  String get resumeGame => 'استئناف اللعب';

  @override
  String get loadingMessagesNormal =>
      'جارٍ إنشاء اللغز…|جارٍ وضع الأسهم…|جارٍ خلط الشبكة…|جارٍ بناء تحديك…|جارٍ تصميم اللوحة…';

  @override
  String get loadingMessagesBoss =>
      'نطبخ صلصة الشيطان…|نستدعي الوحش…|نشحذ المخالب…|نغلي الفوضى في القِدر…|نوقظ حارس الزنزانة…|نصنع الفخاخ من الظلام…|نحرّك الفنون المظلمة…|نستدرج الوحش للخارج…|نجهّز عقابك…|نرفع مستوى الصعوبة…';

  @override
  String get loadingMessagesGod =>
      'نستشير المخطوطات القديمة…|نصفّ النجوم…|نستجمع الطاقة الكونية…|ننسج الواقع عُقدًا…|نطلب لغزًا من العرّافة…|نقطّر جوهر الجنون…|نطوي الزمان والمكان…|نستدعي أساطير الألغاز القديمة…|نعيد كتابة قوانين الفيزياء…|نستحضر التنوير الخالص…';
}

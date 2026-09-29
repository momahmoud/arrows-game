import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_fonts.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart';
import 'data/repositories/progress_repository.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/main_menu/main_menu_screen.dart';
import 'screens/level_select/level_select_screen.dart';
import 'screens/game/game_screen.dart';
import 'screens/game_over/game_over_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/shape_preview/shape_preview_screen.dart';
import 'screens/album/shape_album_screen.dart';
import 'screens/daily/daily_challenge_screen.dart';
import 'screens/shop/coin_shop_screen.dart';
import 'screens/wheel/lucky_wheel_screen.dart';
import 'screens/achievements/achievements_screen.dart';

class ArrowPuzzleApp extends StatelessWidget {
  const ArrowPuzzleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressRepository>();

    final themeMode = progress.themeMode;
    final systemBrightness = MediaQuery.platformBrightnessOf(context);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && systemBrightness == Brightness.dark);
    AppColors.updateTheme(isDark);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    ));

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: progress.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) {
        AppFonts.isArabic = Localizations.localeOf(context).languageCode == 'ar';
        return child!;
      },
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: AppFonts.family,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        textTheme: AppFonts.textTheme(
          ThemeData.light().textTheme,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: AppFonts.family,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        textTheme: AppFonts.textTheme(
          ThemeData.dark().textTheme,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/menu': (_) => const MainMenuScreen(),
        '/levels': (_) => const LevelSelectScreen(),
        '/game': (_) => const GameScreen(),
        '/game_over': (_) => const GameOverScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/shape_preview': (_) => const ShapePreviewScreen(),
        '/album': (_) => const ShapeAlbumScreen(),
        '/daily': (_) => const DailyChallengeScreen(),
        '/shop': (_) => const CoinShopScreen(),
        '/wheel': (_) => const LuckyWheelScreen(),
        '/achievements': (_) => const AchievementsScreen(),
      },
    );
  }
}

import 'dart:io';

import 'package:arrow_escape/l10n/generated/app_localizations.dart';
import 'package:arrow_escape/screens/achievements/achievements_screen.dart';
import 'package:arrow_escape/screens/daily/daily_challenge_screen.dart';
import 'package:arrow_escape/screens/game/game_screen.dart';
import 'package:arrow_escape/screens/level_select/level_select_screen.dart';
import 'package:arrow_escape/screens/settings/settings_screen.dart';
import 'package:arrow_escape/screens/shop/coin_shop_screen.dart';
import 'package:arrow_escape/screens/main_menu/main_menu_screen.dart';
import 'package:arrow_escape/ui/game_ui.dart';
import 'package:arrow_escape/ui/widgets/level_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_harness.dart';

/// Mounts the home and gameplay screens in both languages and themes.
///
/// Always checks they build without layout errors. Set UI_SNAPSHOT_DIR to
/// also write PNGs for manual review.
void main() {
  final outDir = Platform.environment['UI_SNAPSHOT_DIR'];
  const sizes = {'small': Size(360, 690), 'tall': Size(412, 915)};
  const progressPrefs = <String, Object>{
    'currentLevel': 23,
    'highestUnlockedLevel': 23,
    'coins': 1250,
    'hasSeen40x40Warning': true,
    'hasSeenZoomHint': true,
  };

  setUpAll(UiHarness.loadFonts);

  for (final lang in ['en', 'ar']) {
    for (final dark in [false, true]) {
      final theme = dark ? 'dark' : 'light';
      for (final size in sizes.entries) {
        testWidgets(
            'home ${lang}_${theme}_${size.key}',
            (tester) => UiHarness.withoutPlugins(() async {
                  _view(tester, size.value);
                  final h = await UiHarness.create(prefs: progressPrefs);
                  await tester.pumpWidget(h.app(
                    locale: Locale(lang),
                    dark: dark,
                    home: const MainMenuScreen(),
                  ));
                  await tester.pump(const Duration(milliseconds: 300));
                  expect(tester.takeException(), isNull);
                  await UiHarness.capture(
                      tester, outDir, 'home_${lang}_${theme}_${size.key}');
                  await tester.pumpWidget(const SizedBox());
                  await tester.pump(const Duration(seconds: 2));
                }));
      }

      for (final level in [23, 28]) {
        testWidgets(
            'game L${level}_${lang}_$theme',
            (tester) => UiHarness.withoutPlugins(() async {
                  _view(tester, sizes['small']!);
                  final h = await UiHarness.create(prefs: progressPrefs);
                  await tester.pumpWidget(h.app(
                    locale: Locale(lang),
                    dark: dark,
                    initial: RouteSettings(
                        name: '/game', arguments: {'level': level}),
                    routes: {'/game': (_) => const GameScreen()},
                  ));
                  for (var i = 0; i < 160; i++) {
                    await tester.pump(const Duration(milliseconds: 16));
                  }
                  expect(tester.takeException(), isNull);
                  await UiHarness.capture(
                      tester, outDir, 'game_L${level}_${lang}_$theme');
                  await tester.pumpWidget(const SizedBox());
                  await tester.pump(const Duration(seconds: 3));
                }));
      }

      for (final screen in <String, Widget>{
        'levels': const LevelSelectScreen(),
        'shop': const CoinShopScreen(),
        'settings': const SettingsScreen(),
        'daily': const DailyChallengeScreen(),
        'achievements': const AchievementsScreen(),
      }.entries) {
        testWidgets(
            '${screen.key} ${lang}_$theme',
            (tester) => UiHarness.withoutPlugins(() async {
                  _view(tester, sizes['small']!);
                  final h = await UiHarness.create(prefs: progressPrefs);
                  await tester.pumpWidget(h.app(
                    locale: Locale(lang),
                    dark: dark,
                    home: screen.value,
                  ));
                  await tester.pump(const Duration(milliseconds: 300));
                  expect(tester.takeException(), isNull);
                  await UiHarness.capture(
                      tester, outDir, '${screen.key}_${lang}_$theme');
                  await tester.pumpWidget(const SizedBox());
                  await tester.pump(const Duration(seconds: 2));
                }));
      }

      testWidgets(
          'dialogs ${lang}_$theme',
          (tester) => UiHarness.withoutPlugins(() async {
                _view(tester, sizes['small']!);
                final l10n = lookupAppLocalizations(Locale(lang));
                final h = await UiHarness.create(prefs: progressPrefs);
                await tester.pumpWidget(h.app(
                  locale: Locale(lang),
                  dark: dark,
                  initial: const RouteSettings(
                      name: '/game', arguments: {'level': 23}),
                  routes: {'/game': (_) => const GameScreen()},
                ));
                await _frames(tester, 120);

                await tester.tap(find.byTooltip(l10n.pause));
                await _frames(tester, 30);
                expect(tester.takeException(), isNull);
                await UiHarness.capture(tester, outDir, 'pause_${lang}_$theme');
                await tester.tap(find.text(l10n.resumeGame));
                await _frames(tester, 30);

                await tester.tap(find.bySemanticsLabel(
                  l10n.boosterLeft(l10n.powerUpHint, 1),
                ));
                await _frames(tester, 10);
                await tester.tap(find.byTooltip(l10n.pause));
                await _frames(tester, 30);
                await tester.tap(find.text(l10n.restartLevel));
                await _frames(tester, 30);
                expect(tester.takeException(), isNull);
                await UiHarness.capture(
                    tester, outDir, 'restart_confirm_${lang}_$theme');
                await tester.tap(find.text(l10n.keepPlaying));
                await _frames(tester, 30);

                await tester.tap(find.byTooltip(l10n.mainMenu));
                await _frames(tester, 30);
                expect(tester.takeException(), isNull);
                await UiHarness.capture(
                    tester, outDir, 'leave_confirm_${lang}_$theme');
                await tester.tap(find.text(l10n.keepPlaying));
                await _frames(tester, 30);

                await tester.pumpWidget(const SizedBox());
                await tester.pump(const Duration(seconds: 3));
              }));

      testWidgets(
          'results ${lang}_$theme',
          (tester) => UiHarness.withoutPlugins(() async {
                _view(tester, sizes['small']!);
                final l10n = lookupAppLocalizations(Locale(lang));
                final h = await UiHarness.create(prefs: progressPrefs);
                final panels = <String, Widget>{
                  'complete': LevelResultPanel(
                    level: h.levels.getLevel(23),
                    stars: 3,
                    coins: 25,
                    improved: false,
                    onNext: () {},
                    onReplay: () {},
                    onHome: () {},
                    onWatchAd: () {},
                    showCoinAd: true,
                  ),
                  'complete_boss': LevelResultPanel(
                    level: h.levels.getLevel(28),
                    stars: 2,
                    coins: 60,
                    improved: true,
                    onNext: () {},
                    onReplay: () {},
                    onHome: () {},
                  ),
                  'complete_final': LevelResultPanel(
                    level: h.levels.getLevel(1000),
                    stars: 3,
                    coins: 100,
                    improved: false,
                    onNext: () {},
                    onReplay: () {},
                    onHome: () {},
                  ),
                  'game_over': FailurePanel(
                    title: l10n.levelFailed,
                    message: l10n.outOfLives,
                    icon: GameIconKind.heartBroken,
                    lives: 0,
                    maxLives: 3,
                    onRetry: () {},
                    onHome: () {},
                    recovery: ContinueAdButton(
                      label: l10n.watchVideo,
                      subtitle: l10n.watchAdForLifeContinue,
                      onPressed: () {},
                    ),
                    extra: GameButton(
                      label: l10n.needCoins(100, 40),
                      icon: GameIconKind.heart,
                      variant: GameButtonVariant.secondary,
                      compact: true,
                    ),
                  ),
                };
                for (final entry in panels.entries) {
                  await tester.pumpWidget(h.app(
                    locale: Locale(lang),
                    dark: dark,
                    home: Scaffold(
                      body: Builder(
                        builder: (context) => Center(
                          child: TextButton(
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) => Dialog(
                                backgroundColor: Colors.transparent,
                                insetPadding: GameDialog.insetPadding,
                                child:
                                    SingleChildScrollView(child: entry.value),
                              ),
                            ),
                            child: const Text('open'),
                          ),
                        ),
                      ),
                    ),
                  ));
                  await tester.tap(find.text('open'));
                  await tester.pump(const Duration(milliseconds: 600));
                  expect(tester.takeException(), isNull);
                  await UiHarness.capture(
                      tester, outDir, '${entry.key}_${lang}_$theme');
                  await tester.pumpWidget(const SizedBox());
                  await tester.pump(const Duration(seconds: 2));
                }
              }));
    }
  }
}

Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void _view(WidgetTester tester, Size size) {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

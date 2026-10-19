import 'package:arrow_escape/l10n/generated/app_localizations.dart';
import 'package:arrow_escape/screens/game/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../visual/ui_harness.dart';

/// Pause, restart and leave flows on the real gameplay screen.
void main() {
  const prefs = <String, Object>{
    'currentLevel': 23,
    'highestUnlockedLevel': 23,
    'coins': 1250,
    'adsRemoved': true,
    'hasSeen40x40Warning': true,
    'hasSeenZoomHint': true,
  };

  Future<AppLocalizations> openGame(
    WidgetTester tester, {
    String lang = 'en',
  }) async {
    tester.view.physicalSize = const Size(720, 1380);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = await UiHarness.create(prefs: prefs);
    await tester.pumpWidget(h.app(
      locale: Locale(lang),
      dark: false,
      initial: const RouteSettings(name: '/game', arguments: {'level': 23}),
      routes: {
        '/game': (_) => const GameScreen(),
        '/menu': (_) => const Scaffold(body: Text('MENU')),
      },
    ));
    await _frames(tester, 120);
    return lookupAppLocalizations(Locale(lang));
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  }

  Future<void> useHint(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.bySemanticsLabel(
      l10n.boosterLeft(l10n.powerUpHint, 1),
    ));
    await _frames(tester, 10);
  }

  testWidgets(
      'resume is the primary pause action and closes the dialog',
      (tester) => UiHarness.withoutPlugins(() async {
            final l10n = await openGame(tester);
            await tester.tap(find.byTooltip(l10n.pause));
            await _frames(tester, 20);
            expect(find.text(l10n.pausedTitle), findsOneWidget);
            expect(find.text(l10n.soundEffects), findsOneWidget);
            expect(find.text(l10n.backgroundMusic), findsOneWidget);
            expect(find.text(l10n.vibration), findsOneWidget);

            final resume = tester.getRect(find.text(l10n.resumeGame));
            final restart = tester.getRect(find.text(l10n.restartLevel));
            expect(resume.top, lessThan(restart.top));

            await tester.tap(find.text(l10n.resumeGame));
            await _frames(tester, 20);
            expect(find.text(l10n.pausedTitle), findsNothing);
            expect(find.text(l10n.restartConfirmTitle), findsNothing);
            await close(tester);
          }));

  testWidgets(
      'restart without progress needs no confirmation',
      (tester) => UiHarness.withoutPlugins(() async {
            final l10n = await openGame(tester);
            await tester.tap(find.byTooltip(l10n.pause));
            await _frames(tester, 20);
            await tester.tap(find.text(l10n.restartLevel));
            await _frames(tester, 20);
            expect(find.text(l10n.restartConfirmTitle), findsNothing);
            expect(find.text(l10n.pausedTitle), findsNothing);
            await close(tester);
          }));

  testWidgets(
      'restart after progress asks first and can be cancelled',
      (tester) => UiHarness.withoutPlugins(() async {
            final l10n = await openGame(tester);
            await useHint(tester, l10n);
            expect(
              find.bySemanticsLabel(l10n.boosterEmpty(l10n.powerUpHint)),
              findsOneWidget,
            );

            await tester.tap(find.byTooltip(l10n.pause));
            await _frames(tester, 20);
            await tester.tap(find.text(l10n.restartLevel));
            await _frames(tester, 20);
            expect(find.text(l10n.restartConfirmTitle), findsOneWidget);

            await tester.tap(find.text(l10n.keepPlaying));
            await _frames(tester, 20);
            expect(find.text(l10n.restartConfirmTitle), findsNothing);
            expect(
              find.bySemanticsLabel(l10n.boosterEmpty(l10n.powerUpHint)),
              findsOneWidget,
              reason: 'cancelling must not reset the board',
            );

            await tester.tap(find.byTooltip(l10n.pause));
            await _frames(tester, 20);
            await tester.tap(find.text(l10n.restartLevel));
            await _frames(tester, 20);
            final confirm = find.descendant(
              of: find.byType(Dialog),
              matching: find.text(l10n.restartLevel),
            );
            await tester.tap(confirm);
            await _frames(tester, 20);
            expect(find.byType(Dialog), findsNothing);
            expect(
              find.bySemanticsLabel(l10n.boosterLeft(l10n.powerUpHint, 1)),
              findsOneWidget,
              reason: 'a confirmed restart resets the level boosters',
            );
            await close(tester);
          }));

  testWidgets(
      'leaving without progress goes straight to the menu',
      (tester) => UiHarness.withoutPlugins(() async {
            final l10n = await openGame(tester);
            await tester.tap(find.byTooltip(l10n.mainMenu));
            await _frames(tester, 30);
            expect(find.text(l10n.leaveConfirmTitle), findsNothing);
            expect(find.text('MENU'), findsOneWidget);
            await close(tester);
          }));

  testWidgets(
      'leaving after progress asks first; keep playing stays',
      (tester) => UiHarness.withoutPlugins(() async {
            final l10n = await openGame(tester);
            await useHint(tester, l10n);

            await tester.tap(find.byTooltip(l10n.mainMenu));
            await _frames(tester, 20);
            expect(find.text(l10n.leaveConfirmTitle), findsOneWidget);
            expect(find.text(l10n.leaveConfirmBody), findsOneWidget);

            await tester.tap(find.text(l10n.keepPlaying));
            await _frames(tester, 20);
            expect(find.text(l10n.leaveConfirmTitle), findsNothing);
            expect(find.text('MENU'), findsNothing);

            await tester.tap(find.byTooltip(l10n.mainMenu));
            await _frames(tester, 20);
            await tester.tap(find.text(l10n.leaveLevel));
            await _frames(tester, 30);
            expect(find.text('MENU'), findsOneWidget);
            await close(tester);
          }));

  testWidgets(
      'device back uses the same leave confirmation',
      (tester) => UiHarness.withoutPlugins(() async {
            final l10n = await openGame(tester);
            await useHint(tester, l10n);

            await tester.binding.handlePopRoute();
            await _frames(tester, 20);
            expect(find.text(l10n.leaveConfirmTitle), findsOneWidget);

            // Back again dismisses the confirmation, which keeps the level.
            await tester.binding.handlePopRoute();
            await _frames(tester, 20);
            expect(find.text(l10n.leaveConfirmTitle), findsNothing);
            expect(find.text('MENU'), findsNothing);
            await close(tester);
          }));

  testWidgets(
      'Arabic HUD mirrors: pause at the right, home at the left',
      (tester) => UiHarness.withoutPlugins(() async {
            final l10n = await openGame(tester, lang: 'ar');
            final pause = tester.getCenter(find.byTooltip(l10n.pause));
            final home = tester.getCenter(find.byTooltip(l10n.mainMenu));
            expect(pause.dx, greaterThan(home.dx));

            await tester.tap(find.byTooltip(l10n.pause));
            await _frames(tester, 20);
            expect(find.text(l10n.pausedTitle), findsOneWidget);
            final resume = tester.getRect(find.text(l10n.resumeGame));
            final restart = tester.getRect(find.text(l10n.restartLevel));
            expect(resume.top, lessThan(restart.top));
            await close(tester);
          }));

  testWidgets(
      'English HUD: pause at the left, home at the right',
      (tester) => UiHarness.withoutPlugins(() async {
            final l10n = await openGame(tester);
            final pause = tester.getCenter(find.byTooltip(l10n.pause));
            final home = tester.getCenter(find.byTooltip(l10n.mainMenu));
            expect(pause.dx, lessThan(home.dx));
            await close(tester);
          }));
}

Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

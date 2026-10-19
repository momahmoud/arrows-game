import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/l10n/generated/app_localizations.dart';
import 'package:arrow_escape/ui/game_ui.dart';
import 'package:arrow_escape/ui/widgets/level_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../visual/ui_harness.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  Future<UiHarness> mount(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final h = await UiHarness.create();
    await tester.pumpWidget(h.app(
      locale: const Locale('en'),
      dark: false,
      home: Scaffold(body: Center(child: SingleChildScrollView(child: child))),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    return h;
  }

  group('LevelResultPanel', () {
    Future<List<String>> pumpPanel(
      WidgetTester tester, {
      required int level,
      bool canAdvance = true,
    }) async {
      final taps = <String>[];
      final h = await UiHarness.create();
      await mount(
        tester,
        LevelResultPanel(
          level: h.levels.getLevel(level),
          stars: 3,
          coins: 25,
          improved: false,
          canAdvance: canAdvance,
          onNext: () => taps.add('next'),
          onReplay: () => taps.add('replay'),
          onHome: () => taps.add('home'),
        ),
      );
      return taps;
    }

    testWidgets(
        'regular level offers Next, Replay and Home',
        (tester) => UiHarness.withoutPlugins(() async {
              final taps = await pumpPanel(tester, level: 23);
              expect(find.text(en.nextLevel), findsOneWidget);
              expect(find.text(en.retry), findsOneWidget);
              expect(find.text(en.navHome), findsOneWidget);
              await tester.tap(find.text(en.nextLevel));
              await tester.pump();
              expect(taps, ['next']);
              await tester.pump(const Duration(seconds: 2));
            }));

    testWidgets(
        'final level has no Next and makes Home the main action',
        (tester) => UiHarness.withoutPlugins(() async {
              final taps =
                  await pumpPanel(tester, level: AppConstants.totalLevels);
              expect(find.text(en.nextLevel), findsNothing);
              expect(find.text(en.finishedGameTitle), findsOneWidget);
              expect(find.text(en.navHome), findsOneWidget);
              expect(find.text(en.retry), findsOneWidget);
              final home = tester.getRect(find.text(en.navHome));
              final replay = tester.getRect(find.text(en.retry));
              expect(home.top, lessThan(replay.top));
              await tester.tap(find.text(en.navHome));
              await tester.pump();
              expect(taps, ['home']);
              await tester.pump(const Duration(seconds: 2));
            }));

    testWidgets(
        'a run that cannot advance hides Next',
        (tester) => UiHarness.withoutPlugins(() async {
              await pumpPanel(tester, level: 30, canAdvance: false);
              expect(find.text(en.nextLevel), findsNothing);
              expect(find.text(en.finishedGameTitle), findsNothing);
              expect(find.text(en.navHome), findsOneWidget);
              await tester.pump(const Duration(seconds: 2));
            }));
  });

  group('showGameConfirm', () {
    Future<Future<bool>> open(WidgetTester tester) async {
      late Future<bool> result;
      await mount(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => result = showGameConfirm(
              context,
              title: 'Title',
              message: 'Message',
              confirmLabel: 'Confirm',
              confirmIcon: GameIconKind.home,
              cancelLabel: 'Stay',
            ),
            child: const Text('open'),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump(const Duration(milliseconds: 400));
      return result;
    }

    testWidgets(
        'the safe choice is first and returns false',
        (tester) => UiHarness.withoutPlugins(() async {
              final result = await open(tester);
              final stay = tester.getRect(find.text('Stay'));
              final confirm = tester.getRect(find.text('Confirm'));
              expect(stay.top, lessThan(confirm.top));
              await tester.tap(find.text('Stay'));
              await tester.pump(const Duration(milliseconds: 400));
              expect(await result, isFalse);
            }));

    testWidgets(
        'confirm returns true',
        (tester) => UiHarness.withoutPlugins(() async {
              final result = await open(tester);
              await tester.tap(find.text('Confirm'));
              await tester.pump(const Duration(milliseconds: 400));
              expect(await result, isTrue);
            }));

    testWidgets(
        'tapping outside counts as cancel',
        (tester) => UiHarness.withoutPlugins(() async {
              final result = await open(tester);
              await tester.tapAt(const Offset(4, 4));
              await tester.pump(const Duration(milliseconds: 400));
              expect(await result, isFalse);
            }));
  });

  group('BoosterButton', () {
    testWidgets(
        'shows its name and reads name and count',
        (tester) => UiHarness.withoutPlugins(() async {
              var taps = 0;
              await mount(
                tester,
                SizedBox(
                  width: 90,
                  child: BoosterButton(
                    icon: GameIconKind.hint,
                    label: en.powerUpHint,
                    count: 2,
                    enabled: true,
                    canRefill: false,
                    onTap: () => taps++,
                  ),
                ),
              );
              expect(find.text(en.powerUpHint), findsOneWidget);
              final label = en.boosterLeft(en.powerUpHint, 2);
              expect(find.bySemanticsLabel(label), findsOneWidget);
              await tester.tap(find.bySemanticsLabel(label));
              await tester.pump(const Duration(milliseconds: 200));
              expect(taps, 1);
            }));

    testWidgets(
        'an empty booster without refill is not tappable',
        (tester) => UiHarness.withoutPlugins(() async {
              var taps = 0;
              await mount(
                tester,
                SizedBox(
                  width: 90,
                  child: BoosterButton(
                    icon: GameIconKind.ruler,
                    label: en.powerUpRuler,
                    count: 0,
                    enabled: true,
                    canRefill: false,
                    onTap: () => taps++,
                  ),
                ),
              );
              final label = en.boosterEmpty(en.powerUpRuler);
              expect(find.bySemanticsLabel(label), findsOneWidget);
              await tester.tap(find.bySemanticsLabel(label));
              await tester.pump(const Duration(milliseconds: 200));
              expect(taps, 0);
            }));
  });
}

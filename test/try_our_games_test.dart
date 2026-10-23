import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_escape/widgets/try_our_games_sheet.dart';

Future<void> _pumpSheet(
  WidgetTester tester, {
  required String lang,
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: TextButton(
                onPressed: () => TryOurGamesSheet.show(
                  context,
                  languageCode: lang,
                  isRtl: lang == 'ar',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('catalog', () {
    test('hides the current app and lists every other game', () {
      final List<String> shown = TryOurGamesConfig.promotableGames
          .map((FluxyGameEntry g) => g.androidPackageName)
          .toList();
      expect(shown, isNot(contains(TryOurGamesConfig.currentAndroidPackage)));
      expect(
        shown.length,
        TryOurGamesConfig.games.length - 1,
        reason: 'the current app must be in the catalog so it can be hidden',
      );
      expect(
        TryOurGamesConfig.releasedGames.length +
            TryOurGamesConfig.upcomingGames.length,
        shown.length,
      );
    });

    test('the featured game is a released one', () {
      final FluxyGameEntry? featured = TryOurGamesConfig.featuredGame;
      expect(featured, isNotNull);
      expect(featured!.comingSoon, isFalse);
    });

    test('every game has names, a subtitle and an icon that exists', () {
      for (final FluxyGameEntry g in TryOurGamesConfig.games) {
        expect(g.nameEn, isNotEmpty);
        expect(g.nameAr, isNotEmpty);
        expect(g.subtitleEn, isNotEmpty);
        expect(g.subtitleAr, isNotEmpty);
        expect(g.iconAsset, isNotNull, reason: g.androidPackageName);
        expect(
          File(g.iconAsset!).existsSync(),
          isTrue,
          reason: '${g.androidPackageName} icon ${g.iconAsset}',
        );
      }
    });
  });

  group('sheet', () {
    for (final String lang in <String>['en', 'ar']) {
      testWidgets('shows every game without overflow ($lang)', (
        WidgetTester tester,
      ) async {
        await _pumpSheet(tester, lang: lang);
        expect(tester.takeException(), isNull);

        final Finder list = find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        );
        // The sheet scrolls, so reach each game in order (featured, live
        // games, then the coming-soon ones) before checking it.
        final List<FluxyGameEntry> inOrder = <FluxyGameEntry>[
          TryOurGamesConfig.featuredGame!,
          ...TryOurGamesConfig.releasedGames.where(
            (FluxyGameEntry g) => g != TryOurGamesConfig.featuredGame,
          ),
          ...TryOurGamesConfig.upcomingGames,
        ];
        for (final FluxyGameEntry g in inOrder) {
          final Finder name = find.text(g.nameFor(lang));
          await tester.scrollUntilVisible(name, 150, scrollable: list);
          expect(name, findsOneWidget, reason: g.androidPackageName);
        }
        // Let the entrance animation of the last row finish.
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('survives a small phone and large text', (
      WidgetTester tester,
    ) async {
      await _pumpSheet(
        tester,
        lang: 'ar',
        textScale: 1.3,
        size: const Size(320, 568),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the close button dismisses the sheet', (
      WidgetTester tester,
    ) async {
      await _pumpSheet(tester, lang: 'en');
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text(TryOurGamesConfig.titleEn), findsNothing);
    });
  });
}

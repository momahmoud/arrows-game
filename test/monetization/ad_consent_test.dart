import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_escape/monetization/prompts/ad_consent.dart';

class _MemoryStore implements ConsentStore {
  _MemoryStore([this.value]);

  bool? value;

  @override
  Future<bool?> load() async => value;

  @override
  Future<void> save(bool personalized) async => value = personalized;
}

void main() {
  group('region', () {
    test('Europe asks, by language region or by time zone', () {
      expect(ConsentRegion.requiresConsent(countryCodes: ['DE']), isTrue);
      expect(ConsentRegion.requiresConsent(countryCodes: ['gb']), isTrue);
      expect(ConsentRegion.requiresConsent(countryCodes: ['CH']), isTrue);
      expect(ConsentRegion.requiresConsent(timeZone: 'Europe/Paris'), isTrue);
      expect(ConsentRegion.requiresConsent(timeZone: 'Europe/London'), isTrue);
    });

    test('an Arabic-speaking player in Europe is still asked', () {
      expect(
        ConsentRegion.requiresConsent(
          countryCodes: ['SA'],
          timeZone: 'Europe/Berlin',
        ),
        isTrue,
      );
      expect(
        ConsentRegion.requiresConsent(countryCodes: ['SA', 'FR']),
        isTrue,
      );
    });

    test('everywhere else is not asked', () {
      expect(
        ConsentRegion.requiresConsent(
          countryCodes: ['SA', 'EG', 'AE', 'US', null],
          timeZone: 'Asia/Riyadh',
        ),
        isFalse,
      );
      expect(ConsentRegion.requiresConsent(), isFalse);
      expect(ConsentRegion.requiresConsent(timeZone: 'Europe/Moscow'), isFalse);
    });
  });

  group('consent', () {
    late _MemoryStore store;
    late List<bool> applied;

    AdConsent build({bool region = true, bool? saved}) {
      store = _MemoryStore(saved);
      applied = [];
      return AdConsent(
        store: store,
        detectRegion: () async => region,
        apply: (personalized) async => applied.add(personalized),
      );
    }

    test('outside the region nothing is asked and ads start at once', () async {
      final consent = build(region: false);
      expect(await consent.decision, isNull);
      expect(consent.needsAnswer, isFalse);
      var asked = false;
      await consent.askIfNeeded(() async {
        asked = true;
        return true;
      });
      expect(asked, isFalse);
    });

    test('in the region, ads wait for the answer, then get it', () async {
      final consent = build();
      var decided = false;
      bool? result;
      consent.decision.then((value) {
        decided = true;
        result = value;
      });
      await Future<void>.delayed(Duration.zero);
      expect(consent.needsAnswer, isTrue);
      expect(decided, isFalse, reason: 'still waiting for the player');

      await consent.askIfNeeded(() async => false);
      await Future<void>.delayed(Duration.zero);
      expect(decided, isTrue);
      expect(result, isFalse);
      expect(applied, [false]);
      expect(store.value, isFalse);
    });

    test('a saved answer is used straight away and not asked again', () async {
      final consent = build(saved: true);
      expect(await consent.decision, isTrue);
      var asked = false;
      await consent.askIfNeeded(() async {
        asked = true;
        return false;
      });
      expect(asked, isFalse);
    });

    test('a question that goes away unanswered is asked again', () async {
      final consent = build();
      await consent.askIfNeeded(() async => null);
      expect(consent.needsAnswer, isTrue);
      await consent.askIfNeeded(() async => true);
      expect(consent.needsAnswer, isFalse);
    });

    test('only one question at a time', () async {
      final consent = build();
      var asks = 0;
      final first = consent.askIfNeeded(() async {
        asks++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return true;
      });
      await consent.askIfNeeded(() async {
        asks++;
        return false;
      });
      await first;
      expect(asks, 1);
    });

    test('the player can change their mind later', () async {
      final consent = build(saved: true);
      await consent.change(() async => false);
      expect(consent.choice, isFalse);
      expect(applied, [false]);
    });

    test('a failing ad network does not lose the answer', () async {
      store = _MemoryStore();
      final consent = AdConsent(
        store: store,
        detectRegion: () async => true,
        apply: (_) async => throw StateError('sdk'),
      );
      await consent.answer(true);
      expect(consent.choice, isTrue);
      expect(store.value, isTrue);
    });
  });

  test('wording exists in both languages', () {
    for (final lang in ['ar', 'en']) {
      expect(AdConsentCopy.title(lang), isNotEmpty);
      expect(AdConsentCopy.body(lang, 'Game'), contains('Game'));
      expect(AdConsentCopy.allow(lang), isNotEmpty);
      expect(AdConsentCopy.decline(lang), isNotEmpty);
      expect(AdConsentCopy.settingsTitle(lang), isNotEmpty);
      expect(
        AdConsentCopy.settingsSubtitle(lang, personalized: true),
        isNot(AdConsentCopy.settingsSubtitle(lang, personalized: false)),
      );
    }
  });

  group('trigger', () {
    Future<(GlobalKey<NavigatorState>, AdConsent, List<int>)> pumpHome(
      WidgetTester tester,
    ) async {
      final consent = AdConsent(
        store: _MemoryStore(),
        detectRegion: () async => true,
        apply: (_) async {},
      );
      final asked = <int>[];
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: AdConsentTrigger(
            consent: consent,
            show: (context) async {
              asked.add(1);
              return true;
            },
            child: const Text('home'),
          ),
        ),
      );
      return (navigator, consent, asked);
    }

    testWidgets('asks once the screen is in front', (tester) async {
      final (_, consent, asked) = await pumpHome(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(asked, [1]);
      expect(consent.needsAnswer, isFalse);
    });

    testWidgets('waits while another screen is on top of it', (tester) async {
      final consent = AdConsent(
        store: _MemoryStore(),
        detectRegion: () async => true,
        apply: (_) async {},
      );
      final asked = <int>[];
      final navigator = GlobalKey<NavigatorState>();
      // As at launch: the splash is already above the home screen when the
      // home screen is built.
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          onGenerateRoute: (_) => null,
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(
              builder: (_) => AdConsentTrigger(
                consent: consent,
                show: (context) async {
                  asked.add(1);
                  return true;
                },
                child: const Text('home'),
              ),
            ),
            MaterialPageRoute<void>(builder: (_) => const Text('splash')),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(asked, isEmpty, reason: 'must not ask over the splash');
      expect(consent.needsAnswer, isTrue);

      // Still waiting a long while later: a welcome screen can take its time.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(asked, isEmpty);

      navigator.currentState!.pop();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
      expect(asked, [1]);
      expect(consent.needsAnswer, isFalse);
    });

    testWidgets('does not ask where it is not needed', (tester) async {
      final consent = AdConsent(
        store: _MemoryStore(),
        detectRegion: () async => false,
        apply: (_) async {},
      );
      var asked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: AdConsentTrigger(
            consent: consent,
            show: (context) async {
              asked = true;
              return true;
            },
            child: const Text('home'),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(asked, isFalse);
    });
  });
}

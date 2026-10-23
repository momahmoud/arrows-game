import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_escape/monetization/prompts/prompt_coordinator.dart';
import 'package:arrow_escape/monetization/prompts/prompt_policy.dart';

class _MemoryStore implements PromptStore {
  _MemoryStore([this.state = const PromptState()]);

  PromptState state;

  @override
  Future<PromptState> load() async => state;

  @override
  Future<void> save(PromptState next) async => state = next;
}

void main() {
  late DateTime now;
  late _MemoryStore store;
  late int reviews;
  var reviewAvailable = true;

  PromptCoordinator build([PromptState initial = const PromptState()]) {
    store = _MemoryStore(initial);
    reviews = 0;
    reviewAvailable = true;
    return PromptCoordinator(
      store: store,
      clock: () => now,
      settleDelay: Duration.zero,
      requestReview: () async {
        if (!reviewAvailable) return false;
        reviews++;
        return true;
      },
    );
  }

  setUp(() => now = DateTime(2026, 6, 1, 12));

  const ready = PromptState(sessions: 2, wins: 5);

  test('counts sessions, wins and interstitials', () async {
    final prompts = build();
    await prompts.recordSessionStart();
    await prompts.recordWin();
    await prompts.recordInterstitialShown();
    expect(store.state.sessions, 1);
    expect(store.state.wins, 1);
    expect(store.state.interstitials, 1);
    expect(store.state.lastAdMs, now.millisecondsSinceEpoch);
  });

  group('review', () {
    test('takes the win slot, then asks once the result is up', () async {
      final prompts = build(ready);
      expect(await prompts.takeReviewSlot(), isTrue);
      expect(prompts.isBusy, isTrue, reason: 'the ad must be skipped');
      expect(reviews, 0, reason: 'nothing asked until the result is up');

      await prompts.requestPendingReview();
      expect(reviews, 1);
      expect(store.state.reviewRequests, 1);
      expect(store.state.winsAtLastReview, 5);
      expect(prompts.isBusy, isFalse);

      // Not again for a long while.
      expect(await prompts.takeReviewSlot(), isFalse);
    });

    test('is not taken before the player is ready', () async {
      final prompts = build(const PromptState(sessions: 2, wins: 3));
      expect(await prompts.takeReviewSlot(), isFalse);
      expect(prompts.isBusy, isFalse);
    });

    test('a device without the store dialog costs nothing', () async {
      final prompts = build(ready);
      reviewAvailable = false;
      expect(await prompts.takeReviewSlot(), isTrue);
      await prompts.requestPendingReview();
      expect(store.state.reviewRequests, 0, reason: 'try again later');
      expect(await prompts.takeReviewSlot(), isTrue);
    });

    test('leaving before the result gives the slot back', () async {
      final prompts = build(ready);
      expect(await prompts.takeReviewSlot(), isTrue);
      prompts.dropPendingReview();
      expect(prompts.isBusy, isFalse);
      expect(await prompts.takeReviewSlot(), isTrue);
    });

    test('a claimed slot nobody used expires, so ads are not blocked',
        () async {
      final prompts = build(ready);
      expect(await prompts.takeReviewSlot(), isTrue);
      expect(prompts.isBusy, isTrue);
      now = now.add(const Duration(seconds: 31));
      expect(prompts.isBusy, isFalse);
      await prompts.requestPendingReview();
      expect(reviews, 0, reason: 'too late: the result is long gone');
    });

    test('asking with no claimed slot does nothing', () async {
      final prompts = build(ready);
      await prompts.requestPendingReview();
      expect(reviews, 0);
    });
  });

  group('Remove Ads offer', () {
    const seen = PromptState(sessions: 2, interstitials: 3);

    test('shows the popup once, and waits for it to close', () async {
      final prompts = build(seen);
      var shown = 0;
      final shownOffer = await prompts.offerRemoveAds(
        adsRemoved: false,
        show: () async {
          shown++;
          expect(prompts.isBusy, isTrue, reason: 'ads wait for the popup');
        },
      );
      expect(shownOffer, isTrue);
      expect(shown, 1);
      expect(prompts.isBusy, isFalse);
      expect(store.state.offers, 1);
      expect(store.state.interstitialsSinceOffer, 0);

      // Once per session.
      expect(
        await prompts.offerRemoveAds(
            adsRemoved: false, show: () async => shown++),
        isFalse,
      );
      expect(shown, 1);
    });

    test('never to someone who removed ads', () async {
      final prompts = build(seen);
      expect(
        await prompts.offerRemoveAds(adsRemoved: true, show: () async {}),
        isFalse,
      );
    });

    test('never over a review that is about to show', () async {
      final prompts = build(ready.copyWith(interstitials: 3));
      expect(await prompts.takeReviewSlot(), isTrue);
      expect(
        await prompts.offerRemoveAds(adsRemoved: false, show: () async {}),
        isFalse,
      );
    });

    test('a review is not taken while the popup is up', () async {
      final prompts = build(ready.copyWith(interstitials: 3));
      late Future<bool> slot;
      await prompts.offerRemoveAds(
        adsRemoved: false,
        show: () async => slot = prompts.takeReviewSlot(),
      );
      expect(await slot, isFalse);
    });

    test('a popup that fails still frees the screen', () async {
      final prompts = build(seen);
      final shown = await prompts.offerRemoveAds(
        adsRemoved: false,
        show: () async => throw StateError('closed'),
      );
      expect(shown, isTrue);
      expect(prompts.isBusy, isFalse);
    });
  });
}

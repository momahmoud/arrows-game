import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_escape/monetization/prompts/prompt_policy.dart';

void main() {
  final now = DateTime(2026, 6, 1, 12);
  int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch;
  const policy = PromptPolicy();

  const ready = PromptState(sessions: 2, wins: 5);

  group('native review', () {
    test('waits for five wins over two sessions', () {
      expect(policy.shouldRequestReview(ready, now), isTrue);
      expect(
        policy.shouldRequestReview(ready.copyWith(wins: 4), now),
        isFalse,
      );
      expect(
        policy.shouldRequestReview(ready.copyWith(sessions: 1), now),
        isFalse,
      );
    });

    test('not right after a full-screen ad', () {
      expect(
        policy.shouldRequestReview(
          ready.copyWith(lastAdMs: ago(const Duration(seconds: 10))),
          now,
        ),
        isFalse,
      );
      expect(
        policy.shouldRequestReview(
          ready.copyWith(lastAdMs: ago(const Duration(minutes: 2))),
          now,
        ),
        isTrue,
      );
    });

    test('is asked three times at most, thirty days and ten wins apart', () {
      final asked = ready.copyWith(
        wins: 20,
        reviewRequests: 1,
        winsAtLastReview: 5,
        lastReviewMs: ago(const Duration(days: 31)),
      );
      expect(policy.shouldRequestReview(asked, now), isTrue);
      expect(
        policy.shouldRequestReview(
          asked.copyWith(lastReviewMs: ago(const Duration(days: 10))),
          now,
        ),
        isFalse,
        reason: 'too soon',
      );
      expect(
        policy.shouldRequestReview(asked.copyWith(winsAtLastReview: 15), now),
        isFalse,
        reason: 'too few wins since',
      );
      expect(
        policy.shouldRequestReview(asked.copyWith(reviewRequests: 3), now),
        isFalse,
        reason: 'enough asking',
      );
    });

    test('not right after a Remove Ads offer', () {
      expect(
        policy.shouldRequestReview(
          ready.copyWith(lastOfferMs: ago(const Duration(minutes: 3))),
          now,
        ),
        isFalse,
      );
    });
  });

  group('Remove Ads offer', () {
    const seen = PromptState(sessions: 2, interstitials: 3);

    bool offer(PromptState s, {bool removed = false, bool session = false}) =>
        policy.shouldOfferRemoveAds(
          s,
          now,
          adsRemoved: removed,
          offeredThisSession: session,
        );

    test('after the third interstitial, never to someone who bought', () {
      expect(offer(seen), isTrue);
      expect(offer(seen.copyWith(interstitials: 2)), isFalse);
      expect(offer(seen, removed: true), isFalse);
    });

    test('not in the first session', () {
      expect(offer(seen.copyWith(sessions: 1)), isFalse);
    });

    test('once per session', () {
      expect(offer(seen, session: true), isFalse);
    });

    test('again only after five interstitials and a day', () {
      final offered = seen.copyWith(
        interstitials: 8,
        offers: 1,
        interstitialsSinceOffer: 5,
        lastOfferMs: ago(const Duration(hours: 25)),
      );
      expect(offer(offered), isTrue);
      expect(offer(offered.copyWith(interstitialsSinceOffer: 4)), isFalse);
      expect(
        offer(offered.copyWith(lastOfferMs: ago(const Duration(hours: 5)))),
        isFalse,
      );
    });

    test('stops after six offers', () {
      expect(
        offer(
          seen.copyWith(
            offers: 6,
            interstitialsSinceOffer: 9,
            lastOfferMs: ago(const Duration(days: 9)),
          ),
        ),
        isFalse,
      );
    });

    test('not right after a review request', () {
      expect(
        offer(seen.copyWith(lastReviewMs: ago(const Duration(minutes: 2)))),
        isFalse,
      );
    });
  });

  group('state', () {
    test('survives a round trip and ignores bad values', () {
      const state = PromptState(sessions: 3, wins: 9, offers: 1);
      expect(PromptState.fromMap(state.toMap()).wins, 9);
      final bad = PromptState.fromMap({'wins': -4, 'sessions': 'x'});
      expect(bad.wins, 0);
      expect(bad.sessions, 0);
    });
  });
}

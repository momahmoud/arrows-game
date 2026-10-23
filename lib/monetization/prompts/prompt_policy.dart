import 'dart:math' as math;

/// The numbers behind when the game may ask for a store review or offer
/// Remove Ads. Kept together so they are easy to tune.
class PromptRules {
  const PromptRules({
    this.reviewMinWins = 5,
    this.reviewMinSessions = 2,
    this.reviewMaxRequests = 3,
    this.reviewMinWinsBetween = 10,
    this.reviewMinGap = const Duration(days: 30),
    this.reviewAdQuiet = const Duration(seconds: 45),
    this.offerMinInterstitials = 3,
    this.offerMinSessions = 2,
    this.offerEveryInterstitials = 5,
    this.offerMinGap = const Duration(hours: 24),
    this.offerMaxOffers = 6,
    this.promptQuiet = const Duration(minutes: 10),
  });

  /// Wins before the first review request, in at least this many sessions:
  /// the player has seen what the game is before being asked about it.
  final int reviewMinWins;
  final int reviewMinSessions;

  /// Most requests ever. Apple shows the dialog at most three times a year
  /// anyway, and Google limits it too.
  final int reviewMaxRequests;

  /// Wins needed after a request before the next one.
  final int reviewMinWinsBetween;

  /// Time between requests.
  final Duration reviewMinGap;

  /// No review right after a full-screen ad.
  final Duration reviewAdQuiet;

  /// Interstitials the player must have seen before the first offer, and
  /// the sessions they were seen over.
  final int offerMinInterstitials;
  final int offerMinSessions;

  /// Interstitials between two offers, and the time between them.
  final int offerEveryInterstitials;
  final Duration offerMinGap;

  /// Most offers ever.
  final int offerMaxOffers;

  /// Quiet time after any prompt (review or offer) before the next one.
  final Duration promptQuiet;
}

/// What the game remembers to decide on prompts. Plain numbers, stored
/// as-is, so an old save still reads.
class PromptState {
  const PromptState({
    this.sessions = 0,
    this.wins = 0,
    this.reviewRequests = 0,
    this.lastReviewMs = 0,
    this.winsAtLastReview = 0,
    this.interstitials = 0,
    this.interstitialsSinceOffer = 0,
    this.lastAdMs = 0,
    this.offers = 0,
    this.lastOfferMs = 0,
  });

  /// App launches.
  final int sessions;

  /// Levels or rounds won.
  final int wins;

  final int reviewRequests;
  final int lastReviewMs;
  final int winsAtLastReview;

  /// Interstitials shown, and how many since the last Remove Ads offer.
  final int interstitials;
  final int interstitialsSinceOffer;

  /// When a full-screen ad (interstitial or rewarded) last closed.
  final int lastAdMs;

  final int offers;
  final int lastOfferMs;

  /// When the player was last prompted, by either kind.
  int get lastPromptMs => math.max(lastReviewMs, lastOfferMs);

  PromptState copyWith({
    int? sessions,
    int? wins,
    int? reviewRequests,
    int? lastReviewMs,
    int? winsAtLastReview,
    int? interstitials,
    int? interstitialsSinceOffer,
    int? lastAdMs,
    int? offers,
    int? lastOfferMs,
  }) {
    return PromptState(
      sessions: sessions ?? this.sessions,
      wins: wins ?? this.wins,
      reviewRequests: reviewRequests ?? this.reviewRequests,
      lastReviewMs: lastReviewMs ?? this.lastReviewMs,
      winsAtLastReview: winsAtLastReview ?? this.winsAtLastReview,
      interstitials: interstitials ?? this.interstitials,
      interstitialsSinceOffer:
          interstitialsSinceOffer ?? this.interstitialsSinceOffer,
      lastAdMs: lastAdMs ?? this.lastAdMs,
      offers: offers ?? this.offers,
      lastOfferMs: lastOfferMs ?? this.lastOfferMs,
    );
  }

  Map<String, int> toMap() => {
        'sessions': sessions,
        'wins': wins,
        'reviewRequests': reviewRequests,
        'lastReviewMs': lastReviewMs,
        'winsAtLastReview': winsAtLastReview,
        'interstitials': interstitials,
        'interstitialsSinceOffer': interstitialsSinceOffer,
        'lastAdMs': lastAdMs,
        'offers': offers,
        'lastOfferMs': lastOfferMs,
      };

  factory PromptState.fromMap(Map<String, Object?> map) {
    int read(String key) {
      final value = map[key];
      return value is int && value >= 0 ? value : 0;
    }

    return PromptState(
      sessions: read('sessions'),
      wins: read('wins'),
      reviewRequests: read('reviewRequests'),
      lastReviewMs: read('lastReviewMs'),
      winsAtLastReview: read('winsAtLastReview'),
      interstitials: read('interstitials'),
      interstitialsSinceOffer: read('interstitialsSinceOffer'),
      lastAdMs: read('lastAdMs'),
      offers: read('offers'),
      lastOfferMs: read('lastOfferMs'),
    );
  }
}

/// The decisions. Pure: the same state and time always give the same answer.
class PromptPolicy {
  const PromptPolicy([this.rules = const PromptRules()]);

  final PromptRules rules;

  /// Whether the native review dialog may be requested on this win. The
  /// caller counts the win first.
  bool shouldRequestReview(PromptState s, DateTime now) {
    final nowMs = now.millisecondsSinceEpoch;
    if (s.wins < rules.reviewMinWins) return false;
    if (s.sessions < rules.reviewMinSessions) return false;
    if (s.reviewRequests >= rules.reviewMaxRequests) return false;
    if (s.reviewRequests > 0) {
      if (s.wins - s.winsAtLastReview < rules.reviewMinWinsBetween) {
        return false;
      }
      if (nowMs - s.lastReviewMs < rules.reviewMinGap.inMilliseconds) {
        return false;
      }
    }
    if (_within(nowMs, s.lastAdMs, rules.reviewAdQuiet)) return false;
    if (_within(nowMs, s.lastPromptMs, rules.promptQuiet)) return false;
    return true;
  }

  /// Whether Remove Ads may be offered now, right after an interstitial.
  /// The caller counts that interstitial first.
  bool shouldOfferRemoveAds(
    PromptState s,
    DateTime now, {
    required bool adsRemoved,
    required bool offeredThisSession,
  }) {
    final nowMs = now.millisecondsSinceEpoch;
    if (adsRemoved || offeredThisSession) return false;
    if (s.sessions < rules.offerMinSessions) return false;
    if (s.offers >= rules.offerMaxOffers) return false;
    if (s.interstitials < rules.offerMinInterstitials) return false;
    if (s.offers > 0) {
      if (s.interstitialsSinceOffer < rules.offerEveryInterstitials) {
        return false;
      }
      if (nowMs - s.lastOfferMs < rules.offerMinGap.inMilliseconds) {
        return false;
      }
    }
    if (_within(nowMs, s.lastReviewMs, rules.promptQuiet)) return false;
    return true;
  }

  bool _within(int nowMs, int thenMs, Duration window) =>
      thenMs != 0 && nowMs - thenMs < window.inMilliseconds;
}

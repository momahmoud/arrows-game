import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prompt_policy.dart';

/// Where the prompt counters are kept.
abstract class PromptStore {
  Future<PromptState> load();
  Future<void> save(PromptState state);
}

class SharedPreferencesPromptStore implements PromptStore {
  const SharedPreferencesPromptStore();

  static const _key = 'engagement_prompts_v1';

  @override
  Future<PromptState> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return const PromptState();
      return PromptState.fromMap(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return const PromptState();
    }
  }

  @override
  Future<void> save(PromptState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(state.toMap()));
    } catch (_) {
      // Counters are best-effort: a lost save only delays a prompt.
    }
  }
}

/// Decides, and keeps the books for, the two things the game says to the
/// player outside play: a store review request after a win, and an offer to
/// remove ads after an interstitial.
///
/// One prompt at a time, and never next to an ad:
/// - When a review is due it takes that win's slot, and the caller skips the
///   interstitial for that win ([takeReviewSlot]).
/// - The Remove Ads offer comes only right after an interstitial closed, on
///   the screen the player is still looking at ([offerRemoveAds]).
/// - Ad code should not start an interstitial while [isBusy].
class PromptCoordinator {
  PromptCoordinator({
    PromptStore store = const SharedPreferencesPromptStore(),
    Future<bool> Function()? requestReview,
    DateTime Function()? clock,
    PromptPolicy policy = const PromptPolicy(),
    this.settleDelay = const Duration(milliseconds: 700),
    this.claimTimeout = const Duration(seconds: 30),
  })  : _store = store,
        _requestReview = requestReview ?? _nativeReview,
        _clock = clock ?? DateTime.now,
        _policy = policy;

  /// The app-wide coordinator.
  static final PromptCoordinator instance = PromptCoordinator();

  final PromptStore _store;
  final Future<bool> Function() _requestReview;
  final DateTime Function() _clock;
  final PromptPolicy _policy;

  /// Pause before a prompt, so it lands on a calm screen and not on top of
  /// whatever just closed.
  final Duration settleDelay;

  /// How long a claimed review slot waits to be used. A screen that claims
  /// it and never asks (it failed, or the player left) must not keep ads
  /// blocked for good.
  final Duration claimTimeout;

  PromptState _state = const PromptState();
  late final Future<void> _ready = _load();
  bool _reviewClaimed = false;
  DateTime _claimedAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _busy = false;
  bool _offeredThisSession = false;

  /// A claimed slot that has not expired.
  bool get _reviewPending =>
      _reviewClaimed && _clock().difference(_claimedAt) < claimTimeout;

  /// True while a prompt is being shown or about to be.
  bool get isBusy => _busy || _reviewPending;

  PromptState get state => _state;

  Future<void> _load() async => _state = await _store.load();

  Future<void> _update(PromptState Function(PromptState) change) async {
    await _ready;
    _state = change(_state);
    await _store.save(_state);
  }

  /// Once per app launch.
  Future<void> recordSessionStart() =>
      _update((s) => s.copyWith(sessions: s.sessions + 1));

  /// Once per level or round the player wins.
  Future<void> recordWin() => _update((s) => s.copyWith(wins: s.wins + 1));

  /// When an interstitial has closed.
  Future<void> recordInterstitialShown() => _update(
        (s) => s.copyWith(
          interstitials: s.interstitials + 1,
          interstitialsSinceOffer: s.interstitialsSinceOffer + 1,
          lastAdMs: _clock().millisecondsSinceEpoch,
        ),
      );

  /// When a rewarded ad has closed. It counts as a recent ad, nothing more.
  Future<void> recordRewardedShown() =>
      _update((s) => s.copyWith(lastAdMs: _clock().millisecondsSinceEpoch));

  /// At the moment a win is counted: true when the native review takes this
  /// slot. The caller then skips the interstitial for this win, and calls
  /// [requestPendingReview] once the result is on screen.
  Future<bool> takeReviewSlot() async {
    await _ready;
    if (_busy || _reviewPending) return false;
    if (!_policy.shouldRequestReview(_state, _clock())) return false;
    _reviewClaimed = true;
    _claimedAt = _clock();
    return true;
  }

  /// Asks for the native review if [takeReviewSlot] claimed this win. Safe
  /// to call every time. A device without the store dialog (not installed
  /// from the store, or no Play services) costs nothing and tries again at
  /// a later win.
  Future<void> requestPendingReview() async {
    if (!_reviewPending || _busy) return;
    _reviewClaimed = false;
    _busy = true;
    try {
      await Future<void>.delayed(settleDelay);
      final asked = await _requestReview();
      if (asked) {
        await _update(
          (s) => s.copyWith(
            reviewRequests: s.reviewRequests + 1,
            lastReviewMs: _clock().millisecondsSinceEpoch,
            winsAtLastReview: s.wins,
          ),
        );
      }
    } catch (error) {
      debugPrint('Review request failed: $error');
    } finally {
      _busy = false;
    }
  }

  /// Gives the slot back, e.g. when the player left before the result.
  void dropPendingReview() => _reviewClaimed = false;

  /// Right after an interstitial closed (and [recordInterstitialShown]):
  /// shows [show], the app's Remove Ads popup, when the rules allow it, and
  /// returns whether it did. [show] completes when the popup is gone.
  Future<bool> offerRemoveAds({
    required bool adsRemoved,
    required Future<void> Function() show,
  }) async {
    await _ready;
    if (_busy || _reviewPending) return false;
    if (!_policy.shouldOfferRemoveAds(
      _state,
      _clock(),
      adsRemoved: adsRemoved,
      offeredThisSession: _offeredThisSession,
    )) {
      return false;
    }
    _busy = true;
    _offeredThisSession = true;
    try {
      await _update(
        (s) => s.copyWith(
          offers: s.offers + 1,
          lastOfferMs: _clock().millisecondsSinceEpoch,
          interstitialsSinceOffer: 0,
        ),
      );
      await Future<void>.delayed(settleDelay);
      await show();
    } catch (error) {
      // A popup that fails must not break the screen it appeared on.
      debugPrint('Remove Ads offer failed: $error');
    } finally {
      _busy = false;
    }
    return true;
  }

  static Future<bool> _nativeReview() async {
    try {
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return false;
      await review.requestReview();
      return true;
    } catch (error) {
      debugPrint('Native review unavailable: $error');
      return false;
    }
  }
}

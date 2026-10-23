import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

import '../core/analytics.dart';
import '../core/app_colors.dart';
import '../core/app_fonts.dart';
import '../core/constants.dart';
import '../l10n/l10n.dart';
import '../monetization/prompts/ad_consent.dart';
import '../monetization/prompts/prompt_coordinator.dart';

/// Central ad orchestrator: interstitial and rewarded ads on LevelPlay
/// mediation. AdMob and Unity Ads compete inside LevelPlay as networks, so
/// there is no waterfall to manage here. One ad object per format is reused:
/// load, show, load again. With no app key in [AppConstants] ads are off.
class AdManager
    implements LevelPlayInitListener, LevelPlayImpressionDataListener {
  /// LevelPlay may send the reward after the close callback; a close without
  /// a reward waits this long for it (and ends as soon as it arrives).
  static const _rewardGrace = Duration(seconds: 3);

  /// Gap before trying LevelPlay init again after it failed.
  static const _initRetryDelay = Duration(seconds: 30);

  /// Longest a rewarded tap waits for an ad that is still loading.
  static const _rewardedLoadWait = Duration(seconds: 8);

  static const _showTimeout = Duration(minutes: 2);

  LevelPlayRewardedAd? _rewarded;
  LevelPlayInterstitialAd? _interstitial;

  bool _initialized = false;
  bool _starting = false;
  bool _rewardedLoaded = false;
  bool _rewardedLoading = false;
  bool _interstitialLoaded = false;
  bool _interstitialLoading = false;
  Completer<bool>? _rewardedLoad;
  _RewardedShow? _rewardedShow;
  Completer<void>? _interstitialShow;
  DateTime? _lastLeaveAdAt;

  /// True once LevelPlay initialised; banners wait on it before loading.
  final ValueNotifier<bool> sdkReady = ValueNotifier<bool>(false);

  // ── Initialization ────────────────────────────────────────────────────────────

  /// Starts LevelPlay init and returns without waiting for it; ads preload
  /// from [onInitSuccess]. Calling again retries a failed init.
  void initialize() {
    if (_initialized || _starting || !AppConstants.adsConfigured) return;
    _starting = true;
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      // Where the law needs the player's choice (Europe), ads wait for it;
      // everywhere else this returns at once.
      final personalized = await AdConsent.instance.decision;
      if (personalized != null) await AdConsent.applyToLevelPlay(personalized);
      LevelPlay.addImpressionDataListener(this);
      if (kDebugMode) {
        await LevelPlay.setAdaptersDebug(true);
        await LevelPlay.setMetaData({
          'is_test_suite': ['enable'],
        });
      }
      await LevelPlay.init(
        initRequest: LevelPlayInitRequest.builder(
          AppConstants.levelPlayAppKey,
        ).build(),
        initListener: this,
      );
      // Debug only: logs the adapters and manifest entries LevelPlay found.
      if (kDebugMode) unawaited(LevelPlay.validateIntegration());
    } catch (e) {
      debugPrint('LevelPlay init threw: $e');
      _starting = false;
    }
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    _starting = false;
    _initialized = true;
    sdkReady.value = true;
    unawaited(_loadRewarded());
    unawaited(_loadInterstitial());
  }

  @override
  void onInitFailed(LevelPlayInitError error) {
    debugPrint(
      'LevelPlay init failed: ${error.errorCode} ${error.errorMessage}',
    );
    _starting = false;
    // LevelPlay recommends retrying a failed init later.
    Timer(_initRetryDelay, initialize);
  }

  /// Impression-level revenue from every format, banners included.
  @override
  void onImpressionSuccess(LevelPlayImpressionData impressionData) {
    Analytics.logAdImpression(
      network: impressionData.adNetwork,
      format: impressionData.adFormat,
      adUnitName: impressionData.mediationAdUnitName,
      revenueUsd: impressionData.revenue,
      placement: impressionData.placement,
    );
  }

  // ── Interstitial ──────────────────────────────────────────────────────────────

  Future<void> _loadInterstitial() async {
    if (!_initialized || _interstitialLoading || _interstitialLoaded) return;
    if (AppConstants.levelPlayInterstitialAdUnitId.isEmpty) return;
    _interstitialLoading = true;
    try {
      final ad = _interstitial ??= LevelPlayInterstitialAd(
        adUnitId: AppConstants.levelPlayInterstitialAdUnitId,
      )..setListener(_InterstitialListener(this));
      await ad.loadAd();
    } catch (e) {
      debugPrint('Interstitial load threw: $e');
      _onInterstitialLoadFailed();
    }
  }

  void _onInterstitialLoaded() {
    _interstitialLoading = false;
    _interstitialLoaded = true;
  }

  void _onInterstitialLoadFailed() {
    _interstitialLoading = false;
    _interstitialLoaded = false;
    Future.delayed(const Duration(seconds: 15), _loadInterstitial);
  }

  void _finishInterstitial() {
    _interstitialLoaded = false;
    final done = _interstitialShow;
    _interstitialShow = null;
    if (done != null && !done.isCompleted) done.complete();
    unawaited(_loadInterstitial());
  }

  /// Levels 5, 7, 9, and so on. Earlier levels never show a break ad.
  /// Returns whether an ad was shown (and has closed).
  Future<bool> onLevelComplete(int levelNumber) async {
    if (levelNumber < AppConstants.interstitialStartLevel) return false;
    final step = levelNumber - AppConstants.interstitialStartLevel;
    if (step % AppConstants.interstitialLevelInterval != 0) return false;
    return showInterstitial();
  }

  /// Shown when the player leaves a level, at most once per cooldown.
  /// Returns whether an ad was shown (and has closed).
  Future<bool> showLeaveInterstitial() async {
    final last = _lastLeaveAdAt;
    if (last != null &&
        DateTime.now().difference(last) <
            AppConstants.interstitialLeaveCooldown) {
      return false;
    }
    if (!_interstitialLoaded) return false;
    _lastLeaveAdAt = DateTime.now();
    return showInterstitial();
  }

  /// Returns true once an ad has shown and closed; false at once if none is
  /// ready, or if a review request or Remove Ads popup is on screen.
  Future<bool> showInterstitial() async {
    if (_interstitialShow != null || _rewardedShow != null) return false;
    if (PromptCoordinator.instance.isBusy) return false;
    final ad = _interstitial;
    // Loaded ads can expire or be capped; check just before showing.
    if (ad == null || !_interstitialLoaded || !await ad.isAdReady()) {
      _interstitialLoaded = false;
      unawaited(_loadInterstitial());
      return false;
    }
    final done = Completer<void>();
    _interstitialShow = done;
    var shown = true;
    try {
      await ad.showAd();
    } catch (e) {
      debugPrint('Interstitial show threw: $e');
      shown = false;
      _finishInterstitial();
    }
    await done.future.timeout(
      _showTimeout,
      onTimeout: () => _interstitialShow = null,
    );
    if (shown) await PromptCoordinator.instance.recordInterstitialShown();
    return shown;
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────────

  bool get isRewardedAvailable =>
      AppConstants.adsConfigured &&
      AppConstants.levelPlayRewardedAdUnitId.isNotEmpty;

  Future<void> _loadRewarded() async {
    if (!_initialized || _rewardedLoading || _rewardedLoaded) return;
    if (AppConstants.levelPlayRewardedAdUnitId.isEmpty) return;
    _rewardedLoading = true;
    _rewardedLoad ??= Completer<bool>();
    try {
      final ad = _rewarded ??= LevelPlayRewardedAd(
        adUnitId: AppConstants.levelPlayRewardedAdUnitId,
      )..setListener(_RewardedListener(this));
      await ad.loadAd();
    } catch (e) {
      debugPrint('Rewarded load threw: $e');
      _onRewardedLoadFailed();
    }
  }

  void _onRewardedLoaded() {
    _rewardedLoading = false;
    _rewardedLoaded = true;
    final waiter = _rewardedLoad;
    _rewardedLoad = null;
    if (waiter != null && !waiter.isCompleted) waiter.complete(true);
  }

  void _onRewardedLoadFailed() {
    _rewardedLoading = false;
    _rewardedLoaded = false;
    final waiter = _rewardedLoad;
    _rewardedLoad = null;
    if (waiter != null && !waiter.isCompleted) waiter.complete(false);
    Future.delayed(const Duration(seconds: 15), _loadRewarded);
  }

  Future<bool> _rewardedAdIsLive() async {
    final ad = _rewarded;
    return ad != null && await ad.isAdReady();
  }

  /// Waits for a rewarded ad that is still loading instead of failing the tap.
  Future<bool> _rewardedReady() async {
    if (!_initialized) return false;
    if (_rewardedLoaded && await _rewardedAdIsLive()) return true;
    _rewardedLoaded = false;
    if (!_rewardedLoading) unawaited(_loadRewarded());
    final waiter = _rewardedLoad;
    if (waiter == null) return false;
    final loaded = await waiter.future.timeout(
      _rewardedLoadWait,
      onTimeout: () => false,
    );
    return loaded && await _rewardedAdIsLive();
  }

  void _finishRewarded() {
    final show = _rewardedShow;
    _rewardedShow = null;
    show?.graceTimer?.cancel();
    if (show != null && !show.done.isCompleted) show.done.complete();
    _rewardedLoaded = false;
    unawaited(_loadRewarded());
  }

  void _onRewardedDisplayed() => _rewardedShow?.onOpened?.call();

  void _onRewardEarned() {
    final show = _rewardedShow;
    if (show == null) return;
    show.earned = true;
    show.grant();
    // Reward after close: end now instead of waiting out the grace.
    if (show.graceTimer?.isActive ?? false) _finishRewarded();
  }

  void _onRewardedClosed() {
    final show = _rewardedShow;
    if (show == null) return;
    if (show.earned) {
      _finishRewarded();
    } else {
      show.graceTimer = Timer(_rewardGrace, _finishRewarded);
    }
  }

  /// Displays a non-intrusive loading spinner dialog while fetching and preparing the rewarded ad.
  Future<void> showRewardedWithLoader(
    BuildContext context, {
    required void Function() onRewarded,
    void Function()? onDismissed,
  }) async {
    bool loaderOpen = true;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceLight, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.loadingAd,
                    style: AppFonts.style(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    void closeLoader() {
      if (loaderOpen && context.mounted) {
        loaderOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    await showRewarded(
      onAdOpened: closeLoader,
      onRewarded: () {
        closeLoader();
        onRewarded();
      },
      onDismissed: () {
        closeLoader();
        onDismissed?.call();
      },
    );
  }

  /// Shows a rewarded ad. The reward callback runs once, and only after
  /// LevelPlay reports the video completed. A missing or skipped ad grants
  /// nothing. [onDismissed] runs once the ad is over, rewarded or not.
  Future<void> showRewarded({
    required void Function() onRewarded,
    void Function()? onDismissed,
    void Function()? onAdOpened,
  }) async {
    var granted = false;
    void grant() {
      if (granted) return;
      granted = true;
      onRewarded();
    }

    if (_rewardedShow != null || _interstitialShow != null) {
      onDismissed?.call();
      return;
    }
    if (!await _rewardedReady()) {
      debugPrint('Rewarded ad unavailable. No reward granted.');
      onDismissed?.call();
      return;
    }

    final show = _RewardedShow(grant: grant, onOpened: onAdOpened);
    _rewardedShow = show;
    try {
      await _rewarded!.showAd();
      await show.done.future.timeout(
        _showTimeout,
        onTimeout: () {
          show.graceTimer?.cancel();
          if (identical(_rewardedShow, show)) _rewardedShow = null;
        },
      );
    } catch (e) {
      debugPrint('Rewarded show threw: $e');
      _finishRewarded();
    }
    unawaited(PromptCoordinator.instance.recordRewardedShown());
    onDismissed?.call();
  }

  void dispose() {
    unawaited(_rewarded?.dispose());
    unawaited(_interstitial?.dispose());
    _rewarded = null;
    _interstitial = null;
    sdkReady.dispose();
  }
}

/// One rewarded ad on screen: whether it paid out and who to tell.
class _RewardedShow {
  _RewardedShow({required this.grant, this.onOpened});

  final void Function() grant;
  final void Function()? onOpened;
  final Completer<void> done = Completer<void>();
  bool earned = false;
  Timer? graceTimer;
}

/// Routes rewarded callbacks to [AdManager] (both listener interfaces share
/// method names, so one class can't implement both).
class _RewardedListener implements LevelPlayRewardedAdListener {
  _RewardedListener(this._m);

  final AdManager _m;

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) => _m._onRewardedLoaded();

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    debugPrint(
        'Rewarded load failed: ${error.errorCode} ${error.errorMessage}');
    Analytics.logAdLoadFailed('rewarded', error.errorCode, error.errorMessage);
    _m._onRewardedLoadFailed();
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) => _m._onRewardedDisplayed();

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) =>
      _m._finishRewarded();

  @override
  void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) =>
      _m._onRewardEarned();

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) => _m._onRewardedClosed();

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}

class _InterstitialListener implements LevelPlayInterstitialAdListener {
  _InterstitialListener(this._m);

  final AdManager _m;

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) => _m._onInterstitialLoaded();

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    debugPrint(
      'Interstitial load failed: ${error.errorCode} ${error.errorMessage}',
    );
    Analytics.logAdLoadFailed(
      'interstitial',
      error.errorCode,
      error.errorMessage,
    );
    _m._onInterstitialLoadFailed();
  }

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) =>
      _m._finishInterstitial();

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) => _m._finishInterstitial();

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}

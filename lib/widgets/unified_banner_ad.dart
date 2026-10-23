import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

import '../ads/ad_manager.dart';
import '../core/analytics.dart';
import '../core/constants.dart';
import '../data/repositories/progress_repository.dart';

/// 320x50 LevelPlay banner (AdMob and Unity Ads compete inside LevelPlay).
/// Its host row is a fixed 50px, so a missing banner leaves that space empty
/// instead of shifting the screen. Hidden when Remove Ads is owned, ads are
/// off, LevelPlay isn't ready, or the load fails (then it tries again later).
class UnifiedBannerAd extends StatefulWidget {
  const UnifiedBannerAd({super.key});

  @override
  State<UnifiedBannerAd> createState() => _UnifiedBannerAdState();
}

class _UnifiedBannerAdState extends State<UnifiedBannerAd>
    implements LevelPlayBannerAdViewListener {
  /// Gap before re-creating a banner that never loaded, times the attempt.
  static const _retryStep = Duration(seconds: 30);
  static const _maxRetries = 5;

  GlobalKey<LevelPlayBannerAdViewState> _bannerKey = GlobalKey();
  ValueListenable<bool>? _sdkReady;
  bool _failed = false;

  /// True once the mounted banner has shown an ad. LevelPlay refreshes
  /// banners on its own, and a failed refresh must not remove an ad that
  /// is still on screen.
  bool _loaded = false;
  int _retries = 0;
  Timer? _retryTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = context.read<AdManager>().sdkReady;
    if (!identical(next, _sdkReady)) {
      _sdkReady?.removeListener(_onSdkReady);
      _sdkReady = next..addListener(_onSdkReady);
    }
  }

  void _onSdkReady() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _sdkReady?.removeListener(_onSdkReady);
    super.dispose();
  }

  /// Collapses a banner that never loaded, then mounts a fresh one later:
  /// "no fill" is usually temporary, and the native view only loads when
  /// re-created.
  void _collapseAndRetry() {
    if (!mounted || _loaded) return;
    setState(() => _failed = true);
    if (_retries >= _maxRetries) return;
    _retries++;
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryStep * _retries, () {
      if (!mounted) return;
      setState(() {
        _failed = false;
        _bannerKey = GlobalKey();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final adsRemoved = context.watch<ProgressRepository>().adsRemoved;
    if (adsRemoved ||
        _failed ||
        AppConstants.levelPlayBannerAdUnitId.isEmpty ||
        !(_sdkReady?.value ?? false)) {
      // Unmounting the view destroys the native banner; start fresh later.
      _loaded = false;
      return const SizedBox(height: 50);
    }
    final size = LevelPlayAdSize.BANNER;
    return Center(
      child: SizedBox(
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        child: LevelPlayBannerAdView(
          key: _bannerKey,
          adUnitId: AppConstants.levelPlayBannerAdUnitId,
          adSize: size,
          listener: this,
          onPlatformViewCreated: () => _bannerKey.currentState?.loadAd(),
        ),
      ),
    );
  }

  // ── LevelPlayBannerAdViewListener ─────────────────────────────────────────────

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    _loaded = true;
    _retries = 0;
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    debugPrint('Banner load failed: ${error.errorCode} ${error.errorMessage}');
    Analytics.logAdLoadFailed('banner', error.errorCode, error.errorMessage);
    _collapseAndRetry();
  }

  @override
  void onAdDisplayFailed(LevelPlayAdInfo adInfo, LevelPlayAdError error) =>
      _collapseAndRetry();

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdExpanded(LevelPlayAdInfo adInfo) {}

  @override
  void onAdCollapsed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdLeftApplication(LevelPlayAdInfo adInfo) {}
}

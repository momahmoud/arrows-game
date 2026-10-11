import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../core/economy_config.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/level_repository.dart';
import '../../data/models/level.dart';
import '../../widgets/unified_banner_ad.dart';
import '../../ui/game_ui.dart';
import '../../ui/widgets/home_nav.dart';
import '../../core/audio_manager.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import '../../l10n/l10n.dart';
import '../../ui/widgets/monetization_modal.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  bool _isNavigating = false; // prevents double-tap and shows instant feedback

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProgressRepository>().recordDailyPlay();
      _preWarmLevels();
      _checkPlayStoreUpdate();
    });
  }

  /// Pre-generate the current level and next 3 in background isolates so that
  /// tapping Play opens the game screen instantly with no UI-thread jank.
  void _preWarmLevels() {
    final progress = context.read<ProgressRepository>();
    final levelRepo = context.read<LevelRepository>();
    final currentLevel = progress.currentLevel;
    // Pre-warm current + next 3 levels in background isolates (non-blocking)
    for (int i = 0; i < 4; i++) {
      levelRepo.preGenerateAsync(currentLevel + i);
    }
  }

  Future<void> _checkPlayStoreUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint('Play Store update check failed: $e');
    }
  }

  String _getDifficultyLabel(int levelNum) {
    final type = AppConstants.levelTypeFor(levelNum);
    final String base;
    if (type == LevelType.god) {
      base = context.l10n.difficultySuperHard;
    } else if (type == LevelType.boss) {
      base = context.l10n.difficultyHard;
    } else {
      base = context.l10n.difficulty(Difficulty.forLevel(levelNum));
    }
    final special = context.l10n.levelType(type);
    if (special.isEmpty) return base;
    return '$base • $special';
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressRepository>();

    return Scaffold(
      body: Container(
        color: AppColors.isDark ? null : const Color(0xFFFFFFFF),
        decoration: AppColors.isDark
            ? BoxDecoration(gradient: AppColors.bgGradient)
            : null,
        child: Column(
          children: [
            Expanded(child: _HomeTab(progress: progress)),
            SafeArea(
              top: false,
              child: SizedBox(
                height: 50,
                child: Row(
                  children: [
                    const Expanded(
                      child: UnifiedBannerAd(
                        admobUnitId: AppConstants.admobBannerUnitId,
                        unityPlacementId: AppConstants.unityBannerAdId,
                      ),
                    ),
                    if (!progress.adsRemoved)
                      RemoveAdsEntry(
                        onTap: () =>
                            MonetizationPresenter.buy(
                              context,
                              EconomyConfig.removeAdsId,
                            ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _HomeTab({required ProgressRepository progress}) {
    final finished = progress.currentLevel > AppConstants.totalLevels;
    final level = finished ? AppConstants.totalLevels : progress.currentLevel;
    final type = AppConstants.levelTypeFor(level);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          HomeHeader(
            coins: progress.coins,
            onSettings: () {
              AudioManager.instance.playClick();
              Navigator.pushNamed(context, '/settings');
            },
            onCoins: () => _push('/shop'),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                GestureDetector(
                  onLongPress: kReleaseMode ? null : () => _toggleDemo(progress),
                  child: CurrentLevelSection(
                    level: level,
                    difficulty: _getDifficultyLabel(level),
                    levelType: type,
                    finished: finished,
                  ),
                ),
                if (!finished) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: PlayNowButton(
                      label: _isNavigating
                          ? context.l10n.loading
                          : context.l10n.playNow,
                      loading: _isNavigating,
                      onPressed: _isNavigating
                          ? null
                          : () => _play(progress.currentLevel),
                    ),
                  ),
                ],
                if (progress.isDemoMode)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: _DemoBadge(),
                  ),
                const SizedBox(height: 20),
                LevelProgressPreview(
                  currentLevel: progress.currentLevel.clamp(
                    1,
                    AppConstants.totalLevels,
                  ),
                  totalLevels: AppConstants.totalLevels,
                  isUnlocked: progress.isLevelUnlocked,
                  starsFor: progress.getStarsForLevel,
                  onSelect: (selected) {
                    AudioManager.instance.playClick();
                    progress.setCurrentLevel(selected);
                  },
                  onLocked: (locked) {
                    AudioManager.instance.playClick();
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.levelLocked(locked),
                          style: AppFonts.style(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: const Color(0xFFC0392B),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onViewAll: () {
                    AudioManager.instance.playClick();
                    Navigator.pushNamed(context, '/levels');
                  },
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FeatureShortcut(
                          icon: GameIconKind.calendar,
                          label: context.l10n.navDaily,
                          onTap: () => _push('/daily'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FeatureShortcut(
                          icon: GameIconKind.shop,
                          label: context.l10n.navShop,
                          onTap: () => _push('/shop'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FeatureShortcut(
                          icon: GameIconKind.medal,
                          label: context.l10n.navAwards,
                          onTap: () => _push('/achievements'),
                        ),
                      ),
                    ],
                  ),
                ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _push(String route) {
    AudioManager.instance.playClick();
    Navigator.pushNamed(context, route);
  }

  Future<void> _play(int level) async {
    AudioManager.instance.playClick();
    if (!mounted) return;
    setState(() => _isNavigating = true);
    await Navigator.pushNamed(
      context,
      '/game',
      arguments: {'level': level},
    );
    if (!mounted) return;
    setState(() => _isNavigating = false);
    await MonetizationPresenter.removeAds(context);
  }

  void _toggleDemo(ProgressRepository progress) {
    HapticFeedback.heavyImpact();
    progress.toggleDemoMode();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          progress.isDemoMode
              ? '🚀 DEMO MODE ACTIVATED: Unlimited Lives, Unlimited Time & All Levels Unlocked!'
              : 'DEMO MODE DEACTIVATED',
          style: AppFonts.style(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor:
            progress.isDemoMode ? const Color(0xFFE67E22) : Colors.grey[800],
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE67E22),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'DEMO MODE ACTIVE',
          style: AppFonts.style(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

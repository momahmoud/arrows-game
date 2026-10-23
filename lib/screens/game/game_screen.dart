import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart' hide Matrix4;
import 'package:provider/provider.dart';
import '../../widgets/unified_banner_ad.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_fonts.dart';
import 'package:confetti/confetti.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../../core/economy_config.dart';
import '../../data/models/arrow.dart';
import '../../data/models/level.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/level_repository.dart';
import '../../ads/ad_manager.dart';
import '../../game/arrow_puzzle_game.dart';
import '../../game/game_state.dart';
import '../../widgets/combo_banner.dart';
import '../../widgets/power_up_bar.dart';
import '../../ui/widgets/gameplay_hud.dart';
import '../../widgets/arrow_line.dart';
import '../../widgets/boss_intro_banner.dart';
import '../../core/reminders/reminders.dart';
import '../../monetization/monetization_policy.dart';
import '../../monetization/prompts/prompt_coordinator.dart';
import '../../monetization/remove_ads_offer.dart';
import '../../ui/widgets/level_result.dart';
import '../../ui/widgets/monetization_modal.dart';
import '../../widgets/tutorial_hand.dart';
import '../../core/board_style.dart';
import '../../data/meta_rules.dart';
import '../../core/audio_manager.dart';
import '../../l10n/l10n.dart';
import '../../ui/game_ui.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late LevelModel _level;
  late ArrowPuzzleGame _game;
  GameState? _gameState;
  late ConfettiController _confettiController;
  bool _showingGameOver = false;
  bool _continueAdUsed = false;
  bool _showingComplete = false;
  bool _showingDeadlock = false;
  bool _inspectingDeadlock = false;
  int _lives = AppConstants.maxLives;
  int? _lastStateSignature;
  Object? _loadKey;
  bool _shapePreviewMode = false;
  bool _isLoadingLevel = false; // true while level is being generated async

  // Timer fields
  Timer? _levelTimer;
  int _timeRemaining = 0;
  int _totalTime = 0;
  bool _isTimeoutState = false;
  bool _isGamePaused = false;
  bool _isAppBackgrounded = false;
  bool _dailyChallenge = false;
  bool _showBossIntro = false;
  Timer? _introTimer;

  late final TransformationController _transformationController;

  /// Kept so the board can be saved from dispose, where `context` is unsafe.
  ProgressRepository? _progressRepo;
  bool _resumedFromSave = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController =
        ConfettiController(duration: const Duration(milliseconds: 700));
    _transformationController = TransformationController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final previewLevel = args?['previewLevel'] as LevelModel?;
    final levelNum = args?['level'] as int? ?? 1;
    final loadKey = previewLevel ?? levelNum;
    if (_loadKey != loadKey) {
      _loadKey = loadKey;
      _shapePreviewMode = args?['shapePreview'] == true || previewLevel != null;
      _dailyChallenge = args?['daily'] == true && previewLevel == null;
      if (previewLevel != null) {
        _level = previewLevel;
        _initGame();
        setState(() => _isLoadingLevel = false);
      } else {
        _loadLevelAsync(levelNum);
      }
    }
  }

  Future<void> _loadLevelAsync(int levelNum) async {
    final levelRepo = context.read<LevelRepository>();

    // If level is already cached, load it instantly with no spinner.
    if (levelRepo.isCached(levelNum)) {
      _level = levelRepo.getLevel(levelNum);
      _initGame();
      // Pre-warm next levels off the UI thread
      levelRepo.preGenerateRangeAsync(levelNum + 1, 5);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showTutorialDialogIfNeeded(levelNum);
      });
      return;
    }

    // Level not cached — show loading overlay and generate in background isolate
    if (mounted) setState(() => _isLoadingLevel = true);

    try {
      final level = await levelRepo.getLevelAsync(levelNum);
      if (!mounted) return;
      _level = level;
      _initGame();
      setState(() => _isLoadingLevel = false);

      // Pre-warm next levels off the UI thread
      levelRepo.preGenerateRangeAsync(levelNum + 1, 5);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showTutorialDialogIfNeeded(levelNum);
      });
    } catch (_) {
      // Fallback: generate synchronously if async fails
      if (!mounted) return;
      _level = levelRepo.getLevel(levelNum);
      _initGame();
      if (mounted) setState(() => _isLoadingLevel = false);
    }
  }

  void _initGame() {
    _lives = AppConstants.maxLives;
    _lastStateSignature = null;
    _showingGameOver = false;
    _continueAdUsed = false;
    _showingDeadlock = false;
    _inspectingDeadlock = false;
    _transformationController.value = Matrix4.identity();
    _gameState?.removeListener(_onGameStateChanged);
    final progress = context.read<ProgressRepository>();
    final startingPowerUps = {
      for (final type in PowerUpType.values)
        type: AppConstants.powerUpsPerLevel + progress.bonusPowerUp(type),
    };
    _gameState = GameState(
      level: _level,
      onLevelComplete: _onLevelComplete,
      onGameOver: _onGameOver,
      onLifeLost: _onLifeLost,
      onDeadlock: _onDeadlock,
      onArrowExited: _onArrowExited,
      onBonusPowerUpUsed: progress.spendBonusPowerUp,
      arrowSkin: progress.arrowSkin,
      boardTheme: progress.boardTheme,
      startingPowerUps: startingPowerUps,
    );
    _gameState!.addListener(_onGameStateChanged);
    AudioManager.instance.setBoardFill(0);

    _progressRepo = progress;
    _resumedFromSave = false;
    if (_canPersistSession) {
      final session = progress.loadLevelSession(_level.levelNumber);
      if (session != null) {
        if (_gameState!.restoreSession(session)) {
          _lives = _gameState!.lives;
          _resumedFromSave = true;
          final total = _level.totalArrows;
          AudioManager.instance.setBoardFill(total == 0
              ? 0
              : (1 - _gameState!.arrowsRemaining / total).clamp(0.0, 1.0));
        } else {
          // Saved on a board that has since changed.
          progress.clearLevelSession();
        }
      }
    }

    _introTimer?.cancel();
    final introType = AppConstants.levelTypeFor(_level.levelNumber);
    _showBossIntro = introType.isSpecial && !_shapePreviewMode;
    if (_showBossIntro) {
      _introTimer = Timer(const Duration(milliseconds: 1700), () {
        if (mounted) setState(() => _showBossIntro = false);
      });
    }

    _game = ArrowPuzzleGame(
      level: _level,
      gameState: _gameState!,
      onLevelComplete: _onLevelComplete,
      onGameOver: _onGameOver,
      onLifeLost: _onLifeLost,
      comboPerfectLabel: context.l10n.comboPerfect,
    );

    _resetTimerForLevel();

    if (_resumedFromSave) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showPowerUpSnack(context.l10n.progressRestored);
      });
    }
  }

  /// A campaign board with no timer can be saved part-way and resumed.
  bool get _canPersistSession {
    final repo = _progressRepo;
    if (repo == null || _shapePreviewMode || _dailyChallenge) return false;
    if (repo.isDemoMode) return false;
    return _calculateLevelTimerDuration(
            _level.levelNumber, _level.totalArrows) ==
        0;
  }

  void _persistSession() {
    final gs = _gameState;
    if (gs == null || !_canPersistSession || !gs.hasSavableProgress) return;
    _progressRepo!.saveLevelSession(gs.snapshot());
  }

  void _onGameStateChanged() {
    if (!mounted) return;
    final gs = _gameState!;
    final total = _level.totalArrows;
    final left = gs.arrowsRemaining;
    final cleared = total == 0 ? 0.0 : (1 - left / total).clamp(0.0, 1.0);
    AudioManager.instance.setBoardFill(cleared);

    // Hint/ruler/eraser/power-up changes are handled by the PowerUpBar's own
    // ListenableBuilder; only rebuild the screen for values it renders.
    final signature = Object.hash(
      gs.lives,
      gs.combo,
      gs.movesUsed,
      gs.arrows.where((a) => a.state != ArrowState.sliding).length,
    );
    if (signature == _lastStateSignature) return;
    _lastStateSignature = signature;
    setState(() {
      _lives = gs.lives;
    });
    _persistSession();
  }

  void _boosterHaptic() {
    if (context.read<ProgressRepository>().vibrationEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  void _showPowerUpSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppFonts.style()),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get _adsEnabled => AppConstants.adsConfigured;

  Future<void> _offerPowerUpRefill(
      PowerUpType type, String emptyMessage) async {
    if (_shapePreviewMode) {
      _showPowerUpSnack(emptyMessage);
      return;
    }
    setState(() => _isGamePaused = true);
    final shown = await MonetizationPresenter.outOfBooster(
      context,
      type: type,
      onGranted: () {
        if (!mounted) return;
        _gameState?.addPowerUp(type, AppConstants.powerUpsPerRewardedAd);
        setState(() {});
      },
    );
    if (!shown && mounted) _showPowerUpSnack(emptyMessage);
    if (mounted) setState(() => _isGamePaused = false);
  }

  void _useHintPowerUp() {
    final gs = _gameState;
    if (gs == null) return;
    gs.setEraserArmed(false);
    if (gs.powerUpCount(PowerUpType.hint) <= 0) {
      _offerPowerUpRefill(PowerUpType.hint, context.l10n.noHintsLeft);
      return;
    }
    if (!gs.applyHint()) {
      _showPowerUpSnack(context.l10n.noHintAvailable);
      return;
    }
    gs.consumePowerUp(PowerUpType.hint);
    AudioManager.instance.playPowerUp('hint');
    _boosterHaptic();
    setState(() {});
  }

  void _useEraserPowerUp() {
    final gs = _gameState;
    if (gs == null) return;
    if (gs.isEraserArmed) {
      gs.setEraserArmed(false);
      return;
    }
    if (gs.powerUpCount(PowerUpType.eraser) <= 0) {
      _offerPowerUpRefill(PowerUpType.eraser, context.l10n.noErasersLeft);
      return;
    }
    gs.setEraserArmed(true);
    AudioManager.instance.playPowerUp('eraser');
    _boosterHaptic();
    _showPowerUpSnack(context.l10n.tapArrowToErase);
  }

  void _useWandPowerUp() {
    final gs = _gameState;
    if (gs == null) return;
    gs.setEraserArmed(false);
    if (gs.powerUpCount(PowerUpType.wand) <= 0) {
      _offerPowerUpRefill(PowerUpType.wand, context.l10n.noWandsLeft);
      return;
    }
    if (!gs.applyMagicWand()) {
      _showPowerUpSnack(context.l10n.noWandMove);
      return;
    }
    gs.consumePowerUp(PowerUpType.wand);
    AudioManager.instance.playPowerUp('wand');
    _boosterHaptic();
    setState(() {});
  }

  void _useRulerPowerUp() {
    final gs = _gameState;
    if (gs == null) return;
    gs.setEraserArmed(false);
    if (gs.powerUpCount(PowerUpType.ruler) <= 0) {
      _offerPowerUpRefill(PowerUpType.ruler, context.l10n.noRulersLeft);
      return;
    }
    gs.consumePowerUp(PowerUpType.ruler);
    AudioManager.instance.playPowerUp('ruler');
    _boosterHaptic();
    gs.applyRuler();
    setState(() {});
  }

  void _onArrowExited(int combo) {
    if (!mounted || !context.read<ProgressRepository>().vibrationEnabled)
      return;
    const milestones = {3, 6, 10, 15};
    if (milestones.contains(combo)) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _onLifeLost() {
    if (!mounted) return;
    setState(() => _lives = _gameState!.lives);
    if (context.read<ProgressRepository>().vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _onLevelComplete() async {
    if (!mounted || _showingComplete) return;
    _levelTimer?.cancel();
    _progressRepo?.clearLevelSession();
    setState(() => _showingComplete = true);
    if (context.read<ProgressRepository>().vibrationEnabled) {
      HapticFeedback.lightImpact();
    }

    final progress = context.read<ProgressRepository>();
    final gs = _gameState!;
    final alreadyCleared = progress.isLevelCompleted(_level.levelNumber);
    final previousStars = progress.getStarsForLevel(_level.levelNumber);
    final stars = ProgressRepository.calculateStars(
      livesLost: gs.livesLost,
      powerUpsUsed: gs.powerUpsUsed,
    );
    final score =
        AppConstants.baseScore + (_lives * AppConstants.bonusPerRemainingLife);
    ChestReward? chest;
    var coinsEarned = 0;

    if (!_shapePreviewMode) {
      final firstClear = !alreadyCleared;
      final levelType = AppConstants.levelTypeFor(_level.levelNumber);
      coinsEarned = await progress.recordLevelComplete(
        LevelResult(
          levelNumber: _level.levelNumber,
          stars: stars,
          score: score,
          movesUsed: gs.movesUsed,
          livesLost: gs.livesLost,
          completed: true,
          completedAt: DateTime.now(),
        ),
        levelType: levelType,
        perfect: stars == 3,
        daily: _dailyChallenge,
      );
      progress.unlockShape(_level.maskShape);
      if (firstClear && gs.hintsUsed == 0) {
        progress.noteHintFreeClear(_level.levelNumber);
      }
      if (firstClear && stars == 3) {
        progress.notePerfectClear(_level.levelNumber);
      }
      if (firstClear && levelType == LevelType.boss) {
        progress.noteBossClear(_level.levelNumber);
      }
      if (firstClear && levelType == LevelType.god) {
        progress.noteGodClear(_level.levelNumber);
      }
      chest = progress.claimChest(_level.levelNumber);
      context.read<MonetizationPolicy>().noteClear();
    }

    AudioManager.instance.playLevelComplete();
    final reviewClaim = _claimReviewSlot();
    // Leaves room for the board's settle before the result panel.
    Future.delayed(const Duration(milliseconds: 650), () async {
      if (!mounted) {
        PromptCoordinator.instance.dropPendingReview();
        return;
      }
      if (!GameMotion.reduce(context)) _confettiController.play();
      _showLevelCompleteDialog(
        stars,
        coinsEarned,
        chest,
        improved: alreadyCleared && stars > previousStars && !_shapePreviewMode,
      );
      // With the result up: reminders are offered on the very first win (a
      // good moment, and before any review or ad offer); after that, the
      // store review, when it is due.
      await reviewClaim;
      if (_firstWin) {
        unawaited(reminders.requestPermissionOnce());
      } else if (_reviewSlot) {
        unawaited(PromptCoordinator.instance.requestPendingReview());
      }
    });
  }

  /// True when the native review took this win's ad slot: it is asked on the
  /// result, and the break ad after this level is skipped so the two never
  /// meet.
  bool _reviewSlot = false;

  /// True on the player's very first win.
  bool _firstWin = false;

  Future<void> _claimReviewSlot() async {
    if (_shapePreviewMode) return;
    final prompts = PromptCoordinator.instance;
    await prompts.recordWin();
    _firstWin = prompts.state.wins == 1;
    _reviewSlot = await prompts.takeReviewSlot();
  }

  void _onGameOver() {
    if (!mounted || _showingGameOver) return;
    _progressRepo?.clearLevelSession();
    context.read<MonetizationPolicy>().noteFailure();
    setState(() => _showingGameOver = true);
    if (context.read<ProgressRepository>().vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _showGameOverDialog();
    });
  }

  void _onDeadlock() {
    if (!mounted || _showingDeadlock || _showingGameOver || _showingComplete)
      return;
    _levelTimer?.cancel();
    _progressRepo?.clearLevelSession();
    setState(() {
      _showingDeadlock = true;
      _inspectingDeadlock = false;
    });
    if (context.read<ProgressRepository>().vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _showDeadlockDialog();
    });
  }

  Future<void> _showDeadlockDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _bindDeviceBack(
        onBack: () {
          Navigator.pop(context);
          setState(() => _inspectingDeadlock = true);
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SingleChildScrollView(
            child: FailurePanel(
              title: context.l10n.deadlockTitle,
              message: context.l10n.deadlockBody,
              icon: GameIconKind.info,
              onRetry: () {
                Navigator.pop(context);
                _handleRestart();
              },
              onHome: _handleMenu,
              recovery: GameButton(
                label: context.l10n.inspectBoard,
                icon: GameIconKind.eye,
                variant: GameButtonVariant.secondary,
                compact: true,
                onPressed: () {
                  AudioManager.instance.playClick();
                  Navigator.pop(context);
                  setState(() => _inspectingDeadlock = true);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRestart() async {
    _progressRepo?.clearLevelSession();
    if (mounted) {
      setState(() {
        _showingGameOver = false;
        _continueAdUsed = false;
        _showingComplete = false;
        _showingDeadlock = false;
        _inspectingDeadlock = false;
        _transformationController.value = Matrix4.identity();
        _game.resetLevel();
        _lives = AppConstants.maxLives;
        _resetTimerForLevel();
      });
    }
  }

  /// True once the player has done something a restart or exit would undo.
  bool get _hasBoardProgress {
    final gs = _gameState;
    if (gs == null || _shapePreviewMode) return false;
    if (gs.isComplete || _showingComplete || _showingGameOver) return false;
    return gs.movesUsed > 0 || gs.powerUpsUsed > 0 || gs.livesLost > 0;
  }

  Future<void> _showSettingsDialog() async {
    setState(() => _isGamePaused = true);
    final restart = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _PauseDialog(
        onResume: () => Navigator.pop(dialogContext, false),
        onRestart: () => Navigator.pop(dialogContext, true),
      ),
    );
    if (!mounted) return;
    if (restart == true &&
        (!_hasBoardProgress || await _confirmRestart()) &&
        mounted) {
      _handleRestart();
    }
    if (mounted) setState(() => _isGamePaused = false);
  }

  Future<bool> _confirmRestart() {
    final l10n = context.l10n;
    return showGameConfirm(
      context,
      icon: GameIconKind.restart,
      title: l10n.restartConfirmTitle,
      message: l10n.restartConfirmBody,
      confirmLabel: l10n.restartLevel,
      confirmIcon: GameIconKind.restart,
      cancelLabel: l10n.keepPlaying,
    );
  }

  Future<bool> _confirmLeave() {
    final l10n = context.l10n;
    return showGameConfirm(
      context,
      icon: GameIconKind.home,
      title: l10n.leaveConfirmTitle,
      message: l10n.leaveConfirmBody,
      confirmLabel: l10n.leaveLevel,
      confirmIcon: GameIconKind.home,
      cancelLabel: l10n.keepPlaying,
    );
  }

  void _handleNextLevel() => _leaveLevel(afterRewarded: false);

  /// [closeResult] is false when the result dialog is already closed.
  Future<void> _leaveLevel({
    required bool afterRewarded,
    bool closeResult = true,
  }) async {
    if (_leavingLevel) return;
    if (closeResult) Navigator.pop(context);
    _leavingLevel = true;
    if (!afterRewarded) await _breakAd();
    if (!mounted) return;
    if (_shapePreviewMode) {
      Navigator.pop(context);
      return;
    }
    if (!_canAdvance) {
      Navigator.pushReplacementNamed(context, '/menu');
      return;
    }
    Navigator.pushReplacementNamed(
      context,
      '/game',
      arguments: {'level': _level.levelNumber + 1},
    );
  }

  /// A daily run and the final level have no "next" in the campaign.
  bool get _canAdvance =>
      !_dailyChallenge && _level.levelNumber < AppConstants.totalLevels;

  Future<void> _handleMenu() async {
    if (_leavingLevel) return;
    Navigator.pop(context);
    _leavingLevel = true;
    await _breakAd();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/menu');
  }

  /// Level-break ads only. Never on a tutorial, a daily run, or after ads
  /// have been removed.
  bool _canShowBreakAd() {
    if (_shapePreviewMode || _dailyChallenge) return false;
    if (context.read<ProgressRepository>().adsRemoved) return false;
    return AppConstants.levelTypeFor(_level.levelNumber) != LevelType.tutorial;
  }

  /// The ad break when leaving a won level: skipped when a review took the
  /// slot, otherwise an interstitial and, after it, when the rules allow, a
  /// Remove Ads offer on the screen the player is still looking at.
  Future<void> _breakAd() async {
    if (!_canShowBreakAd()) return;
    if (_reviewSlot) {
      _reviewSlot = false;
      return;
    }
    final shown = await context.read<AdManager>().onLevelComplete(
          _level.levelNumber,
        );
    if (shown && mounted) await offerRemoveAdsAfterInterstitial(context);
  }

  void _handleDoubleCoins() {
    final progress = context.read<ProgressRepository>();
    if (!progress.canClaimRewardedCoins) {
      _handleNextLevel();
      return;
    }
    final adManager = context.read<AdManager>();
    Navigator.pop(context);
    var rewarded = false;
    var left = false;
    // The provider may report the reward after the dismissal.
    void leave({required bool afterRewarded}) {
      if (left || !mounted) return;
      left = true;
      _leaveLevel(afterRewarded: afterRewarded, closeResult: false);
    }

    adManager.showRewardedWithLoader(
      context,
      onRewarded: () {
        if (rewarded) return;
        rewarded = true;
        progress.claimRewardedCoins();
        leave(afterRewarded: true);
      },
      onDismissed: () {
        if (!rewarded) leave(afterRewarded: false);
      },
    );
  }

  Future<void> _showLevelCompleteDialog(
    int stars,
    int score,
    ChestReward? chest, {
    required bool improved,
  }) async {
    const adsOn = AppConstants.adsConfigured;
    final god = AppConstants.levelTypeFor(_level.levelNumber) == LevelType.god;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _bindDeviceBack(
        onBack: _handleMenu,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Center(
                  child: SingleChildScrollView(
                    child: LevelResultPanel(
                      level: _level,
                      stars: stars,
                      coins: score,
                      improved: improved,
                      chest: chest,
                      onNext: _handleNextLevel,
                      onReplay: () {
                        Navigator.pop(context);
                        _handleRestart();
                      },
                      onHome: _handleMenu,
                      onWatchAd: _handleDoubleCoins,
                      canAdvance: _canAdvance || _shapePreviewMode,
                      showCoinAd: adsOn &&
                          context
                              .read<ProgressRepository>()
                              .canClaimRewardedCoins,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.04,
                numberOfParticles: god ? 8 : 5,
                maxBlastForce: 36,
                minBlastForce: 14,
                gravity: 0.28,
                shouldLoop: false,
                colors: [
                  AppColors.accent,
                  AppColors.primary,
                  AppColors.accentGreen,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showGameOverDialog() async {
    final levelType = AppConstants.levelTypeFor(_level.levelNumber);
    final hasTimer = (levelType == LevelType.god && _level.levelNumber > 100) ||
        (levelType == LevelType.boss && _level.levelNumber > 200);

    int continueTime = 0;
    if (hasTimer && _gameState != null) {
      final remainingArrows =
          _gameState!.arrows.where((a) => a.state != ArrowState.sliding).length;
      continueTime =
          _calculateContinueDuration(_level.levelNumber, remainingArrows);
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        const adsOn = AppConstants.adsConfigured;
        final progress = context.read<ProgressRepository>();
        final canRefill = progress.coins >= EconomyConfig.heartRefillCost;
        return _bindDeviceBack(
          onBack: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/menu');
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: SingleChildScrollView(
              child: FailurePanel(
                title: context.l10n.levelFailed,
                message: _isTimeoutState
                    ? context.l10n.outOfTime
                    : context.l10n.outOfLives,
                icon: _isTimeoutState
                    ? GameIconKind.hourglass
                    : GameIconKind.heartBroken,
                lives: _gameState?.lives ?? 0,
                maxLives: AppConstants.maxLives,
                onRetry: () {
                  Navigator.pop(context);
                  _handleRestart();
                },
                onHome: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/menu');
                },
                recovery: adsOn && !_continueAdUsed
                    ? ContinueAdButton(
                        label: context.l10n.watchVideo,
                        subtitle: _isTimeoutState
                            ? context.l10n.watchAdForTime(continueTime)
                            : context.l10n.watchAdForLifeContinue,
                        onPressed: () {
                          // Watch rewarded ad to restore 1 life or add extra time
                          final adManager = context.read<AdManager>();
                          Navigator.pop(context);
                          bool rewarded = false;
                          adManager.showRewardedWithLoader(
                            context,
                            onRewarded: () {
                              if (rewarded || _continueAdUsed) return;
                              rewarded = true;
                              _continueAdUsed = true;
                              if (!mounted) return;
                              setState(() {
                                _showingGameOver = false;
                                if (_isTimeoutState) {
                                  _timeRemaining =
                                      continueTime; // Add dynamic extra time
                                  _isTimeoutState = false;
                                  _gameState!.resumeFromTimeout();
                                  _startLevelTimer();
                                } else {
                                  _gameState!.restoreLife();
                                  _lives = _gameState!.lives;
                                }
                              });
                            },
                            onDismissed: () {
                              if (!rewarded && mounted) {
                                _showingGameOver = false;
                                _showGameOverDialog(); // Re-open game over dialog so player can try again or restart
                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.l10n.adNotCompletedRestart,
                                      style: AppFonts.style(
                                          fontWeight: FontWeight.w800),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      )
                    : null,
                extra: _isTimeoutState
                    ? null
                    : GameButton(
                        label: canRefill
                            ? context.l10n
                                .refillHearts(EconomyConfig.heartRefillCost)
                            : context.l10n.needCoins(
                                EconomyConfig.heartRefillCost,
                                progress.coins,
                              ),
                        icon: GameIconKind.heart,
                        variant: GameButtonVariant.secondary,
                        compact: true,
                        onPressed: canRefill
                            ? () {
                                if (!progress.payHeartRefill()) return;
                                AudioManager.instance.playClick();
                                Navigator.pop(context);
                                setState(() {
                                  _showingGameOver = false;
                                  _gameState!.refillLives();
                                  _lives = _gameState!.lives;
                                });
                              }
                            : null,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _persistSession();
    _transformationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _levelTimer?.cancel();
    _introTimer?.cancel();
    _gameState?.removeListener(_onGameStateChanged);
    _confettiController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _isAppBackgrounded = true;
      _persistSession();
    } else if (state == AppLifecycleState.resumed) {
      _isAppBackgrounded = false;
      // Auto-pause and show settings dialog if returned to an active timed level
      final levelType = AppConstants.levelTypeFor(_level.levelNumber);
      final hasTimer =
          (levelType == LevelType.god && _level.levelNumber > 100) ||
              (levelType == LevelType.boss && _level.levelNumber > 200);
      if (hasTimer &&
          !_showingComplete &&
          !_showingGameOver &&
          !_isLoadingLevel &&
          _isLevelReady &&
          !_isGamePaused) {
        _showSettingsDialog();
      }
    }
  }

  int _calculateLevelTimerDuration(int levelNum, int totalArrows) {
    final type = AppConstants.levelTypeFor(levelNum);
    if (type == LevelType.god && levelNum > 100) {
      final baseSeconds =
          (45.0 - (levelNum - 100) * (20.0 / 400.0)).clamp(25.0, 45.0);
      final secondsPerArrow =
          (2.5 - (levelNum - 100) * (1.0 / 400.0)).clamp(1.5, 2.5);
      return (baseSeconds + secondsPerArrow * totalArrows).round();
    } else if (type == LevelType.boss && levelNum > 200) {
      final baseSeconds =
          (40.0 - (levelNum - 200) * (20.0 / 300.0)).clamp(20.0, 40.0);
      final secondsPerArrow =
          (2.2 - (levelNum - 200) * (0.8 / 300.0)).clamp(1.4, 2.2);
      return (baseSeconds + secondsPerArrow * totalArrows).round();
    }
    return 0;
  }

  int _calculateContinueDuration(int levelNum, int remainingArrows) {
    final type = AppConstants.levelTypeFor(levelNum);
    if (type == LevelType.god) {
      final secondsPerArrow =
          (2.2 - (levelNum - 100) * (0.7 / 400.0)).clamp(1.5, 2.2);
      return (20.0 + secondsPerArrow * remainingArrows).round();
    } else if (type == LevelType.boss) {
      final secondsPerArrow =
          (2.0 - (levelNum - 200) * (0.6 / 300.0)).clamp(1.4, 2.0);
      return (15.0 + secondsPerArrow * remainingArrows).round();
    }
    return 45;
  }

  void _resetTimerForLevel() {
    _levelTimer?.cancel();
    _isTimeoutState = false;

    final progress = context.read<ProgressRepository>();
    if (progress.isDemoMode) {
      _totalTime = 0;
      _timeRemaining = 0;
      return;
    }

    final levelType = AppConstants.levelTypeFor(_level.levelNumber);
    final hasTimer = (levelType == LevelType.god && _level.levelNumber > 100) ||
        (levelType == LevelType.boss && _level.levelNumber > 200);

    if (hasTimer) {
      _totalTime = _calculateLevelTimerDuration(
          _level.levelNumber, _level.arrows.length);
      _timeRemaining = _totalTime;
      _startLevelTimer();
    } else {
      _totalTime = 0;
      _timeRemaining = 0;
    }
  }

  void _startLevelTimer() {
    _levelTimer?.cancel();
    _levelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Pause if game state is not active, completed, gameover, paused or backgrounded
      if (_showingComplete ||
          _showingGameOver ||
          _isLoadingLevel ||
          !_isLevelReady ||
          _isGamePaused ||
          _isAppBackgrounded) {
        return;
      }

      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
          if (_timeRemaining == 0) {
            timer.cancel();
            _onTimeOut();
          }
        }
      });
    });
  }

  bool _leavingLevel = false;
  bool _confirmingLeave = false;

  Future<void> _leaveGameplay() async {
    if (!mounted || _leavingLevel || _confirmingLeave) return;
    // A saved board is not lost by leaving, so only ask when it would be.
    if (_hasBoardProgress && !_canPersistSession) {
      _confirmingLeave = true;
      setState(() => _isGamePaused = true);
      final leave = await _confirmLeave();
      _confirmingLeave = false;
      if (!mounted) return;
      setState(() => _isGamePaused = false);
      if (!leave) return;
    }
    _leavingLevel = true;
    if (_canShowBreakAd() &&
        _level.levelNumber >= AppConstants.interstitialStartLevel) {
      await context.read<AdManager>().showLeaveInterstitial();
    }
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/menu');
    }
  }

  /// The device back button runs the same action as the on-screen control.
  Widget _bindDeviceBack({
    required Widget child,
    required VoidCallback onBack,
  }) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBack();
      },
      child: child,
    );
  }

  void _onTimeOut() {
    if (!mounted || _showingGameOver) return;
    setState(() {
      _isTimeoutState = true;
    });
    _gameState?.forceGameOver();
  }

  @override
  Widget build(BuildContext context) {
    // Show a premium loading screen while the level is being generated
    // in the background isolate — no freeze, no blank screen.
    if (_isLoadingLevel || !_isLevelReady) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final levelNum = args?['level'] as int? ?? 1;
      return _bindDeviceBack(
        onBack: _leaveGameplay,
        child: _LevelLoadingScreen(levelNumber: levelNum),
      );
    }

    final levelType = AppConstants.levelTypeFor(_level.levelNumber);
    final boardTheme = context.watch<ProgressRepository>().boardTheme;

    // Calculate level progress
    final totalArrows = _level.arrows.length;
    final activeArrows =
        _gameState?.arrows.where((a) => a.state != ArrowState.sliding).length ??
            totalArrows;
    final clearedArrows = totalArrows - activeArrows;
    final progressVal =
        totalArrows > 0 ? (clearedArrows / totalArrows).clamp(0.0, 1.0) : 0.0;

    return _bindDeviceBack(
      onBack: _leaveGameplay,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: !AppColors.isDark && boardTheme == BoardTheme.classic
                ? const Color(0xFFFFFFFF)
                : null,
            gradient: !AppColors.isDark && boardTheme == BoardTheme.classic
                ? null
                : boardTheme == BoardTheme.classic
                    ? AppColors.bgGradient
                    : BoardStyle.playfield(boardTheme),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    // ── Top Bar ─────────────────────────────────────────────────
                    GameplayHeader(
                      levelNumber: _level.levelNumber,
                      levelType: levelType,
                      lives: _lives,
                      progress: progressVal,
                      onHome: _leaveGameplay,
                      onSettings: _showSettingsDialog,
                    ),
                    if (_totalTime > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _TimerDisplay(
                          timeRemaining: _timeRemaining,
                          totalTime: _totalTime,
                          levelType: levelType,
                        ),
                      ),

                    // ── Game Canvas ──────────────────────────────────────────────
                    Expanded(
                      child: PuzzleStage(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Measure the real screen area BEFORE entering InteractiveViewer.
                            // InteractiveViewer gives unbounded constraints to its children,
                            // so LayoutBuilder must be OUTSIDE to get finite values.
                            // Use the full available rect. The game sizes cells from this
                            // area and keeps the grid inside it, so taps match the arrows.
                            final boardW = constraints.maxWidth;
                            final boardH = constraints.maxHeight;
                            final fadeH = boardH * 0.035;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Canvas — fills the Expanded bounds, clipped hard
                                Positioned.fill(
                                  child: ClipRect(
                                    child: InteractiveViewer(
                                      transformationController:
                                          _transformationController,
                                      // The board already fits at 1x; a zero
                                      // margin keeps it from being dragged
                                      // off screen while zoomed.
                                      minScale: 1.0,
                                      maxScale: 4.0,
                                      boundaryMargin: EdgeInsets.zero,
                                      clipBehavior: Clip.none,
                                      child: Center(
                                        child: SizedBox(
                                          width: boardW,
                                          height: boardH,
                                          child: GameWidget(game: _game),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Edge fades only matter while zoomed, when
                                // arrows can be clipped by the stage.
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: ValueListenableBuilder<Matrix4>(
                                      valueListenable:
                                          _transformationController,
                                      builder: (context, matrix, _) {
                                        if (matrix.getMaxScaleOnAxis() <=
                                            1.01) {
                                          return const SizedBox.shrink();
                                        }
                                        return Column(
                                          children: [
                                            _EdgeFade(
                                              height: fadeH,
                                              color: _stageEdgeColor(
                                                boardTheme,
                                                top: true,
                                              ),
                                              top: true,
                                            ),
                                            const Spacer(),
                                            _EdgeFade(
                                              height: fadeH,
                                              color: _stageEdgeColor(
                                                boardTheme,
                                                top: false,
                                              ),
                                              top: false,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: fadeH * 0.4,
                                  left: 0,
                                  right: 0,
                                  child: IgnorePointer(
                                    child: Center(
                                      child: ComboBanner(
                                          combo: _gameState?.combo ?? 0),
                                    ),
                                  ),
                                ),
                                if (_level.levelNumber <=
                                        AppConstants.tutorialLevels &&
                                    (_gameState?.movesUsed ?? 1) == 0 &&
                                    !_showBossIntro)
                                  const Positioned(
                                    bottom: 28,
                                    child: TutorialHand(),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    if (!_shapePreviewMode && _gameState != null)
                      ListenableBuilder(
                        listenable: _gameState!,
                        builder: (context, _) {
                          final gs = _gameState!;
                          final boardActive = !gs.isComplete &&
                              !gs.isGameOver &&
                              !_showingComplete &&
                              !_showingGameOver &&
                              !_isGamePaused;
                          return PowerUpBar(
                            hintCount: gs.powerUpCount(PowerUpType.hint),
                            eraserCount: gs.powerUpCount(PowerUpType.eraser),
                            wandCount: gs.powerUpCount(PowerUpType.wand),
                            rulerCount: gs.powerUpCount(PowerUpType.ruler),
                            eraserActive: gs.isEraserArmed,
                            enabled: boardActive,
                            canRefill: _adsEnabled,
                            onHint: _useHintPowerUp,
                            onEraser: _useEraserPowerUp,
                            onWand: _useWandPowerUp,
                            onRuler: _useRulerPowerUp,
                          );
                        },
                      ),

                    // ── Banner Ad (centered and sized to avoid layout warnings) ──
                    SizedBox(
                      height: 50,
                      child: Row(
                        children: [
                          const Expanded(child: UnifiedBannerAd()),
                          if (!context.watch<ProgressRepository>().adsRemoved)
                            RemoveAdsEntry(
                              onTap: () => MonetizationPresenter.buy(
                                context,
                                EconomyConfig.removeAdsId,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (_showBossIntro)
                Positioned.fill(
                  child: BossIntroBanner(
                    type: levelType,
                    onDismiss: () {
                      _introTimer?.cancel();
                      setState(() => _showBossIntro = false);
                    },
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: _inspectingDeadlock
            ? FloatingActionButton.extended(
                onPressed: () {
                  AudioManager.instance.playClick();
                  setState(() {
                    _inspectingDeadlock = false;
                  });
                  _showDeadlockDialog();
                },
                backgroundColor: AppColors.primary,
                icon: const GameIcon(kind: GameIconKind.grid, size: 28),
                label: Text(
                  context.l10n.deadlockOptions,
                  style: AppFonts.style(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  bool get _isLevelReady => _gameState != null;

  /// Approximates the stage background where the board meets it, so the
  /// zoom fades blend into the same color the player sees around the board.
  Color _stageEdgeColor(BoardTheme theme, {required bool top}) {
    if (!AppColors.isDark && theme == BoardTheme.classic) return Colors.white;
    final colors = theme == BoardTheme.classic
        ? AppColors.bgGradient.colors
        : BoardStyle.playfield(theme).colors;
    return Color.lerp(colors.first, colors.last, top ? 0.2 : 0.8)!;
  }

  void _showTutorialDialogIfNeeded(int levelNum) {
    if (levelNum == 1) {
      _showTutorialDialog(
        title: context.l10n.tutorialHowToPlayTitle,
        description: context.l10n.tutorialHowToPlayBody,
        icon: GameIconKind.play,
        animationWidget: _buildNormalArrowAnimation(),
        stepText: '1/3',
      );
    } else if (levelNum == 2) {
      _showTutorialDialog(
        title: context.l10n.tutorialPairedTitle,
        description: context.l10n.tutorialPairedBody,
        icon: GameIconKind.coin,
        animationWidget: _buildColorLockAnimation(),
        stepText: '2/3',
      );
    } else if (levelNum == 3) {
      _showTutorialDialog(
        title: context.l10n.tutorialDeflectorTitle,
        description: context.l10n.tutorialDeflectorBody,
        icon: GameIconKind.restart,
        animationWidget: _buildDeflectorAnimation(),
        stepText: '3/3',
      );
    }

    // Check for one-time 40x40 grid warning dialog
    final progressRepo = context.read<ProgressRepository>();
    if (_level.gridSize >= 40 && !progressRepo.hasSeen40x40Warning) {
      progressRepo.setHasSeen40x40Warning(true);
      _show40x40WarningDialog();
    }

    // If the arrows are very small, show a snackbar warning to zoom in/out (one-time only)
    if (_level.gridSize >= 25 && !progressRepo.hasSeenZoomHint) {
      progressRepo.setHasSeenZoomHint(true);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const GameIcon(kind: GameIconKind.info, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.zoomHint,
                    style: AppFonts.style(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      });
    }
  }

  void _show40x40WarningDialog() {
    setState(() => _isGamePaused = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameDialog(
        icon: GameIconKind.info,
        title: context.l10n.massiveGridTitle,
        message: context.l10n.massiveGridBody,
        actions: [
          GameButton(
            label: context.l10n.gotIt,
            onPressed: () {
              AudioManager.instance.playClick();
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isGamePaused = false);
      }
    });
  }

  void _showTutorialDialog({
    required String title,
    required String description,
    required GameIconKind icon,
    required Widget animationWidget,
    required String stepText,
  }) {
    setState(() => _isGamePaused = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => GameDialog(
        eyebrow: context.l10n.tutorialStep(stepText),
        icon: icon,
        iconSize: GameIconSizes.md,
        title: title,
        message: description,
        body: animationWidget,
        actions: [
          GameButton(
            label: context.l10n.startTutorial,
            icon: GameIconKind.play,
            onPressed: () {
              AudioManager.instance.playClick();
              Navigator.pop(dialogContext);
            },
          ),
        ],
      ),
    ).then((_) {
      if (mounted) {
        setState(() => _isGamePaused = false);
      }
    });
  }

  Widget _buildNormalArrowAnimation() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: const GameIcon(kind: GameIconKind.arrowMark, size: 28),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.03, 1.03),
                    duration: 800.ms,
                    curve: Curves.easeInOut)
                .slideX(begin: 0, end: 1.5, delay: 1000.ms, duration: 600.ms)
                .fadeOut(delay: 1000.ms, duration: 200.ms),
            Positioned(
              right: 80,
              bottom: 15,
              child: const GameIcon(kind: GameIconKind.hint, size: 28)
                  .animate(onPlay: (c) => c.repeat())
                  .hide()
                  .fadeIn(delay: 400.ms, duration: 200.ms)
                  .scale(
                      begin: const Offset(1.2, 1.2),
                      end: const Offset(0.9, 0.9),
                      delay: 400.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutBack)
                  .fadeOut(delay: 800.ms, duration: 200.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorLockAnimation() {
    // Color-pair tutorial: show two arrows in DIFFERENT colors so players
    // understand that "matching colors = paired". Arrow 1 exits upward
    // (coral/red), Arrow 2 exits rightward (cyan/teal) — both at the same time.
    final Color color1 = AppColors.getGroupColor(0); // group 0 pair color
    final Color color2 = AppColors.getGroupColor(1); // group 1 pair color
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Arrow 1 (color1, exits UP) ──────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color1.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color1, width: 2),
                      ),
                      child: const GameIcon(
                          kind: GameIconKind.arrowMark, size: 28),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1.05, 1.05),
                            duration: 700.ms,
                            curve: Curves.easeInOut)
                        .slideY(
                            begin: 0,
                            end: -1.4,
                            delay: 900.ms,
                            duration: 550.ms)
                        .fadeOut(delay: 1000.ms, duration: 200.ms),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color1.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(context.l10n.pairBadge,
                          style: TextStyle(
                              fontSize: 9,
                              color: color1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ),
                  ],
                ),

                const SizedBox(width: 36),

                // ── A small link indicator ───────────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GameIcon(kind: GameIconKind.levelLocked, size: 22),
                  ],
                ),

                const SizedBox(width: 36),

                // ── Arrow 2 (color2, exits RIGHT) ────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color2.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color2, width: 2),
                      ),
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: const GameIcon(
                            kind: GameIconKind.arrowMark, size: 28),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1.05, 1.05),
                            duration: 700.ms,
                            curve: Curves.easeInOut)
                        .slideX(
                            begin: 0, end: 1.4, delay: 900.ms, duration: 550.ms)
                        .fadeOut(delay: 1000.ms, duration: 200.ms),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color2.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(context.l10n.pairBadge,
                          style: TextStyle(
                              fontSize: 9,
                              color: color2,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ),
                  ],
                ),
              ],
            ),
            // Tap hint — appears briefly then fades
            Positioned(
              bottom: 10,
              child: const GameIcon(kind: GameIconKind.hint, size: 28)
                  .animate(onPlay: (c) => c.repeat())
                  .hide()
                  .fadeIn(delay: 300.ms, duration: 200.ms)
                  .scale(
                      begin: const Offset(1.2, 1.2),
                      end: const Offset(0.9, 0.9),
                      delay: 300.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutBack)
                  .fadeOut(delay: 750.ms, duration: 200.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeflectorAnimation() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight, width: 1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFAA00),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFAA00).withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: const GameIcon(kind: GameIconKind.arrowMark, size: 22),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                  delay: 600.ms,
                  duration: 200.ms,
                  curve: Curves.easeOutBack)
              .then(duration: 200.ms)
              .scale(
                  begin: const Offset(1.15, 1.15),
                  end: const Offset(1, 1),
                  duration: 200.ms),
          Positioned(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat()).custom(
                  duration: 1.2.seconds,
                  builder: (context, val, child) {
                    double dx = 0;
                    double dy = 0;
                    if (val < 0.5) {
                      dx = 60 * (1 - val * 2);
                      dy = 0;
                    } else {
                      dx = 0;
                      dy = -60 * ((val - 0.5) * 2);
                    }
                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: child,
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

// ── Timer Display ────────────────────────────────────────────────────────────

class _TimerDisplay extends StatelessWidget {
  final int timeRemaining;
  final int totalTime;
  final LevelType levelType;

  const _TimerDisplay({
    required this.timeRemaining,
    required this.totalTime,
    required this.levelType,
  });

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isLowTime = timeRemaining <= 15 || timeRemaining <= totalTime * 0.15;
    final progress = (timeRemaining / totalTime).clamp(0.0, 1.0);

    final color = isLowTime
        ? const Color(0xFFCC2200) // Vibrant red/orange warning
        : (levelType == LevelType.god
            ? AppColors.accent
            : AppColors.accentOrange);

    Widget content = Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowTime ? const Color(0xFFCC2200) : AppColors.surfaceLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isLowTime ? 0.3 : 0.1),
            blurRadius: isLowTime ? 8 : 4,
            spreadRadius: isLowTime ? 1 : 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GameIcon(kind: GameIconKind.hourglass, size: 22),
              const SizedBox(width: 6),
              Text(
                _formatTime(timeRemaining),
                style: AppFonts.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );

    if (isLowTime) {
      content = content
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
          )
          .scaleXY(
              begin: 0.96,
              end: 1.04,
              duration: 400.ms,
              curve: Curves.easeInOut);
    }

    return content;
  }
}

/// Pause menu. Resume is the main action; restart asks first when the board
/// has progress, which the caller decides.
class _PauseDialog extends StatelessWidget {
  const _PauseDialog({required this.onResume, required this.onRestart});

  final VoidCallback onResume;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressRepository>();
    final l10n = context.l10n;
    return GameDialog(
      icon: GameIconKind.pause,
      iconSize: GameIconSizes.md,
      title: l10n.pausedTitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DialogSettingsTile(
            icon: progress.soundEnabled
                ? GameIconKind.soundOn
                : GameIconKind.soundOff,
            label: l10n.soundEffects,
            value: progress.soundEnabled,
            onChanged: progress.setSoundEnabled,
          ),
          _DialogSettingsTile(
            icon: progress.musicEnabled
                ? GameIconKind.musicOn
                : GameIconKind.musicOff,
            label: l10n.backgroundMusic,
            value: progress.musicEnabled,
            onChanged: progress.setMusicEnabled,
          ),
          _DialogSettingsTile(
            icon: GameIconKind.haptic,
            label: l10n.vibration,
            value: progress.vibrationEnabled,
            onChanged: progress.setVibrationEnabled,
          ),
        ],
      ),
      actions: [
        GameButton(
          label: l10n.resumeGame,
          icon: GameIconKind.play,
          onPressed: () {
            AudioManager.instance.playClick();
            onResume();
          },
        ),
        GameButton(
          label: l10n.restartLevel,
          icon: GameIconKind.restart,
          variant: GameButtonVariant.secondary,
          compact: true,
          onPressed: () {
            AudioManager.instance.playClick();
            onRestart();
          },
        ),
      ],
    );
  }
}

class _DialogSettingsTile extends StatelessWidget {
  final GameIconKind icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DialogSettingsTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: SizedBox(
        height: GameSpacing.touch,
        child: Row(
          children: [
            GameIcon(kind: icon, size: GameIconSizes.sm),
            const SizedBox(width: GameSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: (val) {
                AudioManager.instance.playClick();
                onChanged(val);
              },
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgeFade extends StatelessWidget {
  const _EdgeFade({
    required this.height,
    required this.color,
    required this.top,
  });

  final double height;
  final Color color;
  final bool top;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: top ? Alignment.topCenter : Alignment.bottomCenter,
          end: top ? Alignment.bottomCenter : Alignment.topCenter,
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

// ── Themed level loading screens ─────────────────────────────────────────────

/// Typewriter widget — types out one character at a time, then pauses,
/// then cycles to the next message in the list.
class _TypewriterMessages extends StatefulWidget {
  final List<String> messages;
  final Color color;
  final double fontSize;

  const _TypewriterMessages({
    required this.messages,
    required this.color,
    this.fontSize = 14,
  });

  @override
  State<_TypewriterMessages> createState() => _TypewriterMessagesState();
}

class _TypewriterMessagesState extends State<_TypewriterMessages> {
  int _msgIndex = 0;
  int _charCount = 0;
  bool _deleting = false;
  static const _typeSpeed = Duration(milliseconds: 55);
  static const _deleteSpeed = Duration(milliseconds: 25);
  static const _pauseAfterType = Duration(milliseconds: 1800);
  static const _pauseAfterDelete = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() async {
    if (!mounted) return;
    final msg = widget.messages[_msgIndex];

    if (!_deleting) {
      if (_charCount < msg.length) {
        await Future.delayed(_typeSpeed);
        if (!mounted) return;
        setState(() => _charCount++);
        _tick();
      } else {
        // Fully typed — pause then start deleting
        await Future.delayed(_pauseAfterType);
        if (!mounted) return;
        setState(() => _deleting = true);
        _tick();
      }
    } else {
      if (_charCount > 0) {
        await Future.delayed(_deleteSpeed);
        if (!mounted) return;
        setState(() => _charCount--);
        _tick();
      } else {
        // Fully deleted — pause then move to next message
        await Future.delayed(_pauseAfterDelete);
        if (!mounted) return;
        setState(() {
          _deleting = false;
          _msgIndex = (_msgIndex + 1) % widget.messages.length;
        });
        _tick();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.messages[_msgIndex];
    final display = msg.substring(0, _charCount.clamp(0, msg.length));
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          display,
          style: AppFonts.style(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w700,
            color: widget.color,
            letterSpacing: 0.5,
          ),
        ),
        // Blinking cursor
        _BlinkingCursor(color: widget.color),
      ],
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  final Color color;
  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _ctrl.value > 0.5 ? 1.0 : 0.0,
        child: Container(
          margin: const EdgeInsets.only(left: 2),
          width: 2,
          height: 16,
          color: widget.color,
        ),
      ),
    );
  }
}

/// Bouncing colored dots.
class _BouncingDots extends StatefulWidget {
  final Color? color;
  const _BouncingDots({this.color});

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final phase = (_ctrl.value + i * 0.33) % 1.0;
            final t = (1 - (phase * 2 - 1).abs()).clamp(0.0, 1.0);
            return Transform.translate(
              offset: Offset(0, -8.0 * t),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: (widget.color ?? AppColors.primary)
                      .withValues(alpha: 0.5 + 0.5 * t),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ── Normal level loading screen ───────────────────────────────────────────────
class _LevelLoadingScreen extends StatefulWidget {
  final int levelNumber;
  const _LevelLoadingScreen({required this.levelNumber});

  @override
  State<_LevelLoadingScreen> createState() => _LevelLoadingScreenState();
}

class _LevelLoadingScreenState extends State<_LevelLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  LevelType get _levelType => AppConstants.levelTypeFor(widget.levelNumber);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = _levelType;
    if (type == LevelType.boss)
      return _BossLoadingScreen(levelNumber: widget.levelNumber);
    if (type == LevelType.god)
      return _GodLoadingScreen(levelNumber: widget.levelNumber);
    return _buildNormalScreen();
  }

  Widget _buildNormalScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Transform.scale(
                  scale: 0.88 + 0.12 * _pulse.value,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ArrowLine(
                          direction: ArrowDirection.left,
                          color: AppColors.arrowLeft,
                          size: 48,
                          strokeWidth: 5.5),
                      const SizedBox(width: 8),
                      ArrowLine(
                          direction: ArrowDirection.up,
                          color: AppColors.arrowUp,
                          size: 48,
                          strokeWidth: 5.5),
                      const SizedBox(width: 8),
                      ArrowLine(
                          direction: ArrowDirection.right,
                          color: AppColors.arrowRight,
                          size: 48,
                          strokeWidth: 5.5),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                context.l10n.levelNumber(widget.levelNumber),
                style: AppFonts.style(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 16),
              _TypewriterMessages(
                messages: context.l10n.normalLoadingMessages,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 32),
              _BouncingDots(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Boss level loading screen ─────────────────────────────────────────────────
class _BossLoadingScreen extends StatefulWidget {
  final int levelNumber;
  const _BossLoadingScreen({required this.levelNumber});
  @override
  State<_BossLoadingScreen> createState() => _BossLoadingScreenState();
}

class _BossLoadingScreenState extends State<_BossLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _flame;
  static const _bossRed = Color(0xFFCC2200);
  static const _bossGlow = Color(0xFFFF4422);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _flame = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0500), Color(0xFF2D0A00), Color(0xFF0D0D0D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Skull icon pulsing
              AnimatedBuilder(
                animation: _flame,
                builder: (_, __) => Transform.scale(
                  scale: 0.9 + 0.15 * _flame.value,
                  child: GameIcon(
                    kind: GameIconKind.crown,
                    size: 80 + 8 * _flame.value,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // BOSS badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: _bossRed.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _bossRed, width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GameIcon(kind: GameIconKind.crown, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.levelTypeBoss,
                      style: AppFonts.style(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _bossGlow,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const GameIcon(kind: GameIconKind.crown, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Level number — blood red
              AnimatedBuilder(
                animation: _flame,
                builder: (_, __) => Text(
                  context.l10n.levelNumber(widget.levelNumber),
                  style: AppFonts.style(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color.lerp(_bossRed, _bossGlow, _flame.value),
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                          color: _bossGlow.withValues(
                              alpha: 0.6 + 0.4 * _flame.value),
                          blurRadius: 20)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Typewriter evil messages
              _TypewriterMessages(
                messages: context.l10n.bossLoadingMessages,
                color: _bossGlow.withValues(alpha: 0.85),
                fontSize: 15,
              ),
              const SizedBox(height: 36),
              _BouncingDots(color: _bossRed),
            ],
          ),
        ),
      ),
    );
  }
}

// ── God level loading screen ──────────────────────────────────────────────────
class _GodLoadingScreen extends StatefulWidget {
  final int levelNumber;
  const _GodLoadingScreen({required this.levelNumber});
  @override
  State<_GodLoadingScreen> createState() => _GodLoadingScreenState();
}

class _GodLoadingScreenState extends State<_GodLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _glow;
  static const _godPurple = Color(0xFF7B2FBE);
  static const _godGlow = Color(0xFFD78EFF);
  static const _godGold = Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0020), Color(0xFF1A0040), Color(0xFF050510)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sparks / Star icon pulsing
              AnimatedBuilder(
                animation: _glow,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow
                    Container(
                      width: 100 + 12 * _glow.value,
                      height: 100 + 12 * _glow.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _godPurple.withValues(
                                alpha: 0.3 + 0.3 * _glow.value),
                            blurRadius: 40 + 20 * _glow.value,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    GameIcon(
                      kind: GameIconKind.streak,
                      size: 80 + 8 * _glow.value,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // GOD badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: _godPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _godGlow.withValues(alpha: 0.6), width: 1.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GameIcon(kind: GameIconKind.streak, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.godMode,
                      style: AppFonts.style(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: _godGold,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const GameIcon(kind: GameIconKind.streak, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Level number — cosmic purple
              AnimatedBuilder(
                animation: _glow,
                builder: (_, __) => Text(
                  context.l10n.levelNumber(widget.levelNumber),
                  style: AppFonts.style(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color.lerp(_godPurple, _godGlow, _glow.value),
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                          color: _godGlow.withValues(
                              alpha: 0.5 + 0.4 * _glow.value),
                          blurRadius: 24)
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Typewriter cosmic messages
              _TypewriterMessages(
                messages: context.l10n.godLoadingMessages,
                color: _godGlow.withValues(alpha: 0.85),
                fontSize: 15,
              ),
              const SizedBox(height: 36),
              _BouncingDots(color: _godPurple),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/audio_manager.dart';
import '../../core/constants.dart';
import '../../data/repositories/progress_repository.dart';
import '../../l10n/l10n.dart';
import '../../widgets/wavy_progress_bar.dart';
import '../format/coin_format.dart';
import '../icons/game_icon.dart';
import '../icons/game_icon_kind.dart';
import '../theme/game_tokens.dart';
import 'game_badges.dart';
import 'game_button.dart';
import 'heart_display.dart';

/// Home, level, coins, and settings, with progress and hearts underneath.
class GameplayHeader extends StatelessWidget {
  const GameplayHeader({
    super.key,
    required this.levelNumber,
    required this.levelType,
    required this.lives,
    required this.progress,
    required this.onHome,
    required this.onSettings,
  });

  final int levelNumber;
  final LevelType levelType;
  final int lives;
  final double progress;
  final VoidCallback onHome;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final coins = context.watch<ProgressRepository>().coins;
    final title = context.l10n.levelNumber(levelNumber);
    final accent =
        levelType == LevelType.god ? AppColors.streakFire : AppColors.primary;
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset =
            GameplayMetrics.horizontalPadding(constraints.maxWidth);
        return Padding(
          padding: EdgeInsets.fromLTRB(inset, 4, inset, 4),
          child: Column(
            children: [
              Row(
                children: [
                  _HudButton(
                    kind: GameIconKind.settings,
                    tooltip: context.l10n.settings,
                    onPressed: onSettings,
                  ),
                  const SizedBox(width: GameplayMetrics.headerControlGap),
                  Flexible(
                    flex: 3,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: CoinBalancePill(
                          amount: coins,
                          onAdd: () {
                            AudioManager.instance.playClick();
                            Navigator.pushNamed(context, '/shop');
                          },
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GameplayMetrics.headerControlGap,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (levelType.isSpecial)
                            _LevelBadge(levelType: levelType),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              title,
                              maxLines: 1,
                              style: GameTypography.level(GameColors.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _HudButton(
                    kind: GameIconKind.home,
                    tooltip: context.l10n.mainMenu,
                    onPressed: onHome,
                  ),
                ],
              ),
              const SizedBox(height: GameplayMetrics.progressSpacing),
              LevelProgress(progress: progress, color: accent),
              const SizedBox(height: GameplayMetrics.heartSpacing),
              HeartDisplay(
                lives: lives,
                maxLives: AppConstants.maxLives,
                iconSize: 22,
                spacing: 8,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.kind,
    required this.tooltip,
    required this.onPressed,
  });

  final GameIconKind kind;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(GameRadius.sm),
        border: Border.all(color: AppColors.surfaceLight),
        boxShadow: AppColors.isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: GameIconButton(
        kind: kind,
        tooltip: tooltip,
        onPressed: () {
          AudioManager.instance.playClick();
          onPressed();
        },
      ),
    );
  }
}

/// Balance plus a shop entry. The plus opens the shop and does not grant coins.
class CoinBalancePill extends StatelessWidget {
  const CoinBalancePill({
    super.key,
    required this.amount,
    required this.onAdd,
  });

  final int amount;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GameRadius.pill),
        border: Border.all(color: AppColors.surfaceLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppColors.isDark ? 0.22 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          GameplayMetrics.coinPillPadding,
          4,
          4,
          4,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoinAnchor(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GameIcon(kind: GameIconKind.coin, size: 22),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Text(
                      formatCoins(context, amount),
                      key: ValueKey(amount),
                      style: GameTypography.amount(GameColors.text),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: context.l10n.getCoins,
              child: Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onAdd,
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: Text(
                        '+',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.levelType});

  final LevelType levelType;

  @override
  Widget build(BuildContext context) {
    final god = levelType == LevelType.god;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (god) const GodBadge(size: 14) else const BossBadge(size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            context.l10n.levelType(levelType),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GameTypography.caption(
              god ? AppColors.streakFire : AppColors.primary,
            ).copyWith(fontSize: 11, height: 1),
          ),
        ),
      ],
    );
  }
}

/// Track and fill for arrows that have left the board.
class LevelProgress extends StatelessWidget {
  const LevelProgress({
    super.key,
    required this.progress,
    this.color,
  });

  final double progress;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget bar = WavyProgressBar(
          progress: progress,
          width: constraints.maxWidth,
          height: 8,
          color: color,
        );
        if (rtl) bar = Transform.flip(flipX: true, child: bar);
        return bar;
      },
    );
  }
}

/// The space left for the puzzle. No card, just a margin and a faint glow.
class PuzzleStage extends StatelessWidget {
  const PuzzleStage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(child: _BoardGlow()),
          child,
        ],
      ),
    );
  }
}

class _BoardGlow extends StatelessWidget {
  const _BoardGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: AppColors.isDark ? 0.08 : 0.04),
            AppColors.primary.withValues(alpha: 0),
          ],
          stops: const [0, 0.72],
        ),
      ),
    );
  }
}

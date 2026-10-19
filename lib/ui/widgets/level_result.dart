import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/app_colors.dart';
import '../../core/app_fonts.dart';
import '../../core/audio_manager.dart';
import '../../core/constants.dart';
import '../../core/economy_config.dart';
import '../../data/meta_rules.dart';
import '../../data/models/level.dart';
import '../../l10n/l10n.dart';
import '../../widgets/shape_reveal.dart';
import '../game_ui.dart';

/// Shared surface for the clear and fail moments.
class ResultCard extends StatelessWidget {
  const ResultCard({super.key, required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final reduce = GameMotion.reduce(context);
    Widget card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(GameRadius.xl),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GameRadius.xl),
            border: Border.all(
              color: (accent ?? AppColors.surfaceLight)
                  .withValues(alpha: accent == null ? 1 : 0.7),
            ),
            boxShadow: accent == null || reduce
                ? null
                : [
                    BoxShadow(
                      color: accent!.withValues(alpha: 0.22),
                      blurRadius: 16,
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
    if (reduce) return card;
    return card
        .animate()
        .fadeIn(duration: 180.ms, curve: Curves.easeOut)
        .scaleXY(begin: 0.97, end: 1, duration: 180.ms, curve: Curves.easeOut);
  }
}

class LevelResultPanel extends StatelessWidget {
  const LevelResultPanel({
    super.key,
    required this.level,
    required this.stars,
    required this.coins,
    required this.improved,
    required this.onNext,
    required this.onReplay,
    required this.onHome,
    this.chest,
    this.onWatchAd,
    this.showCoinAd = false,
    this.canAdvance = true,
  });

  /// False when Next would leave the current mode, such as a daily run.
  final bool canAdvance;
  final LevelModel level;
  final int stars;
  final int coins;
  final bool improved;
  final ChestReward? chest;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onHome;
  final VoidCallback? onWatchAd;
  final bool showCoinAd;

  bool get _last => level.levelNumber >= AppConstants.totalLevels;
  bool get _advances => canAdvance && !_last;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final levelType = AppConstants.levelTypeFor(level.levelNumber);
    final god = levelType == LevelType.god;
    final boss = levelType == LevelType.boss;
    return ResultCard(
      accent: god
          ? AppColors.streakFire
          : boss
              ? AppColors.primary
              : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResultHeader(
            title: god
                ? l10n.godComplete
                : boss
                    ? l10n.bossComplete
                    : l10n.levelComplete,
            icon: god
                ? GameIconKind.streak
                : boss
                    ? GameIconKind.crown
                    : null,
            perfect: stars >= 3,
            improved: improved,
          ),
          const SizedBox(height: 12),
          StarRating(earned: stars),
          if (coins > 0) ...[
            const SizedBox(height: 12),
            CoinReward(coins: coins),
          ],
          if (chest != null) ...[
            const SizedBox(height: 8),
            Text(
              l10n.chestReward(chest!.coins, l10n.powerUp(chest!.powerUp)),
              textAlign: TextAlign.center,
              style: GameTypography.caption(GameColors.rewardText),
            ),
          ],
          const SizedBox(height: 8),
          ShapeReveal(level: level, compact: true),
          const SizedBox(height: 12),
          if (_last)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l10n.finishedGameTitle,
                textAlign: TextAlign.center,
                style: GameTypography.section(GameColors.rewardText),
              ),
            ),
          if (_advances)
            NextLevelButton(onPressed: onNext)
          else
            GameButton(
              label: l10n.navHome,
              icon: GameIconKind.home,
              onPressed: () {
                AudioManager.instance.playClick();
                onHome();
              },
            ),
          if (showCoinAd && onWatchAd != null) ...[
            const SizedBox(height: 8),
            GameButton(
              label: l10n.watchVideo,
              subtitle: l10n.coinsAmount(EconomyConfig.rewardedAdCoins),
              icon: GameIconKind.watchAd,
              variant: GameButtonVariant.secondary,
              compact: true,
              onPressed: () {
                AudioManager.instance.playClick();
                onWatchAd!();
              },
            ),
          ],
          const SizedBox(height: 4),
          ResultActionRow(
            children: [
              ReplayButton(onPressed: onReplay),
              if (_advances) HomeResultButton(onPressed: onHome),
            ],
          ),
        ],
      ),
    );
  }
}

class ResultHeader extends StatelessWidget {
  const ResultHeader({
    super.key,
    required this.title,
    this.icon,
    this.perfect = false,
    this.improved = false,
  });

  final String title;
  final GameIconKind? icon;
  final bool perfect;
  final bool improved;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reduce = GameMotion.reduce(context);
    Widget? mark = icon == null
        ? null
        : GameIcon(kind: icon!, size: GameIconSizes.feature);
    if (mark != null && !reduce) {
      mark = mark.animate().scaleXY(
            begin: 0.8,
            end: 1,
            duration: 220.ms,
            curve: Curves.easeOutBack,
          );
    }
    return Column(
      children: [
        if (mark != null) ...[
          mark,
          const SizedBox(height: 6),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: GameTypography.title(GameColors.text),
        ),
        if (perfect) ...[
          const SizedBox(height: 4),
          Text(
            l10n.perfectClear,
            textAlign: TextAlign.center,
            style: GameTypography.section(AppColors.accentGreen),
          ),
        ],
        if (improved) ...[
          const SizedBox(height: 4),
          Text(
            l10n.newBest,
            textAlign: TextAlign.center,
            style: GameTypography.caption(GameColors.rewardText),
          ),
        ],
      ],
    );
  }
}

class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.earned});

  final int earned;

  @override
  Widget build(BuildContext context) {
    final reduce = GameMotion.reduce(context);
    return Semantics(
      label: context.l10n.starsEarned(earned.clamp(0, 3)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final filled = i < earned;
            Widget star = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: StarIcon(
                size: GameIconSizes.reward,
                state: filled ? StarState.earned : StarState.empty,
              ),
            );
            if (!filled || reduce) return star;
            return star.animate(delay: Duration(milliseconds: 80 * i)).scaleXY(
                  begin: 0.7,
                  end: 1,
                  duration: 200.ms,
                  curve: Curves.easeOutBack,
                );
          }),
        ),
      ),
    );
  }
}

class CoinReward extends StatefulWidget {
  const CoinReward({super.key, required this.coins});

  final int coins;

  @override
  State<CoinReward> createState() => _CoinRewardState();
}

class _CoinRewardState extends State<CoinReward> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || GameMotion.reduce(context)) return;
      final from = CoinFly.of(_key.currentContext ?? context);
      if (from != null) CoinFly.burst(context, from: from, count: 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduce = GameMotion.reduce(context);
    Widget row = Row(
      key: _key,
      mainAxisSize: MainAxisSize.min,
      children: [
        const GameIcon(kind: GameIconKind.coin, size: 28),
        const SizedBox(width: 6),
        Text(
          formatCoins(context, widget.coins, signed: true),
          style: GameTypography.display(GameColors.rewardText),
        ),
      ],
    );
    if (!reduce) {
      row = row.animate().scaleXY(
            begin: 0.86,
            end: 1,
            duration: 180.ms,
            curve: Curves.easeOutBack,
          );
    }
    return row;
  }
}

class NextLevelButton extends StatelessWidget {
  const NextLevelButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      label: context.l10n.nextLevel,
      icon: GameIconKind.continuePlay,
      onPressed: () {
        AudioManager.instance.playClick();
        onPressed();
      },
    );
  }
}

class ReplayButton extends StatelessWidget {
  const ReplayButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      label: context.l10n.retry,
      icon: GameIconKind.restart,
      variant: GameButtonVariant.secondary,
      compact: true,
      onPressed: () {
        AudioManager.instance.playClick();
        onPressed();
      },
    );
  }
}

class HomeResultButton extends StatelessWidget {
  const HomeResultButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      label: context.l10n.navHome,
      icon: GameIconKind.home,
      variant: GameButtonVariant.secondary,
      compact: true,
      onPressed: () {
        AudioManager.instance.playClick();
        onPressed();
      },
    );
  }
}

class ResultActionRow extends StatelessWidget {
  const ResultActionRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

class RetryButton extends StatelessWidget {
  const RetryButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      label: context.l10n.retry,
      icon: GameIconKind.restart,
      onPressed: () {
        AudioManager.instance.playClick();
        onPressed();
      },
    );
  }
}

class ContinueAdButton extends StatelessWidget {
  const ContinueAdButton({
    super.key,
    required this.label,
    this.subtitle,
    required this.onPressed,
  });

  final String label;
  final String? subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      label: label,
      subtitle: subtitle,
      icon: GameIconKind.watchAd,
      variant: GameButtonVariant.secondary,
      compact: true,
      onPressed: () {
        AudioManager.instance.playClick();
        onPressed();
      },
    );
  }
}

class FailurePanel extends StatelessWidget {
  const FailurePanel({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.onRetry,
    required this.onHome,
    this.lives,
    this.maxLives,
    this.recovery,
    this.extra,
  });

  final String title;
  final String message;
  final GameIconKind icon;
  final VoidCallback onRetry;
  final VoidCallback onHome;
  final int? lives;
  final int? maxLives;
  final Widget? recovery;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final reduce = GameMotion.reduce(context);
    Widget mark = GameIcon(kind: icon, size: GameIconSizes.lg);
    if (!reduce) {
      mark = mark.animate().shake(hz: 2.5, duration: 160.ms);
    }
    return ResultCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GameTypography.title(GameColors.text),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GameTypography.body(GameColors.textMuted),
          ),
          if (lives != null && maxLives != null) ...[
            const SizedBox(height: 12),
            _HeartLine(lives: lives!, maxLives: maxLives!),
          ],
          const SizedBox(height: 16),
          RetryButton(onPressed: onRetry),
          if (recovery != null) ...[
            const SizedBox(height: 8),
            recovery!,
          ],
          if (extra != null) ...[
            const SizedBox(height: 8),
            extra!,
          ],
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              AudioManager.instance.playClick();
              onHome();
            },
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: Text(
              context.l10n.navHome,
              style: AppFonts.style(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartLine extends StatelessWidget {
  const _HeartLine({required this.lives, required this.maxLives});

  final int lives;
  final int maxLives;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final format = NumberFormat.decimalPattern(locale);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < maxLives; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: HeartIcon(filled: i < lives, size: 26),
          ),
        const SizedBox(width: 8),
        Text(
          '${format.format(lives)} / ${format.format(maxLives)}',
          style: GameTypography.section(GameColors.text),
        ),
      ],
    );
  }
}

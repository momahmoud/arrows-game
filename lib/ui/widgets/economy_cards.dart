import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_colors.dart';
import '../../core/audio_manager.dart';
import '../../l10n/l10n.dart';
import '../format/coin_format.dart';
import '../icons/game_icon.dart';
import '../icons/game_icon_kind.dart';
import '../theme/game_tokens.dart';
import 'coin_fly.dart';
import 'game_button.dart';
import 'icon_kit.dart';

typedef GameHeader = GameScreenHeader;
typedef CoinBadge = CoinDisplay;

class GameScreenHeader extends StatelessWidget {
  const GameScreenHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
    this.showBack = true,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GameSpacing.xs,
        GameSpacing.xs,
        GameSpacing.md,
        GameSpacing.xxs,
      ),
      child: Row(
        children: [
          if (showBack) ...[
            GameIconButton(
              kind: GameIconKind.back,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () {
                AudioManager.instance.playClick();
                if (onBack != null) {
                  onBack!();
                } else {
                  Navigator.pop(context);
                }
              },
            ),
            const SizedBox(width: GameSpacing.xs),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GameTypography.title(GameColors.text),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class ShopItemCard extends StatelessWidget {
  const ShopItemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.action,
    required this.onTap,
    this.price,
    this.enabled = true,
    this.highlight = false,
    this.prominentDetail = false,
  });

  final GameIconKind icon;
  final String title;
  final String detail;
  final String action;
  final VoidCallback onTap;
  final int? price;
  final bool enabled;
  final bool highlight;
  final bool prominentDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: GameSpacing.xs),
      padding: const EdgeInsets.all(GameSpacing.sm),
      decoration: GameDecor.card(highlight: highlight),
      child: Row(
        children: [
          GameIcon(kind: icon, size: GameIconSizes.lg),
          const SizedBox(width: GameSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GameTypography.section(GameColors.text)),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: prominentDetail
                      ? GameTypography.section(GameColors.text)
                      : GameTypography.caption(GameColors.textMuted),
                ),
                if (price != null && price! > 0) ...[
                  const SizedBox(height: GameSpacing.xxs),
                  Row(
                    children: [
                      const GameIcon(kind: GameIconKind.coin, size: 22),
                      const SizedBox(width: 4),
                      Text(
                        formatCoins(context, price!),
                        style: GameTypography.caption(
                          enabled ? GameColors.coinInk : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: GameSpacing.xs),
          GameButton(
            label: action,
            expand: false,
            compact: true,
            variant: highlight
                ? GameButtonVariant.reward
                : GameButtonVariant.primary,
            onPressed: enabled ? onTap : null,
          ),
        ],
      ),
    );
  }
}

class WatchAdRewardCard extends StatelessWidget {
  const WatchAdRewardCard({
    super.key,
    required this.coins,
    required this.enabled,
    required this.onWatch,
  });

  final int coins;
  final bool enabled;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: _shopSurface(
        border: AppColors.accentGreen.withValues(alpha: 0.55),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const GameIcon(kind: GameIconKind.watchAd, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.watchVideo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameTypography.section(GameColors.text),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const GameIcon(kind: GameIconKind.coin, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          formatCoins(context, coins, signed: true),
                          style: GameTypography.amount(GameColors.coinInk),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GameButton(
            label: l10n.watchVideo,
            compact: true,
            variant: GameButtonVariant.reward,
            icon: GameIconKind.watchAd,
            onPressed: enabled ? onWatch : null,
          ),
        ],
      ),
    );
  }
}

class RemoveAdsCard extends StatelessWidget {
  const RemoveAdsCard({
    super.key,
    required this.active,
    this.price,
    this.onPurchase,
  });

  final bool active;
  final String? price;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: _shopSurface(
        border: AppColors.primary.withValues(alpha: 0.55),
        fill: Color.alphaBlend(
          AppColors.primary.withValues(alpha: 0.08),
          AppColors.surface,
        ),
      ),
      child: Column(
        children: [
          const GameIcon(kind: GameIconKind.removeAds, size: 36),
          const SizedBox(height: 8),
          Text(
            l10n.removeAds,
            textAlign: TextAlign.center,
            style: GameTypography.section(GameColors.text),
          ),
          const SizedBox(height: 4),
          Text(
            active ? l10n.removeAdsActive : l10n.removeAdsBody,
            textAlign: TextAlign.center,
            style: GameTypography.caption(GameColors.textMuted),
          ),
          if (!active) ...[
            const SizedBox(height: 2),
            Text(
              l10n.rewardedAdsRemain,
              textAlign: TextAlign.center,
              style: GameTypography.caption(GameColors.textMuted),
            ),
            if (price != null) ...[
              const SizedBox(height: 8),
              Text(
                price!,
                textAlign: TextAlign.center,
                style: GameTypography.amount(GameColors.text),
              ),
            ],
            const SizedBox(height: 10),
            GameButton(
              label: l10n.buy,
              compact: true,
              onPressed: onPurchase,
            ),
          ],
        ],
      ),
    );
  }
}

/// Icon-only Remove Ads control that sits beside the banner.
class RemoveAdsEntry extends StatelessWidget {
  const RemoveAdsEntry({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.removeAds,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AudioManager.instance.playClick();
            onTap();
          },
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: GameIcon(kind: GameIconKind.removeAds, size: 32),
            ),
          ),
        ),
      ),
    );
  }
}

enum DailyRewardState { locked, available, claimed, current, missed }

/// A store coin pack. The price stays with the store, so this card does not invent one.
class CoinPackCard extends StatelessWidget {
  const CoinPackCard({
    super.key,
    required this.coins,
    required this.action,
    required this.onBuy,
    this.price,
  });

  final int coins;
  final String action;
  final VoidCallback onBuy;
  final String? price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: _shopSurface(),
      child: Column(
        children: [
          const GameIcon(kind: GameIconKind.coinStack, size: 32),
          const SizedBox(height: 6),
          Text(
            formatCoins(context, coins),
            textAlign: TextAlign.center,
            style: GameTypography.amount(GameColors.text),
          ),
          if (price != null) ...[
            const SizedBox(height: 4),
            Text(
              price!,
              textAlign: TextAlign.center,
              style: GameTypography.caption(GameColors.textMuted),
            ),
          ],
          const SizedBox(height: 8),
          GameButton(
            label: action,
            compact: true,
            onPressed: onBuy,
          ),
        ],
      ),
    );
  }
}

/// One booster: icon, name, owned count, coin price, and a compact buy action.
class ShopBoosterTile extends StatelessWidget {
  const ShopBoosterTile({
    super.key,
    required this.icon,
    required this.title,
    required this.owned,
    required this.price,
    required this.action,
    required this.onBuy,
  });

  final GameIconKind icon;
  final String title;
  final String owned;
  final int price;
  final String action;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      decoration: _shopSurface(),
      child: Column(
        children: [
          GameIcon(kind: icon, size: 32),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GameTypography.caption(GameColors.text),
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              owned,
              key: ValueKey(owned),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GameTypography.caption(GameColors.textMuted),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GameIcon(kind: GameIconKind.coin, size: 16),
              const SizedBox(width: 4),
              Text(
                formatCoins(context, price),
                style: GameTypography.caption(GameColors.coinInk),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GameButton(
            label: action,
            compact: true,
            onPressed: onBuy,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _shopSurface({Color? border, Color? fill}) {
  return BoxDecoration(
    color: fill ?? AppColors.surface,
    borderRadius: BorderRadius.circular(GameRadius.md),
    border: Border.all(color: border ?? AppColors.surfaceLight),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: AppColors.isDark ? 0.22 : 0.05),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class DailyRewardCard extends StatelessWidget {
  const DailyRewardCard({
    super.key,
    required this.dayLabel,
    required this.amountLabel,
    required this.state,
    required this.icon,
    this.onTap,
    this.semanticLabel,
    this.featured = false,
    this.claimLabel,
  });

  final String dayLabel;
  final String amountLabel;
  final DailyRewardState state;
  final GameIconKind icon;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool featured;
  final String? claimLabel;

  @override
  Widget build(BuildContext context) {
    final current = state == DailyRewardState.current ||
        state == DailyRewardState.available;
    final claimed = state == DailyRewardState.claimed;
    final missed = state == DailyRewardState.missed;
    final locked = state == DailyRewardState.locked;
    final tint = claimed
        ? AppColors.accentGreen.withValues(alpha: 0.14)
        : current
            ? GameColors.coin.withValues(alpha: 0.22)
            : featured
                ? GameColors.coin.withValues(alpha: 0.1)
                : null;

    Widget card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GameRadius.md),
        child: Ink(
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              tint ?? Colors.transparent,
              GameColors.surface,
            ),
            borderRadius: BorderRadius.circular(GameRadius.md),
            border: Border.all(
              color: current || featured
                  ? GameColors.coinDeep
                  : claimed
                      ? GameColors.leaf
                      : missed
                          ? GameColors.missed
                          : GameColors.line,
              width: current || featured ? 2.5 : 1.5,
            ),
            boxShadow: current
                ? [
                    BoxShadow(
                      color: GameColors.coin.withValues(alpha: 0.28),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: GameSpacing.xs, horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    dayLabel,
                    maxLines: 1,
                    style: GameTypography.caption(GameColors.textMuted),
                  ),
                ),
                const SizedBox(height: 4),
                Opacity(
                  opacity: locked || missed ? 0.45 : 1,
                  child: GameIcon(kind: icon, size: featured ? 36 : 28),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    amountLabel,
                    style: GameTypography.caption(
                      claimed ? GameColors.leafDeep : GameColors.text,
                    ),
                  ),
                ),
                if (current && claimLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    claimLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameTypography.caption(GameColors.coinInk),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (current && !GameMotion.reduce(context)) {
      card = card
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(
            begin: 1,
            end: 1.03,
            duration: GameMotion.badge,
            curve: Curves.easeInOut,
          );
    }

    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 96),
        child: card,
      ),
    );
  }
}

class DailyRewardCalendar extends StatelessWidget {
  const DailyRewardCalendar({
    super.key,
    required this.amounts,
    required this.claimedThrough,
    required this.claimedToday,
    this.pendingDay,
    this.onClaim,
    this.strip = false,
  });

  /// Seven rewards, in day order. Values come from the economy config.
  final List<int> amounts;

  /// Last claimed day in the cycle, 0 if none.
  final int claimedThrough;
  final bool claimedToday;
  final int? pendingDay;
  final VoidCallback? onClaim;

  /// One horizontal row. Used on the home screen so the board stays in view.
  final bool strip;

  DailyRewardState _state(int day) {
    if (claimedToday) {
      return day <= claimedThrough
          ? DailyRewardState.claimed
          : DailyRewardState.locked;
    }
    final pending = pendingDay ?? 1;
    if (day < pending) return DailyRewardState.claimed;
    if (day == pending) return DailyRewardState.current;
    return DailyRewardState.locked;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = amounts.length;
    if (strip) {
      return SizedBox(
        height: 128,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: GameSpacing.md),
          itemCount: days,
          separatorBuilder: (_, __) => const SizedBox(width: GameSpacing.xs),
          itemBuilder: (context, index) => SizedBox(
            width: 76,
            child: _cell(context, l10n, index + 1),
          ),
        ),
      );
    }
    return Column(
      children: [
        _row(context, l10n, 1, math.min(4, days)),
        const SizedBox(height: GameSpacing.xs),
        if (days > 4) _row(context, l10n, 5, days),
      ],
    );
  }

  Widget _row(BuildContext context, AppLocalizations l10n, int start, int end) {
    return Row(
      children: [
        for (var day = start; day <= end; day++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _cell(context, l10n, day),
            ),
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, AppLocalizations l10n, int day) {
    final state = _state(day);
    final amount = amounts[day - 1];
    final jackpot = day == amounts.length;
    final icon = state == DailyRewardState.claimed
        ? GameIconKind.check
        : jackpot
            ? GameIconKind.chest
            : state == DailyRewardState.locked
                ? GameIconKind.levelLocked
                : GameIconKind.coin;
    return DailyRewardCard(
      dayLabel: jackpot ? l10n.jackpot : l10n.dayLabel(day),
      amountLabel: formatCoins(context, amount, signed: true),
      state: state,
      icon: icon,
      featured: jackpot,
      claimLabel: state == DailyRewardState.current ? l10n.claim : null,
      semanticLabel:
          '${l10n.dayLabel(day)}, ${l10n.coinsAmount(amount)}, ${_stateLabel(l10n, state)}',
      onTap: state == DailyRewardState.current && onClaim != null
          ? () {
              final from = CoinFly.of(context);
              onClaim!();
              if (from != null) CoinFly.burst(context, from: from);
            }
          : null,
    );
  }

  String _stateLabel(AppLocalizations l10n, DailyRewardState state) {
    switch (state) {
      case DailyRewardState.claimed:
        return l10n.rewardClaimed;
      case DailyRewardState.locked:
        return l10n.rewardLocked;
      case DailyRewardState.missed:
        return l10n.rewardMissed;
      case DailyRewardState.current:
      case DailyRewardState.available:
        return l10n.claim;
    }
  }
}

class LevelCompleteReward extends StatelessWidget {
  const LevelCompleteReward({
    super.key,
    required this.stars,
    required this.coins,
  });

  final int stars;
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final filled = i < stars;
            final star = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: StarIcon(
                size: GameIconSizes.reward,
                state: filled ? StarState.earned : StarState.empty,
              ),
            );
            if (!filled || GameMotion.reduce(context)) return star;
            return star
                .animate(
                    delay: GameMotion.starStep * i +
                        const Duration(milliseconds: 160))
                .scaleXY(
                    begin: 0.7,
                    end: 1,
                    curve: Curves.easeOutBack,
                    duration: 420.ms);
          }),
        ),
        if (coins > 0) ...[
          const SizedBox(height: GameSpacing.md),
          Text(
            context.l10n.coinsEarned,
            style: GameTypography.caption(GameColors.textMuted),
          ),
          const SizedBox(height: GameSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: GameSpacing.md, vertical: GameSpacing.xs),
            decoration: BoxDecoration(
              color: GameColors.coin.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(GameRadius.md),
              border: Border.all(
                  color: GameColors.coinDeep.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const GameIcon(kind: GameIconKind.coinBurst, size: 32)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.96, end: 1.04, duration: 700.ms),
                const SizedBox(width: GameSpacing.xs),
                Text(
                  formatCoins(context, coins, signed: true),
                  style: GameTypography.display(GameColors.coinInk),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

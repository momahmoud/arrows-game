import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_colors.dart';
import '../../core/app_fonts.dart';
import '../icons/game_assets.dart';
import '../icons/game_icon.dart';
import '../icons/game_icon_kind.dart';
import '../theme/game_tokens.dart';

enum IconWell { small, feature, reward }

/// Shared wells. Navigation marks and coins often sit without one.
class IconContainer extends StatelessWidget {
  const IconContainer({
    super.key,
    required this.child,
    this.well = IconWell.small,
    this.selected = false,
  });

  final Widget child;
  final IconWell well;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final feature = well == IconWell.feature;
    final reward = well == IconWell.reward;
    final size = reward
        ? 64.0
        : feature
            ? 52.0
            : 40.0;
    return AnimatedContainer(
      duration: GameMotion.tap,
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.16)
            : feature
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.elevated,
        borderRadius: BorderRadius.circular(feature ? 14 : 12),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.surfaceLight,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: reward
            ? null
            : [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: AppColors.isDark ? 0.18 : 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

class QuantityBadge extends StatelessWidget {
  const QuantityBadge({
    super.key,
    required this.label,
    this.filled = true,
  });

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? AppColors.accentGreen : AppColors.textMuted,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 1.25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: AppFonts.style(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = GameIconSizes.small});

  final double size;

  @override
  Widget build(BuildContext context) {
    return GameIcon(kind: GameAssets.coin, size: size);
  }
}

class HeartIcon extends StatelessWidget {
  const HeartIcon({
    super.key,
    this.size = GameIconSizes.nav,
    this.filled = true,
    this.broken = false,
  });

  final double size;
  final bool filled;
  final bool broken;

  @override
  Widget build(BuildContext context) {
    return GameIcon(
      kind: broken
          ? GameIconKind.heartBroken
          : filled
              ? GameAssets.heart
              : GameAssets.heartEmpty,
      size: size,
    );
  }
}

enum StarState { empty, dim, earned, animated }

class StarIcon extends StatelessWidget {
  const StarIcon({
    super.key,
    this.size = GameIconSizes.reward,
    this.state = StarState.earned,
  });

  final double size;
  final StarState state;

  @override
  Widget build(BuildContext context) {
    final earned = state == StarState.earned || state == StarState.animated;
    Widget icon = GameIcon(
      kind: earned || state == StarState.dim
          ? GameAssets.star
          : GameAssets.starEmpty,
      size: size,
    );
    if (state == StarState.dim) {
      icon = Opacity(opacity: 0.45, child: icon);
    }
    if (state == StarState.animated && !GameMotion.reduce(context)) {
      icon = icon.animate().scaleXY(
            begin: 0.7,
            end: 1,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
          );
    }
    return icon;
  }
}

class BoosterIcon extends StatelessWidget {
  const BoosterIcon({
    super.key,
    required this.kind,
    this.size = 52,
    this.enabled = true,
    this.empty = false,
  });

  final GameIconKind kind;
  final double size;
  final bool enabled;
  final bool empty;

  @override
  Widget build(BuildContext context) {
    Widget icon = GameIcon(kind: kind, size: size);
    if (!enabled || empty) {
      icon = Opacity(opacity: enabled ? 0.55 : 0.38, child: icon);
    }
    return icon;
  }
}

class FeatureIcon extends StatelessWidget {
  const FeatureIcon({
    super.key,
    required this.kind,
    this.selected = false,
  });

  final GameIconKind kind;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return IconContainer(
      well: IconWell.feature,
      selected: selected,
      child: GameIcon(kind: kind, size: GameIconSizes.feature),
    );
  }
}

/// Sits on the surface. No extra well.
class NavigationIcon extends StatelessWidget {
  const NavigationIcon({super.key, required this.kind});

  final GameIconKind kind;

  @override
  Widget build(BuildContext context) {
    return GameIcon(kind: kind, size: GameIconSizes.nav);
  }
}

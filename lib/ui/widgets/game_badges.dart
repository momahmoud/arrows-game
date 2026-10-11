import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_colors.dart';
import '../icons/game_assets.dart';
import '../icons/game_icon.dart';
import '../theme/game_tokens.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.child,
    this.highlight = false,
    this.tint,
    this.padding = const EdgeInsets.all(GameSpacing.sm),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final bool highlight;
  final Color? tint;
  final EdgeInsets padding;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: GameDecor.card(highlight: highlight, tint: tint),
      child: child,
    );
  }
}

class BossBadge extends StatelessWidget {
  const BossBadge({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    return _enter(
      context,
      _Marker(
        color: AppColors.primary,
        child: GameIcon(kind: GameAssets.crown, size: size),
      ),
    );
  }
}

class GodBadge extends StatelessWidget {
  const GodBadge({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    return _enter(
      context,
      _Marker(
        color: AppColors.streakFire,
        borderWidth: 2,
        child: GameIcon(kind: GameAssets.flame, size: size),
      ),
    );
  }
}

Widget _enter(BuildContext context, Widget child) {
  if (GameMotion.reduce(context)) return child;
  return child.animate().scaleXY(
        begin: 0.7,
        end: 1,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutBack,
      );
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.color,
    required this.child,
    this.borderWidth = 1.5,
  });

  final Color color;
  final Widget child;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: borderWidth),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: child,
      ),
    );
  }
}

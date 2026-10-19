import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_fonts.dart';
import '../../core/constants.dart';
import '../icons/game_assets.dart';
import '../icons/game_icon.dart';
import '../theme/game_tokens.dart';
import 'game_badges.dart';
import 'icon_kit.dart';

/// One cell in the 5-column level grid.
class LevelCard extends StatefulWidget {
  const LevelCard({
    super.key,
    required this.levelNumber,
    required this.unlocked,
    required this.current,
    required this.stars,
    required this.levelType,
    this.onTap,
  });

  final int levelNumber;
  final bool unlocked;
  final bool current;
  final int stars;
  final LevelType levelType;
  final VoidCallback? onTap;

  @override
  State<LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<LevelCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final completed = widget.stars > 0;
    final card = AnimatedContainer(
      duration: GameMotion.tap,
      curve: Curves.easeOut,
      decoration: LevelStateDecoration.of(
        unlocked: widget.unlocked,
        current: widget.current,
        completed: completed,
        levelType: widget.levelType,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _BadgeSlot(
            levelType: widget.levelType,
            locked: !widget.unlocked,
          ),
          const SizedBox(height: 2),
          LevelNumber(
            number: widget.levelNumber,
            current: widget.current,
            muted: !widget.unlocked,
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 14,
            child: completed ? LevelStars(stars: widget.stars) : null,
          ),
        ],
      ),
    );

    return Semantics(
      button: widget.onTap != null,
      selected: widget.current,
      enabled: widget.unlocked,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown:
            widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapCancel:
            widget.onTap == null ? null : () => setState(() => _down = false),
        onTapUp:
            widget.onTap == null ? null : (_) => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: GameMotion.tap,
          curve: Curves.easeOut,
          child: SizedBox.expand(child: card),
        ),
      ),
    );
  }
}

class LevelNumber extends StatelessWidget {
  const LevelNumber({
    super.key,
    required this.number,
    required this.current,
    required this.muted,
  });

  final int number;
  final bool current;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$number',
            style: AppFonts.style(
              fontSize: number >= 100 ? 15 : 18,
              fontWeight: FontWeight.w800,
              color: muted
                  ? AppColors.textMuted
                  : current
                      ? AppColors.primary
                      : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact earned and empty stars. The same star asset as the rest of the game.
class LevelStars extends StatelessWidget {
  const LevelStars({super.key, required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.5),
          child: StarIcon(
            size: 12,
            state: i < stars ? StarState.earned : StarState.empty,
          ),
        );
      }),
    );
  }
}

class _BadgeSlot extends StatelessWidget {
  const _BadgeSlot({required this.levelType, required this.locked});

  final LevelType levelType;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final Widget mark;
    if (levelType == LevelType.god) {
      mark = const GodBadge(size: 14);
    } else if (levelType == LevelType.boss) {
      mark = const BossBadge(size: 14);
    } else if (locked) {
      mark = const GameIcon(kind: GameAssets.lock, size: 14);
    } else {
      return const SizedBox(height: 16);
    }
    return SizedBox(
      height: 16,
      child: Opacity(opacity: locked ? 0.55 : 1, child: mark),
    );
  }
}

/// Surface, border, and glow for one level tile.
class LevelStateDecoration {
  static BoxDecoration of({
    required bool unlocked,
    required bool current,
    required bool completed,
    required LevelType levelType,
  }) {
    final god = levelType == LevelType.god;
    final boss = levelType == LevelType.boss;
    final Color border;
    var width = 1.15;
    if (!unlocked) {
      border = AppColors.surfaceLight;
    } else if (current && god) {
      border = AppColors.streakFire;
      width = 2.25;
    } else if (current || boss) {
      border = AppColors.primary;
      width = current ? 2.25 : 1.6;
    } else if (god) {
      border = AppColors.streakFire;
      width = 2;
    } else if (completed) {
      border = AppColors.accentGreen.withValues(alpha: 0.7);
      width = 1.25;
    } else {
      border = AppColors.surfaceLight;
    }

    final Color fill;
    if (!unlocked) {
      fill = AppColors.elevated;
    } else if (god) {
      fill = Color.alphaBlend(
        AppColors.streakFire.withValues(alpha: 0.1),
        AppColors.surface,
      );
    } else {
      fill = AppColors.surface;
    }

    final List<BoxShadow>? shadow = current
        ? [
            BoxShadow(
              color: (god ? AppColors.streakFire : AppColors.primary)
                  .withValues(alpha: 0.22),
              blurRadius: 8,
            ),
          ]
        : null;

    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(GameRadius.sm),
      border: Border.all(color: border, width: width),
      boxShadow: shadow,
    );
  }
}

/// Faint link in the gap after a tile. It does not cross the card.
class JourneyConnector extends StatelessWidget {
  const JourneyConnector({
    super.key,
    required this.child,
    required this.showLink,
    required this.reached,
    required this.chapterEnd,
    this.gap = 8,
  });

  final Widget child;
  final bool showLink;
  final bool reached;
  final bool chapterEnd;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final line = reached
        ? AppColors.primary.withValues(alpha: 0.5)
        : AppColors.surfaceLight;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (showLink)
          Positioned(
            right: -gap,
            top: 0,
            bottom: 0,
            width: gap,
            child: Center(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: line,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        if (chapterEnd)
          Positioned(
            left: 6,
            right: 6,
            bottom: -gap / 2,
            height: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.streakFire.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_colors.dart';
import '../../core/app_fonts.dart';
import '../../core/constants.dart';
import '../icons/game_assets.dart';
import '../icons/game_icon.dart';
import '../theme/game_tokens.dart';
import 'game_badges.dart';
import 'icon_kit.dart';

/// Horizontal level path. Keeps the current level centered.
class LevelJourney extends StatefulWidget {
  const LevelJourney({
    super.key,
    required this.currentLevel,
    required this.totalLevels,
    required this.isUnlocked,
    required this.starsFor,
    required this.onSelect,
    required this.onLocked,
    this.haptic = true,
  });

  final int currentLevel;
  final int totalLevels;
  final bool Function(int level) isUnlocked;
  final int Function(int level) starsFor;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onLocked;
  final bool haptic;

  @override
  State<LevelJourney> createState() => _LevelJourneyState();
}

class _LevelJourneyState extends State<LevelJourney> {
  late final ScrollController _controller;
  int _lastTick = -1;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_onScroll);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _center(animate: false));
  }

  @override
  void didUpdateWidget(covariant LevelJourney oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLevel != widget.currentLevel) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _center());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.haptic || !mounted) return;
    final index = (_controller.offset / GameDims.journeyItem).round();
    if (index != _lastTick) {
      _lastTick = index;
      HapticFeedback.selectionClick();
    }
  }

  void _center({bool animate = true}) {
    if (!_controller.hasClients) return;
    final target = (widget.currentLevel - 1) * GameDims.journeyItem;
    final offset = target.clamp(0.0, _controller.position.maxScrollExtent);
    if (animate && !GameMotion.reduce(context)) {
      _controller.animateTo(
        offset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    } else {
      _controller.jumpTo(offset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final path =
        AppColors.isDark ? const Color(0xFF3A443C) : const Color(0xFFE4E1D6);
    final done = AppColors.primary.withValues(alpha: 0.45);

    return SizedBox(
      height: GameDims.journeyHeight,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.08, 0.92, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: widget.totalLevels,
          padding: EdgeInsets.symmetric(
            horizontal:
                MediaQuery.sizeOf(context).width / 2 - GameDims.journeyItem / 2,
          ),
          itemBuilder: (context, index) {
            final level = index + 1;
            final current = level == widget.currentLevel;
            final unlocked = widget.isUnlocked(level);
            final stars = widget.starsFor(level);
            final completed =
                stars > 0 || (unlocked && level < widget.currentLevel);
            final type = AppConstants.levelTypeFor(level);
            final size = current ? GameDims.nodeCurrent : GameDims.node;

            Color fill;
            Color ink;
            if (!unlocked) {
              fill = AppColors.elevated;
              ink = AppColors.textMuted;
            } else if (current) {
              fill = AppColors.primary;
              ink = Colors.white;
            } else if (type == LevelType.god) {
              fill = AppColors.streakFire;
              ink = Colors.white;
            } else if (type == LevelType.boss) {
              fill = AppColors.primaryDark;
              ink = Colors.white;
            } else if (completed) {
              fill = AppColors.surface;
              ink = AppColors.textPrimary;
            } else {
              fill = AppColors.surface;
              ink = AppColors.textSecondary;
            }

            Widget node = AnimatedContainer(
              duration: GameMotion.press,
              curve: Curves.easeOut,
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: current
                      ? Colors.white
                      : completed
                          ? AppColors.accentGreen
                          : AppColors.surfaceLight,
                  width: current ? 3 : 1.5,
                ),
                boxShadow: current
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: !unlocked
                    ? GameIcon(
                        kind: GameAssets.lock,
                        size: size * 0.42,
                      )
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$level',
                          style: AppFonts.style(
                            fontSize: current
                                ? (level >= 100 ? 14 : 18)
                                : (level >= 100 ? 11 : 13),
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
              ),
            );

            if (current && !GameMotion.reduce(context)) {
              node =
                  node.animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(
                        begin: 1,
                        end: 1.06,
                        duration: GameMotion.levelPulse,
                        curve: Curves.easeInOut,
                      );
            }

            final lineBefore = level == 1
                ? Colors.transparent
                : (level <= widget.currentLevel ? done : path);
            final lineAfter = level == widget.totalLevels
                ? Colors.transparent
                : (level < widget.currentLevel ? done : path);

            return SizedBox(
              width: GameDims.journeyItem,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      Expanded(child: Container(height: 3, color: lineBefore)),
                      SizedBox(width: size),
                      Expanded(child: Container(height: 3, color: lineAfter)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      if (widget.haptic) HapticFeedback.selectionClick();
                      if (unlocked) {
                        widget.onSelect(level);
                      } else {
                        widget.onLocked(level);
                      }
                    },
                    child: node,
                  ),
                  if (type == LevelType.boss)
                    const Positioned(top: 4, child: BossBadge(size: 16))
                  else if (type == LevelType.god)
                    const Positioned(top: 4, child: GodBadge(size: 16)),
                  if (completed && !current && stars > 0)
                    const Positioned(
                      bottom: 4,
                      child: const StarIcon(size: 16, state: StarState.earned),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

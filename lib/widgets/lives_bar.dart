import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../ui/icons/game_icon.dart';
import '../ui/icons/game_icon_kind.dart';
import '../ui/theme/game_tokens.dart';
import '../ui/widgets/icon_kit.dart';

class LivesBar extends StatefulWidget {
  final int lives;
  final int maxLives;
  final double iconSize;
  final double spacing;

  const LivesBar({
    super.key,
    required this.lives,
    required this.maxLives,
    this.iconSize = 30,
    this.spacing = 3,
  });

  @override
  State<LivesBar> createState() => _LivesBarState();
}

class _LivesBarState extends State<LivesBar> {
  int? _breakingIndex;
  int _breakKey = 0;
  int? _recoverIndex;
  int _recoverKey = 0;

  @override
  void didUpdateWidget(covariant LivesBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lives < oldWidget.lives && widget.lives >= 0) {
      _breakingIndex = widget.lives;
      _breakKey++;
    } else if (widget.lives > oldWidget.lives) {
      _recoverIndex = widget.lives - 1;
      _recoverKey++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduce = GameMotion.reduce(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxLives, (i) {
        final isFull = i < widget.lives;
        Widget heart = HeartIcon(
          filled: isFull,
          size: widget.iconSize,
        );
        if (isFull && i == _recoverIndex && !reduce) {
          heart = heart.animate(key: ValueKey('gain_$_recoverKey')).scaleXY(
                begin: 0.72,
                end: 1,
                duration: 180.ms,
                curve: Curves.easeOutBack,
              );
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.spacing),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(scale: anim, child: child),
                ),
                child: KeyedSubtree(
                  key: ValueKey('heart_${i}_${isFull ? 'full' : 'empty'}'),
                  child: heart,
                ),
              ),
              if (!isFull && i == _breakingIndex)
                IgnorePointer(
                  child: GameIcon(
                    kind: GameIconKind.heartBroken,
                    size: widget.iconSize,
                  )
                      .animate(key: ValueKey('break_$_breakKey'))
                      .scaleXY(
                        begin: 1,
                        end: 1.2,
                        duration: 120.ms,
                        curve: Curves.easeOut,
                      )
                      .then()
                      .moveY(
                        begin: 0,
                        end: 14,
                        duration: 160.ms,
                        curve: Curves.easeIn,
                      )
                      .fadeOut(duration: 160.ms),
                ),
            ],
          ),
        );
      }),
    );
  }
}

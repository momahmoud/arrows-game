import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_colors.dart';

class LivesBar extends StatefulWidget {
  final int lives;
  final int maxLives;

  const LivesBar({super.key, required this.lives, required this.maxLives});

  @override
  State<LivesBar> createState() => _LivesBarState();
}

class _LivesBarState extends State<LivesBar> with SingleTickerProviderStateMixin {
  static const _calmPulse = Duration(milliseconds: 1800);
  static const _dangerPulse = Duration(milliseconds: 550);

  late AnimationController _animationController;
  int? _breakingIndex;
  int _breakKey = 0;

  bool get _isLastHeart => widget.lives == 1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _isLastHeart ? _dangerPulse : _calmPulse,
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant LivesBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lives < oldWidget.lives && widget.lives >= 0) {
      _breakingIndex = widget.lives;
      _breakKey++;
    }
    final pulse = _isLastHeart ? _dangerPulse : _calmPulse;
    if (_animationController.duration != pulse) {
      _animationController.duration = pulse;
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnimation = Tween<double>(begin: 1.0, end: _isLastHeart ? 1.16 : 1.05)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    final fullColors = _isLastHeart
        ? const [Color(0xFFFF6B6B), Color(0xFFD32F2F)]
        : const [Color(0xFF829079), Color(0xFF5E6B56)];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxLives, (i) {
        final isFull = i < widget.lives;

        final heartWidget = Stack(
          alignment: Alignment.center,
          children: [
            // Soft drop shadow for 3D depth
            if (isFull)
              Icon(
                Icons.favorite,
                color: Colors.black.withValues(alpha: 0.15),
                size: 27,
              ),
            // Heart body
            isFull
                ? ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: fullColors,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 25,
                    ),
                  )
                : Icon(
                    Icons.favorite_border,
                    color: AppColors.surfaceLight,
                    size: 24,
                  ),
            // Glass/glossy reflection dot on top-left of active heart
            if (isFull)
              Positioned(
                top: 5,
                left: 5,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: isFull
                    ? ScaleTransition(
                        key: ValueKey('heart_${i}_full'),
                        scale: scaleAnimation,
                        child: heartWidget,
                      )
                    : SizedBox(
                        key: ValueKey('heart_${i}_empty'),
                        child: heartWidget,
                      ),
              ),
              if (!isFull && i == _breakingIndex)
                IgnorePointer(
                  child: const Icon(Icons.heart_broken, color: Color(0xFFE53935), size: 26)
                      .animate(key: ValueKey('break_$_breakKey'))
                      .scaleXY(begin: 1.0, end: 1.45, duration: 140.ms, curve: Curves.easeOut)
                      .then()
                      .moveY(begin: 0, end: 22, duration: 480.ms, curve: Curves.easeIn)
                      .rotate(begin: 0, end: 0.08, duration: 480.ms)
                      .fadeOut(duration: 480.ms),
                ),
            ],
          ),
        );
      }),
    );
  }
}

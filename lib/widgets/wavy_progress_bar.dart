import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../ui/theme/game_tokens.dart';

/// Rounded level progress. The fill eases forward when arrows escape.
class WavyProgressBar extends StatefulWidget {
  final double progress;
  final double width;
  final double height;
  final Color? color;

  const WavyProgressBar({
    super.key,
    required this.progress,
    this.width = 100,
    this.height = 6,
    this.color,
  });

  @override
  State<WavyProgressBar> createState() => _WavyProgressBarState();
}

class _WavyProgressBarState extends State<WavyProgressBar>
    with SingleTickerProviderStateMixin {
  static const _fill = Duration(milliseconds: 260);

  late final AnimationController _progressController;
  late Animation<double> _progressAnimation;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: _fill);
    _progressAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _progressController.duration =
        GameMotion.reduce(context) ? Duration.zero : _fill;
    if (_started) return;
    _started = true;
    _progressController.forward();
  }

  @override
  void didUpdateWidget(WavyProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress == widget.progress) return;
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: widget.progress,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController
      ..duration = GameMotion.reduce(context) ? Duration.zero : _fill
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: _ProgressPainter(
            progress: _progressAnimation.value,
            color: color,
          ),
        );
      },
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(size.height / 2);
    final track = RRect.fromRectAndRadius(Offset.zero & size, radius);
    canvas.drawRRect(
      track,
      Paint()
        ..color = Color.alphaBlend(
          AppColors.textMuted.withValues(alpha: 0.28),
          AppColors.surfaceLight,
        ),
    );
    if (progress <= 0) return;
    final fillWidth = (size.width * progress).clamp(0.0, size.width);
    if (fillWidth <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, fillWidth, size.height),
        radius,
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

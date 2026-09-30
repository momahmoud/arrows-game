import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Small expanding ring marking the exact cell edge where a move was stopped.
class ImpactPulseComponent extends PositionComponent {
  static const double _kLifetime = 0.32;

  final Color color;
  final double radius;
  double _age = 0.0;
  final Paint _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _core = Paint()..style = PaintingStyle.fill;

  ImpactPulseComponent({
    required Vector2 position,
    required this.color,
    required this.radius,
  }) : super(position: position, priority: 15);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= _kLifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / _kLifetime).clamp(0.0, 1.0);
    final grow = Curves.easeOutCubic.transform(t);
    final fade = 1.0 - Curves.easeIn.transform(t);

    _ring
      ..color = color.withValues(alpha: 0.55 * fade)
      ..strokeWidth = radius * 0.22 * (1 - 0.5 * t);
    canvas.drawCircle(Offset.zero, radius * (0.35 + 0.65 * grow), _ring);

    _core.color = color.withValues(alpha: 0.35 * fade);
    canvas.drawCircle(Offset.zero, radius * 0.28 * (1 - 0.4 * t), _core);
  }
}

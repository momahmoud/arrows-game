import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Short-lived label that pops in, drifts upward and fades out.
class FloatingTextComponent extends PositionComponent {
  static const double _kLifetime = 0.85;

  final TextPainter _painter;
  final double _rise;
  double _age = 0.0;

  FloatingTextComponent({
    required String text,
    required Color color,
    required Vector2 position,
    double fontSize = 18,
  })  : _rise = fontSize * 2.2,
        _painter = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              shadows: const [
                Shadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 1.5)),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
        super(position: position, anchor: Anchor.center, priority: 20) {
    size = Vector2(_painter.width, _painter.height);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= _kLifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_age / _kLifetime).clamp(0.0, 1.0);
    final pop = t < 0.2 ? Curves.easeOutBack.transform(t / 0.2) : 1.0;
    final alpha = t < 0.6 ? 1.0 : 1.0 - (t - 0.6) / 0.4;
    final dy = -Curves.easeOut.transform(t) * _rise;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2 + dy);
    canvas.scale(0.6 + 0.4 * pop);
    canvas.translate(-size.x / 2, -size.y / 2);
    canvas.saveLayer(Rect.fromLTWH(-4, -4, size.x + 8, size.y + 8),
        Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0.0, 1.0)));
    _painter.paint(canvas, Offset.zero);
    canvas.restore();
    canvas.restore();
  }

  @override
  void onRemove() {
    _painter.dispose();
    super.onRemove();
  }
}

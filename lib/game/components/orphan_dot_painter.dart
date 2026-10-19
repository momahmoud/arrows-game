import 'package:flutter/material.dart';

import '../../data/models/arrow.dart';
import '../../data/models/level.dart';

/// Draws the gold deflector plates. Paints and the arrow glyph are reused
/// across frames; the glyph is rebuilt only when the cell size changes.
class OrphanDotPainter {
  OrphanDotPainter._();

  static const Color _plateColor = Color(0xFFFFAA00);

  static final Paint _plate = Paint()
    ..color = _plateColor
    ..style = PaintingStyle.fill;
  static final Paint _rim = Paint()
    ..color = Colors.black.withValues(alpha: 0.18)
    ..style = PaintingStyle.stroke;
  static final Paint _glyphLine = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  static final Paint _glyphFill = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static double _glyphCell = -1;
  static Path _glyphHead = Path();

  static Path _headFor(double cs) {
    if (cs != _glyphCell) {
      _glyphCell = cs;
      _glyphHead = Path()
        ..moveTo(cs * 0.28, 0)
        ..lineTo(cs * 0.04, -cs * 0.18)
        ..lineTo(cs * 0.10, 0)
        ..lineTo(cs * 0.04, cs * 0.18)
        ..close();
    }
    return _glyphHead;
  }

  static ArrowDirection? _direction(OrphanDotType type) {
    switch (type) {
      case OrphanDotType.up:
        return ArrowDirection.up;
      case OrphanDotType.down:
        return ArrowDirection.down;
      case OrphanDotType.left:
        return ArrowDirection.left;
      case OrphanDotType.right:
        return ArrowDirection.right;
      case OrphanDotType.neutral:
        return null;
    }
  }

  /// Neutral dots are left blank.
  static void paint(
      Canvas canvas, Offset center, OrphanDotType type, double cs) {
    final dir = _direction(type);
    if (dir == null) return;

    canvas.drawCircle(center, cs * 0.36, _plate);
    canvas.drawCircle(center, cs * 0.36, _rim..strokeWidth = cs * 0.045);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(dir.rotationRadians);
    canvas.drawLine(Offset(-cs * 0.22, 0), Offset(cs * 0.06, 0),
        _glyphLine..strokeWidth = cs * 0.075);
    canvas.drawPath(_headFor(cs), _glyphFill);
    canvas.restore();
  }
}

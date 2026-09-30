import 'dart:math';
import 'dart:ui';

import '../../core/constants.dart';

/// Single source of truth for how board arrows are drawn.
///
/// Every length is a ratio of the grid cell size, so arrows keep the same
/// proportions on any board, screen size or pixel density. Colour groups
/// never change these values: a red and a green arrow are the same shape.
/// See docs/design/arrow_visual_system.md.
class ArrowVisualConfig {
  ArrowVisualConfig._();

  // ── Shaft ─────────────────────────────────────────────────────────────────
  static const double shaftWidthRatio = 0.16;

  /// Hairline floor for tiny cells; below it the shaft would vanish.
  static const double minShaftWidth = 1.0;

  /// Centre-line radius of every 90° bend. Must stay below 0.5 so two
  /// one-cell turns in a row never overlap.
  static const double cornerRadiusRatio = 0.05;

  // ── Arrowhead ─────────────────────────────────────────────────────────────
  static const double arrowHeadLengthRatio = 0.4;

  /// Full width across the base of the head.
  static const double arrowHeadWidthRatio = 0.34;

  /// Stroke drawn over the filled head; it rounds the three corners.
  static const double arrowHeadRoundingRatio = 0.1;

  /// Share of the head length the shaft reaches into, so shaft and head
  /// overlap instead of meeting edge to edge.
  static const double arrowHeadInsetFraction = 0.5;

  /// Shaft length behind the head of a one-cell arrow, in head lengths.
  static const double singleCellTailFraction = 1.0;

  // ── Colour-lock tail marker ───────────────────────────────────────────────
  static const double lockRingOuterRatio = 0.112;
  static const double lockRingInnerRatio = 0.072;

  // ── States ────────────────────────────────────────────────────────────────
  static const double pressedScale = 0.92;
  static const double pressResponse = 18;

  static const double blockShakeAngle = 0.08;
  static const double blockShakeFrequency = 42;
  static const Color blockedColor = Color(0xFFCC2200);

  static const double blockerGlowWidthRatio = 0.38;
  static const double hintGlowWidthRatio = 0.42;

  /// White mixed into the arrow while it exits: base + flash on activation.
  static const double exitLighten = 0.10;
  static const double exitFlashLighten = 0.22;

  /// Rate the head eases onto a new heading at a deflector (per second).
  static const double headTurnRate = 30;

  // ── Derived sizes ─────────────────────────────────────────────────────────

  /// Cell size the ratios are applied to. Dividing out [boardCellSpacing]
  /// keeps the arrow the same thickness when the board cells are packed
  /// closer. Grows past that only when the shaft would hit [minShaftWidth].
  static double unit(double cellSize) => max(
        cellSize / AppConstants.boardCellSpacing,
        minShaftWidth / shaftWidthRatio,
      );

  static double shaftWidth(double cellSize) => unit(cellSize) * shaftWidthRatio;

  static double cornerRadius(double cellSize) =>
      unit(cellSize) * cornerRadiusRatio;

  static double headLength(double cellSize) =>
      unit(cellSize) * arrowHeadLengthRatio;

  static double headHalfWidth(double cellSize) =>
      unit(cellSize) * arrowHeadWidthRatio / 2;

  static double headRounding(double cellSize) =>
      unit(cellSize) * arrowHeadRoundingRatio;

  static double headInset(double cellSize) =>
      headLength(cellSize) * arrowHeadInsetFraction;

  // ── Geometry ──────────────────────────────────────────────────────────────

  /// Open polyline through [pts] with each turn replaced by a circular bend
  /// of up to [radius]. End segments may be consumed entirely (an arrow that
  /// is halfway round a corner); inner segments are shared by two bends, so
  /// each bend takes at most half.
  static Path roundedPolyline(List<Offset> pts, double radius) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    final last = pts.length - 1;
    for (var i = 1; i < last; i++) {
      final prev = pts[i - 1], cur = pts[i], next = pts[i + 1];
      final vIn = cur - prev, vOut = next - cur;
      final lIn = vIn.distance, lOut = vOut.distance;
      if (lIn < 1e-3 || lOut < 1e-3) {
        path.lineTo(cur.dx, cur.dy);
        continue;
      }
      final cosTurn = (vIn.dx * vOut.dx + vIn.dy * vOut.dy) / (lIn * lOut);
      if (cosTurn > 0.999) {
        path.lineTo(cur.dx, cur.dy);
        continue;
      }
      final r = min(
          radius, min(i == 1 ? lIn : lIn / 2, i == last - 1 ? lOut : lOut / 2));
      final a = cur - vIn / lIn * r;
      final b = cur + vOut / lOut * r;
      path.lineTo(a.dx, a.dy);
      // cos(turn/2) is the conic weight that makes the bend a true circle arc.
      final weight = sqrt(((1 + cosTurn) / 2).clamp(0.04, 1.0));
      path.conicTo(cur.dx, cur.dy, b.dx, b.dy, weight);
    }
    if (last > 0) path.lineTo(pts[last].dx, pts[last].dy);
    return path;
  }

  /// [pts] with the first [distance] of its length removed. Empty when the
  /// polyline is not longer than [distance].
  static List<Offset> trimStart(List<Offset> pts, double distance) {
    var left = distance;
    for (var i = 1; i < pts.length; i++) {
      final seg = pts[i] - pts[i - 1];
      final len = seg.distance;
      if (len > left) {
        return [pts[i - 1] + seg * (left / len), ...pts.sublist(i)];
      }
      left -= len;
    }
    return const [];
  }
}

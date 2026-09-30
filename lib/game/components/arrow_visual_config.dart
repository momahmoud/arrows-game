import 'dart:math';
import 'dart:ui';

/// Single source of truth for how arrows are shaped.
///
/// Every length is a fraction of the grid cell size, so arrows keep the same
/// proportions on any board size, screen size or pixel density.
/// See docs/design/arrow_visual_system.md.
class ArrowGeometry {
  ArrowGeometry._();

  // ── Shaft ─────────────────────────────────────────────────────────────────
  static const double shaftWidth = 0.21;

  /// Radius of the bend where the path turns 90°. Must stay ≤ 0.5 so two
  /// consecutive one-cell turns never overlap.
  static const double cornerRadius = 0.32;

  // ── Head ──────────────────────────────────────────────────────────────────
  /// How far the tip sits past the head cell's centre (the cell edge is 0.5).
  static const double headReach = 0.45;
  static const double headLength = 0.38;

  /// Full width across the base (≈ 2.7× the shaft).
  static const double headWidth = 0.56;
  static const double headTipRadius = 0.045;
  static const double headBaseRadius = 0.07;

  // ── Depth ─────────────────────────────────────────────────────────────────
  /// Drop-shadow offset straight down, relative to cell size.
  static const double shadowOffset = 0.05;
  static const double shadowAlphaOnLight = 0.14;
  static const double shadowAlphaOnDark = 0.32;

  // ── Touch ─────────────────────────────────────────────────────────────────
  /// Minimum comfortable touch target (logical px).
  static const double minTouchTarget = 44.0;

  /// Empty-space taps snap to the nearest arrow within this many cells, at
  /// least half the touch target, never further than [maxTouchReach].
  static const double touchReach = 0.75;
  static const double maxTouchReach = 1.5;

  static double touchRadius(double cellSize) => (minTouchTarget / 2)
      .clamp(cellSize * touchReach, cellSize * maxTouchReach);

  // ── Builders ──────────────────────────────────────────────────────────────

  static Path? _headPath;
  static double _headPathCell = -1;

  /// Arrowhead in local space: pointing along +x, origin at the head cell
  /// centre. Shared by every arrow of the same cell size.
  static Path headPath(double cellSize) {
    if (_headPath != null && _headPathCell == cellSize) return _headPath!;
    final tipX = headReach * cellSize;
    final baseX = tipX - headLength * cellSize;
    final hw = headWidth * cellSize / 2;
    _headPath = roundedPolygon(
      [Offset(tipX, 0), Offset(baseX, hw), Offset(baseX, -hw)],
      [
        headTipRadius * cellSize,
        headBaseRadius * cellSize,
        headBaseRadius * cellSize
      ],
    );
    _headPathCell = cellSize;
    return _headPath!;
  }

  /// Closed polygon whose corners are rounded by the matching [radii].
  static Path roundedPolygon(List<Offset> vertices, List<double> radii) {
    final path = Path();
    final n = vertices.length;
    for (var i = 0; i < n; i++) {
      final prev = vertices[(i - 1 + n) % n];
      final cur = vertices[i];
      final next = vertices[(i + 1) % n];
      final toPrev = prev - cur;
      final toNext = next - cur;
      final r = min(radii[i], min(toPrev.distance, toNext.distance) / 2);
      final a = cur + toPrev / toPrev.distance * r;
      final b = cur + toNext / toNext.distance * r;
      if (i == 0) {
        path.moveTo(a.dx, a.dy);
      } else {
        path.lineTo(a.dx, a.dy);
      }
      path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
    }
    return path..close();
  }

  /// Open polyline through [pts] with each turn replaced by a circular bend
  /// of up to [radius]. End segments may be consumed entirely (moving arrows
  /// that are halfway round a corner); inner segments are shared by two
  /// bends, so each bend takes at most half.
  static Path roundedPolyline(List<Offset> pts, double radius, [Path? into]) {
    final path = into ?? Path();
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
        path.lineTo(cur.dx, cur.dy); // straight through
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

  /// Shortest distance from [p] to the segment [a]–[b].
  static double distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    final t =
        (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }
}

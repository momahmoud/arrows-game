import 'dart:math';
import 'dart:ui';

import '../../data/models/arrow.dart';

/// Decides which arrow a board touch belongs to.
///
/// A cell that holds an arrow always belongs to that arrow, so a tap can
/// never be stolen by a neighbour drawn on top of it. Only touches on empty
/// cells (or just outside the board) fall back to the nearest arrow cell
/// within [slop]; equal distances go to the first cell in row-major order.
/// Sliding arrows have left the board and are ignored.
class ArrowHitResolver {
  ArrowHitResolver({
    required this.gridSize,
    required this.cellSize,
    required this.slop,
    required Iterable<ArrowModel> arrows,
  }) {
    for (final arrow in arrows) {
      if (arrow.state == ArrowState.sliding) continue;
      for (final pt in arrow.path) {
        if (_inGrid(pt[0], pt[1])) _owner[pt[0] * gridSize + pt[1]] = arrow.id;
      }
    }
  }

  final int gridSize;
  final double cellSize;
  final double slop;
  final Map<int, String> _owner = {};

  bool _inGrid(int r, int c) =>
      r >= 0 && r < gridSize && c >= 0 && c < gridSize;

  /// Arrow id at [point] (grid-local pixels), or null when nothing is close.
  String? arrowAt(Offset point) {
    if (cellSize <= 0) return null;
    final r = (point.dy / cellSize).floor();
    final c = (point.dx / cellSize).floor();
    if (_inGrid(r, c)) {
      final own = _owner[r * gridSize + c];
      if (own != null) return own;
    }

    final reach = max(1, (slop / cellSize).ceil());
    String? best;
    var bestDist = slop;
    for (var rr = r - reach; rr <= r + reach; rr++) {
      for (var cc = c - reach; cc <= c + reach; cc++) {
        if (!_inGrid(rr, cc)) continue;
        final id = _owner[rr * gridSize + cc];
        if (id == null) continue;
        final dx = max(
            0.0, max(cc * cellSize - point.dx, point.dx - (cc + 1) * cellSize));
        final dy = max(
            0.0, max(rr * cellSize - point.dy, point.dy - (rr + 1) * cellSize));
        final d = max(dx, dy);
        if (d < bestDist || (best == null && d <= bestDist)) {
          best = id;
          bestDist = d;
        }
      }
    }
    return best;
  }
}

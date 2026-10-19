import 'dart:math';
import 'dart:ui';

import '../core/constants.dart';
import '../data/models/level.dart';

/// Where the board sits inside the game viewport.
///
/// Arrows use the same cell size on every level unless the board would not
/// fit; then cells shrink just enough to keep every arrow on screen. The
/// used part of the board is centered, and the grid stays inside the
/// viewport, which is what taps are measured against.
class BoardLayout {
  const BoardLayout({
    required this.cellSize,
    required this.origin,
    required this.gridSize,
    required this.content,
  });

  /// Pixel size of one grid cell.
  final double cellSize;

  /// Top-left of the full square grid, in viewport pixels.
  final Offset origin;

  final int gridSize;

  /// Cells the level actually uses, in cell units.
  final Rect content;

  double get gridPixelSize => gridSize * cellSize;

  /// Used cells in viewport pixels.
  Rect get contentRect => Rect.fromLTRB(
        origin.dx + content.left * cellSize,
        origin.dy + content.top * cellSize,
        origin.dx + content.right * cellSize,
        origin.dy + content.bottom * cellSize,
      );

  static BoardLayout forLevel(LevelModel level, Size viewport) =>
      fit(contentBounds(level), level.gridSize, viewport);

  static BoardLayout fit(Rect content, int gridSize, Size viewport) {
    final cell = _cellSize(viewport.width, viewport.height, content);
    return BoardLayout(
      cellSize: cell,
      origin: Offset(
        viewport.width / 2 - content.center.dx * cell,
        viewport.height / 2 - content.center.dy * cell,
      ),
      gridSize: gridSize,
      content: content,
    );
  }

  static double _cellSize(double width, double height, Rect bounds) {
    final shorter = min(width, height);
    if (shorter <= 0) return 1;
    const spacing = AppConstants.boardCellSpacing;
    final standard = (shorter / AppConstants.arrowCellSpan) * spacing;
    final fit = min(width / bounds.width, height / bounds.height) * spacing;
    return min(standard, fit);
  }

  /// Cells the level actually uses (mask, arrows, dots), in cell units.
  static Rect contentBounds(LevelModel level) {
    var minR = level.gridSize, minC = level.gridSize, maxR = -1, maxC = -1;
    void include(int r, int c) {
      if (r < minR) minR = r;
      if (c < minC) minC = c;
      if (r > maxR) maxR = r;
      if (c > maxC) maxC = c;
    }

    for (final key in level.mask) {
      final parts = key.split(',');
      include(int.parse(parts[0]), int.parse(parts[1]));
    }
    for (final arrow in level.arrows) {
      for (final pt in arrow.path) {
        include(pt[0], pt[1]);
      }
    }
    for (final dot in level.orphanDots) {
      include(dot.row, dot.col);
    }
    if (maxR < 0) {
      return Rect.fromLTWH(
          0, 0, level.gridSize.toDouble(), level.gridSize.toDouble());
    }
    return Rect.fromLTRB(minC.toDouble(), minR.toDouble(),
        (maxC + 1).toDouble(), (maxR + 1).toDouble());
  }
}

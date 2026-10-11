import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models/level.dart';
import 'components/grid_component.dart';
import 'game_state.dart';

class ArrowPuzzleGame extends FlameGame {
  // ── State ─────────────────────────────────────────────────────────────────────
  final LevelModel level;
  final GameState gameState;
  GridComponent? gridComponent;

  // ── Callbacks to Flutter ──────────────────────────────────────────────────────
  final void Function() onLevelComplete;
  final void Function() onGameOver;
  final void Function() onLifeLost;

  /// Localized label for the top combo milestone popup on the board.
  final String comboPerfectLabel;

  ArrowPuzzleGame({
    required this.level,
    required this.gameState,
    required this.onLevelComplete,
    required this.onGameOver,
    required this.onLifeLost,
    this.comboPerfectLabel = 'Perfect!',
  });

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    final (gridPx, gridX, gridY) = _calcLayout(size);
    gridComponent = GridComponent(
      gameState: gameState,
      gridPixelSize: gridPx,
      position: Vector2(gridX, gridY),
    );

    add(gridComponent!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final (gridPx, gridX, gridY) = _calcLayout(size);
    if (gridComponent == null) return;
    gridComponent!.position = Vector2(gridX, gridY);
    gridComponent!.resize(gridPx);
  }

  /// Arrows use the same cell size on every level unless the board would not
  /// fit; then cells shrink just enough to keep every arrow on screen. The
  /// used part of the board is centered, and the grid stays inside this
  /// widget, which is what taps are measured against.
  (double gridPx, double gridX, double gridY) _calcLayout(Vector2 screenSize) {
    final bounds = _contentBounds;
    final cell = _cellSize(screenSize.x, screenSize.y, bounds);
    final gridPx = level.gridSize * cell;
    final gridX = screenSize.x / 2 - (bounds.left + bounds.right) / 2 * cell;
    final gridY = screenSize.y / 2 - (bounds.top + bounds.bottom) / 2 * cell;
    return (gridPx, gridX, gridY);
  }

  double _cellSize(double width, double height, Rect bounds) {
    final shorter = width < height ? width : height;
    if (shorter <= 0) return 1;
    final spacing = AppConstants.boardCellSpacing;
    final standard = (shorter / AppConstants.arrowCellSpan) * spacing;
    final fit = (width / bounds.width < height / bounds.height
            ? width / bounds.width
            : height / bounds.height) *
        spacing;
    return standard < fit ? standard : fit;
  }

  /// Cells the level actually uses (mask, arrows, dots), in cell units.
  late final Rect _contentBounds = () {
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
  }();

  /// Reset board to initial state (restart level)
  void resetLevel() {
    gameState.resetLevel();
    gridComponent?.rebuild();
  }
}

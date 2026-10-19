import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../data/models/level.dart';
import 'board_layout.dart';
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

  late final Rect _contentBounds = BoardLayout.contentBounds(level);

  (double gridPx, double gridX, double gridY) _calcLayout(Vector2 screenSize) {
    final layout = BoardLayout.fit(
        _contentBounds, level.gridSize, Size(screenSize.x, screenSize.y));
    return (layout.gridPixelSize, layout.origin.dx, layout.origin.dy);
  }

  /// Reset board to initial state (restart level)
  void resetLevel() {
    gameState.resetLevel();
    gridComponent?.rebuild();
  }
}

import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/board_style.dart';
import '../../core/constants.dart';
import '../../core/app_colors.dart';
import '../../data/models/level.dart';
import '../../data/models/arrow.dart';
import '../game_state.dart';
import 'arrow_component.dart';
import 'floating_text_component.dart';
import 'particle_effect.dart';

/// Renders the puzzle grid, mask boundary dots, and all arrow components.
///
/// IMPORTANT: the mask used for RENDERING must match the mask used when the
/// level was generated.  We regenerate it from the stored [MaskShape] so we
/// never drift between generator and renderer.
class GridComponent extends PositionComponent {
  final GameState gameState;
  double gridPixelSize;

  final Map<String, ArrowComponent> _arrowComponents = {};
  late Set<String> _mask;
  late LevelType _levelType;
  int _minR = 0, _maxR = 0, _minC = 0, _maxC = 0;

  static const double _kShakeDuration = 0.28;
  double _shakeTime = 0.0;
  final Vector2 _shakeBase = Vector2.zero();

  ui.Picture? _cachedDotGridPicture;
  bool _isDarkCached = AppColors.isDark;
  BoardTheme? _cachedTheme;

  void _invalidateDotGrid() {
    _cachedDotGridPicture?.dispose();
    _cachedDotGridPicture = null;
  }

  @override
  void onRemove() {
    _invalidateDotGrid();
    super.onRemove();
  }

  GridComponent({
    required this.gameState,
    required this.gridPixelSize,
    required Vector2 position,
  }) : super(position: position);

  double get cellSize => gridPixelSize / gameState.level.gridSize;

  @override
  Future<void> onLoad() async {
    size = Vector2.all(gridPixelSize);
    _levelType = AppConstants.levelTypeFor(gameState.level.levelNumber);
    _refreshMask();
    _buildArrows();
  }

  // ── Mask ──────────────────────────────────────────────────────────────────

  /// Rebuilds the mask from the stored MaskShape on the level model.
  /// Uses a deterministic seed derived from level + shape so the shape
  /// is always the same instance for this level (blob needs a seed).
  void _refreshMask() {
    _mask = gameState.level.mask;
    final n = gameState.level.gridSize;
    _minR = 0;
    _minC = 0;
    _maxR = n - 1;
    _maxC = n - 1;
    if (_mask.isEmpty) return;
    int minR = n, maxR = -1, minC = n, maxC = -1;
    for (final cell in _mask) {
      final parts = cell.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      if (r < minR) minR = r;
      if (r > maxR) maxR = r;
      if (c < minC) minC = c;
      if (c > maxC) maxC = c;
    }
    if (maxR < 0) return;
    _minR = minR;
    _maxR = maxR;
    _minC = minC;
    _maxC = maxC;
  }

  /// Pixel bounds of the playable shape (not the full square grid).
  Rect get boardRect => Rect.fromLTRB(_minC * cellSize, _minR * cellSize,
      (_maxC + 1) * cellSize, (_maxR + 1) * cellSize);

  // ── Effects ───────────────────────────────────────────────────────────────

  void shake() {
    if (_shakeTime <= 0) _shakeBase.setFrom(position);
    _shakeTime = _kShakeDuration;
  }

  double get _effectScale => (cellSize / 24).clamp(0.6, 1.4);

  void spawnExitBurst(Offset at, Color color) {
    add(ExitParticleEffect(
      position: Vector2(at.dx, at.dy),
      color: color,
      scale: _effectScale,
    ));
  }

  void spawnFloatingText(Offset at, String text, Color color) {
    final r = boardRect.deflate(cellSize * 0.8);
    final x = r.width > 0 ? at.dx.clamp(r.left, r.right) : at.dx;
    final y = r.height > 0 ? at.dy.clamp(r.top, r.bottom) : at.dy;
    add(FloatingTextComponent(
      text: text,
      color: color,
      position: Vector2(x.toDouble(), y.toDouble()),
      fontSize: (cellSize * 0.9).clamp(15.0, 26.0),
    ));
  }

  // ── Arrow components ──────────────────────────────────────────────────────

  void _buildArrows() {
    removeAll(children.whereType<ArrowComponent>());
    _arrowComponents.clear();

    for (final arrow in gameState.arrows) {
      final comp = ArrowComponent(
        arrowModel: arrow,
        cellSize: cellSize,
        gameState: gameState,
        levelType: _levelType,
      )..position = Vector2(0, 0);
      _arrowComponents[arrow.id] = comp;
      add(comp);
    }
  }

  void rebuild() {
    _refreshMask();
    _buildArrows();
    _invalidateDotGrid();
  }

  void resize(double newGridPixelSize) {
    gridPixelSize = newGridPixelSize;
    size = Vector2.all(gridPixelSize);
    _shakeTime = 0;
    for (final child in children) {
      if (child is ArrowComponent) child.updateCellSize(cellSize);
    }
    _invalidateDotGrid();
  }

  void _recacheDotGrid() {
    _cachedDotGridPicture?.dispose();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final gridSize = gameState.level.gridSize;
    final cs = cellSize;
    final baseDot = (cs * 0.045).clamp(0.6, 1.6);
    final inR = baseDot;

    final theme = gameState.boardTheme;
    final wash = BoardStyle.cellWash(theme);
    final inPaint = Paint()
      ..color = BoardStyle.dotColor(theme, AppColors.isDark)
      ..style = PaintingStyle.fill;
    final washPaint = Paint()..color = wash;

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final inMask = _mask.contains('$r,$c');
        if (!inMask) continue; // Only render active grid dots inside the mask!

        if (wash.a > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cs, r * cs, cs, cs),
              Radius.circular(cs * 0.18),
            ),
            washPaint,
          );
        }
        canvas.drawCircle(
          Offset((c + 0.5) * cs, (r + 0.5) * cs),
          inR,
          inPaint,
        );
      }
    }

    _cachedDotGridPicture = recorder.endRecording();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  RENDER
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void render(Canvas canvas) {
    final cs = cellSize;

    if (_cachedDotGridPicture == null ||
        _isDarkCached != AppColors.isDark ||
        _cachedTheme != gameState.boardTheme) {
      _isDarkCached = AppColors.isDark;
      _cachedTheme = gameState.boardTheme;
      _recacheDotGrid();
    }
    canvas.drawPicture(_cachedDotGridPicture!);

    // ── Orphan deflector dots (drawn on top of background dots) ────────────
    final orphanDots = gameState.orphanDots;
    for (final entry in orphanDots.entries) {
      final parts = entry.key.split(',');
      final dotR = int.parse(parts[0]);
      final dotC = int.parse(parts[1]);
      _drawOrphanDot(canvas, Offset((dotC + 0.5) * cs, (dotR + 0.5) * cs),
          entry.value, cs);
    }

    super.render(canvas);
  }

  static void _drawOrphanDot(
      Canvas canvas, Offset center, OrphanDotType type, double cs) {
    if (type == OrphanDotType.neutral) return; // Neutral empty dots can be left empty

    const Color baseColor = Color(0xFFFFAA00); // Gold/orange redirect plate

    // Solid dot body (plate) - enlarged to be highly visible
    canvas.drawCircle(
      center,
      cs * 0.36, // Much larger plate (72% of cell size!)
      Paint()
        ..color = baseColor
        ..style = PaintingStyle.fill,
    );

    // Darker outline for contrast
    canvas.drawCircle(
      center,
      cs * 0.36,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cs * 0.045,
    );

    // Drawing the arrow in the middle of the gold plate
    if (type != OrphanDotType.neutral) {
      final ArrowDirection dir;
      switch (type) {
        case OrphanDotType.up:
          dir = ArrowDirection.up;
          break;
        case OrphanDotType.down:
          dir = ArrowDirection.down;
          break;
        case OrphanDotType.left:
          dir = ArrowDirection.left;
          break;
        case OrphanDotType.right:
          dir = ArrowDirection.right;
          break;
        default:
          return;
      }

      final double angle = dir.rotationRadians; // Right is 0 rad

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final linePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = cs * 0.075 // Thick lines
        ..strokeCap = StrokeCap.round;

      // Draw the arrow shaft in the middle
      canvas.drawLine(Offset(-cs * 0.22, 0), Offset(cs * 0.06, 0), linePaint);

      // Draw a large centered arrowhead pointing right
      final arrowheadPath = Path()
        ..moveTo(cs * 0.28, 0) // Tip of the arrow
        ..lineTo(cs * 0.04, -cs * 0.18) // Back corner top
        ..lineTo(cs * 0.10, 0) // Recess center point
        ..lineTo(cs * 0.04, cs * 0.18) // Back corner bottom
        ..close();

      canvas.drawPath(
        arrowheadPath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      canvas.restore();
    } else {
      // Draw a small solid white dot in the center of neutral dots for a clean focal point
      canvas.drawCircle(
        center,
        cs * 0.075,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.fill,
      );
    }
  }



  // ── Update ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeTime > 0) {
      _shakeTime = (_shakeTime - dt).clamp(0.0, _kShakeDuration);
      final t = 1 - _shakeTime / _kShakeDuration;
      final amp = (cellSize * 0.18).clamp(3.0, 7.0) * (1 - t);
      position.setValues(
          _shakeBase.x + sin(t * pi * 9) * amp, _shakeBase.y + sin(t * pi * 7) * amp * 0.35);
      if (_shakeTime == 0) position.setFrom(_shakeBase);
    }
    if (_arrowComponents.length != gameState.arrows.length) {
      final current = gameState.arrows.map((a) => a.id).toSet();
      final gone =
          _arrowComponents.keys.where((id) => !current.contains(id)).toList();
      for (final id in gone) {
        _arrowComponents[id]?.removeFromParent();
        _arrowComponents.remove(id);
      }
    }
  }
}

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../core/board_style.dart';
import '../../core/constants.dart';
import '../../core/app_colors.dart';
import '../../data/models/arrow.dart';
import '../../data/models/level.dart';
import '../arrow_puzzle_game.dart';
import '../game_state.dart';
import 'arrow_visual_config.dart';
import 'grid_component.dart';

/// Renders a multi-cell arrow that winds through the grid.
///
/// path[0] = HEAD (carries the arrowhead triangle, exits first)
/// path[last] = TAIL (exits last — the "rope pulled through" effect)
///
/// Tapping anywhere on the body initiates a head-first sliding exit:
/// the arrowhead pulls out in the arrow's direction, the body follows
/// segment by segment, and the tail disappears last.
///
/// LONG PRESS: holding for 300 ms shows a dashed glowing preview of the
/// arrow's exit path through any deflection dots to the board edge.
class ArrowComponent extends PositionComponent with TapCallbacks, HasPaint {
  ArrowModel arrowModel;
  double cellSize;
  final GameState gameState;
  final LevelType levelType;

  bool _isAnimating = false;
  bool _isBlockedAnimating = false;
  double _blockDuration = 0.0;
  double _blockTime = 0.0;
  double _maxBlockSlide = 0.0;
  double _slideOffset = 0.0;
  // The model stays `blocked` longer than the bump animation lasts; without
  // this latch the state sync would replay the bump until it resets to idle.
  bool _blockPlayed = false;
  Offset? _blockContact;
  bool _blockPulseDone = false;

  // ── Long-press preview ─────────────────────────────────────────────────────────────
  static const double _kLongPressThreshold = 0.30; // 300 ms
  double _longPressAccum = 0.0;
  bool _isTouchDown = false;
  bool _isPreviewMode = false;
  List<Offset>? _previewPath; // pixel coords from head-step-1 → off-screen
  double _previewPhase = 0.0; // marching-ants animation phase (0–1)

  // ── Exit state ──────────────────────────────────────────────────────────────────
  bool _isExiting = false;
  double _exitProgress = 0.0;
  double _exitDuration = 0.35;

  // ── Erase (eraser power-up) ─────────────────────────────────────────────────────
  static const double _kEraseDuration = 0.3;
  bool _isErasing = false;
  double _eraseProgress = 0.0;

  // ── Juice ───────────────────────────────────────────────────────────────────────
  double _pressScale = 1.0;
  bool _exitBurstDone = false;
  int _exitCombo = 0;
  double _blockerFlash = 0;
  double _activateFlash = 0;
  double _fxTime = 0;
  double _lastDt = 0;
  double? _headAngle;

  GridComponent? get _grid {
    final p = parent;
    return p is GridComponent ? p : null;
  }

  /// Pre-built deflected exit track (farthest → head), null = straight exit
  List<Offset>? _deflectedExtension;

  // ── Caching for static paths and coordinates ─────────────────────────────
  List<Offset>? _cachedPathPx;
  List<Offset>? _cachedTrack;
  List<double>? _cachedDist;
  double? _cachedHeadDist;
  double? _cachedTailDist;
  Path? _cachedBodyPath;

  final Paint _bodyPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;
  final Paint _headFillPaint = Paint()..isAntiAlias = true;
  final Paint _headEdgePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;
  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  void _invalidateCache() {
    _cachedPathPx = null;
    _cachedTrack = null;
    _cachedDist = null;
    _cachedHeadDist = null;
    _cachedTailDist = null;
    _cachedBodyPath = null;
  }

  bool _arePathsEqual(List<List<int>> a, List<List<int>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i][0] != b[i][0] || a[i][1] != b[i][1]) return false;
    }
    return true;
  }

  // Group colors for colorLock / colorKey pairs are retrieved dynamically from AppColors.getGroupColor

  ArrowComponent({
    required this.arrowModel,
    required this.cellSize,
    required this.gameState,
    this.levelType = LevelType.normal,
  }) : super(size: Vector2.all(cellSize * gameState.level.gridSize));

  void updateCellSize(double newSize) {
    cellSize = newSize;
    size = Vector2.all(newSize * gameState.level.gridSize);
    _invalidateCache();
  }

  // ── Hit test: tap anywhere along the arrow body ───────────────────────────

  @override
  bool containsLocalPoint(Vector2 point) {
    if (_isExiting || _isErasing) return false;
    // Cells are packed tighter than the arrow is thick, so the tap target
    // stays the size it had before the spacing change.
    final margin = cellSize *
        ((1.5 / AppConstants.boardCellSpacing - 1) / 2);
    for (final pt in arrowModel.path) {
      final cellLeft = pt[1] * cellSize - margin;
      final cellRight = (pt[1] + 1) * cellSize + margin;
      final cellTop = pt[0] * cellSize - margin;
      final cellBottom = (pt[0] + 1) * cellSize + margin;
      if (point.x >= cellLeft &&
          point.x <= cellRight &&
          point.y >= cellTop &&
          point.y <= cellBottom) {
        return true;
      }
    }
    return false;
  }

  @override
  void onTapDown(TapDownEvent event) {
    _isTouchDown = true;
    _longPressAccum = 0.0;
  }

  @override
  void onTapUp(TapUpEvent event) {
    final wasPreview = _isPreviewMode;
    _isTouchDown = false;
    _longPressAccum = 0.0;
    _isPreviewMode = false;
    _previewPath = null;
    if (wasPreview) return; // long-press released — don’t trigger a move
    if (_isAnimating) return;
    _triggerMove();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _isTouchDown = false;
    _longPressAccum = 0.0;
    _isPreviewMode = false;
    _previewPath = null;
  }

  void _triggerMove() {
    if (_isAnimating) return;
    _isAnimating = true;

    final result = gameState.tapArrow(arrowModel.id);
    switch (result) {
      case TapResult.exited:
        _startExitAnimation();
        break;
      case TapResult.blocked:
        _playBlockAnimation();
        final head = arrowModel.path.first;
        _grid?.spawnFloatingText(
          Offset((head[1] + 0.5) * cellSize, (head[0] + 0.5) * cellSize),
          '-1 ♥',
          const Color(0xFFFF5252),
        );
        break;
      case TapResult.locked:
        _playLockedAnimation();
        break;
      case TapResult.ignored:
        _isAnimating = false;
        break;
      case TapResult.erased:
        _isErasing = true;
        _eraseProgress = 0.0;
        _grid?.spawnExitBurst(_pathCenter(_pathPx()), const Color(0xFFFF8A80));
        break;
    }
  }

  List<Offset> _pathPx() => _cachedPathPx ??= arrowModel.path
      .map((pt) => Offset((pt[1] + 0.5) * cellSize, (pt[0] + 0.5) * cellSize))
      .toList();

  // ── Exit: head-first pull-through ────────────────────────────────────────

  void _startExitAnimation() {
    _exitDuration = min(0.4 + arrowModel.path.length * 0.08, 1.4);
    _exitProgress = 0.0;
    _isExiting = true;
    _exitBurstDone = false;
    _exitCombo = gameState.combo;
    _activateFlash = 1.0;
    _headAngle = null;
    _deflectedExtension = _buildDeflectedExtension();
    _invalidateCache();
  }

  /// Eased share of the track already travelled: starts moving on the first
  /// frame (initial speed 0.6×) and accelerates as the arrow pulls out.
  double get _exitTravel {
    final t = _exitProgress.clamp(0.0, 1.0);
    return 0.6 * t + 0.4 * t * t;
  }

  /// Pre-computes the full exit track for arrows that pass through orphan dots.
  /// Returns a list of Offsets from FARTHEST point → first-step-from-head,
  /// or null if the exit is a plain straight line.
  List<Offset>? _buildDeflectedExtension() {
    final orphanDots = Map<String, OrphanDotType>.from(gameState.orphanDots);
    for (final dot in gameState.getConsumedDotsForArrow(arrowModel.id)) {
      orphanDots[dot.key] = dot.type;
    }
    if (orphanDots.isEmpty) return null;

    ArrowDirection currentDir = arrowModel.direction;
    final head = arrowModel.path[0];
    final gridSize = gameState.level.gridSize;
    final pts = <Offset>[];
    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final visited = <String>{};
    bool hasDeflection = false;

    while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
      final key = '$nr,$nc';
      if (visited.contains(key)) break;
      visited.add(key);
      pts.add(Offset((nc + 0.5) * cellSize, (nr + 0.5) * cellSize));

      if (orphanDots.containsKey(key)) {
        final dotType = orphanDots[key]!;
        if (dotType == OrphanDotType.up) {
          hasDeflection = true;
          currentDir = ArrowDirection.up;
        } else if (dotType == OrphanDotType.down) {
          hasDeflection = true;
          currentDir = ArrowDirection.down;
        } else if (dotType == OrphanDotType.left) {
          hasDeflection = true;
          currentDir = ArrowDirection.left;
        } else if (dotType == OrphanDotType.right) {
          hasDeflection = true;
          currentDir = ArrowDirection.right;
        }
      }

      d = currentDir.delta;
      nr += d[0];
      nc += d[1];
    }

    if (!hasDeflection) return null;

    // Pad a few off-screen cells in the final direction so the tail fully exits
    for (int i = 0; i <= 5; i++) {
      pts.add(Offset(
          (nc + d[1] * i + 0.5) * cellSize, (nr + d[0] * i + 0.5) * cellSize));
    }

    return pts.reversed.toList(); // farthest → closest to head
  }

  // ── Block: direction-aware shake ──────────────────────────────────────────

  List<Offset> _buildBlockedExtension() {
    ArrowDirection currentDir = arrowModel.direction;
    final head = arrowModel.path[0];
    final gridSize = gameState.level.gridSize;
    final pts = <Offset>[];
    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final visited = <String>{};
    _blockContact = null;

    while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
      final key = '$nr,$nc';
      if (visited.contains(key)) break;
      visited.add(key);

      // Check if blocked by another arrow
      bool occupied = false;
      for (final other in gameState.arrows) {
        if (other.id == arrowModel.id) continue;
        if (other.state == ArrowState.sliding) continue;
        for (final pt in other.path) {
          if (pt[0] == nr && pt[1] == nc) {
            occupied = true;
            break;
          }
        }
        if (occupied) break;
      }

      if (occupied) {
        final from = pts.isNotEmpty
            ? pts.last
            : Offset((head[1] + 0.5) * cellSize, (head[0] + 0.5) * cellSize);
        final hit = Offset((nc + 0.5) * cellSize, (nr + 0.5) * cellSize);
        _blockContact = Offset.lerp(from, hit, 0.5);
        break;
      }

      pts.add(Offset((nc + 0.5) * cellSize, (nr + 0.5) * cellSize));

      if (gameState.orphanDots.containsKey(key)) {
        final dotType = gameState.orphanDots[key]!;
        if (dotType == OrphanDotType.up) {
          currentDir = ArrowDirection.up;
        } else if (dotType == OrphanDotType.down) {
          currentDir = ArrowDirection.down;
        } else if (dotType == OrphanDotType.left) {
          currentDir = ArrowDirection.left;
        } else if (dotType == OrphanDotType.right) {
          currentDir = ArrowDirection.right;
        }
      }

      d = currentDir.delta;
      nr += d[0];
      nc += d[1];
    }

    // Always add overshoot in final direction
    final lastPoint = pts.isNotEmpty
        ? pts.last
        : Offset((head[1] + 0.5) * cellSize, (head[0] + 0.5) * cellSize);
    final overshootPoint =
        lastPoint + Offset(d[1] * cellSize * 0.25, d[0] * cellSize * 0.25);
    pts.add(overshootPoint);

    return pts.reversed.toList();
  }

  void _playBlockAnimation() {
    _invalidateCache();

    if (_cachedPathPx == null) {
      _cachedPathPx = arrowModel.path
          .map((pt) =>
              Offset((pt[1] + 0.5) * cellSize, (pt[0] + 0.5) * cellSize))
          .toList();
    }
    final pathPx = _cachedPathPx!;
    final blockedExt = _buildBlockedExtension();
    final track = <Offset>[...blockedExt, ...pathPx];
    final dist = <double>[0.0];
    for (int i = 1; i < track.length; i++) {
      dist.add(dist[i - 1] + (track[i] - track[i - 1]).distance);
    }

    _cachedTrack = track;
    _cachedDist = dist;
    _cachedHeadDist = dist[blockedExt.length];
    _cachedTailDist = dist[blockedExt.length + arrowModel.path.length - 1];

    _maxBlockSlide = _cachedHeadDist!;
    _blockDuration = 0.12 + (blockedExt.length - 1) * 0.06;
    _blockTime = 0.0;
    _isBlockedAnimating = true;
    _blockPlayed = true;
    _blockPulseDone = false;
    _headAngle = null;
  }

  // ── ColorLock: lateral rattle ─────────────────────────────────────────────

  void _playLockedAnimation() {
    final ox = position.x, oy = position.y;
    add(SequenceEffect([
      MoveEffect.to(Vector2(ox + 4, oy), EffectController(duration: 0.06)),
      MoveEffect.to(Vector2(ox - 4, oy), EffectController(duration: 0.06)),
      MoveEffect.to(Vector2(ox + 3, oy), EffectController(duration: 0.05)),
      MoveEffect.to(Vector2(ox - 3, oy), EffectController(duration: 0.05)),
      MoveEffect.to(Vector2(ox, oy), EffectController(duration: 0.04)),
    ], onComplete: () => _isAnimating = false));
  }

  // ── Update ────────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    _lastDt = dt;
    _fxTime += dt;
    if (_activateFlash > 0) {
      _activateFlash = max(0.0, _activateFlash - dt / 0.18);
    }

    if (gameState.blockerIds.contains(arrowModel.id)) {
      _blockerFlash += dt * 16;
    } else if (_blockerFlash != 0) {
      _blockerFlash = 0;
    }

    // ── Long-press accumulator ──────────────────────────────────────────────
    if (_isTouchDown && !_isAnimating && !_isExiting) {
      _longPressAccum += dt;
      if (!_isPreviewMode && _longPressAccum >= _kLongPressThreshold) {
        _isPreviewMode = true;
        _previewPath = _buildPreviewPath();
      }
    }
    if (_isPreviewMode) {
      _previewPhase = (_previewPhase + dt * 1.4) % 1.0; // march speed
    }

    final pressTarget =
        (_isTouchDown && !_isAnimating && !_isExiting)
            ? ArrowVisualConfig.pressedScale
            : 1.0;
    _pressScale += (pressTarget - _pressScale) *
        (dt * ArrowVisualConfig.pressResponse).clamp(0.0, 1.0);

    if (_isErasing) {
      _eraseProgress += dt / _kEraseDuration;
      if (_eraseProgress >= 1.0) {
        removeFromParent();
        gameState.handleArrowExitCompleted(arrowModel.id);
      }
      return;
    }

    if (_isExiting) {
      _exitProgress += dt / _exitDuration;
      if (!_exitBurstDone) _checkExitBurst();
      if (_exitProgress >= 1.0) {
        removeFromParent();
        gameState.handleArrowExitCompleted(arrowModel.id);
        return;
      }
    }

    if (_isBlockedAnimating) {
      _blockTime += dt;
      final half = _blockDuration / 2;
      if (!_blockPulseDone && _blockTime >= half * 0.8) {
        _blockPulseDone = true;
        final contact = _blockContact;
        if (contact != null) {
          _grid?.spawnImpactPulse(contact, const Color(0xFFCC2200));
        }
      }
      if (_blockTime < half) {
        final t = _blockTime / half;
        _slideOffset = Curves.easeOut.transform(t) * _maxBlockSlide;
      } else if (_blockTime < _blockDuration) {
        final t = (_blockTime - half) / half;
        _slideOffset = (1.0 - Curves.easeIn.transform(t)) * _maxBlockSlide;
      } else {
        _slideOffset = 0.0;
        _isBlockedAnimating = false;
        _isAnimating = false;
        _invalidateCache();
      }
    }

    if (_isExiting || _isBlockedAnimating) {
      return; // Skip syncing if animating exit or block
    }

    // Sync model from game state (picks up mechanic/state changes)
    ArrowModel? updated;
    final list = gameState.arrows;
    for (int i = 0; i < list.length; i++) {
      if (list[i].id == arrowModel.id) {
        updated = list[i];
        break;
      }
    }

    if (updated != null) {
      if (updated.state == ArrowState.idle) _blockPlayed = false;
      if (updated.state == ArrowState.sliding && !_isExiting && !_isAnimating) {
        _isAnimating = true;
        _startExitAnimation();
        if (gameState.lastWandArrowId == arrowModel.id) {
          _grid?.spawnExitBurst(_pathPx().first, AppColors.accentGold);
        }
      } else if (updated.state == ArrowState.blocked &&
          !_isAnimating &&
          !_blockPlayed) {
        _isAnimating = true;
        _playBlockAnimation();
      }
      if (updated.state != arrowModel.state ||
          updated.direction != arrowModel.direction ||
          !_arePathsEqual(updated.path, arrowModel.path)) {
        _invalidateCache();
      }
      arrowModel = updated;
    }
  }

  /// Fires the particle burst (and combo label) once the head crosses the
  /// edge of the visible shape, so it lands where the player is looking.
  void _checkExitBurst() {
    final track = _cachedTrack;
    final dist = _cachedDist;
    final grid = _grid;
    if (track == null || dist == null || grid == null) return;
    final headDist = _cachedHeadDist!;
    final tailDist = _cachedTailDist!;
    final traveled = (_exitTravel * tailDist).clamp(0.0, tailDist);
    final headPos =
        _lerp(track, dist, (headDist - traveled).clamp(0.0, headDist));
    final bounds = grid.boardRect;
    if (bounds.inflate(cellSize * 0.3).contains(headPos)) return;

    _exitBurstDone = true;
    final at = Offset(
      headPos.dx.clamp(bounds.left, bounds.right),
      headPos.dy.clamp(bounds.top, bounds.bottom),
    );
    final color = _color();
    grid.spawnExitBurst(at, color);
    if (AppConstants.isComboMilestone(_exitCombo)) {
      grid.spawnFloatingText(
        at,
        _exitCombo >= 15
            ? ((findGame() as ArrowPuzzleGame?)?.comboPerfectLabel ??
                'Perfect!')
            : 'x$_exitCombo',
        const Color(0xFFFFC107),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  RENDER
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void render(Canvas canvas) {
    if (!_isErasing) {
      _renderArrow(canvas);
      return;
    }
    final p = _eraseProgress.clamp(0.0, 1.0);
    final c = _pathCenter(_pathPx());
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1 - 0.18 * Curves.easeIn.transform(p));
    canvas.translate(-c.dx, -c.dy);
    canvas.saveLayer(
        null, Paint()..color = Colors.white.withValues(alpha: 1.0 - p));
    _renderArrow(canvas);
    canvas.restore();
    canvas.restore();
  }

  void _renderArrow(Canvas canvas) {
    if (arrowModel.path.isEmpty) return;

    // ── 1. Resolve pathPx ─────────────────────────────────────────────────────
    if (_cachedPathPx == null) {
      _cachedPathPx = arrowModel.path
          .map((pt) =>
              Offset((pt[1] + 0.5) * cellSize, (pt[0] + 0.5) * cellSize))
          .toList();
    }
    final pathPx = _cachedPathPx!;

    final List<Offset> pts;
    final bool isAnimatingNow = _isExiting || _isBlockedAnimating;

    if (isAnimatingNow) {
      // ── 2. Build or retrieve the extended track for exit animation ───
      if (_cachedTrack == null) {
        final delta = arrowModel.direction.delta;
        final headPx = pathPx.first;

        final track = <Offset>[];
        final int extCount;
        if (_deflectedExtension != null) {
          track.addAll(_deflectedExtension!);
          extCount = _deflectedExtension!.length;
        } else {
          extCount = gameState.level.gridSize + 2;
          for (int i = extCount; i >= 1; i--) {
            track.add(headPx +
                Offset(delta[1] * i * cellSize, delta[0] * i * cellSize));
          }
        }
        track.addAll(pathPx);
        _cachedTrack = track;

        // ── 3. Cumulative distances along the track ─────────────────────────────────────
        final dist = <double>[0.0];
        for (int i = 1; i < track.length; i++) {
          dist.add(dist[i - 1] + (track[i] - track[i - 1]).distance);
        }
        _cachedDist = dist;
        _cachedHeadDist = dist[extCount];
        _cachedTailDist = dist[extCount + arrowModel.path.length - 1];
      }

      final track = _cachedTrack!;
      final dist = _cachedDist!;
      final headDist = _cachedHeadDist!;
      final tailDist = _cachedTailDist!;

      // ── 4. Compute animated head/tail positions ─────────────────────────────────────
      final double animHead, animTail;
      if (_isExiting) {
        final traveled = (_exitTravel * tailDist).clamp(0.0, tailDist);
        animHead = (headDist - traveled).clamp(0.0, headDist);
        animTail = (tailDist - traveled).clamp(0.0, tailDist);
      } else {
        final traveled = _slideOffset.clamp(0.0, tailDist);
        animHead = (headDist - traveled).clamp(0.0, headDist);
        animTail = (tailDist - traveled).clamp(0.0, tailDist);
      }

      pts = _slice(track, dist, animHead, animTail);

      if (_isExiting) {
        _drawExitTrail(canvas, track, dist, animTail, tailDist);
      }

      // Draw consumed orphan dots that the arrow head hasn't reached yet
      if (_isExiting) {
        final consumedDots = gameState.getConsumedDotsForArrow(arrowModel.id);
        for (final dot in consumedDots) {
          final dotPx =
              Offset((dot.col + 0.5) * cellSize, (dot.row + 0.5) * cellSize);
          double? dotDist;
          for (int i = 0; i < track.length; i++) {
            if ((track[i] - dotPx).distanceSquared < 0.01) {
              dotDist = dist[i];
              break;
            }
          }
          if (dotDist != null && animHead > dotDist) {
            _drawOrphanDot(canvas, dotPx, dot.type, cellSize);
          }
        }
      }
    } else {
      // Bypass track calculations entirely if stationary
      pts = pathPx;
    }

    if (pts.isEmpty) return;

    // ── 5. Resolve color and stroke width ─────────────────────────────────────────────
    final baseColor = _color();
    final mainColor = _isExiting
        ? Color.lerp(
            baseColor,
            Colors.white,
            ArrowVisualConfig.exitLighten +
                ArrowVisualConfig.exitFlashLighten * _activateFlash)!
        : baseColor;
    final sw = ArrowVisualConfig.shaftWidth(cellSize);
    final heading = _headingVector(pts, smooth: isAnimatingNow);

    canvas.save();
    if (_pressScale < 0.999 || _isBlockedAnimating) {
      final c = _pathCenter(pathPx);
      canvas.translate(c.dx, c.dy);
      if (_pressScale < 0.999) canvas.scale(_pressScale);
      if (_isBlockedAnimating && _blockDuration > 0) {
        final damp = 1 - (_blockTime / _blockDuration).clamp(0.0, 1.0);
        canvas.rotate(sin(_blockTime * ArrowVisualConfig.blockShakeFrequency) *
            ArrowVisualConfig.blockShakeAngle *
            damp);
      }
      canvas.translate(-c.dx, -c.dy);
    }

    // ── 6. Draw body ──────────────────────────────────────────────────────
    // The shaft stops inside the head so the two overlap without a seam.
    final Path bodyPath;
    if (isAnimatingNow) {
      bodyPath = _shaftPath(pts, heading);
    } else {
      _cachedBodyPath ??= _shaftPath(pts, heading);
      bodyPath = _cachedBodyPath!;
    }

    if (gameState.blockerIds.contains(arrowModel.id)) {
      final pulse = (sin(_blockerFlash) + 1) / 2;
      canvas.drawPath(
        bodyPath,
        _glowPaint
          ..color =
              const Color(0xFFFF1744).withValues(alpha: 0.25 + 0.35 * pulse)
          ..strokeWidth =
              ArrowVisualConfig.unit(cellSize) *
                  ArrowVisualConfig.blockerGlowWidthRatio
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
      );
    } else if (!isAnimatingNow && gameState.hintArrowId == arrowModel.id) {
      final pulse = (sin(_fxTime * 4.5) + 1) / 2;
      canvas.drawPath(
        bodyPath,
        _glowPaint
          ..color =
              const Color(0xFFFFC107).withValues(alpha: 0.18 + 0.22 * pulse)
          ..strokeWidth =
              ArrowVisualConfig.unit(cellSize) *
                  ArrowVisualConfig.hintGlowWidthRatio
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
      );
    }

    if (_isExiting) {
      canvas.drawCircle(
        pts.first,
        cellSize * 0.34,
        Paint()
          ..color = baseColor.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );
    }

    canvas.drawPath(
      bodyPath,
      _bodyPaint
        ..color = mainColor
        ..strokeWidth = sw,
    );

    // ── 7. Draw arrowhead at the head end (pts.first) ──────────────────────────────
    _drawHead(canvas, pts.first, heading, mainColor);
    if (arrowModel.mechanic == SnakeMechanic.colorLock) {
      _drawLockTail(canvas, pts.last, mainColor);
    }

    canvas.restore();

    // ── 8. Long-press preview overlay ────────────────────────────────────────────
    if (_isPreviewMode) {
      final preview = _previewPath;
      if (preview != null && preview.length >= 2) {
        final isBlocked = gameState.isArrowBlocked(arrowModel.id);
        _drawPreviewPath(canvas, preview, isBlocked);
      }
    }
  }

  Offset _pathCenter(List<Offset> pathPx) {
    double minX = pathPx.first.dx, maxX = minX;
    double minY = pathPx.first.dy, maxY = minY;
    for (final p in pathPx) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Offset((minX + maxX) / 2, (minY + maxY) / 2);
  }

  /// Glowing streak over the cells the tail just vacated, brightest nearest
  /// the tail so it reads as motion toward the exit.
  void _drawExitTrail(Canvas canvas, List<Offset> track, List<double> dist,
      double animTail, double tailDist) {
    final trailLen = cellSize * 2.4;
    final end = (animTail + trailLen).clamp(animTail, tailDist);
    if (end - animTail < 0.5) return;
    final color = _color();
    const segments = 3;
    final segLen = (end - animTail) / segments;
    for (int i = 0; i < segments; i++) {
      final from = animTail + segLen * i;
      final seg = _slice(track, dist, from, from + segLen);
      if (seg.length < 2) continue;
      final path = Path()..moveTo(seg.first.dx, seg.first.dy);
      for (int j = 1; j < seg.length; j++) {
        path.lineTo(seg[j].dx, seg[j].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.38 * (1 - i / segments))
          ..style = PaintingStyle.stroke
          ..strokeWidth = cellSize * (0.34 - i * 0.07)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
      );
    }
  }

  // ── Arrow shape ───────────────────────────────────────────────────────────
  // A round-capped shaft with rounded bends whose end sits inside a filled
  // triangle. The triangle is stroked as well, which rounds its corners.
  // All sizes come from ArrowVisualConfig.

  Offset _headingVector(List<Offset> pts, {required bool smooth}) {
    // The first vertex far enough from the head gives the real direction;
    // a vertex sitting on the head (mid-slide) would fall back to the
    // model's direction, which is wrong after a deflector.
    var dx = arrowModel.direction.delta[1].toDouble();
    var dy = arrowModel.direction.delta[0].toDouble();
    for (var i = 1; i < pts.length; i++) {
      final dv = pts.first - pts[i];
      final len = dv.distance;
      if (len > 0.01) {
        dx = dv.dx / len;
        dy = dv.dy / len;
        break;
      }
    }

    if (!smooth) {
      _headAngle = null;
      return Offset(dx, dy);
    }

    // Ease onto the new heading instead of snapping 90° at a deflector.
    final target = atan2(dy, dx);
    final current = _headAngle;
    if (current == null) {
      _headAngle = target;
      return Offset(dx, dy);
    }
    var diff = target - current;
    while (diff > pi) {
      diff -= 2 * pi;
    }
    while (diff < -pi) {
      diff += 2 * pi;
    }
    final k = 1 - exp(-_lastDt * ArrowVisualConfig.headTurnRate);
    final next = current + diff * k;
    _headAngle = next;
    return Offset(cos(next), sin(next));
  }

  /// Shaft centre-line: the path trimmed along its own length by the head
  /// inset (so it never backtracks past a bend next to the head), with every
  /// turn replaced by a circular bend of the shared corner radius.
  Path _shaftPath(List<Offset> pts, Offset heading) {
    final inset = ArrowVisualConfig.headInset(cellSize);
    if (pts.length == 1) {
      final head = ArrowVisualConfig.headLength(cellSize);
      final start = pts.first - heading * inset;
      final tail = pts.first -
          heading * (head * ArrowVisualConfig.singleCellTailFraction);
      return Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(tail.dx, tail.dy);
    }
    final shaft = ArrowVisualConfig.trimStart(pts, inset);
    if (shaft.length < 2) return Path();
    return ArrowVisualConfig.roundedPolyline(
        shaft, ArrowVisualConfig.cornerRadius(cellSize));
  }

  void _drawHead(Canvas canvas, Offset tip, Offset heading, Color color) {
    final length = ArrowVisualConfig.headLength(cellSize);
    final half = ArrowVisualConfig.headHalfWidth(cellSize);
    final across = Offset(-heading.dy, heading.dx);
    final back = tip - heading * length;
    final triangle = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(back.dx + across.dx * half, back.dy + across.dy * half)
      ..lineTo(back.dx - across.dx * half, back.dy - across.dy * half)
      ..close();

    canvas.drawPath(triangle, _headFillPaint..color = color);
    canvas.drawPath(
      triangle,
      _headEdgePaint
        ..color = color
        ..strokeWidth = ArrowVisualConfig.headRounding(cellSize),
    );
  }

  void _drawLockTail(Canvas canvas, Offset tail, Color color) {
    final unit = ArrowVisualConfig.unit(cellSize);
    canvas.drawCircle(
      tail,
      unit * ArrowVisualConfig.lockRingOuterRatio,
      _headFillPaint..color = Colors.white,
    );
    canvas.drawCircle(
      tail,
      unit * ArrowVisualConfig.lockRingInnerRatio,
      _headFillPaint..color = color,
    );
  }

  // ── Long-press preview path builder & renderer ──────────────────────────────

  /// Computes the pixel-space exit path from the arrow head outward,
  /// following direction-changing orphan dots, until the arrow would
  /// leave the grid. Returns a list of [Offset]s from the first cell
  /// AFTER the head to an off-screen point (so the line appears to
  /// vanish at the edge).
  List<Offset>? _buildPreviewPath() {
    final orphanDots = gameState.orphanDots;
    ArrowDirection currentDir = arrowModel.direction;
    final head = arrowModel.path[0];
    final gridSize = gameState.level.gridSize;
    final pts = <Offset>[];

    // Start directly from the center of the arrow head
    final headPx =
        Offset((head[1] + 0.5) * cellSize, (head[0] + 0.5) * cellSize);
    pts.add(headPx);

    var d = currentDir.delta;
    int nr = head[0] + d[0];
    int nc = head[1] + d[1];
    final visited = <String>{};

    while (nr >= 0 && nr < gridSize && nc >= 0 && nc < gridSize) {
      final key = '$nr,$nc';
      if (visited.contains(key)) break;
      visited.add(key);
      pts.add(Offset((nc + 0.5) * cellSize, (nr + 0.5) * cellSize));

      if (orphanDots.containsKey(key)) {
        final dotType = orphanDots[key]!;
        switch (dotType) {
          case OrphanDotType.up:
            currentDir = ArrowDirection.up;
            break;
          case OrphanDotType.down:
            currentDir = ArrowDirection.down;
            break;
          case OrphanDotType.left:
            currentDir = ArrowDirection.left;
            break;
          case OrphanDotType.right:
            currentDir = ArrowDirection.right;
            break;
          default:
            break;
        }
      }

      d = currentDir.delta;
      nr += d[0];
      nc += d[1];
    }

    // Add 2 off-screen points so the line fades cleanly past the border.
    for (int i = 1; i <= 2; i++) {
      pts.add(Offset(
          (nc + d[1] * i + 0.5) * cellSize, (nr + d[0] * i + 0.5) * cellSize));
    }

    return pts.isEmpty ? null : pts;
  }

  /// Draws the preview line as a solid glowing shadow path.
  void _drawPreviewPath(Canvas canvas, List<Offset> preview, bool isBlocked) {
    if (preview.length < 2) return;

    // Build a continuous path
    final rawPath = Path()..moveTo(preview.first.dx, preview.first.dy);
    for (int i = 1; i < preview.length; i++) {
      rawPath.lineTo(preview[i].dx, preview[i].dy);
    }

    final Color shadowColor = isBlocked
        ? const Color(0xFFFF3B30) // Shade of red for blocked shadow
        : const Color(0xFF34C759); // Shade of green for clear shadow

    final Color coreColor = isBlocked
        ? const Color(0xFFE53935) // Shade of red for blocked core line
        : const Color(0xFF2E7D32); // Shade of green for clear core line

    // --- Soft glowing shadow layer (wide, blurred) ---
    canvas.drawPath(
      rawPath,
      Paint()
        ..color = shadowColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.45 // Broader shadow (previously 0.32)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0),
    );

    // --- Core guideline layer (narrow, solid) ---
    canvas.drawPath(
      rawPath,
      Paint()
        ..color = coreColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.08
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // ── Color resolution ──────────────────────────────────────────────────────────────

  Color _color() {
    if (arrowModel.state == ArrowState.blocked || _isBlockedAnimating) {
      return ArrowVisualConfig.blockedColor;
    }
    if (gameState.blockerIds.contains(arrowModel.id)) {
      final pulse = (sin(_blockerFlash) + 1) / 2;
      return Color.lerp(
          const Color(0xFFFF1744), const Color(0xFFFF8A80), pulse)!;
    }
    if (gameState.hintArrowId == arrowModel.id) {
      return const Color(0xFFFFD54F);
    }
    if (gameState.rulerHighlightIds.contains(arrowModel.id)) {
      return const Color(0xFF69F0AE);
    }
    final group = arrowModel.colorGroup;
    final base =
        group != null ? AppColors.getGroupColor(group) : AppColors.arrowUp;
    // Salted by group for pairs so both arrows of a group get the same tint.
    return BoardStyle.tintArrow(
      gameState.arrowSkin,
      base,
      salt: group ?? arrowModel.id.hashCode,
      paired: group != null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  PATH INTERPOLATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extract the visible portion of the track between [from] and [to] distance.
  /// Returns Offsets in "head→tail" order (from = head end, to = tail end).
  List<Offset> _slice(
      List<Offset> track, List<double> dist, double from, double to) {
    if (from >= to) {
      if (from == to && track.isNotEmpty) {
        return [_lerp(track, dist, from)];
      }
      return [];
    }
    final pts = <Offset>[_lerp(track, dist, from)];
    for (int i = 0; i < dist.length; i++) {
      if (dist[i] > from && dist[i] < to) pts.add(track[i]);
    }
    pts.add(_lerp(track, dist, to));
    return pts;
  }

  Offset _lerp(List<Offset> track, List<double> dist, double s) {
    if (s <= dist.first) return track.first;
    if (s >= dist.last) return track.last;
    for (int i = 0; i < dist.length - 1; i++) {
      if (s >= dist[i] && s <= dist[i + 1]) {
        final t = (s - dist[i]) / (dist[i + 1] - dist[i]);
        return Offset.lerp(track[i], track[i + 1], t)!;
      }
    }
    return track.last;
  }

  static void _drawOrphanDot(
      Canvas canvas, Offset center, OrphanDotType type, double cs) {
    if (type == OrphanDotType.neutral)
      return; // Neutral empty dots can be left empty

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
}

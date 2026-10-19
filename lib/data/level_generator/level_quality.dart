import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Size;

import '../../core/constants.dart';
import '../../game/board_layout.dart';
import '../models/arrow.dart';
import '../models/level.dart';

/// Play area used to estimate on-screen cell size: the "phone" viewport of
/// test/visual/board_snapshot_test.dart, in logical pixels.
const Size qualityReferenceViewport = Size(366, 600);

/// Measured gameplay and readability properties of one level.
///
/// All solving metrics use the game's exit rule (GameState._computeExitInfo):
/// an arrow leaves when the ray from its head reaches the board edge without
/// meeting another arrow; its own body and its color partner never block;
/// directional dots turn the ray and are consumed; neutral dots are consumed.
/// A "unit" is one tap target: a single arrow or a color pair.
class LevelQualityProfile {
  const LevelQualityProfile({
    required this.level,
    required this.type,
    required this.difficulty,
    required this.shape,
    required this.gridSize,
    required this.contentRows,
    required this.contentCols,
    required this.maskCells,
    required this.arrowCount,
    required this.unitCount,
    required this.pairCount,
    required this.directionalDots,
    required this.neutralDots,
    required this.arrowCells,
    required this.pathMin,
    required this.pathMean,
    required this.pathMax,
    required this.stubShare,
    required this.turnsPerArrow,
    required this.headDirectionEntropy,
    required this.openingMoves,
    required this.peelRounds,
    required this.peelProfile,
    required this.peelCleared,
    required this.meanLegalMoves,
    required this.trapRate,
    required this.forcedShare,
    required this.deadEndRate,
    required this.monotone,
    required this.maxFanIn,
    required this.meanExitTrace,
    required this.meanBlockerDistance,
    required this.hiddenBlockerShare,
    required this.deflectedExitShare,
    required this.cellDp,
    required this.adjacencyShare,
    required this.headCrowding,
    required this.silhouette,
    required this.pattern,
  });

  final int level;
  final LevelType type;
  final Difficulty difficulty;
  final MaskShape shape;
  final int gridSize;

  /// Bounding box of used cells (what the renderer fits on screen).
  final int contentRows;
  final int contentCols;
  final int maskCells;
  final int arrowCount;
  final int unitCount;
  final int pairCount;
  final int directionalDots;
  final int neutralDots;

  /// Cells covered by arrow bodies.
  final int arrowCells;
  final int pathMin;
  final double pathMean;
  final int pathMax;

  /// Share of arrows only 1–2 cells long.
  final double stubShare;
  final double turnsPerArrow;

  /// Shannon entropy (bits, 0–2) of head directions; 2 = evenly mixed.
  final double headDirectionEntropy;

  /// Units that can leave on the first tap.
  final int openingMoves;

  /// Rounds needed when every currently free unit is removed each round:
  /// the length of the longest blocking chain the player must unwind.
  final int peelRounds;

  /// Free units removed in each peel round.
  final List<int> peelProfile;

  /// Whether peeling clears the board (it always can unless dots make the
  /// order matter).
  final bool peelCleared;

  /// Mean number of legal taps per step over seeded random playouts.
  final double meanLegalMoves;

  /// Mean share of remaining units that are blocked at each step: the chance
  /// that an uninformed tap costs a life. Real players inspect before
  /// tapping, so this measures how much inspection a board demands.
  final double trapRate;

  /// Share of steps with exactly one legal tap (excluding the last unit).
  final double forcedShare;

  /// Share of seeded random playouts (legal taps only) that end with units
  /// left and no legal tap. Always 0 when [monotone].
  final double deadEndRate;

  /// No directional dots: removing a unit never makes another unit illegal,
  /// so every sequence of legal taps solves the level.
  final bool monotone;

  /// Most units whose exit ray first hits the same unit at the start.
  final int maxFanIn;

  /// Mean cells a free arrow's ray travels before leaving the board.
  final double meanExitTrace;

  /// Mean cells between a blocked arrow's head and its first blocker.
  final double meanBlockerDistance;

  /// Share of blocked arrows whose blocker is 6+ cells away (easy to miss).
  final double hiddenBlockerShare;

  /// Share of free arrows whose exit ray is turned by a directional dot.
  final double deflectedExitShare;

  /// Cell size in logical pixels on [qualityReferenceViewport], computed
  /// with the renderer's BoardLayout.
  final double cellDp;

  /// Share of arrow cells orthogonally touching another arrow's cell.
  final double adjacencyShare;

  /// Share of arrow heads with another head in the 8 surrounding cells.
  final double headCrowding;

  /// Hash of the mask outline, identical for rotations and mirrors.
  final String silhouette;

  /// Generator pattern name (normal levels include shape and composition).
  final String pattern;

  double get openingShare => unitCount == 0 ? 0 : openingMoves / unitCount;
  double get fill => maskCells == 0 ? 0 : arrowCells / maskCells;

  Map<String, Object?> toJson() => {
        'level': level,
        'type': type.name,
        'difficulty': difficulty.name,
        'shape': shape.name,
        'grid': gridSize,
        'contentRows': contentRows,
        'contentCols': contentCols,
        'maskCells': maskCells,
        'arrows': arrowCount,
        'units': unitCount,
        'pairs': pairCount,
        'directionalDots': directionalDots,
        'neutralDots': neutralDots,
        'arrowCells': arrowCells,
        'fill': _r(fill),
        'pathMin': pathMin,
        'pathMean': _r(pathMean),
        'pathMax': pathMax,
        'stubShare': _r(stubShare),
        'turnsPerArrow': _r(turnsPerArrow),
        'headDirectionEntropy': _r(headDirectionEntropy),
        'openingMoves': openingMoves,
        'openingShare': _r(openingShare),
        'peelRounds': peelRounds,
        'peelProfile': peelProfile,
        'peelCleared': peelCleared,
        'meanLegalMoves': _r(meanLegalMoves),
        'trapRate': _r(trapRate),
        'forcedShare': _r(forcedShare),
        'deadEndRate': _r(deadEndRate),
        'monotone': monotone,
        'maxFanIn': maxFanIn,
        'meanExitTrace': _r(meanExitTrace),
        'meanBlockerDistance': _r(meanBlockerDistance),
        'hiddenBlockerShare': _r(hiddenBlockerShare),
        'deflectedExitShare': _r(deflectedExitShare),
        'cellDp': _r(cellDp),
        'adjacencyShare': _r(adjacencyShare),
        'headCrowding': _r(headCrowding),
        'silhouette': silhouette,
        'pattern': pattern,
      };
}

double _r(double v) => (v * 1000).round() / 1000;

class LevelQuality {
  LevelQuality._();

  /// Seeded random playouts per level. Deterministic for a given level.
  static const int defaultPlayouts = 32;

  static LevelQualityProfile profile(
    LevelModel level, {
    int playouts = defaultPlayouts,
    Size viewport = qualityReferenceViewport,
  }) {
    final arrows = level.arrows;
    final gs = level.gridSize;

    var cells = 0, pathMin = 1 << 30, pathMax = 0, stubs = 0, turns = 0;
    final dirCounts = List<int>.filled(4, 0);
    final owner = <int, int>{};
    for (var i = 0; i < arrows.length; i++) {
      final p = arrows[i].path;
      cells += p.length;
      pathMin = math.min(pathMin, p.length);
      pathMax = math.max(pathMax, p.length);
      if (p.length <= 2) stubs++;
      dirCounts[arrows[i].direction.index]++;
      for (var s = 2; s < p.length; s++) {
        final a = p[s - 1][0] - p[s - 2][0], b = p[s - 1][1] - p[s - 2][1];
        final c = p[s][0] - p[s - 1][0], d = p[s][1] - p[s - 1][1];
        if (a != c || b != d) turns++;
      }
      for (final pt in p) {
        owner[pt[0] * gs + pt[1]] = i;
      }
    }
    if (arrows.isEmpty) pathMin = 0;

    var entropy = 0.0;
    for (final c in dirCounts) {
      if (c == 0) continue;
      final q = c / arrows.length;
      entropy -= q * math.log(q) / math.ln2;
    }

    var adjacent = 0;
    for (final e in owner.entries) {
      final r = e.key ~/ gs, c = e.key % gs;
      for (final d in const [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1]
      ]) {
        final nr = r + d[0], nc = c + d[1];
        if (nr < 0 || nc < 0 || nr >= gs || nc >= gs) continue;
        final o = owner[nr * gs + nc];
        if (o != null && o != e.value) {
          adjacent++;
          break;
        }
      }
    }

    final heads = {for (final a in arrows) a.row * gs + a.col};
    var crowded = 0;
    for (final a in arrows) {
      var near = false;
      for (var dr = -1; dr <= 1 && !near; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final r = a.row + dr, c = a.col + dc;
          if (r < 0 || c < 0 || r >= gs || c >= gs) continue;
          if (heads.contains(r * gs + c)) {
            near = true;
            break;
          }
        }
      }
      if (near) crowded++;
    }

    // Opening state: per-arrow rays, blockers and fan-in.
    final board = _Board(level);
    var exitTrace = 0, exits = 0, deflected = 0;
    var blockDist = 0, blocked = 0, hidden = 0;
    final fanIn = <int, int>{};
    for (var i = 0; i < arrows.length; i++) {
      final ray = board.inspect(i, board.partner[i]);
      if (ray.blocker < 0 && ray.legal) {
        exits++;
        exitTrace += ray.length;
        if (ray.deflected) deflected++;
      } else if (ray.blocker >= 0) {
        blocked++;
        blockDist += ray.length;
        if (ray.length >= 6) hidden++;
        final u = board.unitOf(ray.blocker);
        fanIn[u] = (fanIn[u] ?? 0) + 1;
      }
    }
    final opening = board.legalUnits().length;

    // Peel rounds.
    final peel = _Board(level);
    final peelSizes = <int>[];
    while (peel.remaining > 0) {
      final free = peel.legalUnits();
      if (free.isEmpty) break;
      var removed = 0;
      for (final u in free) {
        if (peel.isLegal(u)) {
          peel.apply(u);
          removed++;
        }
      }
      peelSizes.add(removed);
    }

    var legalSum = 0.0, trapSum = 0.0, forced = 0, steps = 0, deadEnds = 0;
    for (var k = 0; k < playouts; k++) {
      final run = seededPlayout(level, k);
      if (run.deadEnd) deadEnds++;
      for (var s = 0; s < run.taps.length; s++) {
        final legal = run.legalCounts[s], left = run.remainingCounts[s];
        steps++;
        legalSum += legal;
        trapSum += 1 - legal / left;
        if (legal == 1 && left > 1) forced++;
      }
    }

    final dirDots =
        level.orphanDots.where((d) => d.type != OrphanDotType.neutral).length;
    final layout = BoardLayout.forLevel(level, viewport);

    return LevelQualityProfile(
      level: level.levelNumber,
      type: AppConstants.levelTypeFor(level.levelNumber),
      difficulty: level.difficulty,
      shape: level.maskShape,
      gridSize: gs,
      contentRows: layout.content.height.round(),
      contentCols: layout.content.width.round(),
      maskCells: level.mask.length,
      arrowCount: arrows.length,
      unitCount: board.units.length,
      pairCount: arrows.length - board.units.length,
      directionalDots: dirDots,
      neutralDots: level.orphanDots.length - dirDots,
      arrowCells: cells,
      pathMin: pathMin,
      pathMean: arrows.isEmpty ? 0 : cells / arrows.length,
      pathMax: pathMax,
      stubShare: arrows.isEmpty ? 0 : stubs / arrows.length,
      turnsPerArrow: arrows.isEmpty ? 0 : turns / arrows.length,
      headDirectionEntropy: entropy,
      openingMoves: opening,
      peelRounds: peelSizes.length,
      peelProfile: peelSizes,
      peelCleared: peel.remaining == 0,
      meanLegalMoves: steps == 0 ? 0 : legalSum / steps,
      trapRate: steps == 0 ? 0 : trapSum / steps,
      forcedShare: steps == 0 ? 0 : forced / steps,
      deadEndRate: playouts == 0 ? 0 : deadEnds / playouts,
      monotone: dirDots == 0,
      maxFanIn: fanIn.values.fold(0, math.max),
      meanExitTrace: exits == 0 ? 0 : exitTrace / exits,
      meanBlockerDistance: blocked == 0 ? 0 : blockDist / blocked,
      hiddenBlockerShare: blocked == 0 ? 0 : hidden / blocked,
      deflectedExitShare: exits == 0 ? 0 : deflected / exits,
      cellDp: layout.cellSize,
      adjacencyShare: cells == 0 ? 0 : adjacent / cells,
      headCrowding: arrows.isEmpty ? 0 : crowded / arrows.length,
      silhouette: LevelSimilarity.silhouetteKey(level),
      pattern: level.patternName,
    );
  }

  /// Arrow IDs that can leave on the first tap (one ID per unit: the
  /// lower-index arrow of a pair). Exposed to cross-check against GameState.
  static Set<String> openingLegalIds(LevelModel level) {
    final b = _Board(level);
    return {for (final u in b.legalUnits()) level.arrows[u].id};
  }

  /// Playout [k] of [level]: uniformly random legal taps from a seeded LCG.
  static LevelPlayout seededPlayout(LevelModel level, int k) {
    final sim = _Board(level);
    var seed = (level.levelNumber * 2654435761 + k * 40503 + 1) & 0x7fffffff;
    final taps = <String>[], legalCounts = <int>[], remainingCounts = <int>[];
    while (sim.remaining > 0) {
      final legal = sim.legalUnits();
      if (legal.isEmpty) break;
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      final pick = legal[seed % legal.length];
      taps.add(level.arrows[pick].id);
      legalCounts.add(legal.length);
      remainingCounts.add(sim.remaining);
      sim.apply(pick);
    }
    return LevelPlayout(taps, legalCounts, remainingCounts, sim.remaining > 0);
  }

  /// Taps the lowest-index legal unit until the board clears or stalls.
  static List<String> firstLegalPlayout(LevelModel level) {
    final b = _Board(level);
    final taps = <String>[];
    while (b.remaining > 0) {
      final legal = b.legalUnits();
      if (legal.isEmpty) break;
      taps.add(level.arrows[legal.first].id);
      b.apply(legal.first);
    }
    return taps;
  }
}

class LevelPlayout {
  const LevelPlayout(
      this.taps, this.legalCounts, this.remainingCounts, this.deadEnd);

  /// Tapped arrow IDs (one per unit; the lower-index arrow of a pair).
  final List<String> taps;

  /// Legal units before each tap.
  final List<int> legalCounts;

  /// Remaining units before each tap.
  final List<int> remainingCounts;

  /// Units remain but none can leave.
  final bool deadEnd;
}

class _Ray {
  _Ray(this.legal, this.blocker, this.length, this.deflected);
  final bool legal;
  final int blocker;
  final int length;
  final bool deflected;
}

/// Mutable board state with incremental legality. A unit's legality is only
/// recomputed when a cell its last ray touched changes (an arrow left it or
/// a dot on it was consumed).
class _Board {
  _Board(this.level)
      : gs = level.gridSize,
        arrows = level.arrows {
    final n = arrows.length;
    cells = Uint16List(gs * gs);
    dotType = Uint8List(gs * gs);
    dotActive = Uint8List(gs * gs);
    stamp = Uint32List(gs * gs);
    partner = Int32List(n)..fillRange(0, n, -1);
    active = List<bool>.filled(n, true);
    for (var i = 0; i < n; i++) {
      for (final pt in arrows[i].path) {
        cells[pt[0] * gs + pt[1]] = i + 1;
      }
    }
    for (final d in level.orphanDots) {
      final f = d.row * gs + d.col;
      dotType[f] = d.type.index;
      dotActive[f] = 1;
    }
    final groups = <int, List<int>>{};
    for (var i = 0; i < n; i++) {
      final g = arrows[i].colorGroup;
      if (g != null) groups.putIfAbsent(g, () => []).add(i);
    }
    for (final v in groups.values) {
      if (v.length == 2) {
        partner[v[0]] = v[1];
        partner[v[1]] = v[0];
      }
    }
    for (var i = 0; i < n; i++) {
      if (partner[i] == -1 || partner[i] > i) units.add(i);
    }
    remaining = units.length;
    watchers = List.generate(gs * gs, (_) => <int>[]);
    legal = List<bool>.filled(n, false);
    consumed = List<List<int>>.generate(n, (_) => const []);
    dirty = List<bool>.filled(n, true);
  }

  final LevelModel level;
  final int gs;
  final List<ArrowModel> arrows;
  late final Uint16List cells;
  late final Uint8List dotType;
  late final Uint8List dotActive;
  late final Uint32List stamp;
  late final Int32List partner;
  late final List<bool> active;
  final List<int> units = [];
  late int remaining;
  late final List<List<int>> watchers;
  late final List<bool> legal;
  late final List<List<int>> consumed;
  late final List<bool> dirty;
  int _token = 0;

  int unitOf(int arrow) {
    final p = partner[arrow];
    return p != -1 && p < arrow ? p : arrow;
  }

  /// Traces the exit ray of [ai], ignoring [pi]. Registers [watch] on every
  /// touched cell when given.
  _Ray _trace(int ai, int pi, List<int>? dots, int watch) {
    if (++_token == 0) {
      stamp.fillRange(0, stamp.length, 0);
      _token = 1;
    }
    var dir = arrows[ai].direction;
    final head = arrows[ai].path[0];
    var d = dir.delta;
    var r = head[0] + d[0], c = head[1] + d[1];
    var length = 0;
    var deflected = false;
    while (r >= 0 && r < gs && c >= 0 && c < gs) {
      final f = r * gs + c;
      if (watch >= 0) watchers[f].add(watch);
      if (stamp[f] == _token) return _Ray(false, -1, length, deflected);
      stamp[f] = _token;
      length++;
      if (dotActive[f] == 1) {
        dots?.add(f);
        final t = dotType[f];
        if (t <= 3) {
          final next = ArrowDirection.values[t];
          if (next != dir) deflected = true;
          dir = next;
        }
      } else {
        final occ = cells[f];
        if (occ != 0 && occ != ai + 1 && (pi == -1 || occ != pi + 1)) {
          return _Ray(false, occ - 1, length, deflected);
        }
      }
      d = dir.delta;
      r += d[0];
      c += d[1];
    }
    return _Ray(true, -1, length, deflected);
  }

  _Ray inspect(int ai, int pi) => _trace(ai, pi, null, -1);

  bool isLegal(int u) {
    if (dirty[u]) {
      dirty[u] = false;
      final p = partner[u];
      final dots = <int>[];
      final a = _trace(u, p, dots, u);
      final b = p == -1 ? null : _trace(p, u, dots, u);
      legal[u] = a.legal && (b == null || b.legal);
      consumed[u] = dots;
    }
    return legal[u];
  }

  List<int> legalUnits() => [
        for (final u in units)
          if (active[u] && isLegal(u)) u
      ];

  void apply(int u) {
    final p = partner[u];
    final changed = <int>[];
    for (final i in [u, if (p != -1) p]) {
      active[i] = false;
      for (final pt in arrows[i].path) {
        final f = pt[0] * gs + pt[1];
        cells[f] = 0;
        changed.add(f);
      }
    }
    for (final f in consumed[u]) {
      if (dotActive[f] == 1) {
        dotActive[f] = 0;
        changed.add(f);
      }
    }
    remaining--;
    for (final f in changed) {
      final w = watchers[f];
      for (final x in w) {
        dirty[x] = true;
      }
      w.clear();
    }
  }
}

/// Geometric similarity of two levels under the best of the 8 rotations and
/// mirrors, after aligning each board to its own top-left used cell.
class LevelSimilarity {
  const LevelSimilarity({
    required this.maskIoU,
    required this.arrowIoU,
    required this.headIoU,
  });

  /// Overlap of silhouettes (mask cells).
  final double maskIoU;

  /// Overlap of directed arrow cells (cell plus the link toward its head):
  /// 1.0 means identical arrow arrangements.
  final double arrowIoU;

  /// Overlap of arrow heads with their directions.
  final double headIoU;

  static const _ops = [
    [1, 0, 0, 1],
    [0, 1, -1, 0],
    [-1, 0, 0, -1],
    [0, -1, 1, 0],
    [1, 0, 0, -1],
    [-1, 0, 0, 1],
    [0, 1, 1, 0],
    [0, -1, -1, 0],
  ];

  static LevelSimilarity compare(LevelModel a, LevelModel b) {
    final base = _Tokens.of(a, _ops[0]);
    LevelSimilarity? best;
    for (final op in _ops) {
      final t = _Tokens.of(b, op);
      final s = LevelSimilarity(
        maskIoU: _iou(base.mask, t.mask),
        arrowIoU: _iou(base.arrows, t.arrows),
        headIoU: _iou(base.heads, t.heads),
      );
      if (best == null ||
          s.arrowIoU > best.arrowIoU ||
          (s.arrowIoU == best.arrowIoU && s.maskIoU > best.maskIoU)) {
        best = s;
      }
    }
    return best!;
  }

  /// FNV-1a hash (hex) of the smallest sorted mask encoding over the 8
  /// symmetries.
  static String silhouetteKey(LevelModel level) {
    List<int>? best;
    for (final op in _ops) {
      final cells = _Tokens.of(level, op).mask.toList()..sort();
      if (best == null || _lexLess(cells, best)) best = cells;
    }
    var h = 0xcbf29ce484222325;
    for (final v in best!) {
      h = (h ^ v) * 0x100000001b3;
    }
    return '${best.length}:${h.toUnsigned(64).toRadixString(16)}';
  }

  static bool _lexLess(List<int> a, List<int> b) {
    for (var i = 0; i < a.length && i < b.length; i++) {
      if (a[i] != b[i]) return a[i] < b[i];
    }
    return a.length < b.length;
  }

  static double _iou(Set<int> x, Set<int> y) {
    if (x.isEmpty && y.isEmpty) return 1;
    var inter = 0;
    for (final v in x) {
      if (y.contains(v)) inter++;
    }
    return inter / (x.length + y.length - inter);
  }
}

class _Tokens {
  _Tokens(this.mask, this.arrows, this.heads);
  final Set<int> mask;
  final Set<int> arrows;
  final Set<int> heads;

  static _Tokens of(LevelModel level, List<int> op) {
    List<int> map(int r, int c) =>
        [op[0] * r + op[1] * c, op[2] * r + op[3] * c];

    final pts = <List<int>>[
      for (final k in level.mask) k.split(',').map(int.parse).toList(),
    ];
    if (pts.isEmpty) {
      for (final a in level.arrows) {
        pts.addAll(a.path);
      }
    }
    var minR = 1 << 20, minC = 1 << 20;
    for (final p in pts) {
      final m = map(p[0], p[1]);
      minR = math.min(minR, m[0]);
      minC = math.min(minC, m[1]);
    }
    int cell(int r, int c) {
      final m = map(r, c);
      return (m[0] - minR + 64) * 256 + (m[1] - minC + 64);
    }

    int link(int dr, int dc) {
      final m = map(dr, dc);
      return (m[0] + 1) * 3 + (m[1] + 1);
    }

    final mask = {for (final p in pts) cell(p[0], p[1])};
    final arrows = <int>{};
    final heads = <int>{};
    for (final a in level.arrows) {
      final p = a.path;
      final hd = a.direction.delta;
      heads.add(cell(p[0][0], p[0][1]) * 16 + link(hd[0], hd[1]));
      arrows.add(cell(p[0][0], p[0][1]) * 16 + link(hd[0], hd[1]));
      for (var s = 1; s < p.length; s++) {
        arrows.add(cell(p[s][0], p[s][1]) * 16 +
            link(p[s - 1][0] - p[s][0], p[s - 1][1] - p[s][1]));
      }
    }
    return _Tokens(mask, arrows, heads);
  }
}

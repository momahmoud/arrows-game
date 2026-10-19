import 'dart:typed_data';

import 'package:arrow_escape/data/models/arrow.dart';
import 'package:arrow_escape/data/models/level.dart';

/// What a built candidate should contain. Counts are design intents; the
/// builder only places a feature where the stored solution stays legal.
class CandidateBrief {
  const CandidateBrief({
    required this.arrows,
    required this.minLen,
    required this.maxLen,
    this.traps = 0,
    this.detours = 0,
    this.pairs = 0,
    this.straightness = 0.6,
    this.seeds = 96,
    this.seedSalt = 0,
    this.fill = 0.8,
    this.tailGrowth = 5,
    this.outlineBias = 0,
  });

  /// Silhouette share to cover by growing tails after placement.
  final double fill;

  /// How far past [maxLen] a tail may grow.
  final int tailGrowth;

  /// 0–1 preference for outline and tip cells when placing heads and growing
  /// tails. Specials use a high bias so ears, fins and limbs stay occupied.
  final double outlineBias;

  CandidateBrief withFill(double value) => CandidateBrief(
        arrows: arrows,
        minLen: minLen,
        maxLen: maxLen,
        traps: traps,
        detours: detours,
        pairs: pairs,
        straightness: straightness,
        seeds: seeds,
        seedSalt: seedSalt,
        fill: value,
        tailGrowth: tailGrowth,
        outlineBias: outlineBias,
      );

  CandidateBrief withSalt(int salt) => CandidateBrief(
        arrows: arrows,
        minLen: minLen,
        maxLen: maxLen,
        traps: traps,
        detours: detours,
        pairs: pairs,
        straightness: straightness,
        seeds: seeds,
        seedSalt: salt,
        fill: fill,
        tailGrowth: tailGrowth,
        outlineBias: outlineBias,
      );

  CandidateBrief withOutlineBias(double value) => CandidateBrief(
        arrows: arrows,
        minLen: minLen,
        maxLen: maxLen,
        traps: traps,
        detours: detours,
        pairs: pairs,
        straightness: straightness,
        seeds: seeds,
        seedSalt: seedSalt,
        fill: fill,
        tailGrowth: tailGrowth,
        outlineBias: value,
      );

  CandidateBrief copyWith({
    int? arrows,
    int? minLen,
    int? maxLen,
    int? traps,
    int? detours,
    int? pairs,
    double? straightness,
    int? seeds,
    int? seedSalt,
    double? fill,
    int? tailGrowth,
    double? outlineBias,
  }) =>
      CandidateBrief(
        arrows: arrows ?? this.arrows,
        minLen: minLen ?? this.minLen,
        maxLen: maxLen ?? this.maxLen,
        traps: traps ?? this.traps,
        detours: detours ?? this.detours,
        pairs: pairs ?? this.pairs,
        straightness: straightness ?? this.straightness,
        seeds: seeds ?? this.seeds,
        seedSalt: seedSalt ?? this.seedSalt,
        fill: fill ?? this.fill,
        tailGrowth: tailGrowth ?? this.tailGrowth,
        outlineBias: outlineBias ?? this.outlineBias,
      );

  /// Target arrow count including pair members and gadget arrows.
  final int arrows;
  final int minLen;
  final int maxLen;

  /// Order traps: two arrows face each other across a deflector that is their
  /// only way out, with a third arrow that can waste the deflector first.
  final int traps;

  /// Deflectors placed on one arrow's exit so that arrow turns out of the board.
  final int detours;

  final int pairs;

  /// Chance a body keeps its direction while growing.
  final double straightness;

  /// Seeds tried; the caller picks among the results. Special levels use
  /// more because their large silhouettes vary more between seeds.
  final int seeds;
  final int seedSalt;
}

/// One built layout plus the bookkeeping the report needs.
class BuiltCandidate {
  BuiltCandidate(
      this.level, this.seed, this.traps, this.detoursPlaced, this.pairsPlaced);

  final LevelModel level;
  final int seed;
  final List<TrapGadget> traps;
  final int detoursPlaced;
  final int pairsPlaced;

  int get trapsPlaced => traps.length;
}

/// The arrows and deflector of one order trap: [x] and [y] face each other
/// across [dot]; tapping [z] while both still wait uses the dot up.
class TrapGadget {
  const TrapGadget(this.x, this.y, this.z, this.dotRow, this.dotCol);
  final String x;
  final String y;
  final String z;
  final int dotRow;
  final int dotCol;

  Map<String, Object> toJson() =>
      {'x': x, 'y': y, 'z': z, 'dot': '$dotRow,$dotCol'};
}

/// Reverse-construction builder: every arrow is placed so that removing the
/// arrows in reverse placement order is legal under the game's exit rule.
/// That order becomes [LevelModel.solutionOrder]. Placements are scored to
/// block arrows that are currently free, which deepens the dependency chain
/// instead of adding loose arrows.
class CandidateBuilder {
  CandidateBuilder._(this.template, this.brief, this.seed)
      : gs = template.gridSize,
        _rng = _Lcg(seed) {
    occ = Int16List(gs * gs)..fillRange(0, gs * gs, -1);
    for (final key in template.mask) {
      final p = key.split(',');
      final f = int.parse(p[0]) * gs + int.parse(p[1]);
      inMask.add(f);
      cells.add(f);
    }
    cells.sort();
    _classifyOutline();
  }

  /// Outline = mask cell with a 4-neighbour outside the mask. Tips = outline
  /// cells with at most two mask neighbours (ears, fins, fingers, limbs).
  void _classifyOutline() {
    const d4 = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1]
    ];
    for (final f in cells) {
      final r = f ~/ gs, c = f % gs;
      var neighbours = 0;
      var outside = false;
      for (final d in d4) {
        final nr = r + d[0], nc = c + d[1];
        final nf = nr * gs + nc;
        if (nr < 0 || nc < 0 || nr >= gs || nc >= gs || !inMask.contains(nf)) {
          outside = true;
        } else {
          neighbours++;
        }
      }
      if (outside) outline.add(f);
      if (outside && neighbours <= 2) tips.add(f);
    }
  }

  /// Builds [CandidateBrief.seeds] layouts inside [template]'s mask. Keeps the
  /// template's level number, grid, shape, label and pattern name.
  static List<BuiltCandidate> buildAll(
      LevelModel template, CandidateBrief brief) {
    return [
      for (var s = 0; s < brief.seeds; s++)
        CandidateBuilder._(template, brief,
                template.levelNumber * 7919 + brief.seedSalt * 104729 + s)
            ._run(),
    ];
  }

  final LevelModel template;
  final CandidateBrief brief;
  final int seed;
  final int gs;
  final _Lcg _rng;

  final Set<int> inMask = {};
  final List<int> cells = [];
  final Set<int> outline = {};
  final Set<int> tips = {};
  late Int16List occ;
  final List<List<int>> paths = [];
  final List<ArrowDirection> dirs = [];
  final List<int?> groups = [];
  final List<List<int>> units = [];
  final Map<int, OrphanDotType> dots = {};

  /// Dot cell → arrow that must consume it in the stored solution.
  final Map<int, int> owner = {};
  int _groupCount = 0;

  final List<(int, int, int, int)> _traps = [];

  BuiltCandidate _run() {
    var detours = 0, pairs = 0;
    for (var t = 0; t < brief.traps; t++) {
      _tryRepeat(_placeTrap, 400);
    }
    for (var p = 0; p < brief.pairs; p++) {
      if (_tryRepeat(_placePair, 300)) pairs++;
    }
    for (var d = 0; d < brief.detours; d++) {
      if (_tryRepeat(_placeDetour, 300)) detours++;
    }
    var misses = 0;
    // Allow more placement attempts when briefs request denser boards.
    final missCap = brief.arrows >= 40 ? 14 : 8;
    while (paths.length < brief.arrows && misses < missCap) {
      if (_placeBestSingle()) {
        misses = 0;
      } else {
        misses++;
      }
    }
    _growTails();
    _fillGaps();
    final n = template.levelNumber;
    return BuiltCandidate(
        _toLevel(),
        seed,
        [
          for (final (x, y, z, d) in _traps)
            TrapGadget('a_${n}_$x', 'a_${n}_$y', 'a_${n}_$z', d ~/ gs, d % gs),
        ],
        detours,
        pairs);
  }

  int get _covered => paths.fold(0, (n, p) => n + p.length);

  /// Holes no tail can reach get short arrows, then tails grow again. Hole
  /// arrows must start covered, so they never add an opening move; each
  /// joins the stored order after the arrows covering it.
  void _fillGaps() {
    final maxLen = brief.maxLen < 6 ? brief.maxLen : 6;
    var misses = 0;
    while (_covered < brief.fill * cells.length && misses < 4) {
      if (_insertGapArrow(3, maxLen)) {
        misses = 0;
        _growTails();
      } else {
        misses++;
      }
    }
  }

  bool _insertGapArrow(int minLen, int maxLen) {
    for (var k = 0; k < 60; k++) {
      final g = _grow(_randomHead(), minLen, maxLen);
      if (g == null || _headTouchesHead(g.$1.first)) continue;
      final (path, dir) = g;
      final i = paths.length;
      paths.add(path);
      dirs.add(dir);
      groups.add(null);
      for (final f in path) {
        occ[f] = i;
      }
      final startsFree = _trace(i, [i], occ, dots.keys.toSet(), null) != null;
      final n = startsFree ? 0 : units.length;
      final positions = n == 0
          ? const <int>[]
          : (<int>{
              for (var step = 1; step <= n; step *= 2) n - step,
              0,
            }.where((p) => p >= 0).toList()
            ..sort((a, b) => b - a));
      for (final p in positions) {
        units.insert(p, [i]);
        if (_replay()) return true;
        units.removeAt(p);
      }
      for (final f in path) {
        occ[f] = -1;
      }
      paths.removeLast();
      dirs.removeLast();
      groups.removeLast();
    }
    return false;
  }

  /// Lengthens bodies into neighbouring empty silhouette cells until
  /// [CandidateBrief.fill] is reached, so the shape reads without adding
  /// heads. Each step must keep the stored solution legal.
  void _growTails() {
    final cap = brief.maxLen + brief.tailGrowth;
    var covered = _covered;
    var progress = true;
    while (progress && covered < brief.fill * cells.length) {
      progress = false;
      final order = List<int>.generate(paths.length, (i) => i);
      for (var i = order.length - 1; i > 0; i--) {
        final j = _rng.next(i + 1);
        final t = order[i];
        order[i] = order[j];
        order[j] = t;
      }
      for (final i in order) {
        if (covered >= brief.fill * cells.length) break;
        final path = paths[i];
        if (path.length >= cap) continue;
        final tail = path.last;
        final options = <int>[];
        for (final d in ArrowDirection.values) {
          final r = tail ~/ gs + d.delta[0], c = tail % gs + d.delta[1];
          if (r < 0 || c < 0 || r >= gs || c >= gs) continue;
          final f = r * gs + c;
          if (!_free(f) || _touchesPath(f, path, tail)) continue;
          options.add(f);
        }
        if (options.isEmpty) continue;
        final f = _pickBiased(options);
        path.add(f);
        occ[f] = i;
        if (!_rayCrossesOwnBody(path, dirs[i]) && _replay()) {
          covered++;
          progress = true;
        } else {
          path.removeLast();
          occ[f] = -1;
        }
      }
    }
  }

  bool _tryRepeat(bool Function() fn, int tries) {
    for (var i = 0; i < tries; i++) {
      if (fn()) return true;
    }
    return false;
  }

  // ── Features ──────────────────────────────────────────────────────────────

  /// x → D ← y with an exit lane behind D in direction t, and z pointing
  /// along t into D from the other side.
  bool _placeTrap() {
    final d = cells[_rng.next(cells.length)];
    if (!_free(d)) return false;
    final t = ArrowDirection.values[_rng.next(4)];
    final perp = (t == ArrowDirection.up || t == ArrowDirection.down)
        ? ArrowDirection.left
        : ArrowDirection.up;
    final lx = 2 + _rng.next(2), ly = 2 + _rng.next(2), lz = 2 + _rng.next(2);
    final x = _line(d, perp, lx);
    final y = _line(d, perp.opposite, ly);
    final z = _line(d, t.opposite, lz);
    if (x == null || y == null || z == null) return false;
    if (!_laneClear(d, t)) return false;

    final before = _snapshot();
    dots[d] = _dotFor(t);
    final zi = _addUnit([(z, t)]).first;
    final yi = _addUnit([(y, perp)]).first;
    final xi = _addUnit([(x, perp.opposite)]).first;
    owner[d] = xi;
    if (_replay()) {
      _traps.add((xi, yi, zi, d));
      return true;
    }
    _restore(before);
    return false;
  }

  /// A straight run of [len] cells starting next to [from] in direction [d],
  /// head first (head nearest [from]).
  List<int>? _line(int from, ArrowDirection d, int len) {
    final out = <int>[];
    var r = from ~/ gs, c = from % gs;
    for (var i = 0; i < len; i++) {
      r += d.delta[0];
      c += d.delta[1];
      if (r < 0 || c < 0 || r >= gs || c >= gs) return null;
      final f = r * gs + c;
      if (!_free(f)) return null;
      out.add(f);
    }
    return out;
  }

  bool _laneClear(int from, ArrowDirection d) {
    var r = from ~/ gs + d.delta[0], c = from % gs + d.delta[1];
    var len = 0;
    while (r >= 0 && c >= 0 && r < gs && c < gs) {
      final f = r * gs + c;
      if (occ[f] != -1 || dots.containsKey(f)) return false;
      r += d.delta[0];
      c += d.delta[1];
      len++;
    }
    return len >= 2;
  }

  bool _placePair() {
    final a = _grow(_randomHead(), brief.minLen, brief.maxLen);
    if (a == null) return false;
    final before = _snapshot();
    _addUnit([a]);
    final b = _grow(_randomHead(), brief.minLen, brief.maxLen);
    _restore(before);
    if (b == null) return false;
    final ha = a.$1.first, hb = b.$1.first;
    final dist = (ha ~/ gs - hb ~/ gs).abs() + (ha % gs - hb % gs).abs();
    if (dist < 4 || dist > 14) return false;
    _addUnit([a, b], group: _groupCount);
    if (!_replay() || !_pairBlockedOnOneSide()) {
      _restore(before);
      return false;
    }
    _groupCount++;
    return true;
  }

  /// A fresh pair should not be trivially free on both sides forever; the
  /// later fill decides, so this only rejects pairs whose rays leave the
  /// board without crossing any mask cell.
  bool _pairBlockedOnOneSide() {
    final unit = units.last;
    for (final i in unit) {
      if (_rayMaskCells(i) > 0) return true;
    }
    return false;
  }

  int _rayMaskCells(int i) {
    var dir = dirs[i];
    final h = paths[i].first;
    var r = h ~/ gs + dir.delta[0], c = h % gs + dir.delta[1];
    var n = 0;
    while (r >= 0 && c >= 0 && r < gs && c < gs) {
      if (inMask.contains(r * gs + c)) n++;
      r += dir.delta[0];
      c += dir.delta[1];
    }
    return n;
  }

  /// A dot on an arrow's exit that turns it 90°; that arrow must be the one
  /// that uses the dot in the stored solution.
  bool _placeDetour() {
    final grown = _grow(_randomHead(), brief.minLen, brief.maxLen);
    if (grown == null) return false;
    final (path, dir) = grown;
    final h = path.first;
    final steps = 1 + _rng.next(3);
    var r = h ~/ gs, c = h % gs;
    for (var i = 0; i < steps; i++) {
      r += dir.delta[0];
      c += dir.delta[1];
      if (r < 0 || c < 0 || r >= gs || c >= gs) return false;
      final f = r * gs + c;
      if (occ[f] != -1 || dots.containsKey(f) || path.contains(f)) {
        return false;
      }
    }
    final dotCell = r * gs + c;
    if (!inMask.contains(dotCell)) return false;
    final turn = _rng.next(2) == 0 ? _left(dir) : _left(dir).opposite;
    final before = _snapshot();
    dots[dotCell] = _dotFor(turn);
    final i = _addUnit([grown]).first;
    owner[dotCell] = i;
    if (_replay() && _rayMaskCellsFrom(dotCell, turn) >= 2) return true;
    _restore(before);
    return false;
  }

  int _rayMaskCellsFrom(int from, ArrowDirection d) {
    var r = from ~/ gs + d.delta[0], c = from % gs + d.delta[1];
    var n = 0;
    while (r >= 0 && c >= 0 && r < gs && c < gs) {
      if (inMask.contains(r * gs + c)) n++;
      r += d.delta[0];
      c += d.delta[1];
    }
    return n;
  }

  // ── Filler ────────────────────────────────────────────────────────────────

  bool _headTouchesHead(int h) {
    for (final p in paths) {
      final o = p.first;
      if ((o ~/ gs - h ~/ gs).abs() <= 1 && (o % gs - h % gs).abs() <= 1) {
        return true;
      }
    }
    return false;
  }

  bool _placeBestSingle() {
    final free = _currentlyFree();
    final height = _heights();
    final targets = <int>[
      for (final u in free)
        for (final i in units[u]) ..._rayMaskFree(i),
    ];
    (List<int>, ArrowDirection)? best;
    var bestScore = double.negativeInfinity;
    final tries = brief.arrows >= 40 ? 220 : 160;
    for (var k = 0; k < tries; k++) {
      // Mostly aim at the exit of an arrow that is free right now, so the
      // new arrow covers it instead of becoming one more opening move.
      final head = targets.isNotEmpty && _rng.unit() < 0.7
          ? targets[_rng.next(targets.length)]
          : _randomHead();
      final g = _grow(head, brief.minLen, brief.maxLen);
      if (g == null) continue;
      final before = _snapshot();
      _addUnit([g]);
      final ok = _replay();
      _restore(before);
      if (!ok) continue;
      final score = _score(g, free, height);
      if (score > bestScore) {
        bestScore = score;
        best = g;
      }
    }
    if (best == null) return false;
    _addUnit([best]);
    return true;
  }

  /// Free mask cells on arrow [i]'s current exit ray.
  List<int> _rayMaskFree(int i) {
    var dir = dirs[i];
    final h = paths[i].first;
    var r = h ~/ gs + dir.delta[0], c = h % gs + dir.delta[1];
    final out = <int>[];
    final seen = <int>{};
    while (r >= 0 && c >= 0 && r < gs && c < gs) {
      final f = r * gs + c;
      if (!seen.add(f)) break;
      final dot = dots[f];
      if (dot != null) {
        if (dot != OrphanDotType.neutral)
          dir = ArrowDirection.values[dot.index];
      } else if (_free(f)) {
        out.add(f);
      }
      r += dir.delta[0];
      c += dir.delta[1];
    }
    return out;
  }

  /// Length of the longest "waits for" chain ending at each unit: a unit
  /// that blocks a unit of height h has height h + 1.
  List<int> _heights() {
    final height = List<int>.filled(units.length, 1);
    final unitOf = <int, int>{};
    for (var u = 0; u < units.length; u++) {
      for (final i in units[u]) {
        unitOf[i] = u;
      }
    }
    for (var w = 0; w < units.length; w++) {
      for (final i in units[w]) {
        final b = _firstBlocker(i, units[w]);
        if (b == null) continue;
        final u = unitOf[b]!;
        if (height[w] + 1 > height[u]) height[u] = height[w] + 1;
      }
    }
    return height;
  }

  int? _firstBlocker(int i, List<int> unit) {
    var dir = dirs[i];
    final h = paths[i].first;
    var r = h ~/ gs + dir.delta[0], c = h % gs + dir.delta[1];
    final seen = <int>{};
    while (r >= 0 && c >= 0 && r < gs && c < gs) {
      final f = r * gs + c;
      if (!seen.add(f)) return null;
      final dot = dots[f];
      if (dot != null) {
        if (dot != OrphanDotType.neutral)
          dir = ArrowDirection.values[dot.index];
      } else {
        final o = occ[f];
        if (o != -1 && !unit.contains(o)) return o;
      }
      r += dir.delta[0];
      c += dir.delta[1];
    }
    return null;
  }

  double _score(
      (List<int>, ArrowDirection) g, Set<int> freeUnits, List<int> height) {
    final cellsOf = g.$1.toSet();
    var blocks = 0;
    var deepest = 0;
    for (final u in freeUnits) {
      for (final i in units[u]) {
        if (_rayHits(i, cellsOf, units[u])) {
          blocks++;
          if (height[u] > deepest) deepest = height[u];
          break;
        }
      }
    }
    var crowd = 0;
    final h = g.$1.first;
    for (var i = 0; i < paths.length; i++) {
      final o = paths[i].first;
      if ((o ~/ gs - h ~/ gs).abs() <= 1 && (o % gs - h % gs).abs() <= 1) {
        crowd++;
      }
    }
    // An arrow whose exit crosses no mask cell can never be covered later,
    // so it is a guaranteed opening move.
    final coverable = _rayMaskCellsFrom(h, g.$2) > 0;
    var outlineHits = 0, tipHits = 0;
    for (final f in g.$1) {
      if (outline.contains(f)) outlineHits++;
      if (tips.contains(f)) tipHits++;
    }
    final bias = brief.outlineBias;
    // Count bends so multi-turn paths can compete with straight fillers when
    // straightness is lowered for denser, more varied boards.
    var bends = 0;
    final path = g.$1;
    for (var i = 1; i < path.length - 1; i++) {
      final dr1 = path[i] ~/ gs - path[i - 1] ~/ gs;
      final dc1 = path[i] % gs - path[i - 1] % gs;
      final dr2 = path[i + 1] ~/ gs - path[i] ~/ gs;
      final dc2 = path[i + 1] % gs - path[i] % gs;
      if (dr1 != dr2 || dc1 != dc2) bends++;
    }
    // Softened crowd penalty (was 2.0): density targets need more heads while
    // still preferring spaced tips.
    return deepest * 1.5 +
        blocks * 1.0 -
        (blocks == 0 ? 2.0 : 0) -
        (coverable ? 0 : 3.0) -
        crowd * 1.15 +
        g.$1.length * 0.35 +
        bends * 0.55 +
        outlineHits * bias * 0.8 +
        tipHits * bias * 1.6 +
        _rng.unit() * 0.5;
  }

  /// Bias fades once most of the fill target is met, so tips are claimed
  /// early without leaving the interior empty.
  double get _effectiveBias {
    final target = brief.fill * cells.length;
    if (target <= 0 || brief.outlineBias <= 0) return 0;
    final progress = _covered / target;
    if (progress >= 0.78) return 0;
    if (progress >= 0.55) return brief.outlineBias * 0.35;
    return brief.outlineBias;
  }

  /// Prefers tip and outline cells when [_effectiveBias] > 0.
  int _pickBiased(List<int> options) {
    final bias = _effectiveBias;
    if (bias <= 0 || options.length == 1) {
      return options[_rng.next(options.length)];
    }
    final tipOpts = [
      for (final f in options)
        if (tips.contains(f)) f
    ];
    final outOpts = [
      for (final f in options)
        if (outline.contains(f)) f
    ];
    if (tipOpts.isNotEmpty && _rng.unit() < bias) {
      return tipOpts[_rng.next(tipOpts.length)];
    }
    if (outOpts.isNotEmpty && _rng.unit() < bias * 0.7) {
      return outOpts[_rng.next(outOpts.length)];
    }
    return options[_rng.next(options.length)];
  }

  bool _rayHits(int i, Set<int> target, List<int> unit) {
    var dir = dirs[i];
    final h = paths[i].first;
    var r = h ~/ gs + dir.delta[0], c = h % gs + dir.delta[1];
    final seen = <int>{};
    while (r >= 0 && c >= 0 && r < gs && c < gs) {
      final f = r * gs + c;
      if (!seen.add(f)) return false;
      final dot = dots[f];
      if (dot != null) {
        if (dot != OrphanDotType.neutral)
          dir = ArrowDirection.values[dot.index];
      } else {
        if (target.contains(f)) return true;
        final o = occ[f];
        if (o != -1 && !unit.contains(o)) return false;
      }
      r += dir.delta[0];
      c += dir.delta[1];
    }
    return false;
  }

  /// Units whose exit is clear on the current board with every dot present.
  Set<int> _currentlyFree() {
    final out = <int>{};
    for (var u = 0; u < units.length; u++) {
      final unit = units[u];
      var ok = true;
      for (final i in unit) {
        if (_trace(i, unit, occ, dots.keys.toSet(), null) == null) {
          ok = false;
          break;
        }
      }
      if (ok) out.add(u);
    }
    return out;
  }

  int _randomHead() {
    final bias = _effectiveBias;
    if (bias > 0 && _rng.unit() < bias) {
      final freeTips = [
        for (final f in tips)
          if (_free(f)) f
      ];
      if (freeTips.isNotEmpty) return freeTips[_rng.next(freeTips.length)];
      final freeOut = [
        for (final f in outline)
          if (_free(f)) f
      ];
      if (freeOut.isNotEmpty) return freeOut[_rng.next(freeOut.length)];
    }
    return cells[_rng.next(cells.length)];
  }

  /// Grows a body behind [head] through free mask cells. The body never
  /// touches itself except between consecutive cells, so no path cycle can
  /// form, and the head's exit never runs back over its own body.
  (List<int>, ArrowDirection)? _grow(int head, int minLen, int maxLen) {
    if (!_free(head)) return null;
    final dir = ArrowDirection.values[_rng.next(4)];
    final target = minLen + _rng.next(maxLen - minLen + 1);
    final path = [head];
    var back = dir.opposite;
    var cur = head;
    while (path.length < target) {
      final options = <(int, ArrowDirection)>[];
      for (final d in ArrowDirection.values) {
        if (path.length == 1 && d != back) continue;
        if (d == back.opposite && path.length > 1) continue;
        final r = cur ~/ gs + d.delta[0], c = cur % gs + d.delta[1];
        if (r < 0 || c < 0 || r >= gs || c >= gs) continue;
        final f = r * gs + c;
        if (!_free(f) || path.contains(f)) continue;
        if (_touchesPath(f, path, cur)) continue;
        options.add((f, d));
      }
      if (options.isEmpty) break;
      (int, ArrowDirection) pick;
      final straight = options.where((o) => o.$2 == back).toList();
      final turns = options.where((o) => o.$2 != back).toList();
      // Low straightness → prefer a turn when one exists (zigzag bias).
      if (turns.isNotEmpty && _rng.unit() > brief.straightness) {
        pick = turns[_rng.next(turns.length)];
      } else if (straight.isNotEmpty && _rng.unit() < brief.straightness) {
        pick = straight.first;
      } else {
        pick = options[_rng.next(options.length)];
      }
      path.add(pick.$1);
      back = pick.$2;
      cur = pick.$1;
    }
    if (path.length < minLen) return null;
    if (_rayCrossesOwnBody(path, dir)) return null;
    return (path, dir);
  }

  bool _touchesPath(int f, List<int> path, int cur) {
    final r = f ~/ gs, c = f % gs;
    for (final p in path) {
      if (p == cur) continue;
      if ((p ~/ gs - r).abs() + (p % gs - c).abs() == 1) return true;
    }
    return false;
  }

  bool _rayCrossesOwnBody(List<int> path, ArrowDirection dir) {
    final body = path.toSet();
    var r = path.first ~/ gs + dir.delta[0], c = path.first % gs + dir.delta[1];
    while (r >= 0 && c >= 0 && r < gs && c < gs) {
      if (body.contains(r * gs + c)) return true;
      r += dir.delta[0];
      c += dir.delta[1];
    }
    return false;
  }

  bool _free(int f) =>
      inMask.contains(f) && occ[f] == -1 && !dots.containsKey(f);

  // ── Exit rule (same as GameState._computeExitInfo) ────────────────────────

  /// Returns consumed dot cells, or null when blocked or looping.
  List<int>? _trace(int i, List<int> unit, Int16List board, Set<int> active,
      Set<int>? visitedScratch) {
    var dir = dirs[i];
    final h = paths[i].first;
    var r = h ~/ gs + dir.delta[0], c = h % gs + dir.delta[1];
    final consumed = <int>[];
    final seen = visitedScratch ?? <int>{};
    seen.clear();
    while (r >= 0 && c >= 0 && r < gs && c < gs) {
      final f = r * gs + c;
      if (!seen.add(f)) return null;
      if (active.contains(f)) {
        consumed.add(f);
        final t = dots[f]!;
        if (t != OrphanDotType.neutral) dir = ArrowDirection.values[t.index];
      } else {
        final o = board[f];
        if (o != -1 && !unit.contains(o)) return null;
      }
      r += dir.delta[0];
      c += dir.delta[1];
    }
    return consumed;
  }

  /// Removes units in reverse placement order with the real exit rule.
  /// Dots with an [owner] must be consumed by exactly that arrow's unit.
  bool _replay() {
    final board = Int16List.fromList(occ);
    final active = dots.keys.toSet();
    final scratch = <int>{};
    for (final unit in units.reversed) {
      final used = <int>{};
      for (final i in unit) {
        final consumed = _trace(i, unit, board, active, scratch);
        if (consumed == null) return false;
        used.addAll(consumed);
      }
      for (final f in used) {
        final o = owner[f];
        if (o != null && !unit.contains(o)) return false;
      }
      active.removeAll(used);
      for (final i in unit) {
        for (final f in paths[i]) {
          board[f] = -1;
        }
      }
    }
    return true;
  }

  // ── Bookkeeping ──────────────────────────────────────────────────────────

  List<int> _addUnit(List<(List<int>, ArrowDirection)> members, {int? group}) {
    final ids = <int>[];
    for (final (path, dir) in members) {
      final i = paths.length;
      paths.add(path);
      dirs.add(dir);
      groups.add(group);
      for (final f in path) {
        occ[f] = i;
      }
      ids.add(i);
    }
    units.add(ids);
    return ids;
  }

  _Snap _snapshot() => _Snap(paths.length, units.length, {...dots}, {...owner});

  void _restore(_Snap s) {
    while (paths.length > s.arrows) {
      for (final f in paths.last) {
        occ[f] = -1;
      }
      paths.removeLast();
      dirs.removeLast();
      groups.removeLast();
    }
    units.length = s.units;
    dots
      ..clear()
      ..addAll(s.dots);
    owner
      ..clear()
      ..addAll(s.owner);
  }

  static ArrowDirection _left(ArrowDirection d) => d.turnLeft;

  static OrphanDotType _dotFor(ArrowDirection d) =>
      OrphanDotType.values[d.index];

  LevelModel _toLevel() {
    final n = template.levelNumber;
    final arrows = <ArrowModel>[
      for (var i = 0; i < paths.length; i++)
        ArrowModel(
          id: 'a_${n}_$i',
          row: paths[i].first ~/ gs,
          col: paths[i].first % gs,
          direction: dirs[i],
          colorGroup: groups[i],
          mechanic: groups[i] == null
              ? SnakeMechanic.standard
              : SnakeMechanic.colorLock,
          path: [
            for (final f in paths[i]) [f ~/ gs, f % gs]
          ],
        ),
    ];
    final dotList = [
      for (final e in dots.entries.toList()..sort((a, b) => a.key - b.key))
        OrphanDot(row: e.key ~/ gs, col: e.key % gs, type: e.value),
    ];
    return LevelModel(
      levelNumber: n,
      gridSize: gs,
      arrows: arrows,
      patternName: template.patternName,
      difficulty: template.difficulty,
      maskShape: template.maskShape,
      mask: template.mask,
      orphanDots: dotList,
      solutionOrder: [
        for (final unit in units.reversed) 'a_${n}_${unit.first}',
      ],
    );
  }
}

class _Snap {
  _Snap(this.arrows, this.units, this.dots, this.owner);
  final int arrows;
  final int units;
  final Map<int, OrphanDotType> dots;
  final Map<int, int> owner;
}

/// Small deterministic generator so candidates do not depend on the
/// platform's [Random] implementation.
class _Lcg {
  _Lcg(int seed) : _s = (seed * 2654435761 + 1) & 0x7fffffff;
  int _s;

  int next(int bound) {
    _s = (_s * 1103515245 + 12345) & 0x7fffffff;
    return (_s >> 8) % bound;
  }

  double unit() => next(1 << 20) / (1 << 20);
}

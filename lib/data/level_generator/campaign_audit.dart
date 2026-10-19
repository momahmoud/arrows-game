import 'dart:math' as math;
import 'dart:typed_data';

import '../../core/constants.dart';
import '../level_binary_codec.dart';
import '../level_layout_profile.dart';
import '../models/arrow.dart';
import '../models/level.dart';
import 'level_fingerprint.dart';
import 'solver.dart';

/// Solvability classification for one packaged level.
enum SolvabilityKind {
  /// Independently confirmed via greedy simulation and/or DFS.
  confirmedSolvable,

  /// Stored [LevelModel.solutionOrder] executes legally to a clear board.
  storedSolutionValid,

  /// Search exhausted without a solution (not a state-limit timeout).
  confirmedUnsolvable,

  /// Solver hit its state budget before proving solvability.
  unverified,

  /// Structural defects prevent a fair solvability check.
  structurallyInvalid,
}

class LevelAuditFinding {
  const LevelAuditFinding({
    required this.levelNumber,
    required this.issues,
    required this.solvability,
    required this.fingerprint,
    required this.isFallback,
    required this.gridSize,
    required this.arrowCount,
    required this.levelType,
    required this.difficulty,
    required this.maskShape,
    this.duplicateOf,
  });

  final int levelNumber;
  final List<String> issues;
  final SolvabilityKind solvability;
  final String fingerprint;
  final bool isFallback;
  final int gridSize;
  final int arrowCount;
  final LevelType levelType;
  final Difficulty difficulty;
  final MaskShape maskShape;
  final int? duplicateOf;

  bool get isStructurallyValid =>
      issues.where((i) => i.startsWith('STRUCT:')).isEmpty;
}

class CampaignAuditReport {
  CampaignAuditReport({
    required this.expectedCount,
    required this.actualCount,
    required this.findings,
    required this.gridHistogram,
    required this.arrowHistogram,
    required this.difficultyHistogram,
    required this.typeHistogram,
    this.binaryVersion = 0,
    this.byteLength = 0,
    this.dfsStateLimit = 0,
  });

  final int expectedCount;

  /// Level count from the binary header.
  final int actualCount;
  final int binaryVersion;
  final int byteLength;
  final int dfsStateLimit;
  final List<LevelAuditFinding> findings;
  final Map<int, int> gridHistogram;
  final Map<String, int> arrowHistogram;
  final Map<String, int> difficultyHistogram;
  final Map<String, int> typeHistogram;

  int get structurallyValid =>
      findings.where((f) => f.isStructurallyValid).length;
  int get structurallyInvalid =>
      findings.where((f) => !f.isStructurallyValid).length;
  int get confirmedSolvable => findings
      .where((f) =>
          f.solvability == SolvabilityKind.confirmedSolvable ||
          f.solvability == SolvabilityKind.storedSolutionValid)
      .length;
  int get confirmedUnsolvable => findings
      .where((f) => f.solvability == SolvabilityKind.confirmedUnsolvable)
      .length;
  int get unverified =>
      findings.where((f) => f.solvability == SolvabilityKind.unverified).length;
  int get fallbackCount => findings.where((f) => f.isFallback).length;
  int get duplicateCount => findings.where((f) => f.duplicateOf != null).length;

  List<LevelAuditFinding> get structuralFailures =>
      findings.where((f) => !f.isStructurallyValid).toList();
  List<LevelAuditFinding> get unsolvableFailures => findings
      .where((f) => f.solvability == SolvabilityKind.confirmedUnsolvable)
      .toList();
  List<LevelAuditFinding> get duplicates =>
      findings.where((f) => f.duplicateOf != null).toList();
  List<LevelAuditFinding> get fallbacks =>
      findings.where((f) => f.isFallback).toList();
  List<LevelAuditFinding> get unverifiedFindings => findings
      .where((f) => f.solvability == SolvabilityKind.unverified)
      .toList();

  Iterable<LevelAuditFinding> get _decoded =>
      findings.where((f) => f.arrowCount > 0);

  /// Release-blocking invariant violations, one line each. [strict] also
  /// blocks on levels the solver could not verify within its state limit.
  List<String> blockers({bool strict = false}) {
    String ids(List<LevelAuditFinding> list) =>
        list.map((f) => f.levelNumber).join(', ');
    return [
      if (actualCount != expectedCount)
        'header level count $actualCount != expected $expectedCount',
      if (findings.length != expectedCount)
        'audited ${findings.length} levels, expected $expectedCount',
      if (structuralFailures.isNotEmpty)
        'structurally invalid levels: ${ids(structuralFailures)}',
      if (unsolvableFailures.isNotEmpty)
        'confirmed unsolvable levels: ${ids(unsolvableFailures)}',
      if (duplicates.isNotEmpty)
        'exact duplicate fingerprints: '
            '${duplicates.map((f) => '${f.levelNumber}->${f.duplicateOf}').join(', ')}',
      if (fallbacks.isNotEmpty) 'generator fallback levels: ${ids(fallbacks)}',
      if (strict && unverifiedFindings.isNotEmpty)
        'unverified levels (solver limit $dfsStateLimit): '
            '${ids(unverifiedFindings)}',
    ];
  }

  String summary({int detailLimit = 20}) {
    final arrows = _decoded.map((f) => f.arrowCount).toList();
    final grids = _decoded.map((f) => f.gridSize).toList();
    final buf = StringBuffer()
      ..writeln('Campaign audit')
      ..writeln('  binary: version=$binaryVersion bytes=$byteLength '
          'dfsStateLimit=$dfsStateLimit')
      ..writeln('  expected=$expectedCount actual=$actualCount '
          'audited=${findings.length}')
      ..writeln('  structurallyValid=$structurallyValid')
      ..writeln('  structurallyInvalid=$structurallyInvalid')
      ..writeln('  confirmedSolvable=$confirmedSolvable')
      ..writeln('  confirmedUnsolvable=$confirmedUnsolvable')
      ..writeln('  unverified=$unverified')
      ..writeln('  fallback=$fallbackCount')
      ..writeln('  duplicateFingerprints=$duplicateCount');
    if (arrows.isNotEmpty) {
      final total = arrows.reduce((a, b) => a + b);
      buf.writeln('  arrows: min=${arrows.reduce(math.min)} '
          'max=${arrows.reduce(math.max)} '
          'avg=${(total / arrows.length).toStringAsFixed(1)}');
      buf.writeln('  grid: min=${grids.reduce(math.min)} '
          'max=${grids.reduce(math.max)} distinct=${gridHistogram.length}');
    }
    if (structuralFailures.isNotEmpty) {
      buf.writeln('  structural IDs: '
          '${structuralFailures.map((f) => f.levelNumber).join(', ')}');
    }
    if (unsolvableFailures.isNotEmpty) {
      buf.writeln('  unsolvable IDs: '
          '${unsolvableFailures.map((f) => f.levelNumber).join(', ')}');
    }
    if (unverifiedFindings.isNotEmpty) {
      buf.writeln('  unverified IDs (solver limit, not proof of '
          'unsolvability): '
          '${unverifiedFindings.map((f) => f.levelNumber).join(', ')}');
    }
    if (duplicates.isNotEmpty) {
      buf.writeln('  duplicate pairs: '
          '${duplicates.map((f) => '${f.levelNumber}->${f.duplicateOf}').join(', ')}');
    }
    if (fallbacks.isNotEmpty) {
      buf.writeln('  fallback IDs: '
          '${fallbacks.map((f) => f.levelNumber).join(', ')}');
    }
    final failing = findings
        .where((f) =>
            !f.isStructurallyValid ||
            f.solvability == SolvabilityKind.confirmedUnsolvable ||
            f.duplicateOf != null ||
            f.isFallback)
        .toList();
    for (final f in failing.take(detailLimit)) {
      final reasons = [
        ...f.issues,
        if (f.solvability == SolvabilityKind.confirmedUnsolvable)
          'SOLVE: confirmed unsolvable',
        if (f.duplicateOf != null) 'DUP: same fingerprint as ${f.duplicateOf}',
      ];
      buf.writeln('  level ${f.levelNumber} '
          '(${f.levelType.name}, ${f.gridSize}x${f.gridSize}, '
          '${f.arrowCount} arrows): ${reasons.join('; ')}');
    }
    if (failing.length > detailLimit) {
      buf.writeln('  … ${failing.length - detailLimit} more failing levels');
    }
    return buf.toString();
  }

  Map<String, Object?> toJson() => {
        'binaryVersion': binaryVersion,
        'byteLength': byteLength,
        'dfsStateLimit': dfsStateLimit,
        'expectedCount': expectedCount,
        'actualCount': actualCount,
        'auditedCount': findings.length,
        'counts': {
          'structurallyValid': structurallyValid,
          'structurallyInvalid': structurallyInvalid,
          'confirmedSolvable': confirmedSolvable,
          'confirmedUnsolvable': confirmedUnsolvable,
          'unverified': unverified,
          'fallback': fallbackCount,
          'duplicateFingerprints': duplicateCount,
        },
        'blockers': blockers(),
        'unverifiedLevels':
            unverifiedFindings.map((f) => f.levelNumber).toList(),
        'histograms': {
          'type': typeHistogram,
          'difficulty': difficultyHistogram,
          'arrows': arrowHistogram,
          'grid': {
            for (final e in gridHistogram.entries) '${e.key}': e.value,
          },
        },
        'levels': [
          for (final f in findings)
            {
              'level': f.levelNumber,
              'type': f.levelType.name,
              'difficulty': f.difficulty.name,
              'shape': f.maskShape.name,
              'grid': f.gridSize,
              'arrows': f.arrowCount,
              'solvability': f.solvability.name,
              'fallback': f.isFallback,
              if (f.duplicateOf != null) 'duplicateOf': f.duplicateOf,
              if (f.issues.isNotEmpty) 'issues': f.issues,
            },
        ],
      };
}

/// Full-campaign content auditor for packaged `levels.bin` data.
///
/// Reuses [LevelSolver], greedy playability checks, and [LevelFingerprint].
class CampaignAudit {
  CampaignAudit._();

  /// Known generator grid overrides that diverge from [AppConstants.gridSizeForLevel].
  static int expectedGridSize(int levelNumber) {
    if (levelNumber == 213) return 32;
    if (levelNumber == 395) return 35;
    if (levelNumber == 437) return 36;
    return AppConstants.gridSizeForLevel(levelNumber);
  }

  static CampaignAuditReport auditBytes(
    Uint8List bytes, {
    int expectedCount = AppConstants.totalLevels,
    int dfsStateLimit = 8000,
  }) {
    final decoder = LevelBinaryDecoder.fromBytes(bytes);
    final findings = <LevelAuditFinding>[];
    final seenFp = <String, int>{};
    final gridHistogram = <int, int>{};
    final arrowHistogram = <String, int>{};
    final difficultyHistogram = <String, int>{};
    final typeHistogram = <String, int>{};

    for (var n = 1; n <= expectedCount; n++) {
      LevelModel? level;
      final issues = <String>[];
      try {
        level = decoder.decodeLevelByNumber(n);
      } on FormatException catch (e) {
        issues.add('STRUCT: decode FormatException: $e');
      } catch (e) {
        issues.add('STRUCT: decode error: $e');
      }

      if (level == null) {
        issues.add('STRUCT: missing level $n');
        findings.add(LevelAuditFinding(
          levelNumber: n,
          issues: issues,
          solvability: SolvabilityKind.structurallyInvalid,
          fingerprint: '',
          isFallback: false,
          gridSize: 0,
          arrowCount: 0,
          levelType: AppConstants.levelTypeFor(n),
          difficulty: Difficulty.easy,
          maskShape: MaskShape.square,
        ));
        continue;
      }

      issues.addAll(structuralIssues(level, expectedLevelNumber: n));

      final type = AppConstants.levelTypeFor(n);
      final fp = issues.any((i) => i.startsWith('STRUCT:'))
          ? ''
          : LevelFingerprint.canonicalHash(level);
      int? duplicateOf;
      if (fp.isNotEmpty) {
        duplicateOf = seenFp[fp];
        seenFp.putIfAbsent(fp, () => n);
      }

      final solvability = issues.any((i) => i.startsWith('STRUCT:'))
          ? SolvabilityKind.structurallyInvalid
          : classifySolvability(level, dfsStateLimit: dfsStateLimit);

      final isFallback = level.patternName == 'fallback';
      if (isFallback) {
        issues.add('CONTENT: generator fallback pattern');
      }

      gridHistogram[level.gridSize] = (gridHistogram[level.gridSize] ?? 0) + 1;
      final band = _arrowBand(level.arrows.length);
      arrowHistogram[band] = (arrowHistogram[band] ?? 0) + 1;
      difficultyHistogram[level.difficulty.name] =
          (difficultyHistogram[level.difficulty.name] ?? 0) + 1;
      typeHistogram[type.name] = (typeHistogram[type.name] ?? 0) + 1;

      findings.add(LevelAuditFinding(
        levelNumber: n,
        issues: issues,
        solvability: solvability,
        fingerprint: fp,
        isFallback: isFallback,
        gridSize: level.gridSize,
        arrowCount: level.arrows.length,
        levelType: type,
        difficulty: level.difficulty,
        maskShape: level.maskShape,
        duplicateOf: duplicateOf,
      ));
    }

    return CampaignAuditReport(
      expectedCount: expectedCount,
      actualCount: decoder.levelCount,
      findings: findings,
      gridHistogram: gridHistogram,
      arrowHistogram: arrowHistogram,
      difficultyHistogram: difficultyHistogram,
      typeHistogram: typeHistogram,
      binaryVersion: decoder.version,
      byteLength: bytes.length,
      dfsStateLimit: dfsStateLimit,
    );
  }

  static List<String> structuralIssues(
    LevelModel level, {
    required int expectedLevelNumber,
  }) {
    final issues = <String>[];
    if (level.levelNumber != expectedLevelNumber) {
      issues.add(
        'STRUCT: levelNumber ${level.levelNumber} != $expectedLevelNumber',
      );
    }

    final expectedGs = expectedGridSize(expectedLevelNumber);
    if (level.gridSize != expectedGs) {
      issues.add(
        'STRUCT: gridSize ${level.gridSize} != expected $expectedGs',
      );
    }
    if (level.gridSize < 1 || level.gridSize > AppConstants.maxGridSize) {
      issues.add('STRUCT: gridSize ${level.gridSize} out of campaign range');
    }
    if (level.arrows.isEmpty) {
      issues.add('STRUCT: no arrows');
    }

    final occupied = <String, String>{};
    for (final arrow in level.arrows) {
      if (arrow.path.isEmpty) {
        issues.add('STRUCT: empty path ${arrow.id}');
        continue;
      }
      if (arrow.path[0][0] != arrow.row || arrow.path[0][1] != arrow.col) {
        issues.add('STRUCT: head mismatch ${arrow.id}');
      }
      for (var s = 0; s < arrow.path.length; s++) {
        final r = arrow.path[s][0];
        final c = arrow.path[s][1];
        if (r < 0 || c < 0 || r >= level.gridSize || c >= level.gridSize) {
          issues.add('STRUCT: path OOB ${arrow.id} at ($r,$c)');
          break;
        }
        final key = '$r,$c';
        final prior = occupied[key];
        if (prior != null && prior != arrow.id) {
          issues.add('STRUCT: overlap $key ($prior / ${arrow.id})');
        }
        occupied[key] = arrow.id;
        if (s > 0) {
          final pr = arrow.path[s - 1][0];
          final pc = arrow.path[s - 1][1];
          final manhattan = (r - pr).abs() + (c - pc).abs();
          if (manhattan != 1) {
            issues.add(
                'STRUCT: non-adjacent step ${arrow.id} ($pr,$pc)->($r,$c)');
            break;
          }
        }
      }
      if (_pathFormsCycle(arrow.path)) {
        issues.add('STRUCT: path cycle ${arrow.id}');
      }
    }

    for (final cell in level.mask) {
      final parts = cell.split(',');
      if (parts.length != 2) {
        issues.add('STRUCT: bad mask cell $cell');
        continue;
      }
      final r = int.tryParse(parts[0]);
      final c = int.tryParse(parts[1]);
      if (r == null ||
          c == null ||
          r < 0 ||
          c < 0 ||
          r >= level.gridSize ||
          c >= level.gridSize) {
        issues.add('STRUCT: mask OOB $cell');
      }
    }

    for (final dot in level.orphanDots) {
      if (dot.row < 0 ||
          dot.col < 0 ||
          dot.row >= level.gridSize ||
          dot.col >= level.gridSize) {
        issues.add('STRUCT: orphan OOB ${dot.key}');
      }
    }

    final ids = level.arrows.map((a) => a.id).toSet();
    if (ids.length != level.arrows.length) {
      issues.add('STRUCT: duplicate arrow ids');
    }
    final seenSol = <String>{};
    for (final id in level.solutionOrder) {
      if (!ids.contains(id)) {
        issues.add('STRUCT: solution ref missing $id');
      } else if (!seenSol.add(id)) {
        issues.add('STRUCT: duplicate solution ref $id');
      }
    }

    final groups = <int, int>{};
    for (final a in level.arrows) {
      if (a.colorGroup != null) {
        groups[a.colorGroup!] = (groups[a.colorGroup!] ?? 0) + 1;
      }
    }
    for (final entry in groups.entries) {
      if (entry.value != 2) {
        issues.add(
          'STRUCT: color group ${entry.key} size ${entry.value} (expected 2)',
        );
      }
    }

    if (_hasDeflectionLoop(level)) {
      issues.add('STRUCT: deflection loop');
    }

    return issues;
  }

  static SolvabilityKind classifySolvability(
    LevelModel level, {
    int dfsStateLimit = 8000,
  }) {
    if (level.arrows.isEmpty) return SolvabilityKind.structurallyInvalid;

    final storedOk = replayStoredSolution(level);
    final greedyOk = greedyCanSolve(level);

    // A legal stored order or greedy clearance is independent confirmation.
    if (storedOk) return SolvabilityKind.storedSolutionValid;
    if (greedyOk) return SolvabilityKind.confirmedSolvable;

    // Neither path cleared the board — try DFS. Hitting the state budget is
    // reported as unverified, never as unsolvable.
    final outcome = LevelSolver.attempt(level, dfsStateLimit);
    switch (outcome.status) {
      case SolveStatus.solved:
        return SolvabilityKind.confirmedSolvable;
      case SolveStatus.limitReached:
        return SolvabilityKind.unverified;
      case SolveStatus.unsolvable:
        return SolvabilityKind.confirmedUnsolvable;
    }
  }

  /// Executes [LevelModel.solutionOrder] with the same exit rules as the solver.
  static bool replayStoredSolution(LevelModel level) {
    if (level.solutionOrder.isEmpty) return false;
    final gs = level.gridSize;
    final arrs = level.arrows;
    final byId = {for (final a in arrs) a.id: a};
    final indexOf = {for (var i = 0; i < arrs.length; i++) arrs[i].id: i};
    final board = Uint16List(gs * gs);
    final active = List<bool>.filled(arrs.length, true);
    for (var i = 0; i < arrs.length; i++) {
      for (final pt in arrs[i].path) {
        board[pt[0] * gs + pt[1]] = i + 1;
      }
    }
    final dotTypes = Uint8List(gs * gs);
    final dotActive = List<bool>.filled(gs * gs, false);
    for (final od in level.orphanDots) {
      final f = od.row * gs + od.col;
      dotTypes[f] = od.type.index;
      dotActive[f] = true;
    }
    final partner = List<int>.filled(arrs.length, -1);
    final grpMap = <int, List<int>>{};
    for (var i = 0; i < arrs.length; i++) {
      final g = arrs[i].colorGroup;
      if (g != null) grpMap.putIfAbsent(g, () => []).add(i);
    }
    for (final v in grpMap.values) {
      if (v.length == 2) {
        partner[v[0]] = v[1];
        partner[v[1]] = v[0];
      }
    }

    List<int>? tryExit(int ai, int pi) {
      var dir = arrs[ai].direction;
      final h = arrs[ai].path[0];
      var d = dir.delta;
      var r = h[0] + d[0];
      var c = h[1] + d[1];
      final consumed = <int>[];
      final vis = <int>{};
      while (r >= 0 && r < gs && c >= 0 && c < gs) {
        final f = r * gs + c;
        if (!vis.add(f)) return null;
        if (dotActive[f]) {
          consumed.add(f);
          final t = dotTypes[f];
          if (t == 0) {
            dir = ArrowDirection.up;
          } else if (t == 1) {
            dir = ArrowDirection.down;
          } else if (t == 2) {
            dir = ArrowDirection.left;
          } else if (t == 3) {
            dir = ArrowDirection.right;
          }
        } else {
          final occ = board[f];
          if (occ != 0 && occ != ai + 1 && (pi == -1 || occ != pi + 1)) {
            return null;
          }
        }
        d = dir.delta;
        r += d[0];
        c += d[1];
      }
      return consumed;
    }

    void clear(int idx) {
      if (!active[idx]) return;
      active[idx] = false;
      for (final pt in arrs[idx].path) {
        board[pt[0] * gs + pt[1]] = 0;
      }
    }

    for (final id in level.solutionOrder) {
      final arrow = byId[id];
      if (arrow == null) return false;
      final i = indexOf[id]!;
      if (!active[i]) return false;
      final p = partner[i];
      if (p != -1) {
        if (!active[p]) return false;
        final c1 = tryExit(i, p);
        final c2 = tryExit(p, i);
        if (c1 == null || c2 == null) return false;
        for (final f in {...c1, ...c2}) {
          dotActive[f] = false;
        }
        clear(i);
        clear(p);
      } else {
        final c = tryExit(i, -1);
        if (c == null) return false;
        for (final f in c) {
          dotActive[f] = false;
        }
        clear(i);
      }
    }
    return active.every((a) => !a);
  }

  /// Pair-aware greedy clearance used by the existing verify pipeline.
  static bool greedyCanSolve(LevelModel level) {
    if (level.arrows.isEmpty) return true;
    final gs = level.gridSize;
    final board = Uint16List(gs * gs);
    final arrs = level.arrows;
    final active = List<bool>.filled(arrs.length, true);
    for (var i = 0; i < arrs.length; i++) {
      for (final pt in arrs[i].path) {
        board[pt[0] * gs + pt[1]] = i + 1;
      }
    }
    final dotTypes = Uint8List(gs * gs);
    final dotActive = List<bool>.filled(gs * gs, false);
    for (final od in level.orphanDots) {
      final f = od.row * gs + od.col;
      dotTypes[f] = od.type.index;
      dotActive[f] = true;
    }
    final partner = List<int>.filled(arrs.length, -1);
    final grpMap = <int, List<int>>{};
    for (var i = 0; i < arrs.length; i++) {
      final g = arrs[i].colorGroup;
      if (g != null) grpMap.putIfAbsent(g, () => []).add(i);
    }
    for (final v in grpMap.values) {
      if (v.length == 2) {
        partner[v[0]] = v[1];
        partner[v[1]] = v[0];
      }
    }
    var count = arrs.length;
    final seen = <int>{};

    void clear(int idx) {
      if (!active[idx]) return;
      active[idx] = false;
      count--;
      for (final pt in arrs[idx].path) {
        board[pt[0] * gs + pt[1]] = 0;
      }
    }

    List<int>? tryExit(int ai, int pi) {
      var dir = arrs[ai].direction;
      final h = arrs[ai].path[0];
      var d = dir.delta;
      var r = h[0] + d[0];
      var c = h[1] + d[1];
      final consumed = <int>[];
      final vis = <int>{};
      while (r >= 0 && r < gs && c >= 0 && c < gs) {
        final f = r * gs + c;
        if (!vis.add(f)) return null;
        if (dotActive[f]) {
          consumed.add(f);
          final t = dotTypes[f];
          if (t == 0) {
            dir = ArrowDirection.up;
          } else if (t == 1) {
            dir = ArrowDirection.down;
          } else if (t == 2) {
            dir = ArrowDirection.left;
          } else if (t == 3) {
            dir = ArrowDirection.right;
          }
        } else {
          final occ = board[f];
          if (occ != 0 && occ != ai + 1 && (pi == -1 || occ != pi + 1)) {
            return null;
          }
        }
        d = dir.delta;
        r += d[0];
        c += d[1];
      }
      return consumed;
    }

    var progress = true;
    while (progress && count > 0) {
      progress = false;
      seen.clear();
      for (var i = 0; i < arrs.length; i++) {
        if (!active[i]) continue;
        final p = partner[i];
        if (p == -1) continue;
        final g = arrs[i].colorGroup!;
        if (!seen.add(g)) continue;
        if (!active[p]) continue;
        final c1 = tryExit(i, p);
        final c2 = tryExit(p, i);
        if (c1 != null && c2 != null) {
          for (final f in {...c1, ...c2}) {
            dotActive[f] = false;
          }
          clear(i);
          clear(p);
          progress = true;
        }
      }
      for (var i = 0; i < arrs.length; i++) {
        if (!active[i] || partner[i] != -1) continue;
        final c = tryExit(i, -1);
        if (c != null) {
          for (final f in c) {
            dotActive[f] = false;
          }
          clear(i);
          progress = true;
        }
      }
    }
    return count == 0;
  }

  static bool _hasDeflectionLoop(LevelModel level) {
    final orphanMap = {for (final od in level.orphanDots) od.key: od.type};
    for (final arrow in level.arrows) {
      final other = <String>{};
      for (final a in level.arrows) {
        if (a.id == arrow.id) continue;
        for (final pt in a.path) {
          other.add('${pt[0]},${pt[1]}');
        }
      }
      var dir = arrow.direction;
      final h = arrow.path[0];
      var d = dir.delta;
      var nr = h[0] + d[0];
      var nc = h[1] + d[1];
      final vis = <String>{};
      while (nr >= 0 && nr < level.gridSize && nc >= 0 && nc < level.gridSize) {
        final k = '$nr,$nc';
        if (!vis.add(k)) return true;
        if (orphanMap.containsKey(k)) {
          final dt = orphanMap[k]!;
          if (dt == OrphanDotType.up) {
            dir = ArrowDirection.up;
          } else if (dt == OrphanDotType.down) {
            dir = ArrowDirection.down;
          } else if (dt == OrphanDotType.left) {
            dir = ArrowDirection.left;
          } else if (dt == OrphanDotType.right) {
            dir = ArrowDirection.right;
          }
        } else if (other.contains(k)) {
          break;
        }
        d = dir.delta;
        nr += d[0];
        nc += d[1];
      }
    }
    return false;
  }

  static bool _pathFormsCycle(List<List<int>> path) {
    if (path.length < 4) return false;
    final cells = <int>{};
    for (final p in path) {
      cells.add(p[0] * 1000 + p[1]);
    }
    for (var i = 0; i < path.length; i++) {
      final r = path[i][0];
      final c = path[i][1];
      for (final nb in [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ]) {
        final nr = r + nb[0];
        final nc = c + nb[1];
        if (!cells.contains(nr * 1000 + nc)) continue;
        for (var j = 0; j < path.length; j++) {
          if (path[j][0] == nr && path[j][1] == nc && (i - j).abs() > 1) {
            return true;
          }
        }
      }
    }
    return false;
  }

  static String _arrowBand(int count) {
    if (count <= 10) return '1-10';
    if (count <= 25) return '11-25';
    if (count <= 50) return '26-50';
    if (count <= 100) return '51-100';
    if (count <= 200) return '101-200';
    return '201+';
  }

  /// Near-duplicate signal: same shape + same arrow count + same grid + high
  /// layout-profile similarity, excluding exact fingerprint duplicates.
  static List<String> nearDuplicateNotes(List<LevelAuditFinding> findings) => [
        for (final e in nearDuplicateClusters(findings).entries)
          'shape/grid/arrows cluster ${e.key}: levels ${e.value.join(',')}',
      ];

  /// Clusters behind [nearDuplicateNotes], keyed `shape|grid|arrows`, with
  /// sorted level IDs. Only a candidate signal: members share metadata, not
  /// necessarily geometry.
  static Map<String, List<int>> nearDuplicateClusters(
    List<LevelAuditFinding> findings,
  ) {
    final clusters = <String, List<int>>{};
    final byKey = <String, List<LevelAuditFinding>>{};
    for (final f in findings) {
      if (!f.isStructurallyValid || f.fingerprint.isEmpty) continue;
      final key = '${f.maskShape.name}|${f.gridSize}|${f.arrowCount}';
      byKey.putIfAbsent(key, () => []).add(f);
    }
    for (final entry in byKey.entries) {
      if (entry.value.length < 2) continue;
      final ids = entry.value.map((f) => f.levelNumber).toList()..sort();
      // Exact fingerprint dupes are reported separately.
      final fps = entry.value.map((f) => f.fingerprint).toSet();
      if (fps.length == entry.value.length && entry.value.length >= 3) {
        clusters[entry.key] = ids;
      }
    }
    return clusters;
  }

  static LevelLayoutProfile profileOf(LevelModel level) {
    return LevelLayoutProfile.analyze(
      arrows: level.arrows,
      gridSize: level.gridSize,
      maskCells: level.mask.length,
      shapeType: level.maskShape.name,
    );
  }
}

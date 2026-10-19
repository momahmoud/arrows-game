import 'dart:math' as math;

import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/models/level.dart';

import 'candidate_builder.dart';

/// Arrow-count and path-diversity targets for first_500_quality_v2.
///
/// Root cause of v1 sparsity: phase briefs hardcoded ~18–30 arrows for normals
/// (production medians ~38–55) and fill floors ~0.72–0.78, while crowding
/// rejection discarded denser seeds. Zigzag share was already high per arrow;
/// boards looked empty because there were too few arrows, not too few bends.
class DensityPolicy {
  DensityPolicy._();

  /// Minimum retained fraction of production arrow units (records).
  static const double minRetain = 0.75;

  /// Preferred retain fraction for ordinary normals.
  /// Reverse construction rarely hits 90% while staying readable; 82% is the
  /// practical intent (still far above v1's ~55% medians in 251–500).
  static const double preferRetain = 0.82;

  /// Breathers keep a little more breathing room.
  static const double breatherRetain = 0.80;

  /// Overcrowded specials (prod arrows ≥ this) get a documented ceiling.
  static const int overcrowdedSpecialFloor = 100;

  static bool isSpecial(int level) =>
      AppConstants.levelTypeFor(level) != LevelType.normal;

  /// Target arrow record count for reverse construction.
  static int targetArrows(
    LevelModel production, {
    required bool breather,
    String? exceptionTag,
  }) {
    final n = production.arrows.length;
    final level = production.levelNumber;
    if (level <= 3) return n;

    if (isSpecial(level) && n >= overcrowdedSpecialFloor) {
      // Documented exception: do not restore extreme open/crowd specials.
      // Aim for a substantial but readable board.
      final capped = math.max(56, math.min(95, (n * 0.42).round()));
      exceptionTag; // caller records reason
      return capped;
    }
    if (isSpecial(level) && n >= 80) {
      return math.max(48, math.min(100, (n * 0.70).round()));
    }

    final ratio = breather ? breatherRetain : preferRetain;
    final preferred = (n * ratio).round();
    final floor = (n * minRetain).ceil();
    return math.max(floor, preferred);
  }

  /// Whether [candidate] meets the retain floor (or a documented special cap).
  static bool meetsRetainFloor(LevelModel production, LevelModel candidate) {
    final n = production.arrows.length;
    final c = candidate.arrows.length;
    if (production.levelNumber <= 3) return c == n;
    if (isSpecial(production.levelNumber) && n >= overcrowdedSpecialFloor) {
      return c >= 48 && c <= 120;
    }
    if (n == 0) return true;
    return c >= (n * minRetain).ceil();
  }

  /// Accept a densified layout that beats v1 even when below the 75% floor
  /// (documented exception — still denser / repaired vs sparse v1).
  static bool acceptableVsV1({
    required LevelModel production,
    required LevelModel candidate,
    required LevelModel v1,
  }) {
    if (meetsRetainFloor(production, candidate)) return true;
    final c = candidate.arrows.length;
    final v = v1.arrows.length;
    final n = production.arrows.length;
    if (c >= v && c >= (n * 0.45).ceil()) return true;
    if (isSpecial(production.levelNumber) && c >= 48 && c > v) return true;
    return false;
  }

  /// Exception reason when target is below 75% of production, else null.
  static String? exceptionReason(LevelModel production, int target) {
    final n = production.arrows.length;
    if (n == 0) return null;
    if (target >= (n * minRetain).ceil()) return null;
    if (isSpecial(production.levelNumber) && n >= overcrowdedSpecialFloor) {
      return 'overcrowded_special_cap: prod=$n target=$target '
          '(readable ceiling, not 75% restore)';
    }
    return 'below_floor: prod=$n target=$target';
  }

  /// Rewrite a phase brief toward production density + zigzag-friendly growth.
  static CandidateBrief densifyBrief(
    CandidateBrief brief,
    LevelModel production, {
    required bool breather,
    int? trapsOverride,
    int extraSalt = 17,
  }) {
    final target = targetArrows(production, breather: breather);
    final special = isSpecial(production.levelNumber);
    return brief.copyWith(
      arrows: math.max(brief.arrows, target),
      minLen: brief.minLen,
      maxLen: math.max(brief.maxLen, special ? 12 : 11),
      traps: trapsOverride ?? brief.traps,
      fill: math.max(brief.fill, special ? 0.84 : 0.88),
      straightness: 0.34,
      tailGrowth: math.max(brief.tailGrowth, special ? 12 : 10),
      outlineBias: math.max(brief.outlineBias, special ? 0.45 : 0.22),
      seeds: special ? 160 : 144,
      seedSalt: brief.seedSalt + extraSalt,
    );
  }

  static int pathBends(List<List<int>> path) {
    if (path.length < 3) return 0;
    var b = 0;
    for (var i = 1; i < path.length - 1; i++) {
      final dr1 = path[i][0] - path[i - 1][0];
      final dc1 = path[i][1] - path[i - 1][1];
      final dr2 = path[i + 1][0] - path[i][0];
      final dc2 = path[i + 1][1] - path[i][1];
      if (dr1 != dr2 || dc1 != dc2) b++;
    }
    return b;
  }

  static double multiTurnShare(LevelModel level) {
    if (level.arrows.isEmpty) return 0;
    var multi = 0;
    for (final a in level.arrows) {
      if (pathBends(a.path) >= 1) multi++;
    }
    return multi / level.arrows.length;
  }

  /// Geometry-aware multi-turn floor for normals on larger grids.
  static double multiTurnTarget(LevelModel production) {
    if (production.levelNumber <= 3) return 0;
    if (isSpecial(production.levelNumber)) {
      // Small masks: any multi-turn diversity helps; 35% is enough.
      return 0.35;
    }
    if (production.gridSize >= 20) return 0.50;
    return 0.40;
  }
}

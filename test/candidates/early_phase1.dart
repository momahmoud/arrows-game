import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_generator/level_quality.dart';
import 'package:arrow_escape/data/models/level.dart';

import 'candidate_builder.dart';
import 'candidate_checks.dart';

/// Phase-1 early-campaign candidates (levels 4–24). Development only: the
/// output is written under build/ and never replaces assets/levels.bin.
///
/// Mechanics are introduced in the order the tutorials taught them
/// (blocking → pairs → deflectors), each first in a normal level, then in a
/// special level, and order traps only after deflectors are familiar.
class EarlyPhase1 {
  EarlyPhase1._();

  static const int first = 4;
  static const int last = 24;

  static final Map<int, EarlyDesign> designs = {
    for (final d in _designs) d.level: d,
  };

  static final List<EarlyDesign> _designs = [
    const EarlyDesign(4,
        intent: 'First real board: blocking only, a short two-step chain, '
            'large cells.',
        mask: MaskPlan.scaled(8, 6),
        brief: CandidateBrief(arrows: 7, minLen: 2, maxLen: 4),
        opening: (2, 3),
        maxPeel: 4,
        minPeel: 3),
    const EarlyDesign(5,
        intent: 'Bent bodies: an arrow can be blocked by another arrow\'s '
            'body, not just its head.',
        mask: MaskPlan.scaled(9, 9),
        brief:
            CandidateBrief(arrows: 9, minLen: 3, maxLen: 5, straightness: 0.35),
        opening: (2, 3),
        maxPeel: 5,
        minPeel: 4),
    const EarlyDesign(6,
        intent: 'Pair returns from tutorial 2 inside a small chain.',
        mask: MaskPlan.scaled(9, 10),
        brief: CandidateBrief(arrows: 10, minLen: 3, maxLen: 5, pairs: 1),
        opening: (2, 3),
        maxPeel: 6,
        minPeel: 4),
    const EarlyDesign(7,
        intent: 'First boss: deflectors return from tutorial 3 on a large '
            'shape; deeper chain, narrow start, no traps.',
        brief: CandidateBrief(
            seeds: 256, arrows: 28, minLen: 5, maxLen: 12, detours: 3),
        opening: (3, 7),
        minPeel: 9),
    const EarlyDesign(8,
        intent: 'Breather after the boss: small board, two deflectors to '
            'practise reading a turn.',
        mask: MaskPlan.scaled(10, 11),
        brief: CandidateBrief(arrows: 9, minLen: 3, maxLen: 6, detours: 2),
        opening: (3, 4),
        maxPeel: 5,
        minPeel: 3),
    const EarlyDesign(9,
        intent: 'Deflectors and a pair together on the original octagon.',
        brief: CandidateBrief(
            arrows: 12, minLen: 3, maxLen: 7, detours: 2, pairs: 1),
        opening: (2, 4),
        minPeel: 5),
    const EarlyDesign(10,
        intent: 'First god: pairs as locks. Each pair needs both of its '
            'exits clear at once.',
        brief: CandidateBrief(
            seeds: 256,
            arrows: 26,
            minLen: 5,
            maxLen: 12,
            pairs: 3,
            detours: 2),
        opening: (3, 7),
        minPeel: 8),
    const EarlyDesign(11,
        intent: 'Breather: several free openings, one deflector.',
        brief: CandidateBrief(arrows: 11, minLen: 3, maxLen: 7, detours: 1),
        opening: (3, 5),
        maxPeel: 6,
        minPeel: 4),
    const EarlyDesign(12,
        intent: 'First order trap: one shared deflector between two facing '
            'arrows. Using it with the wrong arrow strands them.',
        brief: CandidateBrief(
            arrows: 12, minLen: 3, maxLen: 6, traps: 1, detours: 1),
        opening: (2, 4),
        minPeel: 5,
        traps: true),
    const EarlyDesign(13,
        intent: 'Depth without traps: two pairs and two deflectors in a '
            'longer chain.',
        brief: CandidateBrief(
            arrows: 15, minLen: 4, maxLen: 8, pairs: 2, detours: 2),
        opening: (2, 4),
        minPeel: 7),
    const EarlyDesign(14,
        intent: 'Boss with a trap: a deflector network on a big shape with '
            'one order trap and one pair.',
        brief: CandidateBrief(
            seeds: 512,
            arrows: 36,
            minLen: 6,
            maxLen: 13,
            traps: 1,
            detours: 3,
            pairs: 1),
        opening: (3, 7),
        minPeel: 10,
        traps: true),
    const EarlyDesign(15,
        intent: 'Breather: short chain, one deflector, no traps.',
        brief: CandidateBrief(arrows: 11, minLen: 3, maxLen: 7, detours: 1),
        opening: (3, 5),
        maxPeel: 6,
        minPeel: 4),
    const EarlyDesign(16,
        intent: 'Trap plus pair: freeing the pair\'s second side competes '
            'with the trap deflector.',
        brief: CandidateBrief(
            arrows: 15, minLen: 3, maxLen: 7, traps: 1, pairs: 1, detours: 1),
        opening: (2, 4),
        minPeel: 6,
        traps: true),
    const EarlyDesign(17,
        intent: 'God: one trap, three pairs and three deflectors.',
        brief: CandidateBrief(
            seeds: 256,
            arrows: 38,
            minLen: 6,
            maxLen: 13,
            traps: 1,
            pairs: 3,
            detours: 3),
        opening: (3, 7),
        minPeel: 10,
        traps: true),
    const EarlyDesign(18,
        intent: 'One trap with two working deflectors nearby.',
        brief: CandidateBrief(
            arrows: 16, minLen: 4, maxLen: 8, traps: 1, detours: 2, pairs: 1),
        opening: (2, 4),
        minPeel: 7,
        traps: true),
    const EarlyDesign(19,
        intent: 'Breather: deflectors only, no traps.',
        brief: CandidateBrief(arrows: 13, minLen: 3, maxLen: 7, detours: 2),
        opening: (3, 5),
        maxPeel: 7,
        minPeel: 5),
    const EarlyDesign(20,
        intent: 'Larger grid (25): one trap, two pairs, two deflectors.',
        brief: CandidateBrief(
            arrows: 18, minLen: 4, maxLen: 9, traps: 1, pairs: 2, detours: 2),
        opening: (2, 4),
        minPeel: 8,
        traps: true),
    const EarlyDesign(21,
        intent: 'Boss: deflector-heavy, two traps, one pair.',
        brief: CandidateBrief(
            seeds: 512,
            arrows: 40,
            minLen: 6,
            maxLen: 13,
            traps: 2,
            detours: 6,
            pairs: 1),
        opening: (3, 7),
        minPeel: 10,
        traps: true),
    const EarlyDesign(22,
        intent: 'One trap, a pair and three deflectors.',
        brief: CandidateBrief(
            arrows: 19, minLen: 4, maxLen: 9, traps: 1, pairs: 1, detours: 3),
        opening: (2, 4),
        minPeel: 8,
        traps: true),
    const EarlyDesign(23,
        intent: 'Breather before the god: pairs and deflectors, no traps.',
        brief: CandidateBrief(
            arrows: 16, minLen: 4, maxLen: 8, pairs: 2, detours: 2),
        opening: (3, 5),
        maxPeel: 7,
        minPeel: 6),
    const EarlyDesign(24,
        intent: 'God finale of the opening arc: two traps, four pairs, '
            'four deflectors.',
        brief: CandidateBrief(
            seeds: 512,
            arrows: 50,
            minLen: 5,
            maxLen: 13,
            traps: 2,
            pairs: 4,
            detours: 4),
        opening: (3, 7),
        minPeel: 10,
        traps: true),
  ];

  /// Builds every candidate from the original level's grid, shape, label and
  /// name. Returns the chosen layout per level with its selection evidence.
  static Map<int, CandidateChoice> build(Map<int, LevelModel> originals) {
    return {
      for (var n = first; n <= last; n++) n: choose(designs[n]!, originals[n]!),
    };
  }

  /// Ranks the seeds that meet the brief by [EarlyDesign.score]. Trap levels
  /// then take the best layout in which every trap is a reachable decision
  /// (exhaustive search, see [checkTrap]).
  static CandidateChoice choose(EarlyDesign design, LevelModel original) {
    final template = design.mask.apply(original);
    final built = CandidateBuilder.buildAll(
        template, design.brief.withFill(design.fillTarget));
    final ranked = <CandidateChoice>[];
    CandidateChoice? firstRejected;
    for (final b in built) {
      final p = LevelQuality.profile(b.level);
      final rejected = design.rejectReason(b, p);
      final choice = CandidateChoice(
          design,
          b,
          p,
          rejected == null ? design.score(p) : double.negativeInfinity,
          rejected);
      if (rejected == null) {
        ranked.add(choice);
      } else {
        firstRejected ??= choice;
      }
    }
    ranked.sort((a, b) => a.score != b.score
        ? b.score.compareTo(a.score)
        : a.built.seed.compareTo(b.built.seed));
    for (final c in ranked) {
      final live = c.built.traps.every((t) =>
          checkTrap(c.level, t.x, t.y, t.z, t.dotRow, t.dotCol)
              .decisionReachable);
      if (live) return c;
    }
    final shown = ranked.isEmpty ? firstRejected! : ranked.first;
    return CandidateChoice(design, shown.built, shown.profile,
        double.negativeInfinity, shown.rejected ?? 'no layout with live traps');
  }
}

class EarlyDesign {
  const EarlyDesign(
    this.level, {
    required this.intent,
    required this.brief,
    required this.opening,
    required this.minPeel,
    this.mask = const MaskPlan.original(),
    this.traps = false,
    this.maxPeel,
  });

  final int level;
  final String intent;
  final CandidateBrief brief;
  final MaskPlan mask;

  /// Intended number of tap units free at the start.
  final (int, int) opening;
  final int minPeel;

  /// Depth ceiling for introductory and breather levels.
  final int? maxPeel;

  /// Whether this level is meant to contain an order trap. Levels without
  /// one must never dead-end.
  final bool traps;

  LevelType get type => AppConstants.levelTypeFor(level);

  /// Share of silhouette cells covered by arrows, so the shape still reads.
  /// The brief's arrow count is only where placement stops; tails then grow
  /// toward this target. Small introductory boards stay lighter.
  double get fillTarget => type != LevelType.normal
      ? 0.82
      : mask.rows > 0
          ? 0.7
          : 0.8;

  double get minFill => fillTarget - 0.05;

  /// Share of heads with another head in the 8 surrounding cells. The
  /// originals for 4–24 sit at 0.50–0.85.
  static const double maxHeadCrowding = 0.55;

  /// Ceiling on the share of seeded random playouts that dead-end. The
  /// first trap levels stay forgiving; later ones may punish more.
  double get maxDeadEnd => level <= 14
      ? 0.4
      : level <= 20
          ? 0.55
          : 0.65;

  String? rejectReason(BuiltCandidate b, LevelQualityProfile p) {
    if (b.trapsPlaced < brief.traps) return 'traps ${b.trapsPlaced}';
    if (b.pairsPlaced < brief.pairs) return 'pairs ${b.pairsPlaced}';
    if (b.detoursPlaced < brief.detours) return 'detours ${b.detoursPlaced}';
    if (p.fill < minFill) return 'fill ${p.fill.toStringAsFixed(2)}';
    if (traps && p.deadEndRate == 0) return 'trap never reached';
    if (p.deadEndRate > maxDeadEnd) {
      return 'dead end ${p.deadEndRate.toStringAsFixed(2)}';
    }
    if (!traps && p.deadEndRate > 0) return 'unintended dead end';
    if (p.openingMoves < opening.$1 || p.openingMoves > opening.$2) {
      return 'opening ${p.openingMoves}';
    }
    if (p.headCrowding > maxHeadCrowding) {
      return 'crowded heads ${p.headCrowding.toStringAsFixed(2)}';
    }
    if (p.peelRounds < minPeel || p.peelRounds > (maxPeel ?? p.peelRounds)) {
      return 'peel ${p.peelRounds}';
    }
    return null;
  }

  /// Prefers spread-out heads, a fuller silhouette and (for trap levels) a
  /// trap that random play hits sometimes but not almost always.
  double score(LevelQualityProfile p) {
    var s = -p.headCrowding * 4 + p.fill * 2 + p.peelRounds * 0.15;
    if (traps) s -= (p.deadEndRate - 0.35).abs() * 3;
    return s;
  }
}

/// Where a candidate's playable cells come from.
class MaskPlan {
  const MaskPlan.original()
      : rows = 0,
        cols = 0;

  /// Nearest-neighbour downscale of the original silhouette, centred.
  const MaskPlan.scaled(this.rows, this.cols);

  final int rows;
  final int cols;

  LevelModel apply(LevelModel original) {
    if (rows == 0) {
      return original.copyWith(
          arrows: const [], orphanDots: const [], solutionOrder: const []);
    }
    var minR = 1 << 30, maxR = -1, minC = 1 << 30, maxC = -1;
    final src = <int>{};
    final gs = original.gridSize;
    for (final key in original.mask) {
      final p = key.split(',');
      final r = int.parse(p[0]), c = int.parse(p[1]);
      src.add(r * gs + c);
      if (r < minR) minR = r;
      if (r > maxR) maxR = r;
      if (c < minC) minC = c;
      if (c > maxC) maxC = c;
    }
    final h = maxR - minR + 1, w = maxC - minC + 1;
    final top = (gs - rows) ~/ 2, left = (gs - cols) ~/ 2;
    final mask = <String>{};
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final sr = minR + ((r + 0.5) * h / rows).floor();
        final sc = minC + ((c + 0.5) * w / cols).floor();
        if (src.contains(sr * gs + sc)) mask.add('${r + top},${c + left}');
      }
    }
    return original.copyWith(
        arrows: const [],
        orphanDots: const [],
        solutionOrder: const [],
        mask: mask);
  }
}

class CandidateChoice {
  CandidateChoice(
      this.design, this.built, this.profile, this.score, this.rejected);

  final EarlyDesign design;
  final BuiltCandidate built;
  final LevelQualityProfile profile;
  final double score;

  /// Why the chosen layout misses its brief, or null when it meets it.
  final String? rejected;

  LevelModel get level => built.level;
  bool get meetsBrief => rejected == null;
}

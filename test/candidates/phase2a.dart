import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_generator/level_quality.dart';
import 'package:arrow_escape/data/models/level.dart';

import 'candidate_builder.dart';
import 'early_phase1.dart';
import 'early_phase1b.dart';
import 'silhouette_metrics.dart';

/// Phase 2A pilot: rework campaign levels 251–300 only. Development output
/// under build/candidates/phase2a_251_300/; never writes assets/levels.bin.
///
/// Design goals vs the production plateau after ~250:
/// - intentional order decisions (live traps) instead of inert directional dots
/// - gradual ramp across five decades with deliberate breathers
/// - bosses and gods deeper / more decision-heavy than surrounding normals
/// - readable density (lower arrow counts than production) with outline bias
///   on specials so silhouettes stay occupied
class Phase2A {
  Phase2A._();

  static const int first = 251;
  static const int last = 300;
  static const int seedSalt = 22;

  /// Normals that stay order-independent (breathers).
  static const Set<int> breathers = {
    254,
    260,
    268,
    275,
    282,
    289,
    296,
    300,
  };

  static Phase2ADesign designFor(int level) {
    assert(level >= first && level <= last);
    final type = AppConstants.levelTypeFor(level);
    final band = (level - first) ~/ 10; // 0..4
    final breather = breathers.contains(level);

    if (type == LevelType.boss) {
      return Phase2ADesign(
        level: level,
        intent: 'Boss: order traps and deflector network; deeper peel than '
            'surrounding normals; outline-biased silhouette.',
        brief: CandidateBrief(
          seeds: 448,
          seedSalt: seedSalt,
          arrows: 48 + band * 3,
          minLen: 4,
          maxLen: 11,
          traps: band < 2 ? 1 : 2,
          detours: 3 + (band ~/ 2),
          pairs: 2,
          fill: 0.74,
          tailGrowth: 10,
          outlineBias: 0.55,
        ),
        opening: (4, 18),
        minPeel: 8 + band ~/ 2,
        traps: true,
        maxDeadEnd: band < 2 ? 0.55 : 0.65,
        minFillSlack: 0.08,
        maxHeadCrowding: 0.50,
      );
    }

    if (type == LevelType.god) {
      // L290 is a known production weak special (36 arrows, peel 6); force a
      // distinctive god role while keeping the sun mask.
      final weakRescue = level == 290;
      // The sun mask is only ~248 cells (18×18 content), so peel depth cannot
      // match large gods; distinctiveness is a live trap + denser decisions
      // than the production L290 (peel 6, dead-end rate 0).
      return Phase2ADesign(
        level: level,
        intent: weakRescue
            ? 'God rescue on a small sun mask: live order trap and pair locks; '
                'peel is capped by silhouette size, not by weak generation.'
            : 'God: deepest peel in the cycle, two live traps, pair locks, '
                'outline-biased silhouette.',
        brief: CandidateBrief(
          seeds: 512,
          seedSalt: seedSalt,
          arrows: weakRescue ? 30 : 52 + band * 3,
          minLen: weakRescue ? 3 : 4,
          maxLen: weakRescue ? 9 : 12,
          traps: weakRescue ? 1 : 2,
          detours: weakRescue ? 2 : 4,
          pairs: weakRescue ? 2 : 3,
          fill: weakRescue ? 0.78 : 0.74,
          tailGrowth: weakRescue ? 8 : 10,
          outlineBias: 0.55,
        ),
        opening: weakRescue ? (4, 10) : (4, 14),
        minPeel: weakRescue ? 6 : 10 + band ~/ 2,
        traps: true,
        maxDeadEnd: 0.65,
        minFillSlack: 0.08,
        maxHeadCrowding: 0.50,
      );
    }

    // Normal levels.
    if (breather) {
      return Phase2ADesign(
        level: level,
        intent: 'Breather: readable board, deflectors/pairs without traps.',
        brief: CandidateBrief(
          seeds: 128,
          seedSalt: seedSalt,
          arrows: 18 + band,
          minLen: 3,
          maxLen: 8,
          traps: 0,
          detours: 2,
          pairs: band >= 2 ? 2 : 1,
          fill: 0.74,
          tailGrowth: 5,
          outlineBias: 0.2,
        ),
        opening: (3, 5),
        minPeel: 6 + band,
        maxPeel: 10 + band,
        traps: false,
      );
    }

    // At most one trap on normals so openings stay readable; late bands add
    // detours/pairs instead of a second trap.
    final traps = breather
        ? 0
        : band == 0
            ? (level % 2 == 0 ? 1 : 0)
            : 1;
    final openMax = traps > 0 ? (band >= 4 ? 10 : 8) : 5;
    return Phase2ADesign(
      level: level,
      intent: traps == 0
          ? 'Normal: structured blocking and deflectors; no order trap.'
          : 'Normal: one live order trap among deflectors and pairs.',
      brief: CandidateBrief(
        seeds: traps > 0 ? 320 : 128,
        seedSalt: seedSalt,
        arrows: 20 + band * 2,
        minLen: 4,
        maxLen: 9,
        traps: traps,
        detours: 2 + band ~/ 2 + (band >= 3 ? 1 : 0),
        pairs: 1 + (band >= 2 ? 1 : 0),
        fill: 0.76,
        tailGrowth: 6,
        outlineBias: 0.25,
      ),
      opening: (2, openMax),
      minPeel: 6 + band ~/ 2,
      traps: traps > 0,
      maxDeadEnd: band >= 3 ? 0.6 : 0.5,
      minFillSlack: 0.10,
      maxHeadCrowding: 0.50,
    );
  }

  static Map<int, CandidateChoice> build(Map<int, LevelModel> originals) => {
        for (var n = first; n <= last; n++)
          n: choose(designFor(n), originals[n]!),
      };

  static CandidateChoice choose(Phase2ADesign design, LevelModel original) {
    final template = original.copyWith(
        arrows: const [], orphanDots: const [], solutionOrder: const []);
    final built = CandidateBuilder.buildAll(template, design.brief);
    final ranked = <_Scored>[];
    CandidateChoice? briefMiss;
    var metBrief = 0;
    for (final b in built) {
      final p = LevelQuality.profile(b.level);
      final rejected = design.rejectReason(b, p);
      if (rejected != null) {
        briefMiss ??= CandidateChoice(
            _asEarly(design), b, p, double.negativeInfinity, rejected);
        continue;
      }
      metBrief++;
      if (design.traps) {
        // Small BFS cap then constructive solution-path fallback.
        final live = b.traps
            .every((t) => TrapFairness.analyse(b.level, t, cap: 12000).ok);
        if (!live) continue;
      }
      final sil = SilhouetteMetrics.of(b.level);
      final score = design.score(p, sil);
      ranked.add(
          _Scored(CandidateChoice(_asEarly(design), b, p, score, null), score));
    }
    ranked.sort((a, b) => a.score != b.score
        ? b.score.compareTo(a.score)
        : a.choice.built.seed.compareTo(b.choice.built.seed));
    if (ranked.isNotEmpty) {
      final best = ranked.first;
      return CandidateChoice(_asEarly(design), best.choice.built,
          best.choice.profile, best.score, null);
    }
    final why = metBrief > 0
        ? 'no fair layout ($metBrief met brief)'
        : briefMiss?.rejected ?? 'no seed met brief';
    // Last resort: best brief-meeting seed without fairness (should fail tests).
    if (briefMiss != null && metBrief == 0) {
      return CandidateChoice(_asEarly(design), briefMiss.built,
          briefMiss.profile, double.negativeInfinity, why);
    }
    // Prefer any brief-meeting seed even if fairness failed, marked rejected.
    for (final b in built) {
      final p = LevelQuality.profile(b.level);
      if (design.rejectReason(b, p) == null) {
        return CandidateChoice(
            _asEarly(design), b, p, double.negativeInfinity, why);
      }
    }
    return CandidateChoice(_asEarly(design), briefMiss!.built,
        briefMiss.profile, double.negativeInfinity, why);
  }

  /// Adapt to the shared [CandidateChoice] type used by the test harness.
  static EarlyDesign _asEarly(Phase2ADesign d) => EarlyDesign(
        d.level,
        intent: d.intent,
        brief: d.brief,
        opening: d.opening,
        minPeel: d.minPeel,
        maxPeel: d.maxPeel,
        traps: d.traps,
      );
}

class _Scored {
  _Scored(this.choice, this.score);
  final CandidateChoice choice;
  final double score;
}

class Phase2ADesign {
  const Phase2ADesign({
    required this.level,
    required this.intent,
    required this.brief,
    required this.opening,
    required this.minPeel,
    this.maxPeel,
    this.traps = false,
    this.maxDeadEnd = 0.55,
    this.maxHeadCrowding = 0.45,
    this.minFillSlack = 0.05,
  });

  final int level;
  final String intent;
  final CandidateBrief brief;
  final (int, int) opening;
  final int minPeel;
  final int? maxPeel;
  final bool traps;
  final double maxDeadEnd;
  final double maxHeadCrowding;

  /// How far below [CandidateBrief.fill] is still accepted.
  final double minFillSlack;

  LevelType get type => AppConstants.levelTypeFor(level);

  double get minFill => brief.fill - minFillSlack;

  String? rejectReason(BuiltCandidate b, LevelQualityProfile p) {
    if (b.trapsPlaced < brief.traps) return 'traps ${b.trapsPlaced}';
    if (b.pairsPlaced < brief.pairs) return 'pairs ${b.pairsPlaced}';
    if (b.detoursPlaced < brief.detours) return 'detours ${b.detoursPlaced}';
    if (p.fill < minFill) return 'fill ${p.fill.toStringAsFixed(2)}';
    // Random-play deadEndRate==0 does not prove the trap is inert; selection
    // still requires TrapFairness.ok. Reject only extreme rates.
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
    if (p.peelRounds < minPeel ||
        (maxPeel != null && p.peelRounds > maxPeel!)) {
      return 'peel ${p.peelRounds}';
    }
    return null;
  }

  double score(LevelQualityProfile p, SilhouetteMetrics sil) {
    final special = type != LevelType.normal;
    var s = -p.headCrowding * 4 +
        sil.outlineCover * (special ? 5 : 1.5) +
        sil.tipCover * (special ? 6 : 1.5) +
        p.fill * 1.5 +
        p.peelRounds * 0.12;
    if (traps) s -= (p.deadEndRate - 0.35).abs() * 2.5;
    // Prefer specials that out-peel a typical normal of this band.
    if (special)
      s += (p.peelRounds - (10 + (level - Phase2A.first) ~/ 10)) * 0.2;
    return s;
  }
}

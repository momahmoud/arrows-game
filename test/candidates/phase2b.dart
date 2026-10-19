import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_generator/level_quality.dart';
import 'package:arrow_escape/data/models/level.dart';

import 'candidate_builder.dart';
import 'early_phase1.dart';
import 'early_phase1b.dart';
import 'silhouette_metrics.dart';

/// Puzzle role for a Phase 2B level. Deliberately wider than Phase 2A's
/// mostly trap-or-breather split so decision structures stay varied.
enum Phase2BRole {
  /// Order-independent, lower pressure.
  breather,

  /// Deep blocking / deflector chains; no order traps.
  chain,

  /// Pair locks as the main mechanic; no traps.
  pairLock,

  /// One fair live order trap among structured blocking.
  trap,

  /// Boss: trap-forward (1–2 live traps).
  bossTrap,

  /// Boss: peel/chain-forward with at most one trap.
  bossChain,

  /// God: two live traps.
  godTrap,

  /// God: pair network with one trap.
  godPair,
}

/// Phase 2B: rework campaign levels 301–350 only. Development output under
/// build/candidates/phase2b_301_350/; never writes assets/levels.bin.
///
/// Deliberate differences from Phase 2A:
/// - roles mix chain / pairLock / trap / breather (not almost-all traps)
/// - higher peel floors so boards do not feel as short as 2A
/// - dead-end targets vary by role; scoring does not chase ~0.35
/// - different seed salt and breather schedule
class Phase2B {
  Phase2B._();

  static const int first = 301;
  static const int last = 350;
  static const int seedSalt = 33;

  static const Set<int> breathers = {
    305,
    312,
    320,
    328,
    335,
    342,
    349,
  };

  static const Set<int> chains = {
    302,
    307,
    310,
    316,
    321,
    327,
    334,
    341,
    345,
    348,
  };

  static const Set<int> pairLocks = {
    303,
    309,
    314,
    319,
    324,
    331,
    338,
    344,
  };

  /// Trap normals (remainder of normals not in breathers/chains/pairLocks).
  static const Set<int> traps = {
    306,
    313,
    317,
    323,
    326,
    330,
    333,
    337,
    340,
    347,
  };

  static Phase2BRole roleFor(int level) {
    final type = AppConstants.levelTypeFor(level);
    if (type == LevelType.boss) {
      // Alternate: rescue shallow L301 as chain; end L350 as trap finale.
      const chainBosses = {301, 315, 329, 343};
      return chainBosses.contains(level)
          ? Phase2BRole.bossChain
          : Phase2BRole.bossTrap;
    }
    if (type == LevelType.god) {
      const pairGods = {311, 318, 332, 346};
      return pairGods.contains(level)
          ? Phase2BRole.godPair
          : Phase2BRole.godTrap;
    }
    if (breathers.contains(level)) return Phase2BRole.breather;
    if (chains.contains(level)) return Phase2BRole.chain;
    if (pairLocks.contains(level)) return Phase2BRole.pairLock;
    return Phase2BRole.trap;
  }

  static Phase2BDesign designFor(int level) {
    assert(level >= first && level <= last);
    final role = roleFor(level);
    final band = (level - first) ~/ 10; // 0..4
    return switch (role) {
      Phase2BRole.breather => Phase2BDesign(
          level: level,
          role: role,
          intent: 'Breather: readable deflectors/pairs, no order trap.',
          brief: CandidateBrief(
            seeds: 128,
            seedSalt: seedSalt,
            arrows: 22 + band,
            minLen: 3,
            maxLen: 8,
            traps: 0,
            detours: 2,
            pairs: 1 + (band >= 2 ? 1 : 0),
            fill: 0.74,
            tailGrowth: 6,
            outlineBias: 0.2,
          ),
          opening: (3, 6),
          minPeel: 8 + band ~/ 2,
          maxPeel: 12 + band,
          traps: false,
        ),
      Phase2BRole.chain => Phase2BDesign(
          level: level,
          role: role,
          intent: 'Chain: deep peel via blocking and deflectors; no traps. '
              'Phase 2A under-used this structure.',
          brief: CandidateBrief(
            seeds: 288,
            seedSalt: seedSalt,
            arrows: 28 + band * 2,
            minLen: 4,
            maxLen: 10,
            traps: 0,
            detours: 3 + band ~/ 2,
            pairs: 1,
            fill: 0.78,
            tailGrowth: 8,
            outlineBias: 0.25,
          ),
          opening: (2, band >= 3 ? 10 : 8),
          minPeel: 8 + band ~/ 2,
          traps: false,
          minFillSlack: 0.08,
        ),
      Phase2BRole.pairLock => Phase2BDesign(
          level: level,
          role: role,
          intent: 'Pair-lock: colour pairs as the main dependency; no traps.',
          brief: CandidateBrief(
            seeds: 224,
            seedSalt: seedSalt,
            arrows: 26 + band * 2,
            minLen: 4,
            maxLen: 9,
            traps: 0,
            detours: 2,
            pairs: 2 + (band >= 3 ? 1 : 0),
            fill: 0.76,
            tailGrowth: 6,
            outlineBias: 0.25,
          ),
          opening: (2, 6),
          minPeel: 9 + band ~/ 2,
          traps: false,
        ),
      Phase2BRole.trap => Phase2BDesign(
          level: level,
          role: role,
          intent: 'Trap: one fair live order trap; dead-end ceiling varies by '
              'band (scoring prefers mild rates, not a fixed 0.35).',
          brief: CandidateBrief(
            seeds: 352,
            seedSalt: seedSalt,
            arrows: 24 + band * 2,
            minLen: 4,
            maxLen: 9,
            traps: 1,
            detours: 2 + band ~/ 2,
            pairs: 1 + (band >= 2 ? 1 : 0),
            fill: 0.76,
            tailGrowth: 6,
            outlineBias: 0.25,
          ),
          opening: (2, band >= 3 ? 9 : 7),
          minPeel: 8 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.55,
          minFillSlack: 0.08,
        ),
      Phase2BRole.bossChain => Phase2BDesign(
          level: level,
          role: role,
          intent: level == 301
              ? 'Boss rescue: production L301 was shallow (peel 13, open 34); '
                  'chain-forward with one live trap on the dinosaur mask.'
              : 'Boss chain: peel and deflectors first; at most one trap.',
          brief: CandidateBrief(
            seeds: 448,
            seedSalt: seedSalt,
            arrows: 55 + band * 3,
            minLen: 4,
            maxLen: 11,
            traps: 1,
            detours: 4 + band ~/ 2,
            pairs: 2,
            fill: 0.76,
            tailGrowth: 10,
            outlineBias: 0.55,
          ),
          opening: (4, 18),
          minPeel: 11 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.50,
          minFillSlack: 0.08,
          maxHeadCrowding: 0.50,
        ),
      Phase2BRole.bossTrap => Phase2BDesign(
          level: level,
          role: role,
          intent:
              'Boss trap: one or two live traps; outline-biased silhouette.',
          brief: CandidateBrief(
            seeds: 448,
            seedSalt: seedSalt,
            arrows: 52 + band * 3,
            minLen: 4,
            maxLen: 11,
            traps: band >= 2 ? 2 : 1,
            detours: 3 + band ~/ 2,
            pairs: 2,
            fill: 0.74,
            tailGrowth: 10,
            outlineBias: 0.55,
          ),
          opening: (4, 18),
          minPeel: 10 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.55,
          minFillSlack: 0.08,
          maxHeadCrowding: 0.50,
        ),
      Phase2BRole.godTrap => Phase2BDesign(
          level: level,
          role: role,
          // One trap + heavy deflectors (not Phase 2A's default two traps —
          // dual traps often fail fairness on 40×40 masks).
          intent: 'God trap-forward: one live trap with a dense deflector '
              'network; outline bias.',
          brief: CandidateBrief(
            seeds: 512,
            seedSalt: seedSalt,
            arrows: 58 + band * 3,
            minLen: 4,
            maxLen: 12,
            traps: 1,
            detours: 5,
            pairs: 2,
            fill: 0.74,
            tailGrowth: 10,
            outlineBias: 0.55,
          ),
          opening: (4, 18),
          minPeel: 10 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.55,
          minFillSlack: 0.08,
          maxHeadCrowding: 0.50,
        ),
      Phase2BRole.godPair => Phase2BDesign(
          level: level,
          role: role,
          intent: 'God pair-forward: heavy pair locks with one live trap — '
              'avoids Phase 2A\'s two-trap default on every god.',
          brief: CandidateBrief(
            seeds: 512,
            seedSalt: seedSalt,
            arrows: 56 + band * 3,
            minLen: 4,
            maxLen: 12,
            traps: 1,
            detours: 3,
            pairs: 3,
            fill: 0.74,
            tailGrowth: 10,
            outlineBias: 0.55,
          ),
          opening: (4, 20),
          minPeel: 10 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.55,
          minFillSlack: 0.08,
          maxHeadCrowding: 0.50,
        ),
    };
  }

  static Map<int, CandidateChoice> build(Map<int, LevelModel> originals) => {
        for (var n = first; n <= last; n++)
          n: choose(designFor(n), originals[n]!),
      };

  static CandidateChoice choose(Phase2BDesign design, LevelModel original) {
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
        ? 'no fair layout (${metBrief} met brief)'
        : briefMiss?.rejected ?? 'no seed met brief';
    if (briefMiss != null && metBrief == 0) {
      return CandidateChoice(_asEarly(design), briefMiss.built,
          briefMiss.profile, double.negativeInfinity, why);
    }
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

  static EarlyDesign _asEarly(Phase2BDesign d) => EarlyDesign(
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

class Phase2BDesign {
  const Phase2BDesign({
    required this.level,
    required this.role,
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
  final Phase2BRole role;
  final String intent;
  final CandidateBrief brief;
  final (int, int) opening;
  final int minPeel;
  final int? maxPeel;
  final bool traps;
  final double maxDeadEnd;
  final double maxHeadCrowding;
  final double minFillSlack;

  LevelType get type => AppConstants.levelTypeFor(level);
  double get minFill => brief.fill - minFillSlack;

  String? rejectReason(BuiltCandidate b, LevelQualityProfile p) {
    if (b.trapsPlaced < brief.traps) return 'traps ${b.trapsPlaced}';
    if (b.pairsPlaced < brief.pairs) return 'pairs ${b.pairsPlaced}';
    if (b.detoursPlaced < brief.detours) return 'detours ${b.detoursPlaced}';
    if (p.fill < minFill) return 'fill ${p.fill.toStringAsFixed(2)}';
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

  /// Prefers peel and silhouette; only gently guides trap dead-end rates
  /// (does not chase Phase 2A's 0.35 target).
  double score(LevelQualityProfile p, SilhouetteMetrics sil) {
    final special = type != LevelType.normal;
    var s = -p.headCrowding * 4 +
        sil.outlineCover * (special ? 5 : 1.5) +
        sil.tipCover * (special ? 6 : 1.5) +
        p.fill * 1.2 +
        p.peelRounds * 0.22;
    if (role == Phase2BRole.chain || role == Phase2BRole.bossChain) {
      s += p.peelRounds * 0.15;
    }
    if (role == Phase2BRole.pairLock || role == Phase2BRole.godPair) {
      s += p.pairCount * 0.35;
    }
    if (traps) {
      // Prefer mild, not maximal, deadlock rates.
      final mid = maxDeadEnd * 0.55;
      s -= (p.deadEndRate - mid).abs() * 1.5;
    }
    if (special) {
      s += (p.peelRounds - (11 + (level - Phase2B.first) ~/ 10)) * 0.15;
    }
    return s;
  }
}

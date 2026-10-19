import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_generator/level_quality.dart';
import 'package:arrow_escape/data/models/level.dart';

import 'candidate_builder.dart';
import 'early_phase1.dart';
import 'early_phase1b.dart';
import 'silhouette_metrics.dart';

/// Puzzle role for Phase 2D (401–450).
///
/// Continues varied-role remediation while deliberately raising peel floors
/// and arrow targets vs Phase 2C (which traded peel ~19→12 for readability).
enum Phase2DRole {
  /// Order-independent relief — still long enough not to feel trivial.
  breather,

  /// Deep deflector / blocking chains; no traps.
  chain,

  /// Curved deflector practice; no traps.
  detour,

  /// Pair locks as the main dependency; no traps.
  pairLock,

  /// One fair live order trap among structured blocking.
  trap,

  /// Boss: peel/chain-forward; no traps.
  bossChain,

  /// Boss: one live trap after chain preparation.
  bossTrap,

  /// God: multi-pair coordination; no traps.
  godPair,

  /// God: one live trap on a dense silhouette.
  godTrap,
}

/// Phase 2D: rework campaign levels 401–450 only. Development output under
/// `build/candidates/phase2d_401_450/`; never writes `assets/levels.bin`.
///
/// Baseline is **production** (not Phase 2A/2B/2C merges).
///
/// Deliberate differences from Phase 2C:
/// - higher arrow counts and peel floors (target median peel ~14–16, not ~12)
/// - scoring weights peel more heavily relative to crowding
/// - different seed salt (**55**) and role schedule
/// - rescues for production L434 (peel 3), L437 (0 pairs), L427 (dead 0.91),
///   L413 (shallow boss), L402/L406 (extreme open/crowd)
class Phase2D {
  Phase2D._();

  static const int first = 401;
  static const int last = 450;
  static const int seedSalt = 55;

  /// Includes masks that resist deep peel under reverse construction.
  static const Set<int> breathers = {
    404,
    412,
    421,
    429,
    433,
    442,
    447,
  };

  static const Set<int> chains = {
    401,
    407,
    414,
    422,
    428,
    435,
    449,
    450,
  };

  static const Set<int> detours = {
    405,
    411,
    419,
    426,
    436,
    440,
    446,
  };

  static const Set<int> pairLocks = {
    403,
    410,
    418,
    425,
    432,
    439,
    445,
  };

  /// Includes dead-end normals 415/438.
  static const Set<int> traps = {
    408,
    415,
    417,
    424,
    431,
    438,
    443,
  };

  static Phase2DRole roleFor(int level) {
    final type = AppConstants.levelTypeFor(level);
    if (type == LevelType.boss) {
      // Chain rescues: L413 shallow peel, L434 catastrophic peel 3, L448 finale.
      const chainBosses = {413, 434, 448};
      return chainBosses.contains(level)
          ? Phase2DRole.bossChain
          : Phase2DRole.bossTrap; // 406, 420, 427, 441
    }
    if (type == LevelType.god) {
      const pairGods = {409, 423, 437, 444};
      return pairGods.contains(level)
          ? Phase2DRole.godPair
          : Phase2DRole.godTrap; // 402, 416, 430
    }
    if (breathers.contains(level)) return Phase2DRole.breather;
    if (chains.contains(level)) return Phase2DRole.chain;
    if (detours.contains(level)) return Phase2DRole.detour;
    if (pairLocks.contains(level)) return Phase2DRole.pairLock;
    return Phase2DRole.trap;
  }

  static Phase2DDesign designFor(int level) {
    assert(level >= first && level <= last);
    final role = roleFor(level);
    final band = (level - first) ~/ 10; // 0..4
    return switch (role) {
      Phase2DRole.breather => Phase2DDesign(
          level: level,
          role: role,
          intent: 'Breather: readable recovery that still lasts several peels '
              '(not Phase 2C\'s ultra-light packs).',
          brief: CandidateBrief(
            seeds: 192,
            seedSalt: seedSalt,
            arrows: 28 + band,
            minLen: 3,
            maxLen: 9,
            traps: 0,
            detours: 2,
            pairs: 1,
            fill: 0.75,
            tailGrowth: 7,
            outlineBias: 0.20,
          ),
          opening: (4, 10),
          minPeel: 8 + band ~/ 2,
          maxPeel: 16 + band,
          traps: false,
          maxHeadCrowding: 0.50,
        ),
      Phase2DRole.chain => Phase2DDesign(
          level: level,
          role: role,
          intent: 'Chain: deep peel via blocking/deflectors; no traps. '
              'Higher peel floor than Phase 2C (~12 median).',
          brief: CandidateBrief(
            seeds: 420,
            seedSalt: seedSalt,
            arrows: 36 + band * 2,
            minLen: 4,
            maxLen: 11,
            traps: 0,
            detours: 4 + band ~/ 2,
            pairs: 1,
            fill: 0.80,
            tailGrowth: 10,
            outlineBias: 0.28,
          ),
          opening: (2, band >= 3 ? 12 : 9),
          // Achievable floor above 2C's typical chain peels (~10–11).
          minPeel: 10 + band ~/ 2,
          traps: false,
          minFillSlack: 0.08,
          maxHeadCrowding: 0.55,
        ),
      Phase2DRole.detour => Phase2DDesign(
          level: level,
          role: role,
          intent: 'Detour: curved deflector paths with enough arrows for '
              'duration; no order traps.',
          brief: CandidateBrief(
            seeds: 384,
            seedSalt: seedSalt,
            arrows: 34 + band * 2,
            minLen: 4,
            maxLen: 11,
            traps: 0,
            detours: 5 + band ~/ 2,
            pairs: 0,
            fill: 0.78,
            tailGrowth: 9,
            outlineBias: 0.32,
          ),
          opening: (3, 11),
          minPeel: 10 + band ~/ 2,
          traps: false,
          minFillSlack: 0.08,
          maxHeadCrowding: 0.52,
        ),
      Phase2DRole.pairLock => Phase2DDesign(
          level: level,
          role: role,
          intent: 'Pair-lock: colour pairs as the main dependency; no traps.',
          brief: CandidateBrief(
            seeds: 352,
            seedSalt: seedSalt,
            arrows: 34 + band * 2,
            minLen: 4,
            maxLen: 10,
            traps: 0,
            detours: 2,
            pairs: 2 + (band >= 2 ? 1 : 0),
            fill: 0.78,
            tailGrowth: 8,
            outlineBias: 0.26,
          ),
          opening: (2, band >= 3 ? 12 : 9),
          minPeel: 10 + band ~/ 2,
          traps: false,
          maxHeadCrowding: 0.55,
        ),
      Phase2DRole.trap => Phase2DDesign(
          level: level,
          role: role,
          intent: level == 447
              ? 'Trap rescue: production L447 peel was shallow (11); one fair '
                  'trap with deeper peel.'
              : 'Trap: one fair live order trap; mild dead-end ceiling '
                  '(not a fixed 0.35 chase).',
          brief: CandidateBrief(
            seeds: 448,
            seedSalt: seedSalt,
            arrows: 32 + band * 2,
            minLen: 4,
            maxLen: 10,
            traps: 1,
            detours: 3 + band ~/ 3,
            pairs: band >= 2 ? 1 : 0,
            fill: 0.78,
            tailGrowth: 8,
            outlineBias: 0.26,
          ),
          opening: (2, band >= 3 ? 11 : 9),
          minPeel: 9 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.55,
          minFillSlack: 0.08,
          maxHeadCrowding: 0.55,
        ),
      Phase2DRole.bossChain => Phase2DDesign(
          level: level,
          role: role,
          intent: level == 434
              ? 'Boss chain rescue: production L434 peel was 3 with open 35; '
                  'trap-free deep peel on the candy mask.'
              : level == 413
                  ? 'Boss chain rescue: production L413 peel 17 / open 37; '
                      'deeper chain, tighter opening, no traps.'
                  : 'Boss chain: silhouette-led peel; no traps.',
          brief: CandidateBrief(
            seeds: level == 434 ? 800 : 640,
            seedSalt: seedSalt,
            arrows: level == 434 ? 48 + band * 2 : 58 + band * 3,
            minLen: 4,
            maxLen: 12,
            traps: 0,
            detours: 6 + band ~/ 2,
            pairs: 2,
            fill: level == 434 ? 0.72 : 0.76,
            tailGrowth: 12,
            outlineBias: 0.60,
          ),
          opening: (4, 22),
          // Candy mask (434) resists deep peel; still require >> production's 3.
          minPeel: level == 434 ? 8 : 12 + band ~/ 2,
          traps: false,
          maxDeadEnd: 0,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.58,
        ),
      Phase2DRole.bossTrap => Phase2DDesign(
          level: level,
          role: role,
          intent: level == 427
              ? 'Boss trap rescue: production L427 dead-end 0.91 / peel 15; '
                  'one fair trap with deeper peel and milder deadlock.'
              : level == 406
                  ? 'Boss trap: production open was extreme (52); one fair '
                      'trap, tighter opening, keep meaningful peel.'
                  : 'Boss trap: one fair climax trap after chain preparation.',
          brief: CandidateBrief(
            seeds: 640,
            seedSalt: seedSalt,
            arrows: 56 + band * 3,
            minLen: 4,
            maxLen: 12,
            traps: 1,
            detours: 5 + band ~/ 2,
            pairs: 2,
            fill: 0.76,
            tailGrowth: 11,
            outlineBias: 0.58,
          ),
          opening: (4, 22),
          minPeel: 11 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.55,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.58,
        ),
      Phase2DRole.godPair => Phase2DDesign(
          level: level,
          role: role,
          intent: level == 437
              ? 'God pair rescue: production pretzel had 0 dots / 0 pairs; '
                  'restore multi-pair coordination without traps.'
              : 'God pair: multi-pair climactic mechanic; no traps.',
          brief: CandidateBrief(
            seeds: 672,
            seedSalt: seedSalt,
            arrows: 60 + band * 3,
            minLen: 4,
            maxLen: 13,
            traps: 0,
            detours: 4,
            pairs: 3 + (band >= 2 ? 1 : 0),
            fill: 0.74,
            tailGrowth: 12,
            outlineBias: 0.62,
          ),
          opening: (4, 24),
          minPeel: 11 + band ~/ 2,
          traps: false,
          maxDeadEnd: 0,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.58,
        ),
      Phase2DRole.godTrap => Phase2DDesign(
          level: level,
          role: role,
          intent: level == 402
              ? 'God trap: production dhow had 261 arrows / crowd 0.94 / open '
                  '39; one fair trap, much clearer heads, preserve peel.'
              : 'God trap: one fair trap on a dense silhouette (max one).',
          brief: CandidateBrief(
            seeds: 672,
            seedSalt: seedSalt,
            arrows: 62 + band * 3,
            minLen: 4,
            maxLen: 13,
            traps: 1,
            detours: 5,
            pairs: 2,
            fill: 0.74,
            tailGrowth: 12,
            outlineBias: 0.58,
          ),
          opening: (4, 24),
          minPeel: 11 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.55,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.58,
        ),
    };
  }

  static Map<int, CandidateChoice> build(Map<int, LevelModel> originals) => {
        for (var n = first; n <= last; n++)
          n: choose(designFor(n), originals[n]!),
      };

  static CandidateChoice choose(Phase2DDesign design, LevelModel original) {
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

  static EarlyDesign _asEarly(Phase2DDesign d) => EarlyDesign(
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

class Phase2DDesign {
  const Phase2DDesign({
    required this.level,
    required this.role,
    required this.intent,
    required this.brief,
    required this.opening,
    required this.minPeel,
    this.maxPeel,
    this.traps = false,
    this.maxDeadEnd = 0.55,
    this.maxHeadCrowding = 0.48,
    this.minFillSlack = 0.05,
  });

  final int level;
  final Phase2DRole role;
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
    // Guard against Phase 2C-style over-thinning on normals (specials often
    // place below brief.arrows while still covering the silhouette).
    if (type == LevelType.normal &&
        role != Phase2DRole.breather &&
        p.arrowCount < brief.arrows - 14) {
      return 'too few arrows ${p.arrowCount}';
    }
    return null;
  }

  /// Prefers peel and duration more than Phase 2C; crowding still penalized
  /// but does not dominate peel.
  double score(LevelQualityProfile p, SilhouetteMetrics sil) {
    final special = type != LevelType.normal;
    var s = -p.headCrowding * 3.2 +
        sil.outlineCover * (special ? 5 : 1.5) +
        sil.tipCover * (special ? 6 : 1.5) +
        p.fill * 1.0 +
        p.peelRounds * 0.35 +
        p.arrowCount * 0.04;
    if (role == Phase2DRole.chain || role == Phase2DRole.bossChain) {
      s += p.peelRounds * 0.20;
    }
    if (role == Phase2DRole.detour) {
      s += p.peelRounds * 0.10 + sil.outlineCover * 0.5;
    }
    if (role == Phase2DRole.pairLock || role == Phase2DRole.godPair) {
      s += p.pairCount * 0.35;
    }
    if (traps) {
      final mid = maxDeadEnd * 0.55;
      s -= (p.deadEndRate - mid).abs() * 1.4;
    }
    if (special) {
      s += (p.peelRounds - (13 + (level - Phase2D.first) ~/ 10)) * 0.18;
    }
    return s;
  }
}

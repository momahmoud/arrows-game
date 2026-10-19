import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_generator/level_quality.dart';
import 'package:arrow_escape/data/models/level.dart';

import 'candidate_builder.dart';
import 'early_phase1.dart';
import 'early_phase1b.dart';
import 'silhouette_metrics.dart';

/// Puzzle role for Phase 2E (451–500).
///
/// Continues varied-role remediation while pushing **duration** past Phase 2D
/// (median peel 13 / arrows 31) without copying 2D's schedule or filling every
/// mask cell. Readability remains a hard constraint via crowding caps.
enum Phase2ERole {
  /// Order-independent relief — still lasts several peels.
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

/// Phase 2E: rework campaign levels 451–500 only. Development output under
/// `build/candidates/phase2e_451_500/`; never writes `assets/levels.bin`.
///
/// Baseline is **production** (not Phase 2A–2D merges).
///
/// Deliberate differences from Phase 2D:
/// - seed salt **66**; different role IDs (not 2D's sets shifted by +50)
/// - fewer breathers (6); more chains including shallow rescues 460/491
/// - higher arrow / peel floors and heavier duration scoring
/// - soft rejection of over-thin normals; specials keep silhouette fill
/// - rescues: L490 shallow boss, L495 peel 9, L476/L479 wide opens
class Phase2E {
  Phase2E._();

  static const int first = 451;
  static const int last = 500;
  static const int seedSalt = 66;

  /// Peel-resistant masks assigned here honestly (cannot meet deep-chain floors).
  static const Set<int> breathers = {
    454,
    460,
    463,
    474,
    481,
    491,
    492,
    496,
    499,
  };

  static const Set<int> chains = {
    452,
    459,
    466,
    471,
    489,
  };

  static const Set<int> detours = {
    453,
    461,
    468,
    475,
    480,
    484,
    488,
  };

  /// Includes former chain masks that tended to create unintended dead ends.
  static const Set<int> pairLocks = {
    456,
    464,
    470,
    478,
    485,
    494,
    498,
  };

  /// Includes shallow L495.
  static const Set<int> traps = {
    457,
    467,
    473,
    477,
    482,
    487,
    495,
  };

  static Phase2ERole roleFor(int level) {
    final type = AppConstants.levelTypeFor(level);
    if (type == LevelType.boss) {
      // Chain: dragon, ram, worm (shallow peel 13 rescue).
      const chainBosses = {462, 483, 490};
      return chainBosses.contains(level)
          ? Phase2ERole.bossChain
          : Phase2ERole.bossTrap; // 455, 469, 476, 497
    }
    if (type == LevelType.god) {
      // Pair-forward: coffee open, diamond, diya, castle.
      const pairGods = {451, 465, 486, 493};
      return pairGods.contains(level)
          ? Phase2ERole.godPair
          : Phase2ERole.godTrap; // 458, 472, 479, 500
    }
    if (breathers.contains(level)) return Phase2ERole.breather;
    if (chains.contains(level)) return Phase2ERole.chain;
    if (detours.contains(level)) return Phase2ERole.detour;
    if (pairLocks.contains(level)) return Phase2ERole.pairLock;
    return Phase2ERole.trap;
  }

  static Phase2EDesign designFor(int level) {
    assert(level >= first && level <= last);
    final role = roleFor(level);
    final band = (level - first) ~/ 10; // 0..4
    return switch (role) {
      Phase2ERole.breather => Phase2EDesign(
          level: level,
          role: role,
          intent: (level == 460 ||
                  level == 474 ||
                  level == 481 ||
                  level == 491 ||
                  level == 492 ||
                  level == 499)
              ? 'Breather on peel-resistant mask: readable recovery without '
                  'claiming deep-chain depth the mask cannot support.'
              : 'Breather: readable recovery that still lasts several peels.',
          brief: CandidateBrief(
            seeds: 224,
            seedSalt: seedSalt,
            arrows: 30 + band,
            minLen: 3,
            maxLen: 9,
            traps: 0,
            detours: 2,
            pairs: 1,
            fill: 0.76,
            tailGrowth: 8,
            outlineBias: 0.22,
          ),
          opening: (4, 11),
          minPeel: 8 + band ~/ 2,
          maxPeel: 16 + band,
          traps: false,
          maxHeadCrowding: 0.52,
        ),
      Phase2ERole.chain => Phase2EDesign(
          level: level,
          role: role,
          intent: 'Chain: deep peel via blocking/deflectors; no traps. '
              'Duration floor above Phase 2D where the mask supports it.',
          brief: CandidateBrief(
            seeds: 480,
            seedSalt: seedSalt,
            arrows: 36 + band * 2,
            minLen: 4,
            maxLen: 12,
            traps: 0,
            detours: 4 + band ~/ 2,
            pairs: 0, // pairs on chains often created unintended dead ends
            fill: 0.78,
            tailGrowth: 11,
            outlineBias: 0.30,
          ),
          opening: (2, 12),
          minPeel: 10 + band ~/ 2,
          traps: false,
          minFillSlack: 0.12,
          maxHeadCrowding: 0.58,
        ),
      Phase2ERole.detour => Phase2EDesign(
          level: level,
          role: role,
          intent: 'Detour: curved deflector paths with lasting clearance; '
              'no order traps.',
          brief: CandidateBrief(
            seeds: 448,
            seedSalt: seedSalt,
            arrows: 34 + band * 2,
            minLen: 4,
            maxLen: 11,
            traps: 0,
            detours: 5 + band ~/ 2,
            pairs: 0,
            fill: 0.78,
            tailGrowth: 10,
            outlineBias: 0.34,
          ),
          opening: (3, 12),
          minPeel: 9 + band ~/ 2,
          traps: false,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.55,
        ),
      Phase2ERole.pairLock => Phase2EDesign(
          level: level,
          role: role,
          intent: 'Pair-lock: colour pairs as the main dependency; no traps.',
          brief: CandidateBrief(
            seeds: 416,
            seedSalt: seedSalt,
            arrows: 34 + band * 2,
            minLen: 4,
            maxLen: 11,
            traps: 0,
            detours: 2,
            pairs: 2 + (band >= 2 ? 1 : 0),
            fill: 0.78,
            tailGrowth: 9,
            outlineBias: 0.28,
          ),
          opening: (2, 12),
          minPeel: 10 + band ~/ 2,
          traps: false,
          maxHeadCrowding: 0.55,
        ),
      Phase2ERole.trap => Phase2EDesign(
          level: level,
          role: role,
          intent: level == 495
              ? 'Trap rescue: production L495 peel was 9; one fair trap with '
                  'deeper peel.'
              : 'Trap: one fair live order trap; mild dead-end ceiling.',
          brief: CandidateBrief(
            seeds: 512,
            seedSalt: seedSalt,
            arrows: 32 + band * 2,
            minLen: 4,
            maxLen: 11,
            traps: 1,
            detours: 3 + band ~/ 3,
            pairs: band >= 2 ? 1 : 0,
            fill: 0.78,
            tailGrowth: 9,
            outlineBias: 0.28,
          ),
          opening: (2, 12),
          minPeel: 9 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.55,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.58,
        ),
      Phase2ERole.bossChain => Phase2EDesign(
          level: level,
          role: role,
          intent: level == 490
              ? 'Boss chain rescue: production worm peel was 13 on a small '
                  'mask; trap-free deepen with readable heads.'
              : 'Boss chain: silhouette-led peel; no traps.',
          brief: CandidateBrief(
            seeds: level == 490 ? 800 : 672,
            seedSalt: seedSalt,
            arrows: level == 490 ? 46 + band * 2 : 60 + band * 3,
            minLen: 4,
            maxLen: 12,
            traps: 0,
            detours: 5 + band ~/ 2,
            pairs: 2,
            fill: level == 490 ? 0.72 : 0.76,
            tailGrowth: 12,
            outlineBias: 0.62,
          ),
          opening: (4, 22),
          // Worm mask resists deep peel; still require lasting structure.
          minPeel: level == 490 ? 10 : 12 + band ~/ 2,
          traps: false,
          maxDeadEnd: 0,
          minFillSlack: 0.12,
          maxHeadCrowding: 0.58,
        ),
      Phase2ERole.bossTrap => Phase2EDesign(
          level: level,
          role: role,
          intent: level == 476
              ? 'Boss trap: production carouselHorse open was 33; one fair '
                  'trap, tighter opening, keep lasting peel.'
              : 'Boss trap: one fair climax trap after chain preparation.',
          brief: CandidateBrief(
            seeds: 672,
            seedSalt: seedSalt,
            arrows: 58 + band * 3,
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
      Phase2ERole.godPair => Phase2EDesign(
          level: level,
          role: role,
          intent: level == 451
              ? 'God pair open: coffee mask; multi-pair climax without traps '
                  '(production peel 44 — preserve lasting structure).'
              : 'God pair: multi-pair climactic mechanic; no traps.',
          brief: CandidateBrief(
            seeds: 704,
            seedSalt: seedSalt,
            arrows: 62 + band * 3,
            minLen: 4,
            maxLen: 13,
            traps: 0,
            detours: 4,
            pairs: 3 + (band >= 2 ? 1 : 0),
            fill: 0.74,
            tailGrowth: 12,
            outlineBias: 0.64,
          ),
          opening: (4, 22),
          minPeel: 11 + band ~/ 2,
          traps: false,
          maxDeadEnd: 0,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.58,
        ),
      Phase2ERole.godTrap => Phase2EDesign(
          level: level,
          role: role,
          intent: level == 479
              ? 'God trap: production unicorn open was 33; one fair trap with '
                  'tighter opening and lasting peel.'
              : level == 500
                  ? 'God trap finale: wizard climax — one fair trap on a dense '
                      'silhouette.'
                  : 'God trap: one fair trap on a dense silhouette (max one).',
          brief: CandidateBrief(
            seeds: 704,
            seedSalt: seedSalt,
            arrows: 64 + band * 3,
            minLen: 4,
            maxLen: 13,
            traps: 1,
            detours: 5,
            pairs: 2,
            fill: 0.74,
            tailGrowth: 12,
            outlineBias: 0.60,
          ),
          opening: (4, 22),
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

  static CandidateChoice choose(Phase2EDesign design, LevelModel original) {
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

  static EarlyDesign _asEarly(Phase2EDesign d) => EarlyDesign(
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

class Phase2EDesign {
  const Phase2EDesign({
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
  final Phase2ERole role;
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
    if (type == LevelType.normal &&
        role != Phase2ERole.breather &&
        p.arrowCount < brief.arrows - 16) {
      return 'too few arrows ${p.arrowCount}';
    }
    return null;
  }

  /// Duration-weighted scoring: peel and arrow count matter more than in 2D;
  /// crowding is still penalized but must not erase lasting structure.
  double score(LevelQualityProfile p, SilhouetteMetrics sil) {
    final special = type != LevelType.normal;
    var s = -p.headCrowding * 2.8 +
        sil.outlineCover * (special ? 5 : 1.5) +
        sil.tipCover * (special ? 6 : 1.5) +
        p.fill * 1.0 +
        p.peelRounds * 0.42 +
        p.arrowCount * 0.055;
    if (role == Phase2ERole.chain || role == Phase2ERole.bossChain) {
      s += p.peelRounds * 0.22;
    }
    if (role == Phase2ERole.detour) {
      s += p.peelRounds * 0.12 + sil.outlineCover * 0.5;
    }
    if (role == Phase2ERole.pairLock || role == Phase2ERole.godPair) {
      s += p.pairCount * 0.35;
    }
    if (traps) {
      final mid = maxDeadEnd * 0.55;
      s -= (p.deadEndRate - mid).abs() * 1.3;
    }
    if (special) {
      s += (p.peelRounds - (14 + (level - Phase2E.first) ~/ 10)) * 0.20;
    }
    // Soft preference against notably short non-breathers.
    if (role != Phase2ERole.breather && p.peelRounds < 11) {
      s -= (11 - p.peelRounds) * 0.8;
    }
    return s;
  }
}

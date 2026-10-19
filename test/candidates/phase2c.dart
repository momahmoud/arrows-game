import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_generator/level_quality.dart';
import 'package:arrow_escape/data/models/level.dart';

import 'candidate_builder.dart';
import 'early_phase1.dart';
import 'early_phase1b.dart';
import 'silhouette_metrics.dart';

/// Puzzle role for Phase 2C (351–400). Continues 2B's varied-role approach
/// while introducing a **detour** normal role and a different schedule/salt
/// so layouts do not copy Phase 2A or 2B.
enum Phase2CRole {
  /// Order-independent, lower pressure.
  breather,

  /// Deep blocking / deflector chains; no order traps.
  chain,

  /// Curved deflector practice; no traps, sparse pairs.
  detour,

  /// Pair locks as the main mechanic; no traps.
  pairLock,

  /// One fair live order trap among structured blocking.
  trap,

  /// Boss: peel/chain-forward with **no** traps (differs from 2B).
  bossChain,

  /// Boss: one live trap after chain preparation.
  bossTrap,

  /// God: multi-pair coordination; **no** traps (differs from 2B).
  godPair,

  /// God: one live trap on a dense silhouette.
  godTrap,
}

/// Phase 2C: rework campaign levels 351–400 only. Development output under
/// build/candidates/phase2c_351_400/; never writes assets/levels.bin.
///
/// Baseline is **production** (not Phase 2A/2B merges).
///
/// Deliberate differences from prior mid-campaign phases:
/// - new **detour** role (deflector practice without traps)
/// - fewer trap normals than 2B (7 vs 10); trapish specials stay selective
/// - bossChain / godPair are trap-free (2B still put one trap on both)
/// - seed salt **44**; different breather/chain/trap schedules
class Phase2C {
  Phase2C._();

  static const int first = 351;
  static const int last = 400;
  static const int seedSalt = 44;

  /// Soft breathers — recovery after specials / denser neighbours.
  static const Set<int> breathers = {
    355,
    363,
    370,
    377,
    384,
    391,
    398,
  };

  /// Deflector / peel chains without traps.
  static const Set<int> chains = {
    351,
    356,
    362,
    368,
    375,
    382,
    389,
    396,
    400,
  };

  /// Detour-heavy normals — teach curved paths; no traps.
  static const Set<int> detours = {
    354,
    361,
    369,
    376,
    383,
    390,
    397,
  };

  /// Pair-lock normals.
  static const Set<int> pairLocks = {
    358,
    365,
    372,
    379,
    386,
    393,
  };

  /// Trap normals (includes L352 shallow rescue).
  static const Set<int> traps = {
    352,
    359,
    366,
    373,
    380,
    387,
    394,
  };

  static Phase2CRole roleFor(int level) {
    final type = AppConstants.levelTypeFor(level);
    if (type == LevelType.boss) {
      const chainBosses = {357, 371, 385, 399};
      return chainBosses.contains(level)
          ? Phase2CRole.bossChain
          : Phase2CRole.bossTrap; // 364, 378, 392
    }
    if (type == LevelType.god) {
      const pairGods = {353, 367, 381, 395};
      return pairGods.contains(level)
          ? Phase2CRole.godPair
          : Phase2CRole.godTrap; // 360, 374, 388
    }
    if (breathers.contains(level)) return Phase2CRole.breather;
    if (chains.contains(level)) return Phase2CRole.chain;
    if (detours.contains(level)) return Phase2CRole.detour;
    if (pairLocks.contains(level)) return Phase2CRole.pairLock;
    return Phase2CRole.trap;
  }

  static Phase2CDesign designFor(int level) {
    assert(level >= first && level <= last);
    final role = roleFor(level);
    final band = (level - first) ~/ 10; // 0..4
    return switch (role) {
      Phase2CRole.breather => Phase2CDesign(
          level: level,
          role: role,
          intent: 'Breather: readable recovery after denser neighbours; '
              'no order trap.',
          brief: CandidateBrief(
            seeds: 128,
            seedSalt: seedSalt,
            arrows: 20 + band,
            minLen: 3,
            maxLen: 8,
            traps: 0,
            detours: 1 + band ~/ 3,
            pairs: 0,
            fill: 0.72,
            tailGrowth: 5,
            outlineBias: 0.18,
          ),
          opening: (4, 8),
          minPeel: 7 + band ~/ 2,
          maxPeel: 13 + band,
          traps: false,
        ),
      Phase2CRole.chain => Phase2CDesign(
          level: level,
          role: role,
          intent: 'Chain: deep peel via blocking and deflectors; no traps.',
          brief: CandidateBrief(
            seeds: 320,
            seedSalt: seedSalt,
            arrows: 30 + band * 2,
            minLen: 4,
            maxLen: 10,
            traps: 0,
            detours: 3 + band ~/ 2,
            pairs: band >= 3 ? 1 : 0,
            fill: 0.78,
            tailGrowth: 8,
            outlineBias: 0.25,
          ),
          opening: (2, band >= 3 ? 11 : 8),
          minPeel: 9 + band ~/ 2,
          traps: false,
          minFillSlack: 0.08,
          maxHeadCrowding: 0.55,
        ),
      Phase2CRole.detour => Phase2CDesign(
          level: level,
          role: role,
          intent: 'Detour: curved deflector paths; readable, no order traps. '
              'New Phase 2C role — not used in 2A/2B.',
          brief: CandidateBrief(
            seeds: 288,
            seedSalt: seedSalt,
            arrows: 28 + band * 2,
            minLen: 4,
            maxLen: 10,
            traps: 0,
            detours: 4 + band ~/ 2,
            pairs: 0,
            fill: 0.76,
            tailGrowth: 7,
            outlineBias: 0.30,
          ),
          opening: (3, 9),
          minPeel: 9 + band ~/ 2,
          traps: false,
          minFillSlack: 0.06,
          maxHeadCrowding: 0.45,
        ),
      Phase2CRole.pairLock => Phase2CDesign(
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
            pairs: 2 + (band >= 2 ? 1 : 0),
            fill: 0.76,
            tailGrowth: 6,
            outlineBias: 0.25,
          ),
          opening: (2, 7),
          minPeel: 9 + band ~/ 2,
          traps: false,
        ),
      Phase2CRole.trap => Phase2CDesign(
          level: level,
          role: role,
          intent: level == 352
              ? 'Trap rescue: production L352 peel was shallow (9); one fair '
                  'order decision with deeper peel.'
              : 'Trap: one fair live order trap; mild dead-end ceiling '
                  '(not a fixed 0.35 chase).',
          brief: CandidateBrief(
            seeds: 352,
            seedSalt: seedSalt,
            arrows: 24 + band * 2,
            minLen: 4,
            maxLen: 9,
            traps: 1,
            detours: 2 + band ~/ 3,
            pairs: band >= 2 ? 1 : 0,
            fill: 0.76,
            tailGrowth: 6,
            outlineBias: 0.25,
          ),
          opening: (2, band >= 3 ? 9 : 7),
          minPeel: 9 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.50,
          minFillSlack: 0.08,
        ),
      Phase2CRole.bossChain => Phase2CDesign(
          level: level,
          role: role,
          intent: level == 399
              ? 'Boss chain finale: production already deep (peel 35); keep '
                  'trap-free peel/deflector identity vs trap bosses.'
              : 'Boss chain: silhouette-led peel; **no traps** (differs from '
                  'Phase 2B bossChain which still placed one trap).',
          brief: CandidateBrief(
            seeds: 448,
            seedSalt: seedSalt,
            arrows: 54 + band * 3,
            minLen: 4,
            maxLen: 11,
            traps: 0,
            detours: 5 + band ~/ 2,
            pairs: 2,
            fill: 0.74,
            tailGrowth: 10,
            outlineBias: 0.58,
          ),
          opening: (4, 20),
          minPeel: 11 + band ~/ 2,
          traps: false,
          maxDeadEnd: 0,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.52,
        ),
      Phase2CRole.bossTrap => Phase2CDesign(
          level: level,
          role: role,
          intent: level == 364
              ? 'Boss trap rescue: production L364 had dead-end 0.72 and peel '
                  '16; one fair trap with deeper peel and milder deadlock.'
              : 'Boss trap: one fair climax trap after chain preparation.',
          brief: CandidateBrief(
            seeds: 448,
            seedSalt: seedSalt,
            arrows: 52 + band * 3,
            minLen: 4,
            maxLen: 11,
            traps: 1,
            detours: 4 + band ~/ 2,
            pairs: 1,
            fill: 0.74,
            tailGrowth: 9,
            outlineBias: 0.55,
          ),
          opening: (4, 20),
          minPeel: 10 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.55,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.52,
        ),
      Phase2CRole.godPair => Phase2CDesign(
          level: level,
          role: role,
          intent: level == 395
              ? 'God pair rescue: production nestingDolls had 0 dots / 0 pairs; '
                  'restore multi-pair coordination without traps.'
              : 'God pair: multi-pair climactic mechanic; **no traps** '
                  '(differs from Phase 2B godPair).',
          brief: CandidateBrief(
            seeds: 512,
            seedSalt: seedSalt,
            arrows: 56 + band * 3,
            minLen: 4,
            maxLen: 12,
            traps: 0,
            detours: 4,
            pairs: 3 + (band >= 2 ? 1 : 0),
            fill: 0.72,
            tailGrowth: 10,
            outlineBias: 0.60,
          ),
          opening: (4, 22),
          minPeel: 10 + band ~/ 2,
          traps: false,
          maxDeadEnd: 0,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.55,
        ),
      Phase2CRole.godTrap => Phase2CDesign(
          level: level,
          role: role,
          intent: level == 374
              ? 'God trap: production open was very wide (33); one fair trap '
                  'with tighter opening and dense deflectors.'
              : 'God trap: one fair trap on a dense silhouette (max one).',
          brief: CandidateBrief(
            seeds: 512,
            seedSalt: seedSalt,
            arrows: 58 + band * 3,
            minLen: 4,
            maxLen: 12,
            traps: 1,
            detours: 5,
            pairs: 2,
            fill: 0.72,
            tailGrowth: 10,
            outlineBias: 0.55,
          ),
          opening: (4, 22),
          minPeel: 10 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.55,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.55,
        ),
    };
  }

  static Map<int, CandidateChoice> build(Map<int, LevelModel> originals) => {
        for (var n = first; n <= last; n++)
          n: choose(designFor(n), originals[n]!),
      };

  static CandidateChoice choose(Phase2CDesign design, LevelModel original) {
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

  static EarlyDesign _asEarly(Phase2CDesign d) => EarlyDesign(
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

class Phase2CDesign {
  const Phase2CDesign({
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
  final Phase2CRole role;
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

  double score(LevelQualityProfile p, SilhouetteMetrics sil) {
    final special = type != LevelType.normal;
    var s = -p.headCrowding * 4 +
        sil.outlineCover * (special ? 5 : 1.5) +
        sil.tipCover * (special ? 6 : 1.5) +
        p.fill * 1.2 +
        p.peelRounds * 0.22;
    if (role == Phase2CRole.chain || role == Phase2CRole.bossChain) {
      s += p.peelRounds * 0.15;
    }
    if (role == Phase2CRole.detour) {
      s += p.peelRounds * 0.08 + sil.outlineCover * 0.5;
    }
    if (role == Phase2CRole.pairLock || role == Phase2CRole.godPair) {
      s += p.pairCount * 0.35;
    }
    if (traps) {
      final mid = maxDeadEnd * 0.55;
      s -= (p.deadEndRate - mid).abs() * 1.5;
    }
    if (special) {
      s += (p.peelRounds - (11 + (level - Phase2C.first) ~/ 10)) * 0.15;
    }
    return s;
  }
}

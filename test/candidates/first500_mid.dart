import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_generator/level_quality.dart';
import 'package:arrow_escape/data/models/level.dart';

import 'candidate_builder.dart';
import 'early_phase1.dart';
import 'early_phase1b.dart';
import 'silhouette_metrics.dart';

/// Selective replacements inside production levels **25–250** for the
/// first-500 integrated candidate. Development-only; never writes
/// `assets/levels.bin`.
///
/// Only confirmed / high-confidence problems are targeted — not a full
/// re-roll of the range. Issues drawn from `build/level_quality.json` and
/// `docs/dev/LEVEL_QUALITY_AUDIT.md`.
enum MidRole {
  breather,
  chain,
  trap,
  bossChain,
  bossTrap,
  godPair,
  godTrap,
}

class First500Mid {
  First500Mid._();

  static const int seedSalt = 77;
  static const String tag = 'first500_mid_25_250';

  /// Explicit allow-list — everything else in 25–250 stays production.
  static const Set<int> replaced = {
    // Unfair / high dead-end estimates
    84, 136, 158, 171, 203, 239,
    // Critically shallow normals
    40, 50, 97, 195, 212, 230,
    // Weak / shallow specials
    31, 35, 196, 199,
    // Extreme open / crowding specials
    56, 178, 210, 217, 220,
    // Early-mid shallow / crowded normals
    61, 99,
  };

  static MidRole roleFor(int level) {
    final type = AppConstants.levelTypeFor(level);
    if (type == LevelType.boss) {
      return switch (level) {
        35 || 196 => MidRole.bossChain,
        _ => MidRole.bossTrap, // 56, 84, 203, 210, 217
      };
    }
    if (type == LevelType.god) {
      return switch (level) {
        31 || 199 => MidRole.godPair,
        _ => MidRole.godTrap, // 136, 171, 178, 220
      };
    }
    // Normals
    if ({40, 50, 61, 99}.contains(level)) return MidRole.breather;
    if ({97, 195, 212, 230}.contains(level)) return MidRole.chain;
    return MidRole.trap; // 158, 239
  }

  static String issueFor(int level) => switch (level) {
        31 => 'God falcon peel only 11 — shallow for early god.',
        35 => 'Boss scorpion peel 13 / crowd 0.91 — weak boss identity.',
        40 => 'Normal peel 8 with very wide open (18) — soft spike.',
        50 => 'Normal peel 6 — progression hole.',
        56 => 'Boss hourglass open 32 / crowd 0.88.',
        61 => 'Normal peel 9 / crowd 0.84.',
        84 => 'Boss balloon dead-end 0.47 / open 29.',
        97 => 'Normal peel 6 / dead-end 0.34.',
        99 => 'Normal peel 8.',
        136 => 'God feather open 38 / dead-end 0.41.',
        158 => 'Normal dead-end 0.47.',
        171 => 'God dates dead-end 0.53.',
        178 => 'God mermaid open 36 / crowd 0.91.',
        195 => 'Normal peel 9.',
        196 => 'Boss rat peel 12 — shallow mid boss.',
        199 => 'God giraffe peel 13 — shallow.',
        203 => 'Boss tropicalFish dead-end 0.62 / open 30.',
        210 => 'Boss trumpet open 48 / crowd 0.88.',
        212 => 'Normal peel 9 / crowd 0.82.',
        217 => 'Boss scissors open 58 / crowd 0.93 / 225 arrows.',
        220 => 'God palmTree open 46 / crowd 0.93.',
        230 => 'Normal peel 7 / dead-end 0.34.',
        239 => 'Normal dead-end 0.84 — highest in 25–250.',
        _ => 'Selected quality replacement.',
      };

  static MidDesign designFor(int level) {
    assert(replaced.contains(level));
    final role = roleFor(level);
    final band = level < 100
        ? 0
        : level < 150
            ? 1
            : level < 200
                ? 2
                : 3;
    return switch (role) {
      MidRole.breather => MidDesign(
          level: level,
          role: role,
          issue: issueFor(level),
          intent: 'Breather/repair: readable board with modest peel; no traps.',
          brief: CandidateBrief(
            seeds: 192,
            seedSalt: seedSalt,
            arrows: 18 + band * 2,
            minLen: 3,
            maxLen: 8,
            traps: 0,
            detours: 1,
            pairs: 0,
            fill: 0.72,
            tailGrowth: 5,
            outlineBias: 0.20,
          ),
          opening: (3, 12),
          minPeel: 6 + band ~/ 2,
          maxPeel: 14 + band,
          traps: false,
          maxHeadCrowding: 0.50,
        ),
      MidRole.chain => MidDesign(
          level: level,
          role: role,
          issue: issueFor(level),
          intent: 'Chain repair: deepen shallow production peel; no traps.',
          brief: CandidateBrief(
            seeds: 320,
            seedSalt: seedSalt,
            arrows: 24 + band * 3,
            minLen: 3,
            maxLen: 10,
            traps: 0,
            detours: 3 + band ~/ 2,
            pairs: 0,
            fill: 0.76,
            tailGrowth: 8,
            outlineBias: 0.25,
          ),
          opening: (2, 12),
          minPeel: 9 + band ~/ 2,
          traps: false,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.55,
        ),
      MidRole.trap => MidDesign(
          level: level,
          role: role,
          issue: issueFor(level),
          intent: 'Trap repair: one fair live order trap; milder than '
              'production accidental deadlocks.',
          brief: CandidateBrief(
            seeds: 384,
            seedSalt: seedSalt,
            arrows: 22 + band * 3,
            minLen: 3,
            maxLen: 9,
            traps: 1,
            detours: 2,
            pairs: band >= 2 ? 1 : 0,
            fill: 0.76,
            tailGrowth: 7,
            outlineBias: 0.25,
          ),
          opening: (2, 12),
          minPeel: 8 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.55,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.55,
        ),
      MidRole.bossChain => MidDesign(
          level: level,
          role: role,
          issue: issueFor(level),
          intent: 'Boss chain: deepen shallow boss; trap-free peel identity.',
          brief: CandidateBrief(
            seeds: level == 35 ? 640 : 448,
            seedSalt: seedSalt,
            arrows: level == 35 ? 36 : 40 + band * 4,
            minLen: 4,
            maxLen: 11,
            traps: 0,
            detours: 4,
            pairs: 2,
            fill: level == 35 ? 0.70 : 0.74,
            tailGrowth: 10,
            outlineBias: 0.55,
          ),
          opening: (4, 20),
          // Early scorpion mask resists deep peel; still beat production 13
          // crowding and aim for lasting structure.
          minPeel: level == 35 ? 8 : 11 + band ~/ 2,
          traps: false,
          minFillSlack: 0.12,
          maxHeadCrowding: 0.58,
        ),
      MidRole.bossTrap => MidDesign(
          level: level,
          role: role,
          issue: issueFor(level),
          intent: 'Boss trap: one fair trap; tighten extreme openings / crowd.',
          brief: CandidateBrief(
            seeds: 480,
            seedSalt: seedSalt,
            arrows: 42 + band * 4,
            minLen: 4,
            maxLen: 11,
            traps: 1,
            detours: 4,
            pairs: 2,
            fill: 0.74,
            tailGrowth: 10,
            outlineBias: 0.55,
          ),
          opening: (4, 20),
          minPeel: 10 + band ~/ 2,
          traps: true,
          maxDeadEnd: 0.55,
          minFillSlack: 0.10,
          maxHeadCrowding: 0.58,
        ),
      MidRole.godPair => MidDesign(
          level: level,
          role: role,
          issue: issueFor(level),
          intent: 'God pair: multi-pair climax; deepen shallow god; no traps.',
          brief: CandidateBrief(
            seeds: level == 199 ? 640 : 512,
            seedSalt: seedSalt,
            arrows: level == 199 ? 40 + band * 3 : 44 + band * 4,
            minLen: 4,
            maxLen: 12,
            traps: 0,
            detours: 3,
            pairs: level == 199 ? 2 : 3,
            fill: level == 199 ? 0.70 : 0.72,
            tailGrowth: 10,
            outlineBias: 0.58,
          ),
          opening: (4, 22),
          minPeel: level == 199 ? 8 : 10 + band ~/ 2,
          traps: false,
          minFillSlack: 0.12,
          maxHeadCrowding: 0.58,
        ),
      MidRole.godTrap => MidDesign(
          level: level,
          role: role,
          issue: issueFor(level),
          intent: 'God trap: one fair trap; reduce extreme open/crowd.',
          brief: CandidateBrief(
            seeds: 512,
            seedSalt: seedSalt,
            arrows: 46 + band * 4,
            minLen: 4,
            maxLen: 12,
            traps: 1,
            detours: 4,
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
          maxHeadCrowding: 0.58,
        ),
    };
  }

  static Map<int, CandidateChoice> build(Map<int, LevelModel> originals) => {
        for (final n in replaced.toList()..sort())
          n: choose(designFor(n), originals[n]!),
      };

  static CandidateChoice choose(MidDesign design, LevelModel original) {
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

  static EarlyDesign _asEarly(MidDesign d) => EarlyDesign(
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

class MidDesign {
  const MidDesign({
    required this.level,
    required this.role,
    required this.issue,
    required this.intent,
    required this.brief,
    required this.opening,
    required this.minPeel,
    this.maxPeel,
    this.traps = false,
    this.maxDeadEnd = 0.55,
    this.maxHeadCrowding = 0.50,
    this.minFillSlack = 0.06,
  });

  final int level;
  final MidRole role;
  final String issue;
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
    var s = -p.headCrowding * 3.0 +
        sil.outlineCover * (special ? 5 : 1.5) +
        sil.tipCover * (special ? 6 : 1.5) +
        p.fill * 1.0 +
        p.peelRounds * 0.30 +
        p.arrowCount * 0.04;
    if (role == MidRole.chain || role == MidRole.bossChain) {
      s += p.peelRounds * 0.15;
    }
    if (traps) {
      final mid = maxDeadEnd * 0.55;
      s -= (p.deadEndRate - mid).abs() * 1.4;
    }
    return s;
  }
}

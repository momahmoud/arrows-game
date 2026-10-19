import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_generator/level_quality.dart';
import 'package:arrow_escape/data/models/arrow.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:arrow_escape/game/game_state.dart';

import 'candidate_builder.dart';
import 'candidate_checks.dart';
import 'early_phase1.dart';
import 'silhouette_metrics.dart';

/// Phase-1B refinement of levels 4–24. Development only: writes under
/// build/candidates/early_phase1b/ and never replaces assets/levels.bin or
/// the Phase-1 baseline under early_phase1/.
///
/// Changes vs Phase 1:
/// - Outline/tip-biased placement so special silhouettes keep distinguishing
///   features occupied.
/// - Selection rewards outline and tip cover, not only fill.
/// - Trap fairness filters: live decision with a competing free move, and a
///   gentler first trap on level 12.
class EarlyPhase1B {
  EarlyPhase1B._();

  static const int first = EarlyPhase1.first;
  static const int last = EarlyPhase1.last;

  /// Distinct from Phase 1 so layouts differ while staying deterministic.
  static const int seedSalt = 11;

  static final Map<int, EarlyDesign> designs = {
    for (final d in _refined) d.level: d,
  };

  /// Phase-1 designs with outline bias on specials, a fairer first trap, and
  /// a different salt so the seed search explores a new family of boards.
  static final List<EarlyDesign> _refined = [
    for (final base in EarlyPhase1.designs.values)
      EarlyDesign(
        base.level,
        intent: _intent(base),
        brief: _brief(base),
        opening: base.opening,
        minPeel: base.minPeel,
        maxPeel: base.maxPeel,
        mask: base.mask,
        traps: base.traps,
      ),
  ];

  static String _intent(EarlyDesign base) {
    if (base.level == 12) {
      return 'First order trap (refined): the waste arrow competes with a '
          'correct free move at a reachable decision; facing arrows sit on '
          'a shared deflector.';
    }
    if ({10, 14, 17, 21, 24}.contains(base.level)) {
      return '${base.intent} Outline and tip cells are preferred so the '
          'shape\'s distinguishing features stay occupied.';
    }
    return base.intent;
  }

  static CandidateBrief _brief(EarlyDesign base) {
    final special = AppConstants.levelTypeFor(base.level) != LevelType.normal;
    // Bias is strong enough to claim tips early; the builder fades it once
    // fill is mostly met so interiors still reach the Phase-1 fill floor.
    final outlineBias = special
        ? 0.6
        : base.level == 12
            ? 0.3
            : 0.2;
    final seeds = special
        ? (base.brief.seeds < 512 ? 512 : base.brief.seeds)
        : base.level == 12
            ? 256
            : base.brief.seeds;
    return CandidateBrief(
      arrows: base.brief.arrows,
      minLen: base.brief.minLen,
      maxLen: base.brief.maxLen,
      traps: base.brief.traps,
      detours: base.brief.detours,
      pairs: base.brief.pairs,
      straightness: base.brief.straightness,
      seeds: seeds,
      seedSalt: seedSalt,
      fill: base.fillTarget,
      tailGrowth: special ? base.brief.tailGrowth + 2 : base.brief.tailGrowth,
      outlineBias: outlineBias,
    );
  }

  static Map<int, CandidateChoice> build(Map<int, LevelModel> originals) {
    return {
      for (var n = first; n <= last; n++) n: choose(designs[n]!, originals[n]!),
    };
  }

  /// Ranks layouts that meet the Phase-1 brief, then keeps only those whose
  /// traps are live and fair. Among survivors, prefers silhouette outline
  /// and tip cover (especially on specials) and a moderate first-trap depth.
  static CandidateChoice choose(EarlyDesign design, LevelModel original) {
    final template = design.mask.apply(original);
    final built = CandidateBuilder.buildAll(template, design.brief);
    final ranked = <_Scored>[];
    CandidateChoice? briefMiss;
    var metBrief = 0;
    for (final b in built) {
      final p = LevelQuality.profile(b.level);
      final rejected = design.rejectReason(b, p);
      if (rejected != null) {
        briefMiss ??=
            CandidateChoice(design, b, p, double.negativeInfinity, rejected);
        continue;
      }
      metBrief++;
      if (!_trapsLive(b)) continue;
      final fair = _trapFairness(b);
      if (fair == null) continue;
      if (design.level == 12 && !_firstTrapOk(fair)) continue;
      final sil = SilhouetteMetrics.of(b.level);
      final score = _score(design, p, sil, fair);
      ranked.add(_Scored(
          CandidateChoice(design, b, p, score, null), sil, fair, score));
    }
    ranked.sort((a, b) => a.score != b.score
        ? b.score.compareTo(a.score)
        : a.choice.built.seed.compareTo(b.choice.built.seed));
    if (ranked.isNotEmpty) {
      final best = ranked.first;
      return CandidateChoice(
          design, best.choice.built, best.choice.profile, best.score, null);
    }
    final why = metBrief > 0
        ? 'no fair live-trap silhouette layout ($metBrief met brief)'
        : briefMiss?.rejected ?? 'no seed met brief';
    final fallback =
        EarlyPhase1.choose(EarlyPhase1.designs[design.level]!, original);
    return CandidateChoice(design, briefMiss?.built ?? fallback.built,
        briefMiss?.profile ?? fallback.profile, double.negativeInfinity, why);
  }

  static bool _trapsLive(BuiltCandidate b) => b.traps.every((t) =>
      checkTrap(b.level, t.x, t.y, t.z, t.dotRow, t.dotCol).decisionReachable);

  /// Null when any trap fails the fairness checks.
  static List<TrapFairness>? _trapFairness(BuiltCandidate b) {
    if (b.traps.isEmpty) return const [];
    final out = <TrapFairness>[];
    for (final t in b.traps) {
      final f = TrapFairness.analyse(b.level, t);
      if (!f.ok) return null;
      out.add(f);
    }
    return out;
  }

  /// Level 12: decision after a short peel, waste competes with another free
  /// move, and the random-play dead-end estimate stays forgiving.
  static bool _firstTrapOk(List<TrapFairness> fair) {
    if (fair.length != 1) return false;
    final f = fair.first;
    return f.decisionAfterTaps >= 2 &&
        f.decisionAfterTaps <= 6 &&
        f.competingFreeMoves >= 1;
  }

  static double _score(EarlyDesign design, LevelQualityProfile p,
      SilhouetteMetrics sil, List<TrapFairness> fair) {
    final special = design.type != LevelType.normal;
    var s = -p.headCrowding * 4 +
        sil.outlineCover * (special ? 6 : 2) +
        sil.tipCover * (special ? 8 : 2) +
        p.fill * (special ? 1.0 : 2.0) +
        p.peelRounds * 0.15;
    if (design.traps) {
      s -= (p.deadEndRate - (design.level == 12 ? 0.28 : 0.35)).abs() * 3;
      for (final f in fair) {
        s += f.competingFreeMoves * 0.4;
        if (design.level == 12) {
          s -= (f.decisionAfterTaps - 3).abs() * 0.5;
        }
      }
    }
    return s;
  }
}

class _Scored {
  _Scored(this.choice, this.silhouette, this.fairness, this.score);
  final CandidateChoice choice;
  final SilhouetteMetrics silhouette;
  final List<TrapFairness> fairness;
  final double score;
}

/// Whether a live trap is a fair decision under the real exit rule.
class TrapFairness {
  const TrapFairness({
    required this.x,
    required this.y,
    required this.z,
    required this.decisionReachable,
    required this.decisionAfterTaps,
    required this.freeAtDecision,
    required this.competingFreeMoves,
    required this.wasteFreeAtStart,
    required this.wrongTapDeadlocks,
  });

  final String x, y, z;
  final bool decisionReachable;
  final int decisionAfterTaps;

  /// Idle units free at the decision (before the waste tap).
  final int freeAtDecision;

  /// Free units at the decision other than the waste arrow.
  final int competingFreeMoves;

  /// Whether the waste arrow is free on the opening board.
  final bool wasteFreeAtStart;

  final bool wrongTapDeadlocks;

  bool get ok =>
      decisionReachable &&
      wrongTapDeadlocks &&
      competingFreeMoves >= 1 &&
      freeAtDecision >= 2;

  Map<String, Object?> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'decisionReachable': decisionReachable,
        'decisionAfterTaps': decisionAfterTaps,
        'freeAtDecision': freeAtDecision,
        'competingFreeMoves': competingFreeMoves,
        'wasteFreeAtStart': wasteFreeAtStart,
        'wrongTapDeadlocks': wrongTapDeadlocks,
        'ok': ok,
      };

  static TrapFairness analyse(LevelModel level, TrapGadget t,
      {int cap = 400000}) {
    final check = checkTrap(level, t.x, t.y, t.z, t.dotRow, t.dotCol, cap: cap);
    if (check.decisionReachable) {
      return _fromPath(level, t, check.path);
    }
    // Large boards often exhaust the BFS budget before the decision. Fall
    // back to walking the stored solution, which is a legal path by
    // construction and still proves the player can reach the choice.
    final along = decisionAlongSolution(level, t);
    if (along != null) return _fromPath(level, t, along);
    return TrapFairness(
      x: t.x,
      y: t.y,
      z: t.z,
      decisionReachable: false,
      decisionAfterTaps: 0,
      freeAtDecision: 0,
      competingFreeMoves: 0,
      wasteFreeAtStart: false,
      wrongTapDeadlocks: false,
    );
  }

  /// Prefix of [LevelModel.solutionOrder] after which [t.z] is free while
  /// both facing arrows and the trap dot remain. Null when none exists.
  static List<String>? decisionAlongSolution(LevelModel level, TrapGadget t) {
    final path = <String>[];
    final remaining = {for (final a in level.arrows) a.id};
    for (final id in level.solutionOrder) {
      final free = _freeIds(level, path);
      final dotAlive = remaining.contains(t.x) &&
          remaining.contains(t.y) &&
          _dotPresent(level, path, t.dotRow, t.dotCol);
      if (free.contains(t.z) && dotAlive) return List<String>.from(path);
      if (!remaining.contains(id)) continue;
      final group = level.arrows.firstWhere((a) => a.id == id).colorGroup;
      final unit = [
        for (final a in level.arrows)
          if (a.id == id || (group != null && a.colorGroup == group)) a.id,
      ];
      path.add(id);
      remaining.removeAll(unit);
      if (!remaining.contains(t.x) || !remaining.contains(t.y)) break;
    }
    return null;
  }

  static bool _dotPresent(
      LevelModel level, List<String> taps, int row, int col) {
    final state = GameState(
      level: level,
      onLevelComplete: () {},
      onGameOver: () {},
      onLifeLost: () {},
      onDeadlock: () {},
    );
    for (final id in taps) {
      final group = state.arrows.firstWhere((a) => a.id == id).colorGroup;
      final unit = [
        for (final a in state.arrows)
          if (a.id == id || (group != null && a.colorGroup == group)) a.id,
      ];
      if (state.tapArrow(id) != TapResult.exited) return false;
      for (final a in unit) {
        state.handleArrowExitCompleted(a);
      }
    }
    return state.orphanDots.containsKey('$row,$col');
  }

  static TrapFairness _fromPath(
      LevelModel level, TrapGadget t, List<String> path) {
    final openingFree = _freeIds(level, const []);
    final freeAtDecision = _freeIds(level, path);
    final (deadlocked, left) = playOnInGame(level, [...path, t.z]);
    final stranded = left.contains(t.x) && left.contains(t.y);
    return TrapFairness(
      x: t.x,
      y: t.y,
      z: t.z,
      decisionReachable: true,
      decisionAfterTaps: path.length,
      freeAtDecision: freeAtDecision.length,
      competingFreeMoves: freeAtDecision.where((id) => id != t.z).length,
      wasteFreeAtStart: openingFree.contains(t.z),
      wrongTapDeadlocks: deadlocked && stranded,
    );
  }

  /// Arrow IDs that [GameState] reports free after [taps] (one ID per unit).
  static Set<String> _freeIds(LevelModel level, List<String> taps) {
    final state = GameState(
      level: level,
      onLevelComplete: () {},
      onGameOver: () {},
      onLifeLost: () {},
      onDeadlock: () {},
    );
    for (final id in taps) {
      final group = state.arrows.firstWhere((a) => a.id == id).colorGroup;
      final unit = [
        for (final a in state.arrows)
          if (a.id == id || (group != null && a.colorGroup == group)) a.id,
      ];
      if (state.tapArrow(id) != TapResult.exited) {
        throw StateError('L${level.levelNumber}: $id did not exit');
      }
      for (final a in unit) {
        state.handleArrowExitCompleted(a);
      }
    }
    return {
      for (final a in state.arrows)
        if (a.state == ArrowState.idle && !state.isArrowBlocked(a.id)) a.id
    };
  }
}

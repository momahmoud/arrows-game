import 'dart:math' as math;

import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/models/level.dart';

import 'density_policy.dart';
import 'early_phase1.dart';
import 'early_phase1b.dart';
import 'first500_mid.dart';
import 'phase2a.dart';
import 'phase2b.dart';
import 'phase2c.dart';
import 'phase2d.dart';
import 'phase2e.dart';

/// First-500 density + zigzag revision (v2).
///
/// Artifacts under [outDir] only. Never touches assets/levels.bin or
/// build/candidates/first_500_quality/.
class First500V2 {
  First500V2._();

  static const outDir = 'build/candidates/first_500_quality_v2';
  static const int salt = 29;

  /// Thin Phase 2A normal traps to ~40% instead of nearly every level.
  static bool _keep2ATrap(int level) {
    if (AppConstants.levelTypeFor(level) != LevelType.normal) return true;
    if (Phase2A.breathers.contains(level)) return false;
    return level % 5 == 0 || level % 5 == 2;
  }

  static Phase2ADesign densify2A(Phase2ADesign base, LevelModel prod) {
    final breather = Phase2A.breathers.contains(base.level);
    final special = DensityPolicy.isSpecial(base.level);
    var traps = base.brief.traps;
    var wantTraps = base.traps;
    if (!special && !breather) {
      wantTraps = _keep2ATrap(base.level);
      traps = wantTraps ? math.max(1, base.brief.traps) : 0;
    }
    final brief = DensityPolicy.densifyBrief(
      base.brief,
      prod,
      breather: breather,
      trapsOverride: traps,
      extraSalt: salt,
    );
    return Phase2ADesign(
      level: base.level,
      intent: '${base.intent} [v2 densify+zigzag'
          '${wantTraps != base.traps ? "; trap schedule thinned" : ""}]',
      brief: brief,
      opening: (
        base.opening.$1,
        math.max(base.opening.$2, special ? 20 : 14),
      ),
      minPeel: base.minPeel + (breather ? 0 : 1),
      maxPeel: base.maxPeel,
      traps: wantTraps,
      maxDeadEnd: base.maxDeadEnd,
      minFillSlack: math.max(base.minFillSlack, 0.10),
      maxHeadCrowding: math.max(base.maxHeadCrowding, 0.62),
    );
  }

  static CandidateChoice build2A(int level, LevelModel prod) =>
      Phase2A.choose(densify2A(Phase2A.designFor(level), prod), prod);

  static CandidateChoice build2B(int level, LevelModel prod) {
    final base = Phase2B.designFor(level);
    final breather = Phase2B.breathers.contains(level);
    final brief = DensityPolicy.densifyBrief(
      base.brief,
      prod,
      breather: breather,
      extraSalt: salt,
    );
    return Phase2B.choose(
      Phase2BDesign(
        level: base.level,
        role: base.role,
        intent: '${base.intent} [v2 densify+zigzag]',
        brief: brief,
        opening: (base.opening.$1, math.max(base.opening.$2, 14)),
        minPeel: base.minPeel + (breather ? 0 : 1),
        maxPeel: base.maxPeel,
        traps: base.traps,
        maxDeadEnd: base.maxDeadEnd,
        minFillSlack: math.max(base.minFillSlack, 0.10),
        maxHeadCrowding: math.max(base.maxHeadCrowding, 0.62),
      ),
      prod,
    );
  }

  static CandidateChoice build2C(int level, LevelModel prod) {
    final base = Phase2C.designFor(level);
    final breather = Phase2C.breathers.contains(level);
    final brief = DensityPolicy.densifyBrief(
      base.brief,
      prod,
      breather: breather,
      extraSalt: salt,
    );
    return Phase2C.choose(
      Phase2CDesign(
        level: base.level,
        role: base.role,
        intent: '${base.intent} [v2 densify+zigzag]',
        brief: brief,
        opening: (base.opening.$1, math.max(base.opening.$2, 14)),
        minPeel: base.minPeel + (breather ? 0 : 1),
        maxPeel: base.maxPeel,
        traps: base.traps,
        maxDeadEnd: base.maxDeadEnd,
        minFillSlack: math.max(base.minFillSlack, 0.10),
        maxHeadCrowding: math.max(base.maxHeadCrowding, 0.62),
      ),
      prod,
    );
  }

  static CandidateChoice build2D(int level, LevelModel prod) {
    final base = Phase2D.designFor(level);
    final breather = Phase2D.breathers.contains(level);
    final brief = DensityPolicy.densifyBrief(
      base.brief,
      prod,
      breather: breather,
      extraSalt: salt,
    );
    return Phase2D.choose(
      Phase2DDesign(
        level: base.level,
        role: base.role,
        intent: '${base.intent} [v2 densify+zigzag]',
        brief: brief,
        opening: (base.opening.$1, math.max(base.opening.$2, 14)),
        minPeel: base.minPeel + (breather ? 0 : 1),
        maxPeel: base.maxPeel,
        traps: base.traps,
        maxDeadEnd: base.maxDeadEnd,
        minFillSlack: math.max(base.minFillSlack, 0.10),
        maxHeadCrowding: math.max(base.maxHeadCrowding, 0.62),
      ),
      prod,
    );
  }

  static CandidateChoice build2E(int level, LevelModel prod) {
    final base = Phase2E.designFor(level);
    final breather = Phase2E.breathers.contains(level);
    final brief = DensityPolicy.densifyBrief(
      base.brief,
      prod,
      breather: breather,
      extraSalt: salt,
    );
    return Phase2E.choose(
      Phase2EDesign(
        level: base.level,
        role: base.role,
        intent: '${base.intent} [v2 densify+zigzag]',
        brief: brief,
        opening: (base.opening.$1, math.max(base.opening.$2, 14)),
        minPeel: base.minPeel + (breather ? 0 : 1),
        maxPeel: base.maxPeel,
        traps: base.traps,
        maxDeadEnd: base.maxDeadEnd,
        minFillSlack: math.max(base.minFillSlack, 0.10),
        maxHeadCrowding: math.max(base.maxHeadCrowding, 0.62),
      ),
      prod,
    );
  }

  static CandidateChoice buildMid(int level, LevelModel prod) {
    final base = First500Mid.designFor(level);
    final breather = base.role == MidRole.breather;
    final brief = DensityPolicy.densifyBrief(
      base.brief,
      prod,
      breather: breather,
      extraSalt: salt,
    );
    return First500Mid.choose(
      MidDesign(
        level: base.level,
        role: base.role,
        issue: base.issue,
        intent: '${base.intent} [v2 densify+zigzag]',
        brief: brief,
        opening: (base.opening.$1, math.max(base.opening.$2, 14)),
        minPeel: base.minPeel + (breather ? 0 : 1),
        maxPeel: base.maxPeel,
        traps: base.traps,
        maxDeadEnd: base.maxDeadEnd,
        minFillSlack: math.max(base.minFillSlack, 0.10),
        maxHeadCrowding: math.max(base.maxHeadCrowding, 0.62),
      ),
      prod,
    );
  }

  /// Early 4–24: densify brief; EarlyDesign still caps crowding at 0.45 so
  /// some levels may reject — caller should fall back to Phase 1B binary.
  static CandidateChoice buildEarly(int level, LevelModel prod) {
    final base = EarlyPhase1B.designs[level]!;
    final brief = DensityPolicy.densifyBrief(
      base.brief,
      prod,
      breather: false,
      extraSalt: salt,
    );
    return EarlyPhase1B.choose(
      EarlyDesign(
        base.level,
        intent: '${base.intent} [v2 densify+zigzag]',
        brief: brief,
        opening: (
          base.opening.$1,
          math.max(base.opening.$2, 10),
        ),
        minPeel: base.minPeel,
        maxPeel: base.maxPeel,
        mask: base.mask,
        traps: base.traps,
      ),
      prod,
    );
  }
}

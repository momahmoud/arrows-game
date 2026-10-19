import 'dart:math';

import '../../core/constants.dart';

/// How a normal level's arrows are drawn inside its silhouette.
///
/// The family changes turn rhythm and dependency pressure. It does not add
/// a new mechanic.
enum CompositionFamily {
  straightLanes,
  parallelLanes,
  offsetLanes,
  lShapes,
  uShapes,
  cShapes,
  zigzags,
  staircases,
  nested,
  doubleNested,
  centralCluster,
  cornerCluster,
  cross,
  frame,
  ring,
  spiral,
  opposing,
  interlock,
  asymmetric,
  pairedColor,
  multiDependency,
}

/// Turn bias handed to the existing path grower.
class PathBias {
  final int maxStraight;
  final double turnBias;
  final bool consistentTurn;
  final bool alternateTurns;

  const PathBias({
    required this.maxStraight,
    required this.turnBias,
    this.consistentTurn = false,
    this.alternateTurns = false,
  });
}

/// One normal level's design target. Boss, god, and tutorial levels are not
/// in this table — those boards keep their current packed layouts.
class CampaignBrief {
  final int level;
  final String shape;
  final CompositionFamily composition;
  final String dependency;
  final String difficultyTarget;
  final int window;
  final int minArrows;
  final int maxArrows;
  final int targetArrows;
  final int avgPath;
  final int minDepth;
  final double tangle;
  final PathBias pathBias;

  const CampaignBrief({
    required this.level,
    required this.shape,
    required this.composition,
    required this.dependency,
    required this.difficultyTarget,
    required this.window,
    required this.minArrows,
    required this.maxArrows,
    required this.targetArrows,
    required this.avgPath,
    required this.minDepth,
    required this.tangle,
    required this.pathBias,
  });
}

/// Deterministic 1–1000 normal-level plan.
///
/// Shape quotas sum to the 713 normal levels that sit between the tutorial
/// and the boss/god cadence. The same shape returns later with a different
/// composition, so the silhouette is not the puzzle.
class CampaignComposition {
  CampaignComposition._();

  static const Map<String, int> shapeQuotas = {
    'longRectangle': 50,
    'pentagon': 45,
    'circle': 45,
    'hexagon': 45,
    'octagon': 45,
    'heart': 41,
    'diamond': 41,
    'plus': 41,
    'hShape': 35,
    'parallelogram': 35,
    'ribbon': 29,
    'trapezoid': 29,
    'blob': 29,
    'wideRectangle': 29,
    'cornerCluster': 29,
    'uShape': 29,
    'cShape': 29,
    'staircase': 29,
    'zShape': 29,
    'frame': 29,
  };

  static const List<String> _world1 = [
    'longRectangle',
    'circle',
    'pentagon',
    'hexagon',
    'octagon',
    'diamond',
    'plus',
    'uShape',
    'cShape',
  ];

  static const List<String> _world2 = [
    'heart',
    'hShape',
    'ribbon',
    'trapezoid',
    'blob',
    'wideRectangle',
  ];

  static const List<String> _world3 = [
    'staircase',
    'zShape',
    'parallelogram',
    'cornerCluster',
    'frame',
  ];

  static final Map<int, CampaignBrief> _byLevel = _build();

  static CampaignBrief briefFor(int level) {
    final brief = _byLevel[level];
    if (brief == null) {
      throw ArgumentError('No normal-level brief for $level');
    }
    return brief;
  }

  static bool hasBrief(int level) => _byLevel.containsKey(level);

  static Map<String, int> scheduledCounts() {
    final counts = <String, int>{};
    for (final brief in _byLevel.values) {
      counts[brief.shape] = (counts[brief.shape] ?? 0) + 1;
    }
    return counts;
  }

  static Map<int, CampaignBrief> _build() {
    final normals = <int>[];
    for (var n = AppConstants.tutorialLevels + 1; n <= 1000; n++) {
      if (AppConstants.levelTypeFor(n) == LevelType.normal) normals.add(n);
    }

    final remaining = Map<String, int>.from(shapeQuotas);
    final recent = <String>[];
    final visits = <String, int>{};
    final out = <int, CampaignBrief>{};
    final unlockOrdinal = <String, int>{
      for (final name in _world1) name: 0,
      for (final name in _world2) name: _normalOrdinal(101),
      for (final name in _world3) name: _normalOrdinal(201),
    };
    String? lastComposition;

    for (var ordinal = 0; ordinal < normals.length; ordinal++) {
      final level = normals[ordinal];
      final unlocked = _unlocked(level);
      final shape = _pickShape(
        unlocked: unlocked,
        remaining: remaining,
        recent: recent,
        ordinal: ordinal,
        unlockOrdinal: unlockOrdinal,
      );
      remaining[shape] = remaining[shape]! - 1;
      recent.add(shape);
      if (recent.length > 3) recent.removeAt(0);

      final allowed = _compositionsFor(level);
      final visit = visits[shape] ?? 0;
      visits[shape] = visit + 1;
      var composition =
          allowed[(visit + unlocked.indexOf(shape)) % allowed.length];
      if (composition.name == lastComposition && allowed.length > 1) {
        final i = allowed.indexOf(composition);
        composition = allowed[(i + 1 + visit) % allowed.length];
      }
      lastComposition = composition.name;

      final arrows = _arrowBand(level);
      final target =
          arrows.$1 + ((level * 5 + visit) % (arrows.$2 - arrows.$1 + 1));
      final style = _style(composition);
      out[level] = CampaignBrief(
        level: level,
        shape: shape,
        composition: composition,
        dependency: _dependencyFor(level, composition),
        difficultyTarget: _difficultyTarget(level),
        window: _window(level, shape),
        minArrows: arrows.$1,
        maxArrows: arrows.$2,
        targetArrows: target.clamp(arrows.$1, arrows.$2),
        avgPath: _avgPath(level),
        minDepth: _minDepth(level, composition),
        tangle: style.$1,
        pathBias: style.$2,
      );
    }

    return out;
  }

  static List<String> _unlocked(int level) {
    final names = <String>[..._world1];
    if (level >= 101) names.addAll(_world2);
    if (level >= 201) names.addAll(_world3);
    return names;
  }

  static int _normalOrdinal(int level) {
    var ordinal = 0;
    for (var n = AppConstants.tutorialLevels + 1; n < level; n++) {
      if (AppConstants.levelTypeFor(n) == LevelType.normal) ordinal++;
    }
    return ordinal;
  }

  static String _pickShape({
    required List<String> unlocked,
    required Map<String, int> remaining,
    required List<String> recent,
    required int ordinal,
    required Map<String, int> unlockOrdinal,
  }) {
    List<String> pool(bool ignoreRecent) {
      return unlocked.where((name) {
        if ((remaining[name] ?? 0) <= 0) return false;
        if (!ignoreRecent && recent.contains(name)) return false;
        return true;
      }).toList();
    }

    var choices = pool(false);
    if (choices.isEmpty) choices = pool(true);
    if (choices.isEmpty) {
      choices =
          shapeQuotas.keys.where((name) => (remaining[name] ?? 0) > 0).toList();
    }

    double debt(String name) {
      final quota = shapeQuotas[name]!;
      final used = quota - remaining[name]!;
      final start = unlockOrdinal[name] ?? 0;
      final span = max(1, 713 - start);
      final since = max(0, ordinal - start);
      return quota * (since + 1) / span - used;
    }

    choices.sort((a, b) {
      final da = debt(a);
      final db = debt(b);
      if ((da - db).abs() > 0.15) return db.compareTo(da);
      final prefer = ordinal % unlocked.length;
      int turn(String name) {
        final index = unlocked.indexOf(name);
        if (index < 0) return 99;
        return (index - prefer) % unlocked.length;
      }

      final order = turn(a).compareTo(turn(b));
      if (order != 0) return order;
      return a.compareTo(b);
    });
    return choices.first;
  }

  static List<CompositionFamily> _compositionsFor(int level) {
    final families = <CompositionFamily>[
      CompositionFamily.straightLanes,
      CompositionFamily.parallelLanes,
      CompositionFamily.offsetLanes,
      CompositionFamily.lShapes,
      CompositionFamily.uShapes,
      CompositionFamily.cShapes,
    ];
    if (level >= 21) {
      families.addAll([
        CompositionFamily.zigzags,
        CompositionFamily.staircases,
        CompositionFamily.opposing,
      ]);
    }
    if (level >= 51) {
      families.addAll([
        CompositionFamily.nested,
        CompositionFamily.centralCluster,
        CompositionFamily.cornerCluster,
        CompositionFamily.cross,
      ]);
    }
    if (level >= 101) {
      families.addAll([
        CompositionFamily.frame,
        CompositionFamily.ring,
        CompositionFamily.pairedColor,
        CompositionFamily.asymmetric,
      ]);
    }
    if (level >= 201) {
      families.addAll([
        CompositionFamily.doubleNested,
        CompositionFamily.spiral,
        CompositionFamily.interlock,
        CompositionFamily.multiDependency,
      ]);
    }
    return families;
  }

  static String _dependencyFor(int level, CompositionFamily composition) {
    if (level <= 20) {
      return level.isEven ? 'linear' : 'branch';
    }
    switch (composition) {
      case CompositionFamily.nested:
      case CompositionFamily.doubleNested:
      case CompositionFamily.spiral:
        return 'nested';
      case CompositionFamily.multiDependency:
      case CompositionFamily.interlock:
        return 'branch';
      case CompositionFamily.opposing:
      case CompositionFamily.asymmetric:
      case CompositionFamily.cross:
        return 'choice';
      case CompositionFamily.pairedColor:
      case CompositionFamily.frame:
      case CompositionFamily.ring:
        return 'falseChoice';
      default:
        const cycle = ['linear', 'branch', 'choice', 'nested', 'falseChoice'];
        return cycle[level % cycle.length];
    }
  }

  static String _difficultyTarget(int level) {
    if (level <= 20) return 'foundation';
    if (level <= 50) return 'early';
    if (level <= 100) return 'core';
    if (level <= 200) return 'expansion';
    if (level <= 400) return 'intermediate';
    if (level <= 600) return 'advanced';
    if (level <= 800) return 'expert';
    if (level <= 900) return 'master';
    return 'endgame';
  }

  static int _window(int level, String shape) {
    int window;
    if (level <= 20) {
      window = 14;
    } else if (level <= 50) {
      window = 18;
    } else if (level <= 100) {
      window = 19;
    } else if (level <= 200) {
      window = 20;
    } else if (level <= 400) {
      window = 22;
    } else if (level <= 600) {
      window = 23;
    } else if (level <= 800) {
      window = 24;
    } else {
      window = 25;
    }
    const roomy = {
      'frame',
      'heart',
      'hShape',
      'ribbon',
      'plus',
      'uShape',
      'cShape',
    };
    if (roomy.contains(shape)) window += 1;
    if (shape == 'longRectangle') window -= 1;
    if (shape == 'heart') window -= 2;
    return window.clamp(13, 26);
  }

  static (int, int) _arrowBand(int level) {
    if (level <= 20) return (26, 38);
    if (level <= 50) return (34, 50);
    if (level <= 100) return (38, 56);
    if (level <= 200) return (42, 62);
    if (level <= 400) return (48, 70);
    if (level <= 600) return (52, 76);
    if (level <= 800) return (56, 84);
    return (60, 92);
  }

  static int _avgPath(int level) {
    if (level <= 20) return 5;
    if (level <= 100) return 6;
    return 6;
  }

  static int _minDepth(int level, CompositionFamily composition) {
    var depth = 2;
    if (level > 50) depth = 3;
    if (level > 200) depth = 3;
    if (level > 500) depth = 4;
    if (composition == CompositionFamily.nested ||
        composition == CompositionFamily.doubleNested ||
        composition == CompositionFamily.multiDependency ||
        composition == CompositionFamily.spiral) {
      depth += 1;
    }
    return depth;
  }

  static (double, PathBias) _style(CompositionFamily composition) {
    switch (composition) {
      case CompositionFamily.straightLanes:
        return (0.34, const PathBias(maxStraight: 3, turnBias: 0.42));
      case CompositionFamily.parallelLanes:
        return (0.38, const PathBias(maxStraight: 3, turnBias: 0.45));
      case CompositionFamily.offsetLanes:
        return (0.40, const PathBias(maxStraight: 3, turnBias: 0.42));
      case CompositionFamily.lShapes:
        return (0.32, const PathBias(maxStraight: 4, turnBias: 0.30));
      case CompositionFamily.uShapes:
        return (
          0.42,
          const PathBias(maxStraight: 3, turnBias: 0.42, consistentTurn: true),
        );
      case CompositionFamily.cShapes:
        return (
          0.48,
          const PathBias(maxStraight: 3, turnBias: 0.46, consistentTurn: true),
        );
      case CompositionFamily.zigzags:
        return (
          0.62,
          const PathBias(maxStraight: 2, turnBias: 0.55, alternateTurns: true),
        );
      case CompositionFamily.staircases:
        return (
          0.58,
          const PathBias(maxStraight: 2, turnBias: 0.48, consistentTurn: true),
        );
      case CompositionFamily.nested:
        return (0.55, const PathBias(maxStraight: 3, turnBias: 0.48));
      case CompositionFamily.doubleNested:
        return (0.72, const PathBias(maxStraight: 2, turnBias: 0.58));
      case CompositionFamily.centralCluster:
        return (0.36, const PathBias(maxStraight: 4, turnBias: 0.30));
      case CompositionFamily.cornerCluster:
        return (0.40, const PathBias(maxStraight: 3, turnBias: 0.34));
      case CompositionFamily.cross:
        return (0.28, const PathBias(maxStraight: 5, turnBias: 0.22));
      case CompositionFamily.frame:
        return (
          0.34,
          const PathBias(maxStraight: 4, turnBias: 0.32, consistentTurn: true),
        );
      case CompositionFamily.ring:
        return (
          0.46,
          const PathBias(maxStraight: 3, turnBias: 0.50, consistentTurn: true),
        );
      case CompositionFamily.spiral:
        return (
          0.78,
          const PathBias(maxStraight: 2, turnBias: 0.70, consistentTurn: true),
        );
      case CompositionFamily.opposing:
        return (0.22, const PathBias(maxStraight: 5, turnBias: 0.18));
      case CompositionFamily.interlock:
        return (
          0.64,
          const PathBias(maxStraight: 2, turnBias: 0.55, alternateTurns: true),
        );
      case CompositionFamily.asymmetric:
        return (0.50, const PathBias(maxStraight: 3, turnBias: 0.42));
      case CompositionFamily.pairedColor:
        return (0.38, const PathBias(maxStraight: 4, turnBias: 0.32));
      case CompositionFamily.multiDependency:
        return (0.58, const PathBias(maxStraight: 3, turnBias: 0.46));
    }
  }
}

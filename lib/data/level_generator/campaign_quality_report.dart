import 'dart:math' as math;

import '../../core/constants.dart';
import '../models/level.dart';
import 'level_quality.dart';

/// Thresholds used to flag candidates for human review. They select levels
/// to look at; they are not verdicts on design quality.
class QualityThresholds {
  QualityThresholds._();

  /// Robust z-score (median/MAD over ±[outlierWindow] normal levels).
  static const double outlierZ = 3;
  static const int outlierWindow = 10;

  /// Few blocking layers: the board unwinds in a handful of rounds.
  static const int shallowPeelRounds = 6;

  /// Many units free at once.
  static const double openOpeningShare = 0.4;

  /// Many steps with only one legal tap.
  static const double singleTrackForcedShare = 0.3;

  /// Cell size (logical px) at 1x zoom on the reference phone viewport.
  static const double smallCellDp = 9;
  static const double crowdedHeads = 0.75;

  /// Blockers 6+ cells away from the blocked head.
  static const double hiddenBlockerShare = 0.15;

  /// Same silhouette returning within this many levels.
  static const int silhouetteReuseGap = 7;

  /// Similarity classification of near-duplicate clusters.
  static const double strongArrowIoU = 0.5;
  static const double sameSilhouetteIoU = 0.95;
  static const int nearbySpan = 50;

  /// A special level counts as "distinct" from its cycle's normal levels
  /// when it exceeds their median by any of these.
  static const double specialUnitsRatio = 1.5;
  static const double specialTrapDelta = 0.03;
  static const double specialPeelRatio = 1.25;
}

enum ClusterVerdict {
  acceptableRecurrence,
  suspiciousRepetition,
  strongDuplicate
}

class ClusterReview {
  const ClusterReview({
    required this.key,
    required this.levels,
    required this.minMaskIoU,
    required this.maxArrowIoU,
    required this.span,
    required this.peelRange,
    required this.openingRange,
    required this.verdict,
  });

  final String key;
  final List<int> levels;
  final double minMaskIoU;
  final double maxArrowIoU;
  final int span;
  final List<int> peelRange;
  final List<double> openingRange;
  final ClusterVerdict verdict;

  Map<String, Object?> toJson() => {
        'key': key,
        'levels': levels,
        'minMaskIoU': _r(minMaskIoU),
        'maxArrowIoU': _r(maxArrowIoU),
        'span': span,
        'peelRounds': peelRange,
        'openingShare': openingRange.map(_r).toList(),
        'verdict': verdict.name,
      };
}

class CampaignQualityReport {
  CampaignQualityReport._(this.profiles, this.sections, this.clusters);

  final List<LevelQualityProfile> profiles;
  final Map<String, Object?> sections;
  final List<ClusterReview> clusters;

  static const ranges = [
    [1, 20],
    [21, 50],
    [51, 100],
    [101, 250],
    [251, 500],
    [501, 750],
    [751, 1000],
  ];

  static const _rangeMetrics = [
    'units',
    'openingShare',
    'peelRounds',
    'trapRate',
    'forcedShare',
    'meanLegalMoves',
    'deadEndRate',
    'pathMean',
    'directionalDots',
    'pairs',
    'cellDp',
    'headCrowding',
  ];

  static const _labelOrder = Difficulty.values;

  /// [clusters] are CampaignAudit.nearDuplicateClusters for the same levels.
  static CampaignQualityReport build(
    List<LevelModel> levels, {
    required Map<String, List<int>> clusters,
    int playouts = LevelQuality.defaultPlayouts,
  }) {
    final profiles = [
      for (final l in levels) LevelQuality.profile(l, playouts: playouts),
    ];
    final byLevel = {for (final p in profiles) p.level: p};
    final byNumber = {for (final l in levels) l.levelNumber: l};
    final normals = profiles.where((p) => p.type == LevelType.normal).toList();
    final played = profiles.where((p) => p.type != LevelType.tutorial).toList();

    double m(LevelQualityProfile p, String k) => (p.toJson()[k] as num) * 1.0;

    // Ranges.
    final rangeRows = <Map<String, Object?>>[];
    for (final r in ranges) {
      for (final t in [LevelType.normal, LevelType.boss, LevelType.god]) {
        final xs = profiles
            .where((p) => p.level >= r[0] && p.level <= r[1] && p.type == t)
            .toList();
        if (xs.isEmpty) continue;
        rangeRows.add({
          'range': '${r[0]}-${r[1]}',
          'type': t.name,
          'n': xs.length,
          'labels': {for (final p in xs) p.difficulty.name}.toList()..sort(),
          'median': {
            for (final k in _rangeMetrics)
              k: _r(_quantile(xs.map((p) => m(p, k)).toList(), 0.5)),
          },
          'p10p90': {
            for (final k in ['trapRate', 'peelRounds', 'units'])
              k: [
                _r(_quantile(xs.map((p) => m(p, k)).toList(), 0.1)),
                _r(_quantile(xs.map((p) => m(p, k)).toList(), 0.9)),
              ],
          },
        });
      }
    }

    // Labels.
    final labelRows = <Map<String, Object?>>[];
    for (final d in _labelOrder) {
      final xs = profiles.where((p) => p.difficulty == d).toList();
      if (xs.isEmpty) continue;
      labelRows.add({
        'label': d.name,
        'n': xs.length,
        'byType': _count(xs.map((p) => p.type.name)),
        'levels': [xs.first.level, xs.last.level],
        'median': {
          for (final k in ['units', 'peelRounds', 'trapRate', 'cellDp'])
            k: _r(_quantile(xs.map((p) => m(p, k)).toList(), 0.5)),
        },
      });
    }
    final labelRank = normals.map((p) => p.difficulty.index * 1.0).toList();
    final levelRank = normals.map((p) => p.level * 1.0).toList();
    final correlations = {
      for (final k in [
        'units',
        'peelRounds',
        'trapRate',
        'openingShare',
        'forcedShare',
        'meanLegalMoves',
        'deadEndRate',
        'cellDp',
      ])
        k: {
          'label':
              _r(_spearman(labelRank, normals.map((p) => m(p, k)).toList())),
          'level':
              _r(_spearman(levelRank, normals.map((p) => m(p, k)).toList())),
        },
    };
    final hard = normals.where((p) => p.difficulty == Difficulty.hard).toList();
    final hardPeel =
        _quantile(hard.map((p) => p.peelRounds * 1.0).toList(), .5);
    final hardTrap = _quantile(hard.map((p) => p.trapRate).toList(), .5);
    final legend = profiles.where((p) => p.difficulty == Difficulty.legend);
    final legendSection = {
      'count': legend.length,
      'byType': _count(legend.map((p) => p.type.name)),
      'firstByType': {
        for (final t in LevelType.values)
          if (legend.any((p) => p.type == t))
            t.name: legend.firstWhere((p) => p.type == t).level,
      },
      'normalsAtOrBelowMedianHard': [
        for (final p in normals)
          if (p.difficulty == Difficulty.legend &&
              p.peelRounds <= hardPeel &&
              p.trapRate <= hardTrap)
            p.level,
      ],
      'medianHard': {'peelRounds': hardPeel, 'trapRate': _r(hardTrap)},
    };

    // Local outliers among normal levels, in play order.
    final outliers = <String, Object?>{};
    for (final k in ['peelRounds', 'trapRate', 'forcedShare', 'openingShare']) {
      final rows = <Map<String, Object?>>[];
      for (var i = 0; i < normals.length; i++) {
        const w = QualityThresholds.outlierWindow;
        final nb = [
          for (var j = math.max(0, i - w);
              j <= math.min(normals.length - 1, i + w);
              j++)
            if (j != i) m(normals[j], k),
        ];
        final med = _quantile(nb, .5);
        final mad = _quantile(nb.map((x) => (x - med).abs()).toList(), .5);
        if (mad == 0) continue;
        final z = (m(normals[i], k) - med) / (1.4826 * mad);
        if (z.abs() >= QualityThresholds.outlierZ) {
          rows.add({
            'level': normals[i].level,
            'value': _r(m(normals[i], k)),
            'localMedian': _r(med),
            'z': _r(z),
          });
        }
      }
      rows.sort((a, b) =>
          (b['z'] as double).abs().compareTo((a['z'] as double).abs()));
      outliers[k] = rows;
    }

    // Play-order jumps between consecutive levels.
    final jumps = <Map<String, Object?>>[];
    for (var i = 1; i < profiles.length; i++) {
      final a = profiles[i - 1], b = profiles[i];
      if (b.unitCount >= 2 * a.unitCount && b.unitCount - a.unitCount >= 15) {
        jumps.add({
          'from': a.level,
          'to': b.level,
          'toType': b.type.name,
          'units': [a.unitCount, b.unitCount],
          'peelRounds': [a.peelRounds, b.peelRounds],
        });
      }
    }

    List<int> where(bool Function(LevelQualityProfile p) f) => [
          for (final p in played)
            if (f(p)) p.level
        ];

    final candidates = {
      'shallow':
          where((p) => p.peelRounds <= QualityThresholds.shallowPeelRounds),
      'openStart':
          where((p) => p.openingShare >= QualityThresholds.openOpeningShare),
      'singleTrack': where(
          (p) => p.forcedShare >= QualityThresholds.singleTrackForcedShare),
      'orderDependent': {
        for (final p in played)
          if (p.deadEndRate > 0) '${p.level}': _r(p.deadEndRate),
      },
      'peelStalls': where((p) => !p.peelCleared),
      'smallCells': where((p) => p.cellDp < QualityThresholds.smallCellDp),
      'smallCellsCrowdedHeads': where((p) =>
          p.cellDp < QualityThresholds.smallCellDp &&
          p.headCrowding >= QualityThresholds.crowdedHeads),
      'hiddenBlockers': where(
          (p) => p.hiddenBlockerShare >= QualityThresholds.hiddenBlockerShare),
    };

    // Silhouettes.
    final silhouettes = <String, List<int>>{};
    for (final p in profiles) {
      silhouettes.putIfAbsent(p.silhouette, () => []).add(p.level);
    }
    final reuses = <List<int>>[];
    for (final ids in silhouettes.values) {
      for (var i = 1; i < ids.length; i++) {
        reuses.add([ids[i - 1], ids[i]]);
      }
    }
    final close = reuses
        .where((r) =>
            r[1] - r[0] <= QualityThresholds.silhouetteReuseGap &&
            byLevel[r[0]]!.type != LevelType.tutorial)
        .toList()
      ..sort((a, b) => a[0].compareTo(b[0]));
    final specialSil = profiles
        .where((p) => p.type == LevelType.boss || p.type == LevelType.god);
    final silhouetteSection = {
      'distinct': silhouettes.length,
      'reuseHistogram': _count(silhouettes.values.map((v) => '${v.length}')),
      'reusesWithin25': reuses.where((r) => r[1] - r[0] <= 25).length,
      'totalReuses': reuses.length,
      'closeReuses': close,
      'mostReused': (silhouettes.entries.toList()
            ..sort((a, b) => b.value.length != a.value.length
                ? b.value.length.compareTo(a.value.length)
                : a.value.first.compareTo(b.value.first)))
          .take(10)
          .map((e) => {
                'shape': byLevel[e.value.first]!.shape.name,
                'levels': e.value,
              })
          .toList(),
      'specialLevelsSharingSilhouette':
          specialSil.where((p) => silhouettes[p.silhouette]!.length > 1).length,
      'specialLevels': specialSil.length,
    };

    // Special levels against the normal levels of the same 7-level cycle.
    final specials = <String, Object?>{};
    for (final t in [LevelType.boss, LevelType.god]) {
      final rows = profiles.where((p) => p.type == t).toList();
      final labelOnly = <int>[];
      final noMechanics = <int>[];
      var unitsUp = 0, trapUp = 0, peelUp = 0;
      final wrongName = <int>[];
      for (final p in rows) {
        final cycle = (p.level - AppConstants.tutorialLevels - 1) ~/ 7;
        final start = AppConstants.tutorialLevels + 1 + cycle * 7;
        final peers = [
          for (var n = start; n < start + 7; n++)
            if (byLevel[n]?.type == LevelType.normal) byLevel[n]!,
        ];
        if (peers.isEmpty) continue;
        final u = _quantile(peers.map((q) => q.unitCount * 1.0).toList(), .5);
        final tr = _quantile(peers.map((q) => q.trapRate).toList(), .5);
        final pr = _quantile(peers.map((q) => q.peelRounds * 1.0).toList(), .5);
        final bigger = p.unitCount >= QualityThresholds.specialUnitsRatio * u;
        final trappier = p.trapRate >= tr + QualityThresholds.specialTrapDelta;
        final deeper = p.peelRounds >= QualityThresholds.specialPeelRatio * pr;
        if (bigger) unitsUp++;
        if (trappier) trapUp++;
        if (deeper) peelUp++;
        if (!bigger && !trappier && !deeper) labelOnly.add(p.level);
        if (p.directionalDots == 0 && p.pairCount == 0) {
          noMechanics.add(p.level);
        }
        final name = byNumber[p.level]!.patternName.toLowerCase();
        if (!name.startsWith(t.name)) wrongName.add(p.level);
      }
      specials[t.name] = {
        'count': rows.length,
        'firstLevels': rows.take(4).map((p) => p.level).toList(),
        'biggerThanCycleNormals': unitsUp,
        'trappierThanCycleNormals': trapUp,
        'deeperThanCycleNormals': peelUp,
        'notDistinctFromCycleNormals': labelOnly,
        'noDotsOrPairs': noMechanics,
        'patternNameMismatch': wrongName,
      };
    }

    // Near-duplicate clusters.
    final reviews = <ClusterReview>[];
    final keys = clusters.keys.toList()..sort();
    for (final key in keys) {
      final ids = clusters[key]!;
      var minMask = 1.0, maxArrow = 0.0;
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          final s =
              LevelSimilarity.compare(byNumber[ids[i]]!, byNumber[ids[j]]!);
          minMask = math.min(minMask, s.maskIoU);
          maxArrow = math.max(maxArrow, s.arrowIoU);
        }
      }
      final ps = ids.map((n) => byLevel[n]!).toList();
      final span = ids.last - ids.first;
      final verdict = maxArrow >= QualityThresholds.strongArrowIoU
          ? ClusterVerdict.strongDuplicate
          : minMask >= QualityThresholds.sameSilhouetteIoU &&
                  span <= QualityThresholds.nearbySpan
              ? ClusterVerdict.suspiciousRepetition
              : ClusterVerdict.acceptableRecurrence;
      reviews.add(ClusterReview(
        key: key,
        levels: ids,
        minMaskIoU: minMask,
        maxArrowIoU: maxArrow,
        span: span,
        peelRange: [
          ps.map((p) => p.peelRounds).reduce(math.min),
          ps.map((p) => p.peelRounds).reduce(math.max),
        ],
        openingRange: [
          ps.map((p) => p.openingShare).reduce(math.min),
          ps.map((p) => p.openingShare).reduce(math.max),
        ],
        verdict: verdict,
      ));
    }

    return CampaignQualityReport._(
      profiles,
      {
        'ranges': rangeRows,
        'labels': labelRows,
        'labelCorrelationNormal': correlations,
        'legend': legendSection,
        'outliers': outliers,
        'playOrderJumps': jumps,
        'candidates': candidates,
        'silhouettes': silhouetteSection,
        'specials': specials,
        'clusterVerdicts': _count(reviews.map((r) => r.verdict.name)),
      },
      reviews,
    );
  }

  Map<String, Object?> toJson() => {
        'thresholds': {
          'outlierZ': QualityThresholds.outlierZ,
          'outlierWindow': QualityThresholds.outlierWindow,
          'shallowPeelRounds': QualityThresholds.shallowPeelRounds,
          'openOpeningShare': QualityThresholds.openOpeningShare,
          'singleTrackForcedShare': QualityThresholds.singleTrackForcedShare,
          'smallCellDp': QualityThresholds.smallCellDp,
          'crowdedHeads': QualityThresholds.crowdedHeads,
          'hiddenBlockerShare': QualityThresholds.hiddenBlockerShare,
          'silhouetteReuseGap': QualityThresholds.silhouetteReuseGap,
          'strongArrowIoU': QualityThresholds.strongArrowIoU,
          'sameSilhouetteIoU': QualityThresholds.sameSilhouetteIoU,
          'nearbySpan': QualityThresholds.nearbySpan,
        },
        ...sections,
        'clusters': clusters.map((c) => c.toJson()).toList(),
        'levels': profiles.map((p) => p.toJson()).toList(),
      };

  /// Short, deterministic text summary for logs.
  String summary() {
    final buf =
        StringBuffer('Level quality audit (${profiles.length} levels)\n');
    for (final row in sections['ranges'] as List) {
      final r = row as Map<String, Object?>;
      final med = r['median'] as Map<String, Object?>;
      buf.writeln('  ${r['range']} ${r['type']} n=${r['n']} '
          'units=${med['units']} peel=${med['peelRounds']} '
          'trap=${med['trapRate']} open=${med['openingShare']} '
          'forced=${med['forcedShare']} cellDp=${med['cellDp']}');
    }
    final legend = sections['legend'] as Map<String, Object?>;
    buf.writeln('  legend=${legend['count']} ${legend['byType']} '
        'first=${legend['firstByType']}');
    final c = sections['candidates'] as Map<String, Object?>;
    for (final e in c.entries) {
      final v = e.value;
      final n = v is List ? v.length : (v as Map).length;
      buf.writeln('  ${e.key}: $n');
    }
    final s = sections['silhouettes'] as Map<String, Object?>;
    buf.writeln('  silhouettes distinct=${s['distinct']} '
        'reuses=${s['totalReuses']} within25=${s['reusesWithin25']}');
    buf.writeln('  clusters ${sections['clusterVerdicts']}');
    return buf.toString();
  }
}

double _r(num v) => (v * 1000).round() / 1000;

Map<String, int> _count(Iterable<String> xs) {
  final out = <String, int>{};
  for (final x in xs) {
    out[x] = (out[x] ?? 0) + 1;
  }
  return Map.fromEntries(
      out.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
}

/// Nearest-rank quantile.
double _quantile(List<double> xs, double q) {
  if (xs.isEmpty) return 0;
  final s = [...xs]..sort();
  return s[((s.length - 1) * q).round()];
}

List<double> _ranks(List<double> xs) {
  final idx = List.generate(xs.length, (i) => i)
    ..sort((a, b) => xs[a].compareTo(xs[b]));
  final ranks = List<double>.filled(xs.length, 0);
  var i = 0;
  while (i < idx.length) {
    var j = i;
    while (j + 1 < idx.length && xs[idx[j + 1]] == xs[idx[i]]) {
      j++;
    }
    for (var k = i; k <= j; k++) {
      ranks[idx[k]] = (i + j) / 2;
    }
    i = j + 1;
  }
  return ranks;
}

double _spearman(List<double> a, List<double> b) {
  final ra = _ranks(a), rb = _ranks(b);
  final ma = ra.reduce((x, y) => x + y) / ra.length;
  final mb = rb.reduce((x, y) => x + y) / rb.length;
  var num = 0.0, da = 0.0, db = 0.0;
  for (var i = 0; i < ra.length; i++) {
    num += (ra[i] - ma) * (rb[i] - mb);
    da += (ra[i] - ma) * (ra[i] - ma);
    db += (rb[i] - mb) * (rb[i] - mb);
  }
  return da == 0 || db == 0 ? 0 : num / math.sqrt(da * db);
}

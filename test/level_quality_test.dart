// ignore_for_file: avoid_print

@Tags(['campaign'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:arrow_escape/core/audio_manager.dart';
import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/level_generator/campaign_audit.dart';
import 'package:arrow_escape/data/level_generator/campaign_quality_report.dart';
import 'package:arrow_escape/data/level_generator/level_quality.dart';
import 'package:arrow_escape/data/models/arrow.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:arrow_escape/game/game_state.dart';
import 'package:flutter_test/flutter_test.dart';

ArrowModel _arrow(String id, ArrowDirection dir, List<List<int>> path,
        [int? group]) =>
    ArrowModel(
      id: id,
      row: path[0][0],
      col: path[0][1],
      direction: dir,
      path: path,
      colorGroup: group,
    );

LevelModel _level(List<ArrowModel> arrows, [List<OrphanDot> dots = const []]) =>
    LevelModel(
      levelNumber: 5,
      gridSize: 5,
      arrows: arrows,
      orphanDots: dots,
      patternName: 'test',
      difficulty: Difficulty.easy,
    );

/// X and Y face each other across an "up" dot. Either of them passing the
/// dot first escapes upward; Z also consumes the dot, after which X and Y
/// block each other for good.
LevelModel _orderTrap() => _level([
      _arrow('x', ArrowDirection.right, [
        [2, 0]
      ]),
      _arrow('y', ArrowDirection.left, [
        [2, 4]
      ]),
      _arrow('z', ArrowDirection.up, [
        [4, 2]
      ]),
    ], const [
      OrphanDot(row: 2, col: 2, type: OrphanDotType.up),
    ]);

/// Replays [taps] through the real GameState. Returns whether the game
/// reported a deadlock; fails if any tap is not a legal exit.
bool _replay(LevelModel level, List<String> taps) {
  var deadlocked = false;
  final state = GameState(
    level: level,
    onLevelComplete: () {},
    onGameOver: () {},
    onLifeLost: () {},
    onDeadlock: () => deadlocked = true,
  );
  for (final id in taps) {
    final group = state.arrows.firstWhere((a) => a.id == id).colorGroup;
    final unit = [
      for (final a in state.arrows)
        if (a.id == id || (group != null && a.colorGroup == group)) a.id,
    ];
    expect(state.tapArrow(id), TapResult.exited,
        reason: 'level ${level.levelNumber}: $id should exit');
    for (final a in unit) {
      state.handleArrowExitCompleted(a);
    }
  }
  if (!deadlocked) expect(state.isComplete, isTrue);
  return deadlocked;
}

/// One representative ID per tap unit (the lower-index arrow of a pair).
List<String> _unitIds(LevelModel level) {
  final seen = <int>{};
  return [
    for (final a in level.arrows)
      if (a.colorGroup == null || seen.add(a.colorGroup!)) a.id,
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AudioManager.instance.setSoundEnabled(false);

  group('LevelQuality rules', () {
    test('blocking chain without dots is monotone', () {
      // c is free; a waits for c; b waits for a.
      final level = _level([
        _arrow('a', ArrowDirection.right, [
          [1, 1],
          [1, 0]
        ]),
        _arrow('b', ArrowDirection.up, [
          [3, 1],
          [4, 1]
        ]),
        _arrow('c', ArrowDirection.up, [
          [1, 3],
          [2, 3]
        ]),
      ]);
      final p = LevelQuality.profile(level);
      expect(p.monotone, isTrue);
      expect(p.openingMoves, 1);
      expect(LevelQuality.openingLegalIds(level), {'c'});
      expect(p.peelRounds, 3);
      expect(p.peelProfile, [1, 1, 1]);
      expect(p.deadEndRate, 0);
      expect(p.forcedShare, closeTo(2 / 3, 1e-9));
      expect(p.maxFanIn, 1);
      expect(_replay(level, LevelQuality.firstLegalPlayout(level)), isFalse);
    });

    test('dot consumption can strand arrows, and GameState agrees', () {
      final level = _orderTrap();
      expect(LevelQuality.openingLegalIds(level), {'x', 'y', 'z'});
      expect(_replay(level, ['z']), isTrue);
      expect(_replay(level, ['x', 'y', 'z']), isFalse);

      final p = LevelQuality.profile(level);
      expect(p.monotone, isFalse);
      expect(p.deadEndRate, greaterThan(0));
      for (var k = 0; k < 16; k++) {
        final run = LevelQuality.seededPlayout(level, k);
        expect(_replay(level, run.taps), run.deadEnd);
      }
    });

    test('pairs leave together and never block each other', () {
      final level = _level([
        _arrow(
            'p1',
            ArrowDirection.right,
            [
              [2, 0]
            ],
            1),
        _arrow(
            'p2',
            ArrowDirection.left,
            [
              [2, 1]
            ],
            1),
      ]);
      final p = LevelQuality.profile(level);
      expect(p.unitCount, 1);
      expect(p.pairCount, 1);
      expect(p.openingMoves, 1);
      expect(_replay(level, LevelQuality.firstLegalPlayout(level)), isFalse);
    });

    test('profiles are deterministic', () {
      final level = _orderTrap();
      expect(jsonEncode(LevelQuality.profile(level).toJson()),
          jsonEncode(LevelQuality.profile(level).toJson()));
    });

    test('similarity ignores rotation and mirroring', () {
      final a = _level([
        _arrow('a', ArrowDirection.right, [
          [1, 2],
          [1, 1],
          [2, 1]
        ]),
        _arrow('b', ArrowDirection.up, [
          [3, 3],
          [4, 3]
        ]),
      ]);
      // 90° clockwise: (r, c) -> (c, 4 - r); right -> down, up -> right.
      final b = _level([
        _arrow('a', ArrowDirection.down, [
          [2, 3],
          [1, 3],
          [1, 2]
        ]),
        _arrow('b', ArrowDirection.right, [
          [3, 1],
          [3, 0]
        ]),
      ]);
      final s = LevelSimilarity.compare(a, b);
      expect(s.arrowIoU, 1);
      expect(s.headIoU, 1);
      expect(
          LevelSimilarity.silhouetteKey(a), LevelSimilarity.silhouetteKey(b));
    });
  });

  group('packaged campaign quality', () {
    final bytes = File('assets/levels.bin').readAsBytesSync();
    final decoder = LevelBinaryDecoder.fromBytes(bytes);
    final levels = [
      for (var n = 1; n <= decoder.levelCount; n++)
        decoder.decodeLevelByNumber(n)!,
    ];

    test('legal moves and dead ends match GameState on sampled levels', () {
      final sample = {
        for (var n = 1; n <= 30; n++) n,
        for (var n = 37; n <= levels.length; n += 37) n,
      };
      for (final n in sample) {
        final level = levels[n - 1];
        final legal = LevelQuality.openingLegalIds(level);
        final state = GameState(
          level: level,
          onLevelComplete: () {},
          onGameOver: () {},
          onLifeLost: () {},
          onDeadlock: () {},
        );
        for (final id in _unitIds(level)) {
          expect(!state.isArrowBlocked(id), legal.contains(id),
              reason: 'level $n arrow $id');
        }
        final taps = LevelQuality.firstLegalPlayout(level);
        expect(_replay(level, taps), taps.length < _unitIds(level).length,
            reason: 'level $n first-legal playout');
      }

      // Every dead end the profiler reports must be a real GameState deadlock.
      var checked = 0;
      for (final level in levels) {
        if (level.orphanDots.isEmpty) continue;
        for (var k = 0; k < LevelQuality.defaultPlayouts; k++) {
          final run = LevelQuality.seededPlayout(level, k);
          if (!run.deadEnd) continue;
          expect(_replay(level, run.taps), isTrue,
              reason: 'level ${level.levelNumber} playout $k');
          checked++;
          break;
        }
      }
      print('  confirmed dead ends in GameState: $checked levels');
    }, timeout: const Timeout(Duration(minutes: 10)));

    test('quality report covers every level', () {
      final audit = CampaignAudit.auditBytes(bytes);
      final clusters = CampaignAudit.nearDuplicateClusters(audit.findings);
      final sw = Stopwatch()..start();
      final report = CampaignQualityReport.build(levels, clusters: clusters);
      sw.stop();
      print(report.summary());
      print('  elapsed=${sw.elapsed.inSeconds}s');

      final path = Platform.environment['LEVEL_QUALITY_JSON'];
      if (path != null && path.isNotEmpty) {
        File(path)
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(
              const JsonEncoder.withIndent(' ').convert(report.toJson()));
        print('  json=$path');
      }

      expect(report.profiles, hasLength(levels.length));
      expect(report.clusters, hasLength(clusters.length));
      for (final p in report.profiles) {
        if (p.monotone) {
          expect(p.deadEndRate, 0, reason: 'level ${p.level}');
          expect(p.peelCleared, isTrue, reason: 'level ${p.level}');
        }
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}

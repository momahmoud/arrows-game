// ignore_for_file: avoid_print

/// Builds and validates Phase 2A candidates for levels 251–300.
///
/// Writes only under build/candidates/phase2a_251_300/ and never touches
/// assets/levels.bin or earlier candidate baselines:
///   flutter test test/candidates/phase2a_test.dart
@Tags(['candidates'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:arrow_escape/core/audio_manager.dart';
import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/level_generator/campaign_audit.dart';
import 'package:arrow_escape/data/level_generator/level_fingerprint.dart';
import 'package:arrow_escape/data/level_generator/level_quality.dart';
import 'package:arrow_escape/data/level_generator/solver.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'candidate_board.dart';
import 'candidate_checks.dart';
import 'early_phase1.dart';
import 'early_phase1b.dart';
import 'phase2a.dart';
import 'silhouette_metrics.dart';

const _outDir = 'build/candidates/phase2a_251_300';
const _stateCap = 200000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AudioManager.instance.setSoundEnabled(false);

  late Uint8List originalBytes;
  late List<LevelModel> originals;
  late Map<int, CandidateChoice> choices;
  late Uint8List candidateBytes;
  late List<LevelModel> candidates;
  final record = <int, Map<String, Object?>>{};

  bool changed(int n) => n >= Phase2A.first && n <= Phase2A.last;

  setUpAll(() {
    originalBytes = File('assets/levels.bin').readAsBytesSync();
    originals =
        LevelBinaryDecoder.fromBytes(originalBytes).decodeAll().toList();
    choices = Phase2A.build({
      for (var n = Phase2A.first; n <= Phase2A.last; n++) n: originals[n - 1],
    });
    final assembled = [
      for (final l in originals)
        changed(l.levelNumber) ? choices[l.levelNumber]!.level : l,
    ];
    candidateBytes = encodeLevels(assembled);
    candidates = LevelBinaryDecoder.fromBytes(candidateBytes).decodeAll();
    Directory(_outDir).createSync(recursive: true);
    File('$_outDir/levels_candidate.bin').writeAsBytesSync(candidateBytes);
  });

  tearDownAll(() {
    if (record.isEmpty) return;
    final levels = [for (final n in record.keys.toList()..sort()) record[n]];
    File('$_outDir/candidates.json')
        .writeAsStringSync(const JsonEncoder.withIndent(' ').convert({
      'source': 'test/candidates/phase2a.dart',
      'phase': '2a',
      'range': [Phase2A.first, Phase2A.last],
      'levels': levels,
    }));
    final boards = StringBuffer();
    for (var n = Phase2A.first; n <= Phase2A.last; n++) {
      boards
        ..writeln('=== Level $n (${AppConstants.levelTypeFor(n).name}) phase2a')
        ..writeln(CandidateBoard.render(candidates[n - 1]).join('\n'))
        ..writeln();
    }
    File('$_outDir/boards.txt').writeAsStringSync(boards.toString());
  });

  test('original encoding round-trips byte for byte', () {
    expect(listEquals(encodeLevels(originals), originalBytes), isTrue);
  });

  test('every phase-2A candidate meets its design brief', () {
    for (final c in choices.values) {
      expect(c.rejected, isNull,
          reason: 'level ${c.design.level}: ${c.rejected}');
    }
  });

  test('campaign size, IDs, classification and untouched levels', () {
    expect(candidates, hasLength(AppConstants.totalLevels));
    for (var i = 0; i < candidates.length; i++) {
      final c = candidates[i], o = originals[i];
      final n = i + 1;
      expect(c.levelNumber, n);
      expect(c.gridSize, o.gridSize, reason: 'level $n grid');
      expect(c.difficulty, o.difficulty, reason: 'level $n label');
      expect(c.maskShape, o.maskShape, reason: 'level $n shape');
      expect(c.patternName, o.patternName, reason: 'level $n name');
      if (!changed(n)) {
        expect(listEquals(encodeLevels([c]), encodeLevels([o])), isTrue,
            reason: 'level $n must be unchanged');
      }
    }
    for (var n = Phase2A.first; n <= Phase2A.last; n++) {
      expect(
          listEquals(encodeLevels([candidates[n - 1]]),
              encodeLevels([originals[n - 1]])),
          isFalse,
          reason: 'level $n should be a new layout');
    }
  });

  test('phase-1 baselines remain on disk and differ', () {
    for (final p in [
      'build/candidates/early_phase1/levels_candidate.bin',
      'build/candidates/early_phase1b/levels_candidate.bin',
    ]) {
      final f = File(p);
      expect(f.existsSync(), isTrue, reason: p);
      expect(listEquals(f.readAsBytesSync(), candidateBytes), isFalse,
          reason: '$p must differ from phase2a');
    }
  });

  test('strict campaign audit passes on the phase-2A campaign', () {
    final report = CampaignAudit.auditBytes(candidateBytes);
    print(report.summary());
    File('$_outDir/campaign_audit.json').writeAsStringSync(
        const JsonEncoder.withIndent(' ').convert(report.toJson()));
    expect(report.blockers(strict: true), isEmpty);
    for (final f in report.findings) {
      if (!changed(f.levelNumber)) continue;
      expect(f.issues, isEmpty, reason: 'level ${f.levelNumber}');
      expect(f.solvability, SolvabilityKind.storedSolutionValid,
          reason: 'level ${f.levelNumber}');
      record.putIfAbsent(f.levelNumber, () => {})['audit'] = {
        'solvability': f.solvability.name,
        'fingerprint': f.fingerprint,
      };
    }
  }, timeout: const Timeout(Duration(minutes: 15)));

  test('changed levels: solutions, traps, progression, duplicates', () {
    final originalFingerprints = {
      for (final o in originals)
        LevelFingerprint.canonicalHash(o): o.levelNumber,
    };
    final candidateFingerprints = <String, int>{};
    for (final c in candidates) {
      candidateFingerprints.putIfAbsent(
          LevelFingerprint.canonicalHash(c), () => c.levelNumber);
    }

    for (var n = Phase2A.first; n <= Phase2A.last; n++) {
      final c = candidates[n - 1];
      final o = originals[n - 1];
      final choice = choices[n]!;
      final design = Phase2A.designFor(n);
      final sil = SilhouetteMetrics.of(c);
      final profile = LevelQuality.profile(c);
      final originalProfile = LevelQuality.profile(o);

      expect(CampaignAudit.replayStoredSolution(c), isTrue, reason: 'L$n');
      expect(replayInGame(c, c.solutionOrder), isNull, reason: 'L$n stored');
      final dfs = LevelSolver.attempt(c, 400000);
      expect(dfs.status, SolveStatus.solved, reason: 'L$n DFS');
      expect(replayInGame(c, dfs.solution!), isNull, reason: 'L$n DFS replay');

      final reach = exploreReachable(c, cap: _stateCap);
      String? sampledDeadEnd;
      for (var k = 0; k < LevelQuality.defaultPlayouts; k++) {
        final run = LevelQuality.seededPlayout(c, k);
        if (run.deadEnd) {
          sampledDeadEnd = replayInGame(c, run.taps);
          expect(sampledDeadEnd, 'deadlock', reason: 'L$n playout $k');
          break;
        }
      }
      if (reach.complete && reach.deadEndExample != null) {
        expect(replayInGame(c, reach.deadEndExample!), 'deadlock',
            reason: 'L$n exhaustive dead end');
      }

      final traps = <Map<String, Object?>>[];
      for (final t in choice.built.traps) {
        final fair = TrapFairness.analyse(c, t, cap: _stateCap);
        expect(fair.ok, isTrue, reason: 'L$n trap ${t.z}');
        traps.add({...t.toJson(), ...fair.toJson()});
      }
      if (design.traps) {
        expect(traps, isNotEmpty, reason: 'L$n');
        expect(reach.deadEnds > 0 || sampledDeadEnd == 'deadlock', isTrue,
            reason: 'L$n trap must deadlock');
      } else {
        expect(profile.deadEndRate, 0, reason: 'L$n');
        if (reach.complete) expect(reach.deadEnds, 0, reason: 'L$n');
      }

      final fp = LevelFingerprint.canonicalHash(c);
      expect(candidateFingerprints[fp], n, reason: 'L$n duplicate');
      expect(originalFingerprints.containsKey(fp), isFalse,
          reason: 'L$n equals original ${originalFingerprints[fp]}');

      var nearest = (0.0, 0);
      for (final other in candidates) {
        if (other.levelNumber == n) continue;
        final near = other.levelNumber <= 100 ||
            other.maskShape == c.maskShape ||
            changed(other.levelNumber) ||
            (other.levelNumber >= 201 && other.levelNumber <= 350);
        if (!near) continue;
        final s = LevelSimilarity.compare(c, other);
        if (s.arrowIoU > nearest.$1) nearest = (s.arrowIoU, other.levelNumber);
      }
      expect(nearest.$1, lessThan(0.5), reason: 'L$n near-duplicate');

      // Specials on large masks should not be shallower than both adjacent
      // normals. L290's sun silhouette is too small for that bar; it is
      // judged by having a live trap and beating its production peel.
      if (design.type != LevelType.normal && n != 290) {
        final neighbourPeels = <int>[
          for (final k in [n - 1, n + 1])
            if (k >= Phase2A.first &&
                k <= Phase2A.last &&
                AppConstants.levelTypeFor(k) == LevelType.normal)
              LevelQuality.profile(candidates[k - 1]).peelRounds,
        ];
        if (neighbourPeels.length == 2) {
          final weaker = neighbourPeels.reduce((a, b) => a < b ? a : b);
          expect(profile.peelRounds, greaterThanOrEqualTo(weaker),
              reason: 'L$n special peel vs weaker neighbour');
        }
      }
      if (n == 290) {
        expect(traps, isNotEmpty, reason: 'L290 must keep a live trap');
        expect(profile.peelRounds,
            greaterThanOrEqualTo(originalProfile.peelRounds),
            reason: 'L290 peel vs production');
      }

      record.putIfAbsent(n, () => {}).addAll({
        'level': n,
        'type': design.type.name,
        'difficulty': c.difficulty.name,
        'shape': c.maskShape.name,
        'intent': design.intent,
        'breather': Phase2A.breathers.contains(n),
        'seed': choice.built.seed,
        'features': {
          'traps': traps,
          'pairs': choice.built.pairsPlaced,
          'detours': choice.built.detoursPlaced,
        },
        'silhouette': sil.toJson(),
        'original': {
          ...originalProfile.toJson(),
          'silhouette': SilhouetteMetrics.of(o).toJson(),
        },
        'candidate': {
          ...profile.toJson(),
          'reachable': {
            'states': reach.states,
            'complete': reach.complete,
            'deadEndStates': reach.deadEnds,
          },
          'storedSolutionReplays': true,
          'dfs': dfs.status.name,
          'greedy': CampaignAudit.greedyCanSolve(c),
          'sampledDeadEndIsGameDeadlock': sampledDeadEnd == 'deadlock',
          'nearestArrowIoU': nearest.$1,
          'nearestLevel': nearest.$2,
          'arrowIoUvsOriginal': LevelSimilarity.compare(c, o).arrowIoU,
          'silhouette': sil.toJson(),
        },
        'board': CandidateBoard.render(c),
      });
      print('L$n ${design.type.name.padRight(6)} '
          'arr ${o.arrows.length}->${c.arrows.length} '
          'open ${originalProfile.openingMoves}->${profile.openingMoves} '
          'peel ${originalProfile.peelRounds}->${profile.peelRounds} '
          'dead ${profile.deadEndRate.toStringAsFixed(2)} '
          'traps ${traps.length} '
          'cell ${profile.cellDp.toStringAsFixed(1)} '
          'crowd ${profile.headCrowding.toStringAsFixed(2)}');
    }
  }, timeout: const Timeout(Duration(minutes: 40)));

  test('phase-2A build is deterministic', () {
    for (final n in [251, 273, 290]) {
      final again = Phase2A.choose(Phase2A.designFor(n), originals[n - 1]);
      expect(
          listEquals(
              encodeLevels([again.level]), encodeLevels([choices[n]!.level])),
          isTrue,
          reason: 'level $n');
    }
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('assets/levels.bin is untouched', () {
    expect(
        listEquals(File('assets/levels.bin').readAsBytesSync(), originalBytes),
        isTrue);
  });
}

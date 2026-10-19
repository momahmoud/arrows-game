// ignore_for_file: avoid_print

/// Builds and validates Phase 2C candidates for levels 351–400.
///
/// Baseline is production assets/levels.bin (not Phase 2A/2B). Writes only under
/// build/candidates/phase2c_351_400/:
///   flutter test test/candidates/phase2c_test.dart
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
import 'phase2c.dart';
import 'silhouette_metrics.dart';

const _outDir = 'build/candidates/phase2c_351_400';
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

  bool changed(int n) => n >= Phase2C.first && n <= Phase2C.last;

  setUpAll(() {
    originalBytes = File('assets/levels.bin').readAsBytesSync();
    originals =
        LevelBinaryDecoder.fromBytes(originalBytes).decodeAll().toList();
    choices = Phase2C.build({
      for (var n = Phase2C.first; n <= Phase2C.last; n++) n: originals[n - 1],
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
      'source': 'test/candidates/phase2c.dart',
      'phase': '2c',
      'range': [Phase2C.first, Phase2C.last],
      'seedSalt': Phase2C.seedSalt,
      'levels': levels,
    }));
    final boards = StringBuffer();
    for (var n = Phase2C.first; n <= Phase2C.last; n++) {
      boards
        ..writeln('=== Level $n (${AppConstants.levelTypeFor(n).name}) '
            '${Phase2C.roleFor(n).name} phase2c')
        ..writeln(CandidateBoard.render(candidates[n - 1]).join('\n'))
        ..writeln();
    }
    File('$_outDir/boards.txt').writeAsStringSync(boards.toString());
  });

  test('original encoding round-trips byte for byte', () {
    expect(listEquals(encodeLevels(originals), originalBytes), isTrue);
  });

  test('every phase-2C candidate meets its design brief', () {
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
    // Production baseline: 1–350 and 401–1000 untouched; 351–400 changed.
    for (var n = 1; n <= 350; n++) {
      expect(
          listEquals(encodeLevels([candidates[n - 1]]),
              encodeLevels([originals[n - 1]])),
          isTrue,
          reason: 'L$n');
    }
    for (var n = 401; n <= AppConstants.totalLevels; n++) {
      expect(
          listEquals(encodeLevels([candidates[n - 1]]),
              encodeLevels([originals[n - 1]])),
          isTrue,
          reason: 'L$n');
    }
    for (var n = Phase2C.first; n <= Phase2C.last; n++) {
      expect(
          listEquals(encodeLevels([candidates[n - 1]]),
              encodeLevels([originals[n - 1]])),
          isFalse,
          reason: 'level $n should be a new layout');
    }
  });

  test('earlier candidate baselines remain and differ', () {
    for (final p in [
      'build/candidates/early_phase1/levels_candidate.bin',
      'build/candidates/early_phase1b/levels_candidate.bin',
      'build/candidates/phase2a_251_300/levels_candidate.bin',
      'build/candidates/phase2b_301_350/levels_candidate.bin',
    ]) {
      final f = File(p);
      expect(f.existsSync(), isTrue, reason: p);
      expect(listEquals(f.readAsBytesSync(), candidateBytes), isFalse,
          reason: '$p must differ from phase2c');
    }
  });

  test('role mix is varied and not trap-majority', () {
    final roles = [
      for (var n = Phase2C.first; n <= Phase2C.last; n++) Phase2C.roleFor(n)
    ];
    final trapish = roles
        .where((r) =>
            r == Phase2CRole.trap ||
            r == Phase2CRole.bossTrap ||
            r == Phase2CRole.godTrap)
        .length;
    final nonTrap = roles.length - trapish;
    expect(nonTrap, greaterThan(trapish),
        reason: 'non-trap roles should outnumber trap roles');
    expect(Phase2C.breathers.length, greaterThanOrEqualTo(6));
    expect(Phase2C.chains.length, greaterThanOrEqualTo(8));
    expect(Phase2C.detours.length, greaterThanOrEqualTo(6));
    expect(Phase2C.traps.length, lessThanOrEqualTo(8));
  });

  test('strict campaign audit passes on the phase-2C campaign', () {
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

  test('changed levels: solutions, traps, roles, duplicates', () {
    final originalFingerprints = {
      for (final o in originals)
        LevelFingerprint.canonicalHash(o): o.levelNumber,
    };
    final candidateFingerprints = <String, int>{};
    for (final c in candidates) {
      candidateFingerprints.putIfAbsent(
          LevelFingerprint.canonicalHash(c), () => c.levelNumber);
    }

    for (var n = Phase2C.first; n <= Phase2C.last; n++) {
      final c = candidates[n - 1];
      final o = originals[n - 1];
      final choice = choices[n]!;
      final design = Phase2C.designFor(n);
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
            (other.levelNumber >= 301 && other.levelNumber <= 450);
        if (!near) continue;
        final s = LevelSimilarity.compare(c, other);
        if (s.arrowIoU > nearest.$1) nearest = (s.arrowIoU, other.levelNumber);
      }
      expect(nearest.$1, lessThan(0.5), reason: 'L$n near-duplicate');

      // Targeted rescues vs production.
      if (n == 352) {
        expect(profile.peelRounds, greaterThan(originalProfile.peelRounds),
            reason: 'L352 peel vs production');
      }
      if (n == 364) {
        expect(profile.peelRounds, greaterThanOrEqualTo(10),
            reason: 'L364 peel floor');
        expect(profile.deadEndRate, lessThan(originalProfile.deadEndRate),
            reason: 'L364 milder deadlock than production 0.72');
      }
      if (n == 395) {
        expect(profile.pairCount, greaterThan(0),
            reason: 'L395 must restore pairs');
      }

      record.putIfAbsent(n, () => {}).addAll({
        'level': n,
        'type': design.type.name,
        'role': design.role.name,
        'difficulty': c.difficulty.name,
        'shape': c.maskShape.name,
        'intent': design.intent,
        'breather': design.role == Phase2CRole.breather,
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
      print('L$n ${design.role.name.padRight(10)} '
          'arr ${o.arrows.length}->${c.arrows.length} '
          'open ${originalProfile.openingMoves}->${profile.openingMoves} '
          'peel ${originalProfile.peelRounds}->${profile.peelRounds} '
          'dead ${profile.deadEndRate.toStringAsFixed(2)} '
          'traps ${traps.length} '
          'cell ${profile.cellDp.toStringAsFixed(1)}');
    }
  }, timeout: const Timeout(Duration(minutes: 45)));

  test('phase-2C build is deterministic', () {
    for (final n in [351, 370, 395]) {
      final again = Phase2C.choose(Phase2C.designFor(n), originals[n - 1]);
      expect(
          listEquals(
              encodeLevels([again.level]), encodeLevels([choices[n]!.level])),
          isTrue,
          reason: 'level $n');
    }
  }, timeout: const Timeout(Duration(minutes: 12)));

  test('assets/levels.bin is untouched', () {
    expect(
        listEquals(File('assets/levels.bin').readAsBytesSync(), originalBytes),
        isTrue);
  });
}

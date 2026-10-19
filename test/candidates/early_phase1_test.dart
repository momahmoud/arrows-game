// ignore_for_file: avoid_print

/// Builds and validates the phase-1 early-campaign candidates (levels 4–24).
///
/// Writes only under build/candidates/early_phase1/ and never touches
/// assets/levels.bin:
///   flutter test --tags candidates
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

const _outDir = 'build/candidates/early_phase1';

/// Exhaustive search budget per level; boards that exceed it are reported as
/// not exhaustively verified rather than as safe.
const _stateCap = 400000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AudioManager.instance.setSoundEnabled(false);

  late Uint8List originalBytes;
  late List<LevelModel> originals;
  late Map<int, CandidateChoice> choices;
  late Uint8List candidateBytes;
  late List<LevelModel> candidates;
  final record = <int, Map<String, Object?>>{};

  bool changed(int n) => n >= EarlyPhase1.first && n <= EarlyPhase1.last;

  setUpAll(() {
    originalBytes = File('assets/levels.bin').readAsBytesSync();
    originals =
        LevelBinaryDecoder.fromBytes(originalBytes).decodeAll().toList();
    choices = EarlyPhase1.build({
      for (var n = EarlyPhase1.first; n <= EarlyPhase1.last; n++)
        n: originals[n - 1],
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
      'source': 'test/candidates/early_phase1.dart',
      'levels': levels,
    }));
    final boards = StringBuffer();
    for (var n = EarlyPhase1.first; n <= EarlyPhase1.last; n++) {
      boards
        ..writeln('=== Level $n (${AppConstants.levelTypeFor(n).name}) '
            'candidate')
        ..writeln(CandidateBoard.render(candidates[n - 1]).join('\n'))
        ..writeln();
    }
    File('$_outDir/boards.txt').writeAsStringSync(boards.toString());
  });

  test('original encoding round-trips byte for byte', () {
    // Untouched levels are re-encoded, so this is what keeps them identical.
    expect(listEquals(encodeLevels(originals), originalBytes), isTrue);
  });

  test('every candidate meets its design brief', () {
    for (final c in choices.values) {
      expect(c.rejected, isNull, reason: 'level ${c.design.level}');
    }
  });

  test('campaign size, IDs, classification and untouched levels', () {
    expect(candidates, hasLength(AppConstants.totalLevels));
    expect(candidates.length, originals.length);
    for (var i = 0; i < candidates.length; i++) {
      final c = candidates[i], o = originals[i];
      final n = i + 1;
      expect(c.levelNumber, n);
      expect(c.levelNumber, o.levelNumber);
      expect(c.gridSize, o.gridSize, reason: 'level $n grid');
      expect(c.difficulty, o.difficulty, reason: 'level $n label');
      expect(c.maskShape, o.maskShape, reason: 'level $n shape');
      expect(c.patternName, o.patternName, reason: 'level $n name');
      if (!changed(n)) {
        expect(listEquals(encodeLevels([c]), encodeLevels([o])), isTrue,
            reason: 'level $n must be unchanged');
      }
    }
    for (var n = EarlyPhase1.first; n <= EarlyPhase1.last; n++) {
      expect(
          listEquals(encodeLevels([candidates[n - 1]]),
              encodeLevels([originals[n - 1]])),
          isFalse,
          reason: 'level $n should be a new layout');
    }
  });

  test('strict campaign audit passes on the candidate campaign', () {
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
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('changed levels: completion paths, dead ends and duplicates', () {
    final originalFingerprints = {
      for (final o in originals)
        LevelFingerprint.canonicalHash(o): o.levelNumber,
    };
    final candidateFingerprints = <String, int>{};
    for (final c in candidates) {
      candidateFingerprints.putIfAbsent(
          LevelFingerprint.canonicalHash(c), () => c.levelNumber);
    }

    for (var n = EarlyPhase1.first; n <= EarlyPhase1.last; n++) {
      final c = candidates[n - 1];
      final o = originals[n - 1];
      final choice = choices[n]!;
      final design = choice.design;

      // Completion: stored order in the real game, plus an independent DFS.
      expect(CampaignAudit.replayStoredSolution(c), isTrue, reason: 'L$n');
      expect(replayInGame(c, c.solutionOrder), isNull, reason: 'L$n stored');
      final dfs = LevelSolver.attempt(c, 400000);
      expect(dfs.status, SolveStatus.solved, reason: 'L$n DFS');
      expect(replayInGame(c, dfs.solution!), isNull, reason: 'L$n DFS replay');

      // Dead ends: exhaustive where the state space fits, sampled otherwise.
      final reach = exploreReachable(c, cap: _stateCap);
      final profile = LevelQuality.profile(c);
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
        // Reach the decision, waste the dot, then play on in the real game.
        final check =
            checkTrap(c, t.x, t.y, t.z, t.dotRow, t.dotCol, cap: _stateCap);
        expect(check.decisionReachable, isTrue, reason: 'L$n trap ${t.z}');
        final (deadlocked, left) = playOnInGame(c, [...check.path, t.z]);
        expect(deadlocked, isTrue, reason: 'L$n trap ${t.z} deadlock');
        expect(left, containsAll([t.x, t.y]), reason: 'L$n trap ${t.z}');
        traps.add({
          ...t.toJson(),
          'decisionAfterTaps': check.path.length,
          'wrongTapDeadlocksInGame': deadlocked,
        });
      }
      if (design.traps) {
        expect(traps, isNotEmpty, reason: 'L$n');
        expect(reach.deadEnds > 0 || sampledDeadEnd == 'deadlock', isTrue,
            reason: 'L$n trap must be a real deadlock');
      } else {
        expect(profile.deadEndRate, 0, reason: 'L$n');
        if (reach.complete) expect(reach.deadEnds, 0, reason: 'L$n');
      }

      // Duplicates: whole candidate campaign and every original level.
      final fp = LevelFingerprint.canonicalHash(c);
      expect(candidateFingerprints[fp], n, reason: 'L$n duplicate in campaign');
      expect(originalFingerprints.containsKey(fp), isFalse,
          reason: 'L$n equals original ${originalFingerprints[fp]}');

      var nearest = (0.0, 0);
      for (final other in candidates) {
        if (other.levelNumber == n) continue;
        final near = other.levelNumber <= 100 ||
            other.maskShape == c.maskShape ||
            changed(other.levelNumber);
        if (!near) continue;
        final s = LevelSimilarity.compare(c, other);
        if (s.arrowIoU > nearest.$1) nearest = (s.arrowIoU, other.levelNumber);
      }
      final vsOriginal = LevelSimilarity.compare(c, o).arrowIoU;
      expect(nearest.$1, lessThan(0.5), reason: 'L$n near-duplicate');

      final originalReach = exploreReachable(o, cap: _stateCap);
      record.putIfAbsent(n, () => {}).addAll({
        'level': n,
        'type': AppConstants.levelTypeFor(n).name,
        'difficulty': c.difficulty.name,
        'shape': c.maskShape.name,
        'intent': design.intent,
        'seed': choice.built.seed,
        'features': {
          'traps': traps,
          'pairs': choice.built.pairsPlaced,
          'detours': choice.built.detoursPlaced,
        },
        'original': {
          ...LevelQuality.profile(o).toJson(),
          'reachable': _reachJson(originalReach),
        },
        'candidate': {
          ...profile.toJson(),
          'reachable': _reachJson(reach),
          'storedSolutionReplays': true,
          'dfs': dfs.status.name,
          'greedy': CampaignAudit.greedyCanSolve(c),
          'sampledDeadEndIsGameDeadlock': sampledDeadEnd == 'deadlock',
          'nearestArrowIoU': nearest.$1,
          'nearestLevel': nearest.$2,
          'arrowIoUvsOriginal': vsOriginal,
        },
        'board': CandidateBoard.render(c),
      });
      print('L$n ${AppConstants.levelTypeFor(n).name.padRight(6)} '
          'arrows ${o.arrows.length}->${c.arrows.length} '
          'open ${LevelQuality.profile(o).openingMoves}->${profile.openingMoves} '
          'peel ${LevelQuality.profile(o).peelRounds}->${profile.peelRounds} '
          'dead ${profile.deadEndRate.toStringAsFixed(2)} '
          'states ${reach.states}${reach.complete ? '' : '+'} '
          'deadStates ${reach.deadEnds} '
          'nearest ${nearest.$1.toStringAsFixed(2)}@${nearest.$2}');
    }
  }, timeout: const Timeout(Duration(minutes: 20)));

  test('candidate build is deterministic', () {
    for (final n in [4, 12, 21]) {
      final again =
          EarlyPhase1.choose(EarlyPhase1.designs[n]!, originals[n - 1]);
      expect(
          listEquals(
              encodeLevels([again.level]), encodeLevels([choices[n]!.level])),
          isTrue,
          reason: 'level $n');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('assets/levels.bin is untouched', () {
    expect(
        listEquals(File('assets/levels.bin').readAsBytesSync(), originalBytes),
        isTrue);
  });
}

Map<String, Object?> _reachJson(ReachableStates r) => {
      'states': r.states,
      'complete': r.complete,
      'deadEndStates': r.deadEnds,
    };

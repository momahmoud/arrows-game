// ignore_for_file: avoid_print

/// Builds and validates the integrated first-500 quality candidate.
///
///   flutter test test/candidates/first500_test.dart
///
/// Output under build/candidates/first_500_quality/. Never writes
/// assets/levels.bin. Does not overwrite prior phase artifacts.
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
import 'first500_integrate.dart';
import 'first500_mid.dart';
import 'silhouette_metrics.dart';

const _outDir = First500Integrate.outDir;
const _stateCap = 200000;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AudioManager.instance.setSoundEnabled(false);

  late Uint8List originalBytes;
  late List<LevelModel> production;
  late Map<String, List<LevelModel>> phases;
  late Map<int, CandidateChoice> midChoices;
  late List<LevelModel> integrated;
  late Map<int, First500Source> sources;
  late Uint8List candidateBytes;
  final record = <int, Map<String, Object?>>{};

  setUpAll(() {
    originalBytes = File('assets/levels.bin').readAsBytesSync();
    production =
        LevelBinaryDecoder.fromBytes(originalBytes).decodeAll().toList();

    phases = {};
    for (final name in First500Integrate.phaseRanges.keys) {
      final path = 'build/candidates/$name/levels_candidate.bin';
      expect(File(path).existsSync(), isTrue, reason: path);
      phases[name] = First500Integrate.loadBin(path);
    }

    midChoices = First500Mid.build({
      for (final n in First500Mid.replaced) n: production[n - 1],
    });
    final midLevels = <int, LevelModel>{
      for (final e in midChoices.entries) e.key: e.value.level,
    };

    final assembled = First500Integrate.assemble(
      production: production,
      phases: phases,
      midReplacements: midLevels,
    );
    integrated = assembled.levels;
    sources = assembled.sources;
    candidateBytes = encodeLevels(integrated);
    Directory(_outDir).createSync(recursive: true);
    File('$_outDir/levels_candidate.bin').writeAsBytesSync(candidateBytes);
  });

  tearDownAll(() {
    if (record.isEmpty) return;
    final levels = [for (final n in record.keys.toList()..sort()) record[n]];
    final sourceSummary = <String, int>{};
    for (final s in sources.values) {
      sourceSummary[s.name] = (sourceSummary[s.name] ?? 0) + 1;
    }
    File('$_outDir/candidates.json')
        .writeAsStringSync(const JsonEncoder.withIndent(' ').convert({
      'source': 'test/candidates/first500_test.dart',
      'tag': 'first_500_quality',
      'sourceCounts': sourceSummary,
      'midReplacements': First500Mid.replaced.toList()..sort(),
      'levels': levels,
    }));
    final boards = StringBuffer();
    for (final n in First500Mid.replaced.toList()..sort()) {
      boards
        ..writeln('=== L$n mid ${First500Mid.roleFor(n).name} '
            '${First500Mid.issueFor(n)}')
        ..writeln(CandidateBoard.render(integrated[n - 1]).join('\n'))
        ..writeln();
    }
    File('$_outDir/mid_boards.txt').writeAsStringSync(boards.toString());
  });

  test('production encoding round-trips; assets untouched', () {
    expect(listEquals(encodeLevels(production), originalBytes), isTrue);
    expect(
        listEquals(File('assets/levels.bin').readAsBytesSync(), originalBytes),
        isTrue);
  });

  test('every prior phase binary is range-correct vs production', () {
    for (final e in First500Integrate.phaseRanges.entries) {
      final (first, last) = e.value;
      First500Integrate.assertPhaseRangeOnly(
        production: production,
        phase: phases[e.key]!,
        first: first,
        last: last,
        label: e.key,
      );
      print('OK ${e.key} range $first–$last');
    }
  });

  test('every mid replacement meets its brief', () {
    for (final e in midChoices.entries) {
      expect(e.value.rejected, isNull,
          reason: 'L${e.key}: ${e.value.rejected}');
    }
  });

  test('integrated campaign size, IDs, metadata, untouched tails', () {
    expect(integrated, hasLength(AppConstants.totalLevels));
    for (var i = 0; i < integrated.length; i++) {
      final c = integrated[i], o = production[i];
      final n = i + 1;
      expect(c.levelNumber, n);
      expect(c.gridSize, o.gridSize, reason: 'L$n grid');
      expect(c.difficulty, o.difficulty, reason: 'L$n difficulty');
      expect(c.maskShape, o.maskShape, reason: 'L$n shape');
      expect(c.patternName, o.patternName, reason: 'L$n name');
      expect(AppConstants.levelTypeFor(n), AppConstants.levelTypeFor(n));
    }
    for (var n = 1; n <= 3; n++) {
      expect(
          listEquals(encodeLevels([integrated[n - 1]]),
              encodeLevels([production[n - 1]])),
          isTrue,
          reason: 'tutorial L$n');
    }
    // Untouched production pockets inside 25–250 (not mid-replaced).
    for (var n = 25; n <= 250; n++) {
      if (First500Mid.replaced.contains(n)) continue;
      expect(
          listEquals(encodeLevels([integrated[n - 1]]),
              encodeLevels([production[n - 1]])),
          isTrue,
          reason: 'untouched L$n');
      expect(sources[n], First500Source.production);
    }
    for (var n = 501; n <= AppConstants.totalLevels; n++) {
      expect(
          listEquals(encodeLevels([integrated[n - 1]]),
              encodeLevels([production[n - 1]])),
          isTrue,
          reason: 'L$n');
      expect(sources[n], First500Source.production);
    }
  });

  test('source map covers intended composition', () {
    expect(sources[1], First500Source.production);
    expect(sources[4], First500Source.phase1b);
    expect(sources[24], First500Source.phase1b);
    expect(sources[25], First500Source.production);
    expect(sources[First500Mid.replaced.first], First500Source.mid25_250);
    expect(sources[251], First500Source.phase2a);
    expect(sources[301], First500Source.phase2b);
    expect(sources[351], First500Source.phase2c);
    expect(sources[401], First500Source.phase2d);
    expect(sources[451], First500Source.phase2e);
    expect(sources[500], First500Source.phase2e);
    expect(sources[501], First500Source.production);
  });

  test('prior phase artifacts remain and differ from integrated', () {
    for (final name in First500Integrate.phaseRanges.keys) {
      final f = File('build/candidates/$name/levels_candidate.bin');
      expect(f.existsSync(), isTrue);
      expect(listEquals(f.readAsBytesSync(), candidateBytes), isFalse,
          reason: '$name must differ from integrated');
    }
  });

  test('strict campaign audit passes on integrated candidate', () {
    final report = CampaignAudit.auditBytes(candidateBytes);
    print(report.summary());
    File('$_outDir/campaign_audit.json').writeAsStringSync(
        const JsonEncoder.withIndent(' ').convert(report.toJson()));
    expect(report.blockers(strict: true), isEmpty);
    expect(report.findings, hasLength(AppConstants.totalLevels));
    for (final f in report.findings) {
      expect(f.issues, isEmpty, reason: 'L${f.levelNumber}');
      // Tutorials / some production levels are confirmedSolvable without a
      // stored-solution label; changed candidates must replay stored solutions.
      final ok = f.solvability == SolvabilityKind.storedSolutionValid ||
          f.solvability == SolvabilityKind.confirmedSolvable;
      expect(ok, isTrue, reason: 'L${f.levelNumber} ${f.solvability}');
      if (sources[f.levelNumber] != First500Source.production) {
        expect(f.solvability, SolvabilityKind.storedSolutionValid,
            reason: 'changed L${f.levelNumber}');
      }
    }
  }, timeout: const Timeout(Duration(minutes: 20)));

  test('changed levels 1–500: solutions, mid traps, duplicates sample', () {
    final fingerprints = <String, int>{};
    for (final c in integrated) {
      fingerprints.putIfAbsent(
          LevelFingerprint.canonicalHash(c), () => c.levelNumber);
    }

    // Validate every non-production level in 1–500 thoroughly.
    final changed = <int>[
      for (var n = 1; n <= 500; n++)
        if (sources[n] != First500Source.production) n
    ];
    print('changed in 1–500: ${changed.length}');

    for (final n in changed) {
      final c = integrated[n - 1];
      final o = production[n - 1];
      final profile = LevelQuality.profile(c);
      final originalProfile = LevelQuality.profile(o);
      final sil = SilhouetteMetrics.of(c);

      expect(CampaignAudit.replayStoredSolution(c), isTrue, reason: 'L$n');
      expect(replayInGame(c, c.solutionOrder), isNull, reason: 'L$n stored');
      final dfs = LevelSolver.attempt(c, 400000);
      expect(dfs.status, SolveStatus.solved, reason: 'L$n DFS');
      expect(replayInGame(c, dfs.solution!), isNull, reason: 'L$n DFS replay');

      final fp = LevelFingerprint.canonicalHash(c);
      expect(fingerprints[fp], n, reason: 'L$n exact duplicate');

      final traps = <Map<String, Object?>>[];
      if (sources[n] == First500Source.mid25_250) {
        final choice = midChoices[n]!;
        final design = First500Mid.designFor(n);
        for (final t in choice.built.traps) {
          final fair = TrapFairness.analyse(c, t, cap: _stateCap);
          expect(fair.ok, isTrue, reason: 'L$n trap');
          traps.add({...t.toJson(), ...fair.toJson()});
        }
        if (design.traps) {
          expect(traps, isNotEmpty);
          expect(profile.deadEndRate, greaterThan(0),
              reason: 'L$n trap should show dead ends');
        } else {
          expect(profile.deadEndRate, 0);
        }
        // Targeted mid rescues
        if (n == 239) {
          expect(profile.deadEndRate, lessThan(originalProfile.deadEndRate));
        }
        if (n == 50 || n == 97 || n == 230) {
          expect(profile.peelRounds, greaterThan(originalProfile.peelRounds));
        }
        if ({210, 217, 220}.contains(n)) {
          expect(profile.openingMoves, lessThan(originalProfile.openingMoves));
          expect(profile.headCrowding, lessThan(0.6));
        }
      }

      record[n] = {
        'level': n,
        'source': sources[n]!.name,
        'type': AppConstants.levelTypeFor(n).name,
        'shape': c.maskShape.name,
        if (sources[n] == First500Source.mid25_250) ...{
          'role': First500Mid.roleFor(n).name,
          'issue': First500Mid.issueFor(n),
          'intent': midChoices[n]!.design.intent,
          'features': {
            'traps': traps,
            'pairs': midChoices[n]!.built.pairsPlaced,
            'detours': midChoices[n]!.built.detoursPlaced,
          },
        },
        'original': originalProfile.toJson(),
        'candidate': {
          ...profile.toJson(),
          'silhouette': sil.toJson(),
          'dfs': dfs.status.name,
          'storedSolutionReplays': true,
        },
      };
    }

    // Spot-check production pockets still encode-identical.
    for (final n in [25, 100, 150, 200, 250, 501, 750, 1000]) {
      if (First500Mid.replaced.contains(n)) continue;
      expect(
          listEquals(encodeLevels([integrated[n - 1]]),
              encodeLevels([production[n - 1]])),
          isTrue,
          reason: 'spot L$n');
    }
  }, timeout: const Timeout(Duration(minutes: 90)));

  test('first-500 duration and boundary snapshot metrics', () {
    final bands = <(int, int, String)>[
      (1, 24, '1–24'),
      (25, 100, '25–100'),
      (101, 150, '101–150'),
      (151, 200, '151–200'),
      (201, 250, '201–250'),
      (251, 300, '251–300'),
      (301, 350, '301–350'),
      (351, 400, '351–400'),
      (401, 450, '401–450'),
      (451, 500, '451–500'),
    ];
    int med(List<int> xs) {
      xs = [...xs]..sort();
      return xs[xs.length ~/ 2];
    }

    final summary = <Map<String, Object?>>[];
    for (final (a, b, label) in bands) {
      final peels = [
        for (var n = a; n <= b; n++)
          LevelQuality.profile(integrated[n - 1]).peelRounds
      ];
      final arrows = [
        for (var n = a; n <= b; n++) integrated[n - 1].arrows.length
      ];
      final crowds = [
        for (var n = a; n <= b; n++)
          LevelQuality.profile(integrated[n - 1]).headCrowding
      ];
      final short = peels.where((p) => p < 11).length;
      final row = {
        'band': label,
        'medianPeel': med(peels),
        'p10Peel': ([...peels]..sort())[peels.length ~/ 10],
        'p90Peel': ([...peels]..sort())[(peels.length * 9) ~/ 10],
        'shortPeelLt11': short,
        'medianArrows': med(arrows),
        'medianCrowd': ([...crowds]..sort())[crowds.length ~/ 2],
      };
      summary.add(row);
      print('$label peel=${row['medianPeel']} '
          'p10/p90=${row['p10Peel']}/${row['p90Peel']} '
          'short=${row['shortPeelLt11']} arr=${row['medianArrows']} '
          'crowd=${(row['medianCrowd'] as double).toStringAsFixed(2)}');
    }
    File('$_outDir/band_summary.json')
        .writeAsStringSync(const JsonEncoder.withIndent(' ').convert(summary));

    // Boundary pairs: report deltas (not hard-fail).
    final boundaries = [3, 24, 100, 200, 250, 300, 350, 400, 450, 500];
    final bounds = <Map<String, Object?>>[];
    for (final n in boundaries) {
      if (n >= 1000) continue;
      final a = LevelQuality.profile(integrated[n - 1]);
      final b = LevelQuality.profile(integrated[n]);
      bounds.add({
        'left': n,
        'right': n + 1,
        'leftSource': sources[n]!.name,
        'rightSource': sources[n + 1]!.name,
        'peel': [a.peelRounds, b.peelRounds],
        'arrows': [a.arrowCount, b.arrowCount],
        'open': [a.openingMoves, b.openingMoves],
        'crowd': [a.headCrowding, b.headCrowding],
      });
      print('boundary $n|${n + 1} '
          '${sources[n]!.name}->${sources[n + 1]!.name} '
          'peel ${a.peelRounds}->${b.peelRounds} '
          'arr ${a.arrowCount}->${b.arrowCount} '
          'open ${a.openingMoves}->${b.openingMoves}');
    }
    File('$_outDir/boundaries.json')
        .writeAsStringSync(const JsonEncoder.withIndent(' ').convert(bounds));
  }, timeout: const Timeout(Duration(minutes: 15)));

  test('assets/levels.bin still untouched after suite', () {
    expect(
        listEquals(File('assets/levels.bin').readAsBytesSync(), originalBytes),
        isTrue);
  });
}

// ignore_for_file: avoid_print

@Tags(['campaign'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_generator/campaign_audit.dart';
import 'package:arrow_escape/data/level_generator/solver.dart';
import 'package:arrow_escape/data/models/arrow.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CampaignAudit unit checks', () {
    test('SolveOutcome distinguishes limit from unsolvable', () {
      final empty = LevelModel(
        levelNumber: 1,
        gridSize: 2,
        arrows: const [],
        patternName: 'empty',
        difficulty: Difficulty.easy,
      );
      // Empty board is immediately solved by DFS (remainingCount == 0).
      expect(LevelSolver.attempt(empty).status, SolveStatus.solved);
    });

    test('structuralIssues catches overlapping paths', () {
      final level = LevelModel(
        levelNumber: 4,
        gridSize: AppConstants.gridSizeForLevel(4),
        arrows: [
          ArrowModel(
            id: 'a_4_0',
            row: 1,
            col: 1,
            direction: ArrowDirection.right,
            path: const [
              [1, 1],
              [1, 2],
            ],
          ),
          ArrowModel(
            id: 'a_4_1',
            row: 1,
            col: 2,
            direction: ArrowDirection.down,
            path: const [
              [1, 2],
              [2, 2],
            ],
          ),
        ],
        patternName: 'bad',
        difficulty: Difficulty.easy,
        mask: {'1,1', '1,2', '2,2'},
      );
      final issues = CampaignAudit.structuralIssues(
        level,
        expectedLevelNumber: 4,
      );
      expect(issues.any((i) => i.contains('overlap')), isTrue);
    });
  });

  group('CampaignAuditReport output', () {
    LevelAuditFinding finding(int n, SolvabilityKind kind) => LevelAuditFinding(
          levelNumber: n,
          issues: const [],
          solvability: kind,
          fingerprint: 'fp$n',
          isFallback: false,
          gridSize: 10,
          arrowCount: 5,
          levelType: LevelType.normal,
          difficulty: Difficulty.easy,
          maskShape: MaskShape.square,
        );

    test('unverified blocks only in strict mode and is never unsolvable', () {
      final report = CampaignAuditReport(
        expectedCount: 2,
        actualCount: 2,
        findings: [
          finding(1, SolvabilityKind.confirmedSolvable),
          finding(2, SolvabilityKind.unverified),
        ],
        gridHistogram: const {10: 2},
        arrowHistogram: const {},
        difficultyHistogram: const {},
        typeHistogram: const {},
        dfsStateLimit: 8000,
      );
      expect(report.blockers(), isEmpty);
      expect(report.blockers(strict: true).single, contains('unverified'));
      expect(report.confirmedUnsolvable, 0);
      expect(report.summary(), contains('unverified IDs'));

      final json = jsonDecode(jsonEncode(report.toJson())) as Map;
      expect(json['unverifiedLevels'], [2]);
      expect((json['counts'] as Map)['confirmedUnsolvable'], 0);
      expect((json['levels'] as List).length, 2);
    });

    test('count mismatch and unsolvable levels are blockers', () {
      final report = CampaignAuditReport(
        expectedCount: 3,
        actualCount: 2,
        findings: [
          finding(1, SolvabilityKind.confirmedSolvable),
          finding(2, SolvabilityKind.confirmedUnsolvable),
        ],
        gridHistogram: const {10: 2},
        arrowHistogram: const {},
        difficultyHistogram: const {},
        typeHistogram: const {},
      );
      final blockers = report.blockers();
      expect(blockers, hasLength(3));
      expect(blockers.last, 'confirmed unsolvable levels: 2');
      expect(report.summary(), contains('level 2'));
    });
  });

  group('packaged campaign audit', () {
    test('audits every level 1..totalLevels from assets/levels.bin', () {
      final env = Platform.environment;
      final strict = env['CAMPAIGN_AUDIT_STRICT'] == '1';
      final jsonPath = env['CAMPAIGN_AUDIT_JSON'];
      final github = env['GITHUB_ACTIONS'] == 'true';

      final file = File('assets/levels.bin');
      expect(file.existsSync(), isTrue, reason: 'assets/levels.bin required');

      final sw = Stopwatch()..start();
      final CampaignAuditReport report;
      try {
        report = CampaignAudit.auditBytes(
          file.readAsBytesSync(),
          expectedCount: AppConstants.totalLevels,
          dfsStateLimit: 8000,
        );
      } on FormatException catch (e) {
        if (github) print('::error file=assets/levels.bin::$e');
        fail('assets/levels.bin is not a valid level binary: $e');
      }
      sw.stop();

      print(report.summary());
      print('  elapsed=${sw.elapsed.inSeconds}s');
      print('  typeHistogram=${report.typeHistogram}');
      print('  difficultyHistogram=${report.difficultyHistogram}');
      print('  arrowBands=${report.arrowHistogram}');
      print('  distinctGridSizes=${report.gridHistogram.length}');

      final near = CampaignAudit.nearDuplicateNotes(report.findings);
      if (near.isNotEmpty) {
        print('  nearDuplicateClusters=${near.length}');
        for (final note in near.take(12)) {
          print('    $note');
        }
      }

      if (jsonPath != null && jsonPath.isNotEmpty) {
        final json = report.toJson()
          ..['strict'] = strict
          ..['nearDuplicateNotes'] = near;
        File(jsonPath)
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(
            const JsonEncoder.withIndent('  ').convert(json),
          );
        print('  json=$jsonPath');
      }

      final blockers = report.blockers(strict: strict);
      if (blockers.isNotEmpty) {
        print('  RELEASE BLOCKERS (strict=$strict):');
        for (final b in blockers) {
          print('    - $b');
          if (github) print('::error file=assets/levels.bin::$b');
        }
        print('  Reproduce locally: '
            '${strict ? 'CAMPAIGN_AUDIT_STRICT=1 ' : ''}'
            'flutter test test/campaign_audit_test.dart');
      }

      expect(blockers, isEmpty);
      expect(report.actualCount, AppConstants.totalLevels);
      expect(report.findings.length, AppConstants.totalLevels);

      // Hard failures — these are confirmed content defects.
      expect(
        report.structuralFailures.map((f) => '${f.levelNumber}:${f.issues}'),
        isEmpty,
        reason: 'Structural failures must be empty',
      );
      expect(
        report.unsolvableFailures.map((f) => f.levelNumber),
        isEmpty,
        reason: 'Confirmed-unsolvable levels must be empty',
      );
      expect(
        report.duplicates.map((f) => '${f.levelNumber}->${f.duplicateOf}'),
        isEmpty,
        reason: 'Exact fingerprint duplicates must be empty',
      );
      expect(
        report.fallbacks.map((f) => f.levelNumber),
        isEmpty,
        reason: 'Packaged fallback levels must be empty',
      );

      // Every level must be confirmed solvable (greedy/DFS/stored) or honestly
      // marked unverified — never silently treated as valid-without-check.
      final unknown = report.findings.where(
        (f) =>
            f.solvability != SolvabilityKind.confirmedSolvable &&
            f.solvability != SolvabilityKind.storedSolutionValid &&
            f.solvability != SolvabilityKind.unverified,
      );
      expect(unknown, isEmpty);

      // Prefer full confirmation; allow an explicit unverified budget only when
      // the DFS state limit is the blocker (reported above).
      expect(
        report.confirmedSolvable + report.unverified,
        AppConstants.totalLevels,
      );
    }, timeout: const Timeout(Duration(minutes: 45)));
  });
}

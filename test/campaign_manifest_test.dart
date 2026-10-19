// ignore_for_file: avoid_print

@Tags(['generator'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/level_generator/campaign_level_spec.dart';
import 'package:arrow_escape/data/level_generator/campaign_manifest.dart';
import 'package:arrow_escape/data/level_generator/level_fingerprint.dart';
import 'package:arrow_escape/data/level_generator/solver.dart';
import 'package:arrow_escape/data/level_layout_profile.dart';
import 'package:arrow_escape/core/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Campaign binary integrity (1000 levels)', () {
    final bin = File('assets/levels.bin');
    expect(bin.existsSync(), isTrue, reason: 'Run build_levels_bin_test first');

    final decoder = LevelBinaryDecoder.fromBytes(bin.readAsBytesSync());
    expect(decoder.levelCount, 1000);

    final fps = <String>{};
    var dupes = 0;
    var unsolvable = 0;
    var minArrows = 1 << 30;
    var maxArrows = 0;
    var totalArrows = 0;
    var minDen = 1.0;
    var maxDen = 0.0;
    var totalDen = 0.0;

    final manifest = <Map<String, dynamic>>[];

    for (var n = 1; n <= 1000; n++) {
      final level = decoder.decodeLevelByNumber(n);
      expect(level, isNotNull, reason: 'Missing level $n');
      expect(level!.levelNumber, n);

      final type = AppConstants.levelTypeFor(n);
      if (CampaignLevelSpec.isCampaignLevel(n, type)) {
        expect(
          level.arrows.length,
          inInclusiveRange(
            CampaignLevelSpec.minArrowCount(n, type),
            CampaignLevelSpec.maxArrowCount(n, type) + 5,
          ),
          reason: 'Level $n arrow band',
        );
      }

      final sol = LevelSolver.solve(level, 8000);
      if (sol == null) unsolvable++;

      final profile = LevelLayoutProfile.analyze(
        arrows: level.arrows,
        gridSize: level.gridSize,
        maskCells: level.mask.length,
        shapeType: level.maskShape.name,
      );
      totalArrows += level.arrows.length;
      minArrows =
          minArrows > level.arrows.length ? level.arrows.length : minArrows;
      maxArrows =
          maxArrows < level.arrows.length ? level.arrows.length : maxArrows;
      totalDen += profile.densityScore;
      if (profile.densityScore < minDen) minDen = profile.densityScore;
      if (profile.densityScore > maxDen) maxDen = profile.densityScore;

      final fp = LevelFingerprint.canonicalHash(level);
      if (fps.contains(fp)) dupes++;
      fps.add(fp);

      manifest.add(CampaignManifestEntry.fromLevel(level).toJson());
    }

    Directory('docs/dev').createSync(recursive: true);
    File('docs/dev/level_manifest.json').writeAsStringSync(
      jsonEncode(manifest),
    );

    print('Total: 1000');
    print('Valid: ${1000 - unsolvable}');
    print('Unsolvable: $unsolvable');
    print('Duplicate fingerprints: $dupes');
    print('Min arrows: $minArrows');
    print('Max arrows: $maxArrows');
    print('Avg arrows: ${totalArrows / 1000}');
    print('Min density: $minDen');
    print('Max density: $maxDen');
    print('Avg density: ${totalDen / 1000}');

    expect(unsolvable, 0);
    expect(dupes, 0);
  }, skip: !File('assets/levels.bin').existsSync());
}

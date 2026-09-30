// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

import 'verify_chunk_helper.dart';

// Regenerates levels in assets/levels.bin with the current generator, keeping
// every level that fails verification exactly as it is in the file today.
//
// Heavy — skipped unless asked for:
//   LEVELS_PART=1-1000 LEVELS_JOBS=7 flutter test test/rebuild_levels_bin_test.dart
//     generates + verifies the range into build/levels_rebuild/, split across
//     isolates. Re-running resumes; levels already passing are skipped.
//     Never start two `flutter test` runs at once: they share build/ and crash.
//   LEVELS_MERGE=1 flutter test test/rebuild_levels_bin_test.dart
//     writes every passing level into assets/levels.bin. A level that failed
//     keeps its current board, so the file never loses a level.
//
// Each isolate keeps its own boss/god shape history, so which silhouette a
// boss or god level gets depends on the split. Run with LEVELS_JOBS=1 to
// reproduce the original sequential shape order.

const _outDir = 'build/levels_rebuild';

void main() {
  final part = Platform.environment['LEVELS_PART'];
  final merge = Platform.environment['LEVELS_MERGE'] == '1';
  final jobs = int.tryParse(Platform.environment['LEVELS_JOBS'] ?? '') ?? 1;

  test('Generate levels', () async {
    final bounds = part!.split('-').map(int.parse).toList();
    final levels = [for (var n = bounds[0]; n <= bounds[1]; n++) n];
    Directory(_outDir).createSync(recursive: true);
    // Interleaved so every job gets a fair share of the large late boards.
    await Future.wait([
      for (var j = 0; j < jobs; j++)
        Isolate.run(() => _generate(
              [for (var i = j; i < levels.length; i += jobs) levels[i]],
              '$_outDir/job_${j}_of_$jobs.json',
            )),
    ]);
  }, skip: part == null, timeout: Timeout.none);

  test('Merge levels into levels.bin', _merge,
      skip: !merge, timeout: Timeout.none);
}

void _generate(List<int> levels, String path) {
  final file = File(path);
  final results = file.existsSync()
      ? (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)
      : <String, dynamic>{};

  for (final n in levels) {
    final previous = results['$n'] as Map<String, dynamic>?;
    if (previous?['status'] == 'pass') continue;

    final result = verifyLevel(n);
    results['$n'] = result;
    file.writeAsStringSync(jsonEncode(results), flush: true);

    if (result['status'] == 'pass') {
      final level = result['level'] as Map<String, dynamic>;
      final arrows = level['arrows'] as List;
      final lens = [
        for (final a in arrows) ((a as Map)['path'] as List).length,
      ];
      final short = lens.where((l) => l == 2).length;
      print('OK   $n ${MaskShape.values[level['maskShape'] as int].name} '
          'grid ${level['gridSize']} arrows ${arrows.length} '
          'len2 ${(short / lens.length * 100).round()}% ${result['ms']}ms');
    } else {
      print('FAIL $n ${result['errors']}');
    }
  }
}

void _merge() {
  final passing = <int, LevelModel>{};
  final failed = <int>{};
  final dir = Directory(_outDir);
  if (dir.existsSync()) {
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      final data = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      for (final e in data.entries) {
        final entry = e.value as Map<String, dynamic>;
        final n = int.parse(e.key);
        if (entry['status'] == 'pass') {
          passing[n] =
              LevelModel.fromJson(entry['level'] as Map<String, dynamic>);
        } else {
          failed.add(n);
        }
      }
    }
  }
  failed.removeAll(passing.keys);

  final source = File('assets/levels.bin');
  final decoder = LevelBinaryDecoder.fromBytes(source.readAsBytesSync());
  final levels = <LevelModel>[];
  final kept = <int>[];
  for (var n = 1; n <= decoder.levelCount; n++) {
    final replacement = passing[n];
    if (replacement == null) kept.add(n);
    levels.add(replacement ?? decoder.decodeLevelByNumber(n)!);
  }

  source.writeAsBytesSync(encodeLevels(levels));

  var arrows = 0, short = 0;
  for (final level in levels) {
    for (final arrow in level.arrows) {
      arrows++;
      if (arrow.path.length == 2) short++;
    }
  }
  print('levels.bin: ${levels.length} levels, '
      '${levels.length - kept.length} rebuilt, ${kept.length} unchanged');
  print('2-cell arrows across the file: '
      '${(short / arrows * 100).round()}% of $arrows');
  if (kept.isNotEmpty) print('Unchanged: ${kept.join(', ')}');
  if (failed.isNotEmpty) print('Failed generation: ${failed.join(', ')}');
}

// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

import 'verify_chunk_helper.dart';

// Regenerates only the NORMAL levels in assets/levels.bin with their shaped
// masks. Tutorial, boss and god levels are copied byte-for-byte.
//
// Heavy — skipped unless asked for:
//   SHAPES_PART=4-1000 SHAPES_JOBS=6 flutter test test/rebuild_normal_shapes_test.dart
//     generates + verifies the normal levels in range into build/shape_rebuild/,
//     split across isolates. Re-running resumes; passing levels are skipped.
//     Never start two `flutter test` runs at once: they share build/ and crash.
//   SHAPES_MERGE=1 flutter test test/rebuild_normal_shapes_test.dart
//     writes every passing level into assets/levels.bin. A level that failed
//     keeps its old rectangle board, so the file never loses a level.

const _outDir = 'build/shape_rebuild';

void main() {
  final part = Platform.environment['SHAPES_PART'];
  final merge = Platform.environment['SHAPES_MERGE'] == '1';
  final jobs = int.tryParse(Platform.environment['SHAPES_JOBS'] ?? '') ?? 1;

  test('Generate shaped normal levels', () async {
    final bounds = part!.split('-').map(int.parse).toList();
    final normals = [
      for (var n = bounds[0]; n <= bounds[1]; n++)
        if (AppConstants.levelTypeFor(n) == LevelType.normal) n,
    ];
    Directory(_outDir).createSync(recursive: true);
    // Interleaved so every job gets a fair share of the large late boards.
    await Future.wait([
      for (var j = 0; j < jobs; j++)
        Isolate.run(() => _generate(
              [for (var i = j; i < normals.length; i += jobs) normals[i]],
              '$_outDir/job_${j}_of_$jobs.json',
            )),
    ]);
  }, skip: part == null, timeout: Timeout.none);

  test('Merge shaped normal levels into levels.bin', _merge,
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
      final shape = MaskShape.values[level['maskShape'] as int].name;
      print('OK   $n $shape ${level['gridSize']} '
          '${(level['arrows'] as List).length} arrows ${result['ms']}ms');
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
    final isNormal = AppConstants.levelTypeFor(n) == LevelType.normal;
    final replacement = isNormal ? passing[n] : null;
    if (isNormal && replacement == null) kept.add(n);
    levels.add(replacement ?? decoder.decodeLevelByNumber(n)!);
  }

  final bytes = encodeLevels(levels);
  source.writeAsBytesSync(bytes);
  final normals = levels
      .where((l) => AppConstants.levelTypeFor(l.levelNumber) == LevelType.normal)
      .length;
  print('levels.bin: ${levels.length} levels, '
      '${normals - kept.length} of $normals normal levels reshaped, '
      '${kept.length} left as rectangles');
  if (kept.isNotEmpty) print('Left as rectangles: ${kept.join(', ')}');
  if (failed.isNotEmpty) print('Failed generation: ${failed.join(', ')}');
}

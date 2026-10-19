// ignore_for_file: avoid_print

@Tags(['generator'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

// Writes passing levels from assets/verify_progress_chunk_*.json into
// assets/levels.bin. Levels that have not passed stay as they are in the file.
//
//   MERGE_VERIFIED=1 flutter test test/merge_verified_progress_test.dart

void main() {
  final merge = Platform.environment['MERGE_VERIFIED'] == '1';

  test('Merge passing verify progress into levels.bin', () {
    final passing = <int, LevelModel>{};
    for (var chunk = 1; chunk <= 10; chunk++) {
      final file = File('assets/verify_progress_chunk_$chunk.json');
      if (!file.existsSync()) continue;
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final entry in data.entries) {
        final record = entry.value as Map<String, dynamic>;
        if (record['status'] != 'pass') continue;
        final n = int.parse(entry.key);
        final level = LevelModel.fromJson(
          record['level'] as Map<String, dynamic>,
        );
        if (level.levelNumber != n) {
          fail('Progress key $n has levelNumber ${level.levelNumber}');
        }
        passing[n] = level;
      }
    }

    final source = File('assets/levels.bin');
    final decoder = LevelBinaryDecoder.fromBytes(source.readAsBytesSync());
    final levels = <LevelModel>[];
    final replaced = <int>[];
    for (var n = 1; n <= decoder.levelCount; n++) {
      final replacement = passing.remove(n);
      if (replacement == null) {
        levels.add(decoder.decodeLevelByNumber(n)!);
      } else {
        levels.add(replacement);
        replaced.add(n);
      }
    }

    expect(levels.length, decoder.levelCount);
    expect(passing, isEmpty, reason: 'Passing levels outside levels.bin');
    for (var i = 0; i < levels.length; i++) {
      expect(levels[i].levelNumber, i + 1);
    }

    final bytes = encodeLevels(levels);
    final check = LevelBinaryDecoder.fromBytes(bytes);
    expect(check.levelCount, levels.length);
    for (final n in replaced) {
      final stored = check.decodeLevelByNumber(n)!;
      expect(stored.levelNumber, n);
      expect(stored.arrows.length, levels[n - 1].arrows.length);
    }

    source.writeAsBytesSync(bytes);
    print('levels.bin: ${levels.length} levels, '
        '${replaced.length} replaced, '
        '${levels.length - replaced.length} kept');
    print('Replaced: ${replaced.join(', ')}');
  }, skip: !merge);
}

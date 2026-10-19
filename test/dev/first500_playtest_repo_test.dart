/// Safety checks for the first-500 playtest level attach path.
///
///   flutter test test/dev/first500_playtest_repo_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/repositories/level_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('playtest attach skips prefs layout cache and never clears progress',
      () async {
    SharedPreferences.setMockInitialValues({
      'currentLevel': 42,
      'highestUnlockedLevel': 42,
      'cached_level_12': '{"invalid":true}',
    });
    final prefs = await SharedPreferences.getInstance();

    final production = File('assets/levels.bin').readAsBytesSync();
    final candidatePath =
        'build/candidates/first_500_quality/levels_candidate.bin';
    expect(File(candidatePath).existsSync(), isTrue);
    final candidate = File(candidatePath).readAsBytesSync();

    final repo = LevelRepository(prefs);
    repo.debugAttachPlaytestBinary(candidate);

    expect(repo.isPlaytestBinaryAttached, isTrue);
    expect(repo.packagedLevelCount, AppConstants.totalLevels);

    final level = repo.getLevel(12);
    expect(level.levelNumber, 12);
    expect(level.arrows, isNotEmpty);

    // Progress keys untouched; stale layout cache key left on disk but ignored.
    expect(prefs.getInt('currentLevel'), 42);
    expect(prefs.getInt('highestUnlockedLevel'), 42);
    expect(prefs.containsKey('cached_level_12'), isTrue);

    // Switching sources stays memory-only.
    repo.debugAttachPlaytestBinary(Uint8List.fromList(production));
    final prodL12 =
        LevelBinaryDecoder.fromBytes(production).decodeLevelByNumber(12)!;
    final attached = repo.getLevel(12);
    expect(attached.arrows.length, prodL12.arrows.length);

    expect(prefs.getInt('currentLevel'), 42);
  });

  test('null-prefs playtest repo never writes disk layout cache', () {
    final candidate =
        File('build/candidates/first_500_quality/levels_candidate.bin')
            .readAsBytesSync();
    final repo = LevelRepository();
    repo.debugAttachPlaytestBinary(candidate);
    final level = repo.getLevel(251);
    expect(level.levelNumber, 251);
    expect(repo.isPlaytestBinaryAttached, isTrue);
  });
}

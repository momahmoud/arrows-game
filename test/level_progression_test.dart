import 'dart:io';
import 'dart:typed_data';

import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:flutter_test/flutter_test.dart';

/// Documented campaign contract used only as a test oracle.
/// Production classification stays in [AppConstants.levelTypeFor].
LevelType _expectedType(int level) {
  if (level <= AppConstants.tutorialLevels) return LevelType.tutorial;
  final pos = ((level - AppConstants.tutorialLevels - 1) % 7) + 1;
  if (pos == 7) return LevelType.god;
  if (pos == 4) return LevelType.boss;
  return LevelType.normal;
}

void _expectValidGrid(int level, int size) {
  expect(size,
      inInclusiveRange(AppConstants.startingGridSize, AppConstants.maxGridSize),
      reason: 'Level $level grid size $size out of bounds');
  expect(size, equals(AppConstants.gridSizeForLevel(level)),
      reason: 'Level $level gridSizeForLevel must match itself');

  final type = AppConstants.levelTypeFor(level);
  switch (type) {
    case LevelType.tutorial:
      expect(size, 10, reason: 'Tutorial level $level');
    case LevelType.normal:
      if (level < 20) {
        expect(size, inInclusiveRange(15, 24), reason: 'Early normal $level');
      } else {
        expect(size, inInclusiveRange(25, 35), reason: 'Late normal $level');
      }
    case LevelType.boss:
    case LevelType.god:
      expect(size, inInclusiveRange(27, 40), reason: 'Special level $level');
  }
}

void main() {
  group('campaign progression contract', () {
    test('every level 1..totalLevels has the expected type and valid grid', () {
      var boss = 0;
      var god = 0;

      for (var level = 1; level <= AppConstants.totalLevels; level++) {
        final expected = _expectedType(level);
        final actual = AppConstants.levelTypeFor(level);
        expect(actual, expected, reason: 'levelTypeFor($level)');
        expect(AppConstants.isBossLevel(level), expected == LevelType.boss,
            reason: 'isBossLevel($level)');
        expect(AppConstants.isGodLevel(level), expected == LevelType.god,
            reason: 'isGodLevel($level)');

        if (expected == LevelType.boss) boss++;
        if (expected == LevelType.god) god++;

        expect(AppConstants.bossCycleCount(level), boss,
            reason: 'bossCycleCount($level)');
        expect(AppConstants.godCycleCount(level), god,
            reason: 'godCycleCount($level)');

        _expectValidGrid(level, AppConstants.gridSizeForLevel(level));
      }
    });

    test('regression anchors for early campaign levels', () {
      const cases = <int, LevelType>{
        3: LevelType.tutorial,
        4: LevelType.normal,
        7: LevelType.boss,
        10: LevelType.god,
        11: LevelType.normal,
        14: LevelType.boss,
        17: LevelType.god,
      };

      for (final entry in cases.entries) {
        final level = entry.key;
        final expected = entry.value;
        expect(AppConstants.levelTypeFor(level), expected,
            reason: 'levelTypeFor($level)');
        expect(AppConstants.isBossLevel(level), expected == LevelType.boss);
        expect(AppConstants.isGodLevel(level), expected == LevelType.god);
        _expectValidGrid(level, AppConstants.gridSizeForLevel(level));
      }

      expect(AppConstants.bossCycleCount(7), 1);
      expect(AppConstants.godCycleCount(10), 1);
      expect(AppConstants.bossCycleCount(14), 2);
      expect(AppConstants.godCycleCount(17), 2);
      expect(AppConstants.gridSizeForLevel(3), 10);
      expect(AppConstants.gridSizeForLevel(4), 15);
      expect(AppConstants.gridSizeForLevel(7), 27);
      expect(AppConstants.gridSizeForLevel(10), 27);
      expect(AppConstants.gridSizeForLevel(11), 19);
      expect(AppConstants.gridSizeForLevel(14), 28);
      expect(AppConstants.gridSizeForLevel(17), 28);
    });
  });

  group('assets/levels.bin header', () {
    test('ships totalLevels entries as LVLB v3', () {
      final file = File('assets/levels.bin');
      expect(file.existsSync(), isTrue);

      final bytes = file.readAsBytesSync();
      expect(bytes.length, greaterThanOrEqualTo(8));
      expect(
        String.fromCharCodes(bytes.sublist(0, 4)),
        'LVLB',
      );

      final data = ByteData.sublistView(bytes);
      expect(data.getUint16(4, Endian.little), 3);
      expect(data.getUint16(6, Endian.little), AppConstants.totalLevels);

      final decoder = LevelBinaryDecoder.fromBytes(bytes);
      expect(decoder.levelCount, AppConstants.totalLevels);
      expect(decoder.decodeLevelByNumber(1), isNotNull);
      expect(decoder.decodeLevelByNumber(AppConstants.totalLevels), isNotNull);
      expect(decoder.decodeLevelByNumber(AppConstants.totalLevels + 1), isNull);
    });
  });
}

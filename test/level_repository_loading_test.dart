import 'dart:convert';
import 'dart:typed_data';

import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/models/arrow.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:arrow_escape/data/repositories/level_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

LevelModel _level(int n, {String name = 'packaged'}) {
  return LevelModel(
    levelNumber: n,
    gridSize: 4,
    arrows: [
      ArrowModel(
        id: 'a_${n}_0',
        row: 0,
        col: 0,
        direction: ArrowDirection.right,
        path: const [
          [0, 0],
          [0, 1],
        ],
      ),
    ],
    patternName: name,
    difficulty: Difficulty.easy,
    solutionOrder: ['a_${n}_0'],
    mask: {'0,0', '0,1'},
  );
}

Uint8List _bundle(List<LevelModel> levels) => encodeLevels(levels);

Uint8List _corruptLevelBundle() {
  final good = encodeLevels([_level(1)]);
  // Truncate away the payload after a valid header/index.
  return Uint8List.fromList(good.sublist(0, 12)); // header(8)+index(4), no data
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LevelRepository loading', () {
    test('missing packaged asset falls back to generator without hanging',
        () async {
      var generates = 0;
      final repo = LevelRepository(
        await SharedPreferences.getInstance(),
        (n) {
          generates++;
          return _level(n, name: 'generated-$n');
        },
      );
      repo.debugAttachBinaryBytes(null);

      final sync = repo.getLevel(12);
      final asyncLevel = await repo.getLevelAsync(12);
      expect(sync.patternName, 'generated-12');
      expect(asyncLevel.patternName, 'generated-12');
      expect(generates, greaterThanOrEqualTo(1));
      expect(repo.packagedLevelCount, isNull);
    });

    test('level absent from packaged data uses emergency generator', () async {
      final repo = LevelRepository(
        null,
        (n) => _level(n, name: 'fallback-$n'),
      );
      repo.debugAttachBinaryBytes(_bundle([_level(1)]));

      expect(repo.getLevel(1).patternName, 'packaged');
      expect(repo.getLevel(2).patternName, 'fallback-2');
      expect(await repo.getLevelAsync(2), isA<LevelModel>());
    });

    test('decoding failure recovers via generator (not a partial level)', () {
      var generates = 0;
      final repo = LevelRepository(
        null,
        (n) {
          generates++;
          return _level(n, name: 'recovered');
        },
      );
      repo.debugAttachBinaryBytes(_corruptLevelBundle());

      final level = repo.getLevel(1);
      expect(level.patternName, 'recovered');
      expect(level.arrows, isNotEmpty);
      expect(generates, 1);
    });

    test('sync and async loading return the same packaged level', () async {
      final repo =
          LevelRepository(null, (n) => _level(n, name: 'should-not-run'));
      // Decoder addresses slot N-1, so level 1 occupies index 0.
      repo.debugAttachBinaryBytes(_bundle([_level(1, name: 'bin-1')]));

      final a = repo.getLevel(1);
      final b = await repo.getLevelAsync(1);
      expect(a.patternName, 'bin-1');
      expect(b.patternName, 'bin-1');
      expect(identical(a, b), isTrue);
    });

    test('memory cache wins over binary and disk', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_level_1',
        jsonEncode(_level(1, name: 'disk').toJson()),
      );
      final repo = LevelRepository(
        prefs,
        (n) => _level(n, name: 'gen'),
      );
      repo.debugAttachBinaryBytes(_bundle([_level(1, name: 'bin')]));
      // First load prefers binary over disk; second hit is memory.
      expect(repo.getLevel(1).patternName, 'bin');
      expect(repo.getLevel(1).patternName, 'bin');
    });

    test('lookup order is cache, then binary, then disk, then generate',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'cached_level_8',
        jsonEncode(_level(8, name: 'disk-8').toJson()),
      );

      var generates = 0;
      final repo = LevelRepository(
        prefs,
        (n) {
          generates++;
          return _level(n, name: 'gen-8');
        },
      );

      // No binary → disk
      repo.debugAttachBinaryBytes(null);
      expect(repo.getLevel(8).patternName, 'disk-8');
      expect(generates, 0);

      // Binary present for another level; requested level only on disk path after miss
      final repo2 = LevelRepository(
        prefs,
        (n) {
          generates++;
          return _level(n, name: 'gen-$n');
        },
      );
      repo2.debugAttachBinaryBytes(_bundle([_level(1, name: 'bin-1')]));
      expect(repo2.getLevel(8).patternName, 'disk-8');
      expect(repo2.getLevel(1).patternName, 'bin-1');
      expect(repo2.getLevel(9).patternName, 'gen-9');
    });

    test('concurrent async requests share one in-flight generate', () async {
      var generates = 0;
      final repo = LevelRepository(
        null,
        (n) {
          generates++;
          return _level(n, name: 'once');
        },
      );
      repo.debugAttachBinaryBytes(null);

      final results = await Future.wait([
        repo.getLevelAsync(40),
        repo.getLevelAsync(40),
        repo.getLevelAsync(40),
      ]);
      expect(results.every((l) => l.patternName == 'once'), isTrue);
      expect(generates, 1);
    });

    test('generator failure completes async request instead of hanging',
        () async {
      final repo = LevelRepository(
        null,
        (n) => throw StateError('generate failed for $n'),
      );
      repo.debugAttachBinaryBytes(null);

      await expectLater(
        repo.getLevelAsync(77).timeout(const Duration(seconds: 2)),
        throwsA(isA<StateError>()),
      );
    });
  });
}

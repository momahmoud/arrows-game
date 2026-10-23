import 'dart:convert';

import 'package:arrow_escape/data/models/arrow.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:arrow_escape/data/models/level_session.dart';
import 'package:arrow_escape/data/repositories/progress_repository.dart';
import 'package:arrow_escape/game/game_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ArrowModel _arrow(String id, ArrowDirection dir, List<List<int>> path) =>
    ArrowModel(
      id: id,
      row: path[0][0],
      col: path[0][1],
      direction: dir,
      path: path,
    );

/// Three arrows that all leave straight up, one behind another, plus a
/// direction dot that the first arrow passes on its way out.
LevelModel _level({int number = 12}) => LevelModel(
      levelNumber: number,
      gridSize: 6,
      arrows: [
        _arrow('a', ArrowDirection.up, [
          [3, 0],
          [4, 0],
        ]),
        _arrow('b', ArrowDirection.up, [
          [3, 2],
          [4, 2],
        ]),
        _arrow('c', ArrowDirection.up, [
          [3, 4],
          [4, 4],
        ]),
      ],
      orphanDots: const [
        OrphanDot(row: 1, col: 0, type: OrphanDotType.up),
        OrphanDot(row: 1, col: 2, type: OrphanDotType.up),
      ],
      patternName: 'test',
      difficulty: Difficulty.easy,
    );

GameState _state(LevelModel level) => GameState(
      level: level,
      onLevelComplete: () {},
      onGameOver: () {},
      onLifeLost: () {},
      onDeadlock: () {},
    );

/// Taps [id] and finishes its exit animation, like the board does.
void _clear(GameState gs, String id) {
  expect(gs.tapArrow(id), TapResult.exited);
  gs.handleArrowExitCompleted(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameState save and resume', () {
    test('a fresh board has nothing worth saving', () {
      expect(_state(_level()).hasSavableProgress, isFalse);
    });

    test('left arrows and used dots come back after a restore', () {
      final level = _level();
      final before = _state(level);
      _clear(before, 'a');
      expect(before.hasSavableProgress, isTrue);

      final session = LevelSession.tryFromJson(
        jsonDecode(jsonEncode(before.snapshot().toJson())),
      )!;

      final after = _state(level);
      expect(after.restoreSession(session), isTrue);
      expect(after.arrows.map((a) => a.id), ['b', 'c']);
      expect(after.orphanDots.keys, ['1,2']);
      expect(after.movesUsed, 1);
      expect(after.lives, before.lives);
    });

    test('lives, lost hearts and boosters survive', () {
      final level = _level();
      final before = _state(level);
      _clear(before, 'a');
      before.consumePowerUp(PowerUpType.hint);

      final after = _state(level);
      expect(after.restoreSession(before.snapshot()), isTrue);
      expect(after.powerUpCount(PowerUpType.hint),
          before.powerUpCount(PowerUpType.hint));
      expect(after.powerUpsUsed, 1);
      expect(after.hintsUsed, 1);
    });

    test('an arrow still sliding out counts as gone', () {
      final level = _level();
      final before = _state(level);
      expect(before.tapArrow('a'), TapResult.exited);
      expect(before.snapshot().arrowIds, ['b', 'c']);
      expect(before.snapshot().dotKeys, ['1,2']);
    });

    test('a finished board is not saved', () {
      final level = _level();
      final gs = _state(level);
      _clear(gs, 'a');
      _clear(gs, 'b');
      _clear(gs, 'c');
      expect(gs.isComplete, isTrue);
      expect(gs.hasSavableProgress, isFalse);
    });

    test('a session from another level or board is refused', () {
      final level = _level();
      final before = _state(level);
      _clear(before, 'a');
      final session = before.snapshot();

      final otherLevel = _state(_level(number: 13));
      expect(otherLevel.restoreSession(session), isFalse);
      expect(otherLevel.arrows, hasLength(3));

      // Same number, different board (as after a rebuilt levels.bin).
      final changed = LevelModel(
        levelNumber: level.levelNumber,
        gridSize: level.gridSize,
        arrows: [
          ...level.arrows.take(2),
          _arrow('c', ArrowDirection.up, [
            [2, 4],
            [3, 4],
          ]),
        ],
        orphanDots: level.orphanDots,
        patternName: 'test',
        difficulty: Difficulty.easy,
      );
      final rebuilt = _state(changed);
      expect(rebuilt.restoreSession(session), isFalse);
      expect(rebuilt.arrows, hasLength(3));
    });

    test('garbage is not a session', () {
      expect(LevelSession.tryFromJson('nope'), isNull);
      expect(LevelSession.tryFromJson({'level': 1}), isNull);
    });
  });

  group('ProgressRepository level session', () {
    late ProgressRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = ProgressRepository(await SharedPreferences.getInstance());
    });

    test('saves, loads for the same level only, and clears', () {
      final gs = _state(_level());
      _clear(gs, 'a');
      repo.saveLevelSession(gs.snapshot());

      expect(repo.loadLevelSession(13), isNull);
      final loaded = repo.loadLevelSession(12)!;
      expect(loaded.arrowIds, ['b', 'c']);

      repo.clearLevelSession();
      expect(repo.loadLevelSession(12), isNull);
    });

    test('a corrupt entry is ignored', () async {
      SharedPreferences.setMockInitialValues({'levelSession': '{oops'});
      final bad = ProgressRepository(await SharedPreferences.getInstance());
      expect(bad.loadLevelSession(12), isNull);
    });
  });
}

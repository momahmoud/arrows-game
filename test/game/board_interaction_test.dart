import 'dart:io';

import 'package:arrow_escape/core/audio_manager.dart';
import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/models/arrow.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:arrow_escape/game/arrow_puzzle_game.dart';
import 'package:arrow_escape/game/board_layout.dart';
import 'package:arrow_escape/game/components/arrow_component.dart';
import 'package:arrow_escape/game/game_state.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Taps through the real Flame event dispatch.
void main() {
  final file = File('assets/levels.bin');
  final decoder = file.existsSync()
      ? LevelBinaryDecoder.fromBytes(file.readAsBytesSync())
      : null;
  setUpAll(() => AudioManager.instance.setSoundEnabled(false));

  for (final n in [4, 213, 1000]) {
    for (final viewport in const [Size(366, 600), Size(744, 880)]) {
      testWidgets(
          'level $n ${viewport.width.toInt()}w: a tap near a later-drawn '
          'neighbour goes to the arrow under the finger', (tester) async {
        final level = decoder!.decodeLevelByNumber(n)!;
        final pairs = _overlapPairs(level).take(6).toList();
        expect(pairs, isNotEmpty);
        for (final pair in pairs) {
          final h = await _mount(tester, level, viewport);
          final cell = h.game.gridComponent!.cellSize;
          final at = h.origin +
              Offset((pair.cell[1] + 0.5 + pair.dc * 0.4) * cell,
                  (pair.cell[0] + 0.5 + pair.dr * 0.4) * cell);
          await tester.tapAt(at);
          await tester.pump(const Duration(milliseconds: 16));
          expect(h.state(pair.owner), isNot(ArrowState.idle),
              reason: 'level $n: tap in ${pair.owner} cell ${pair.cell}');
          expect(h.state(pair.neighbour), ArrowState.idle,
              reason: 'level $n: ${pair.neighbour} must not take the tap');
          await _settle(tester);
        }
      }, skip: decoder == null);
    }
  }

  testWidgets('resizing keeps geometry and touch targets consistent',
      (tester) async {
    final level = decoder!.decodeLevelByNumber(213)!;
    final h = await _mount(tester, level, const Size(366, 600));
    for (final size in const [
      Size(744, 880),
      Size(1000, 520),
      Size(296, 440)
    ]) {
      tester.view.physicalSize = size;
      await tester.pump(const Duration(milliseconds: 16));
      final grid = h.game.gridComponent!;
      final expected = BoardLayout.forLevel(level, size);
      expect(grid.cellSize, closeTo(expected.cellSize, 1e-9));
      // Vector2 stores float32.
      expect(grid.position.x, closeTo(expected.origin.dx, 1e-3));
      expect(grid.position.y, closeTo(expected.origin.dy, 1e-3));
      for (final c in grid.children.whereType<ArrowComponent>()) {
        expect(c.cellSize, closeTo(expected.cellSize, 1e-9));
      }
    }
    // A tap after the last resize still lands on the arrow under it.
    final pair = _overlapPairs(level).first;
    final cell = h.game.gridComponent!.cellSize;
    final origin = h.game.gridComponent!.position;
    await tester.tapAt(Offset(
        origin.x + (pair.cell[1] + 0.5 + pair.dc * 0.4) * cell,
        origin.y + (pair.cell[0] + 0.5 + pair.dr * 0.4) * cell));
    await tester.pump(const Duration(milliseconds: 16));
    expect(h.state(pair.owner), isNot(ArrowState.idle));
    expect(h.state(pair.neighbour), ArrowState.idle);
    await _settle(tester);
  }, skip: decoder == null);
}

class _Pair {
  _Pair(this.owner, this.neighbour, this.cell, this.dr, this.dc);
  final String owner, neighbour;
  final List<int> cell;
  final int dr, dc;
}

/// Cells of an arrow whose side neighbour belongs to an arrow drawn later,
/// i.e. on top of it.
Iterable<_Pair> _overlapPairs(LevelModel level) sync* {
  final owner = <String, int>{};
  for (var i = 0; i < level.arrows.length; i++) {
    for (final pt in level.arrows[i].path) {
      owner['${pt[0]},${pt[1]}'] = i;
    }
  }
  for (var i = 0; i < level.arrows.length; i++) {
    final a = level.arrows[i];
    for (final pt in a.path) {
      for (final (dr, dc) in const [(0, 1), (1, 0), (0, -1), (-1, 0)]) {
        final j = owner['${pt[0] + dr},${pt[1] + dc}'];
        if (j != null &&
            j > i &&
            level.arrows[j].colorGroup == null &&
            a.colorGroup == null) {
          yield _Pair(a.id, level.arrows[j].id, pt, dr, dc);
          break;
        }
      }
    }
  }
}

class _Harness {
  _Harness(this.game, this.gameState);
  final ArrowPuzzleGame game;
  final GameState gameState;
  Offset get origin =>
      Offset(game.gridComponent!.position.x, game.gridComponent!.position.y);
  ArrowState state(String id) =>
      gameState.arrows.firstWhere((a) => a.id == id).state;
}

Future<_Harness> _mount(
    WidgetTester tester, LevelModel level, Size viewport) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final state = GameState(
    level: level,
    onLevelComplete: () {},
    onGameOver: () {},
    onLifeLost: () {},
    onDeadlock: () {},
  );
  final game = ArrowPuzzleGame(
    level: level,
    gameState: state,
    onLevelComplete: () {},
    onGameOver: () {},
    onLifeLost: () {},
  );
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: GameWidget(key: UniqueKey(), game: game),
  ));
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return _Harness(game, state);
}

/// Lets block resets and exit animations finish so no timers stay pending.
Future<void> _settle(WidgetTester tester) async {
  final frames =
      (AppConstants.arrowShakeDuration.inMilliseconds / 16).ceil() + 120;
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:arrow_escape/core/app_colors.dart';
import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:arrow_escape/game/arrow_puzzle_game.dart';
import 'package:arrow_escape/game/game_state.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Renders packaged levels through the real Flame components.
///
/// Always checks that boards mount and paint without errors. Set
/// BOARD_SNAPSHOT_DIR to also write each frame as a PNG for manual review.
/// BOARD_SNAPSHOT_LEVELS (e.g. `1,402,570`) and BOARD_SNAPSHOT_VIEWPORTS
/// (e.g. `phone`) narrow the set; BOARD_SNAPSHOT_THEMES=light skips dark.
/// BOARD_SNAPSHOT_BIN renders another level file, such as a development
/// candidate under build/, with the same settings.
void main() {
  final env = Platform.environment;
  final outDir = env['BOARD_SNAPSHOT_DIR'];
  final file = File(env['BOARD_SNAPSHOT_BIN'] ?? 'assets/levels.bin');
  final decoder = file.existsSync()
      ? LevelBinaryDecoder.fromBytes(file.readAsBytesSync())
      : null;

  const allViewports = <String, Size>{
    'phone_small': Size(296, 440),
    'phone': Size(366, 600),
    'tablet': Size(744, 880),
    'landscape': Size(1000, 520),
  };
  final viewportNames = env['BOARD_SNAPSHOT_VIEWPORTS']?.split(',').toSet();
  final viewports = {
    for (final e in allViewports.entries)
      if (viewportNames == null || viewportNames.contains(e.key))
        e.key: e.value,
  };
  final levels = env['BOARD_SNAPSHOT_LEVELS']
          ?.split(',')
          .map((s) => int.parse(s.trim()))
          .toList() ??
      const [1, 4, 7, 14, 213, 437, 1000];
  final themes =
      env['BOARD_SNAPSHOT_THEMES'] == 'light' ? [false] : [false, true];

  for (final dark in themes) {
    for (final n in levels) {
      for (final entry in viewports.entries) {
        final name = 'L${n}_${entry.key}_${dark ? 'dark' : 'light'}';
        testWidgets('renders $name', (tester) async {
          final level = decoder!.decodeLevelByNumber(n)!;
          await _render(tester, level, entry.value, dark, outDir, name);
        }, skip: decoder == null);
      }
    }
  }

  // Held (not released) on the middle of the level's longest arrow.
  for (final n in [437, 1000]) {
    testWidgets('renders L${n}_pressed_long', (tester) async {
      final level = decoder!.decodeLevelByNumber(n)!;
      final game =
          await _render(tester, level, const Size(366, 600), false, null, '');
      final longest =
          level.arrows.reduce((a, b) => b.path.length > a.path.length ? b : a);
      final mid = longest.path[longest.path.length ~/ 2];
      final grid = game.gridComponent!;
      final gesture = await tester.startGesture(Offset(
          grid.position.x + (mid[1] + 0.5) * grid.cellSize,
          grid.position.y + (mid[0] + 0.5) * grid.cellSize));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await _capture(tester, outDir, 'L${n}_pressed_long');
      await gesture.cancel();
      await tester.pump(const Duration(milliseconds: 16));
    }, skip: decoder == null);
  }
}

final _boundaryKey = GlobalKey();

Future<void> _capture(WidgetTester tester, String? outDir, String name) async {
  if (outDir == null) return;
  final boundary =
      _boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(outDir).createSync(recursive: true);
    File('$outDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<ArrowPuzzleGame> _render(WidgetTester tester, LevelModel level,
    Size viewport, bool dark, String? outDir, String name) async {
  AppColors.isDark = dark;
  addTearDown(() => AppColors.isDark = false);
  tester.view.physicalSize = viewport * 2;
  tester.view.devicePixelRatio = 2;
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
    child: RepaintBoundary(
      key: _boundaryKey,
      child: ColoredBox(
        color: AppColors.background,
        child: GameWidget(game: game),
      ),
    ),
  ));
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(game.gridComponent, isNotNull);
  expect(game.gridComponent!.isMounted, isTrue);
  expect(tester.takeException(), isNull);
  if (name.isNotEmpty) await _capture(tester, outDir, name);
  return game;
}

import 'dart:io';

import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/models/arrow.dart';
import 'package:arrow_escape/game/components/arrow_hit_resolver.dart';
import 'package:arrow_escape/game/components/arrow_visual_config.dart';
import 'package:flutter_test/flutter_test.dart';

ArrowModel _arrow(String id, List<List<int>> path,
        {ArrowState state = ArrowState.idle}) =>
    ArrowModel(
      id: id,
      row: path.first[0],
      col: path.first[1],
      path: path,
      direction: ArrowDirection.right,
      state: state,
    );

ArrowHitResolver _resolver(List<ArrowModel> arrows,
        {int grid = 6, double cell = 40}) =>
    ArrowHitResolver(
      gridSize: grid,
      cellSize: cell,
      slop: ArrowVisualConfig.hitSlop(cell),
      arrows: arrows,
    );

void main() {
  const cell = 40.0;
  final slop = ArrowVisualConfig.hitSlop(cell);

  group('ArrowHitResolver', () {
    test('an occupied cell always belongs to its own arrow', () {
      // b is listed (and drawn) after a, so it used to win the overlap.
      final a = _arrow('a', [
        [2, 1],
      ]);
      final b = _arrow('b', [
        [2, 2],
      ]);
      final r = _resolver([a, b]);
      // Inside a's cell, 0.1 cell from b's edge: within b's old slop.
      expect(r.arrowAt(const Offset(1.9 * cell, 2.5 * cell)), 'a');
      expect(r.arrowAt(const Offset(2.1 * cell, 2.5 * cell)), 'b');
      // Order of the arrow list does not matter.
      final reversed = _resolver([b, a]);
      expect(reversed.arrowAt(const Offset(1.9 * cell, 2.5 * cell)), 'a');
      expect(reversed.arrowAt(const Offset(2.1 * cell, 2.5 * cell)), 'b');
    });

    test('empty cells fall back to the nearest arrow within slop', () {
      final a = _arrow('a', [
        [2, 0],
      ]);
      final b = _arrow('b', [
        [2, 3],
      ]);
      final r = _resolver([a, b]);
      // Cells (2,1) and (2,2) are empty.
      expect(r.arrowAt(Offset(cell + slop * 0.5, 2.5 * cell)), 'a');
      expect(r.arrowAt(Offset(3 * cell - slop * 0.5, 2.5 * cell)), 'b');
      expect(r.arrowAt(const Offset(2 * cell, 2.5 * cell)), isNull);
    });

    test('touches beyond the slop hit nothing', () {
      final r = _resolver([
        _arrow('a', [
          [2, 2],
        ]),
      ]);
      expect(r.arrowAt(Offset(3 * cell + slop + 0.5, 2.5 * cell)), isNull);
      expect(r.arrowAt(Offset(3 * cell + slop - 0.5, 2.5 * cell)), 'a');
    });

    test('edge arrows keep their slop outside the board', () {
      final r = _resolver([
        _arrow('edge', [
          [0, 0],
        ]),
      ]);
      expect(r.arrowAt(Offset(-slop * 0.8, -slop * 0.8)), 'edge');
      expect(r.arrowAt(Offset(-slop - 1, 0.5 * cell)), isNull);
    });

    test('sliding arrows release their cells', () {
      final a = _arrow(
          'a',
          [
            [2, 1],
          ],
          state: ArrowState.sliding);
      final b = _arrow('b', [
        [2, 2],
      ]);
      final r = _resolver([a, b]);
      expect(r.arrowAt(const Offset(1.5 * cell, 2.5 * cell)), isNull);
      expect(r.arrowAt(Offset(2 * cell - slop * 0.5, 2.5 * cell)), 'b');
    });

    test('ties go to the first cell in row-major order', () {
      final left = _arrow('left', [
        [2, 1],
      ]);
      final above = _arrow('above', [
        [1, 2],
      ]);
      // Empty cell (2,2), near its top-left corner: equally close to both.
      final tie = Offset(2 * cell + slop * 0.5, 2 * cell + slop * 0.5);
      expect(_resolver([left, above]).arrowAt(tie), 'above');
      expect(_resolver([above, left]).arrowAt(tie), 'above');
    });

    test('results do not depend on the cell size', () {
      final arrows = [
        _arrow('a', [
          [1, 1],
          [1, 2],
          [2, 2],
        ]),
        _arrow('b', [
          [2, 3],
          [3, 3],
        ]),
      ];
      const probes = [
        Offset(2.95, 1.5),
        Offset(3.05, 2.5),
        Offset(2.5, 2.98),
        Offset(1.2, 2.2),
        Offset(4.2, 3.5),
      ];
      final small = _resolver(arrows, cell: 7);
      final large = _resolver(arrows, cell: 90);
      for (final p in probes) {
        expect(small.arrowAt(p * 7), large.arrowAt(p * 90), reason: '$p');
      }
    });
  });

  final file = File('assets/levels.bin');
  test('every packaged arrow cell resolves to its owner', () {
    final decoder = LevelBinaryDecoder.fromBytes(file.readAsBytesSync());
    // Inner points cover the whole cell except a hairline at the border.
    const inner = [-0.45, 0.0, 0.45];
    var probes = 0;
    for (final n in [1, 4, 7, 14, 100, 213, 395, 437, 777, 1000]) {
      final level = decoder.decodeLevelByNumber(n)!;
      final r = ArrowHitResolver(
        gridSize: level.gridSize,
        cellSize: cell,
        slop: slop,
        arrows: level.arrows,
      );
      for (final arrow in level.arrows) {
        for (final pt in arrow.path) {
          for (final dy in inner) {
            for (final dx in inner) {
              final p =
                  Offset((pt[1] + 0.5 + dx) * cell, (pt[0] + 0.5 + dy) * cell);
              expect(r.arrowAt(p), arrow.id, reason: 'level $n ${arrow.id}');
              probes++;
            }
          }
        }
      }
    }
    expect(probes, greaterThan(10000));
  }, skip: !file.existsSync());
}

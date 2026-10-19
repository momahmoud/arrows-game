import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/game/board_layout.dart';
import 'package:flutter_test/flutter_test.dart';

/// Game viewports, i.e. the area left for the board under the HUD.
const _viewports = <String, Size>{
  'small phone': Size(296, 440),
  'phone': Size(366, 600),
  'tall phone': Size(406, 700),
  'tablet': Size(744, 880),
  'landscape phone': Size(780, 300),
  'landscape tablet': Size(1000, 520),
};

void main() {
  test('used cells are centred and fit with a margin', () {
    final layout = BoardLayout.fit(
        const Rect.fromLTRB(3, 5, 13, 9), 20, const Size(400, 300));
    final r = layout.contentRect;
    expect(r.center.dx, closeTo(200, 1e-6));
    expect(r.center.dy, closeTo(150, 1e-6));
    expect(layout.gridPixelSize, closeTo(20 * layout.cellSize, 1e-9));
  });

  test('cell size stays fixed until the board would not fit', () {
    const viewport = Size(360, 600);
    final small = BoardLayout.fit(const Rect.fromLTWH(0, 0, 4, 4), 4, viewport);
    final medium =
        BoardLayout.fit(const Rect.fromLTWH(0, 0, 8, 8), 8, viewport);
    final big =
        BoardLayout.fit(const Rect.fromLTWH(0, 0, 30, 30), 30, viewport);
    expect(small.cellSize, medium.cellSize);
    expect(big.cellSize, lessThan(medium.cellSize));
  });

  test('degenerate viewports do not produce invalid sizes', () {
    final layout =
        BoardLayout.fit(const Rect.fromLTWH(0, 0, 10, 10), 10, Size.zero);
    expect(layout.cellSize, greaterThan(0));
    expect(layout.cellSize.isFinite, isTrue);
  });

  final file = File('assets/levels.bin');
  test('every packaged level fits, centred, on every viewport', () {
    final decoder = LevelBinaryDecoder.fromBytes(file.readAsBytesSync());
    final minCell = <String, double>{};
    final minCellLevel = <String, int>{};
    for (var n = 1; n <= AppConstants.totalLevels; n++) {
      final level = decoder.decodeLevelByNumber(n)!;
      for (final entry in _viewports.entries) {
        final v = entry.value;
        final layout = BoardLayout.forLevel(level, v);
        final r = layout.contentRect;
        final why = 'level $n on ${entry.key}';
        expect(r.left, greaterThanOrEqualTo(-1e-6), reason: why);
        expect(r.top, greaterThanOrEqualTo(-1e-6), reason: why);
        expect(r.right, lessThanOrEqualTo(v.width + 1e-6), reason: why);
        expect(r.bottom, lessThanOrEqualTo(v.height + 1e-6), reason: why);
        expect(r.center.dx, closeTo(v.width / 2, 1e-6), reason: why);
        expect(r.center.dy, closeTo(v.height / 2, 1e-6), reason: why);
        // The limiting side keeps the spacing margin.
        final used = max(r.width / v.width, r.height / v.height);
        expect(used, lessThanOrEqualTo(AppConstants.boardCellSpacing + 1e-9),
            reason: why);
        if (layout.cellSize < (minCell[entry.key] ?? double.infinity)) {
          minCell[entry.key] = layout.cellSize;
          minCellLevel[entry.key] = n;
        }
      }
    }
    for (final k in _viewports.keys) {
      // ignore: avoid_print
      print('smallest cell on $k: '
          '${minCell[k]!.toStringAsFixed(2)} px (level ${minCellLevel[k]})');
      expect(minCell[k], greaterThan(4), reason: k);
    }
  }, skip: !file.existsSync());
}

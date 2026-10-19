import 'package:arrow_escape/game/components/arrow_visual_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cells = [5.0, 7.0, 12.0, 24.0, 48.0, 90.0];

  test('arrowheads stay inside their cell and wider than the shaft', () {
    for (final cell in cells) {
      final half = ArrowVisualConfig.headHalfWidth(cell) +
          ArrowVisualConfig.headRounding(cell) / 2;
      // Heads of parallel neighbours, one cell apart, never touch.
      expect(half, lessThan(cell / 2), reason: 'cell $cell');
      expect(ArrowVisualConfig.headLength(cell), lessThan(cell / 2 + 0.01),
          reason: 'cell $cell');
      // The head reads as a head, not a thicker stretch of shaft.
      expect(half * 2, greaterThan(ArrowVisualConfig.shaftWidth(cell) * 2.2),
          reason: 'cell $cell');
      expect(ArrowVisualConfig.shaftWidth(cell),
          greaterThanOrEqualTo(ArrowVisualConfig.minShaftWidth));
    }
  });

  test('stroke proportions are the same at every normal cell size', () {
    final ratio = ArrowVisualConfig.shaftWidth(24) / 24;
    for (final cell in [12.0, 48.0, 90.0]) {
      expect(ArrowVisualConfig.shaftWidth(cell) / cell, closeTo(ratio, 1e-9));
    }
  });

  test('press and bump feedback never move a point beyond the cap', () {
    const cap = ArrowVisualConfig.maxFeedbackShiftRatio;
    for (final cell in cells) {
      for (final cellsReach in [0.4, 1.0, 2.0, 6.0, 20.0, 40.0]) {
        final reach = cell * cellsReach;
        final scale = ArrowVisualConfig.pressedScaleFor(reach, cell);
        final angle = ArrowVisualConfig.blockShakeAngleFor(reach, cell);
        expect((1 - scale) * reach, lessThanOrEqualTo(cell * cap + 1e-9));
        expect(angle * reach, lessThanOrEqualTo(cell * cap + 1e-9));
        expect(scale, greaterThanOrEqualTo(ArrowVisualConfig.pressedScale));
        expect(angle, lessThanOrEqualTo(ArrowVisualConfig.blockShakeAngle));
      }
    }
  });

  test('short arrows keep the full press and bump feedback', () {
    const cell = 30.0;
    expect(ArrowVisualConfig.pressedScaleFor(cell * 0.5, cell),
        ArrowVisualConfig.pressedScale);
    expect(ArrowVisualConfig.blockShakeAngleFor(cell * 0.5, cell),
        ArrowVisualConfig.blockShakeAngle);
  });

  test('touch slop and lock rattle scale with the cell', () {
    expect(ArrowVisualConfig.hitSlop(30), closeTo(10, 1e-9));
    expect(ArrowVisualConfig.hitSlop(60), closeTo(20, 1e-9));
    expect(ArrowVisualConfig.hitSlop(30), lessThan(15));
    expect(ArrowVisualConfig.lockRattle(6), ArrowVisualConfig.minLockRattle);
    expect(ArrowVisualConfig.lockRattle(20), closeTo(3, 1e-9));
    expect(ArrowVisualConfig.lockRattle(80), ArrowVisualConfig.maxLockRattle);
  });
}

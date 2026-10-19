import 'package:arrow_escape/data/models/level.dart';

/// Occupancy of the mask outline and tip cells, used to prefer layouts where
/// distinctive silhouette features stay occupied.
class SilhouetteMetrics {
  const SilhouetteMetrics({
    required this.maskCells,
    required this.outlineCells,
    required this.tipCells,
    required this.coveredOutline,
    required this.coveredTips,
    required this.coveredMask,
  });

  final int maskCells;
  final int outlineCells;
  final int tipCells;
  final int coveredOutline;
  final int coveredTips;
  final int coveredMask;

  double get outlineCover =>
      outlineCells == 0 ? 0 : coveredOutline / outlineCells;

  double get tipCover => tipCells == 0 ? 0 : coveredTips / tipCells;

  double get fill => maskCells == 0 ? 0 : coveredMask / maskCells;

  Map<String, Object> toJson() => {
        'maskCells': maskCells,
        'outlineCells': outlineCells,
        'tipCells': tipCells,
        'coveredOutline': coveredOutline,
        'coveredTips': coveredTips,
        'outlineCover': double.parse(outlineCover.toStringAsFixed(3)),
        'tipCover': double.parse(tipCover.toStringAsFixed(3)),
        'fill': double.parse(fill.toStringAsFixed(3)),
      };

  /// Outline = mask cell with a 4-neighbour outside the mask. Tips = outline
  /// cells with at most two mask neighbours (protrusions).
  static SilhouetteMetrics of(LevelModel level) {
    final gs = level.gridSize;
    final mask = <int>{};
    for (final key in level.mask) {
      final p = key.split(',');
      mask.add(int.parse(p[0]) * gs + int.parse(p[1]));
    }
    final occupied = <int>{};
    for (final a in level.arrows) {
      for (final cell in a.path) {
        occupied.add(cell[0] * gs + cell[1]);
      }
    }
    for (final d in level.orphanDots) {
      occupied.add(d.row * gs + d.col);
    }

    const d4 = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1]
    ];
    var outline = 0, tips = 0, coveredOutline = 0, coveredTips = 0;
    for (final f in mask) {
      final r = f ~/ gs, c = f % gs;
      var neighbours = 0;
      var outside = false;
      for (final d in d4) {
        final nr = r + d[0], nc = c + d[1];
        final nf = nr * gs + nc;
        if (nr < 0 || nc < 0 || nr >= gs || nc >= gs || !mask.contains(nf)) {
          outside = true;
        } else {
          neighbours++;
        }
      }
      if (!outside) continue;
      outline++;
      final covered = occupied.contains(f);
      if (covered) coveredOutline++;
      if (neighbours <= 2) {
        tips++;
        if (covered) coveredTips++;
      }
    }
    return SilhouetteMetrics(
      maskCells: mask.length,
      outlineCells: outline,
      tipCells: tips,
      coveredOutline: coveredOutline,
      coveredTips: coveredTips,
      coveredMask: occupied.intersection(mask).length,
    );
  }
}

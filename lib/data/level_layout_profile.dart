import 'models/arrow.dart';

/// Lightweight reading of a board, used to reject layouts that are crowded
/// without a plan. Not stored in the level binary — the generator consults
/// it while a level is still being accepted.
class LevelLayoutProfile {
  final int arrowCount;
  final int turnCount;
  final int pathLength;
  final int openingMoves;
  final int blockingCount;
  final int dependencyDepth;
  final int dependencyEdgeCount;
  final double participationRatio;
  final int colorGroupCount;
  final double densityScore;
  final String shapeType;

  const LevelLayoutProfile({
    required this.arrowCount,
    required this.turnCount,
    required this.pathLength,
    required this.openingMoves,
    required this.blockingCount,
    required this.dependencyDepth,
    required this.dependencyEdgeCount,
    required this.participationRatio,
    required this.colorGroupCount,
    required this.densityScore,
    required this.shapeType,
  });

  /// Share of arrows that are only one or two cells long.
  double stubRatio(int stubCount) =>
      arrowCount == 0 ? 1 : stubCount / arrowCount;

  /// Every arrow can leave immediately, so there is nothing to plan.
  bool get isImmediatelySolved => arrowCount >= 4 && openingMoves >= arrowCount;

  factory LevelLayoutProfile.analyze({
    required List<ArrowModel> arrows,
    required int gridSize,
    required int maskCells,
    required String shapeType,
  }) {
    var turns = 0;
    var cells = 0;
    final groups = <int>{};
    final occupied = <int, int>{};

    for (var i = 0; i < arrows.length; i++) {
      final arrow = arrows[i];
      cells += arrow.path.length;
      final group = arrow.colorGroup;
      if (group != null) groups.add(group);
      for (final pt in arrow.path) {
        occupied[pt[0] * 1000 + pt[1]] = i;
      }
      for (var s = 2; s < arrow.path.length; s++) {
        final dr1 = arrow.path[s - 1][0] - arrow.path[s - 2][0];
        final dc1 = arrow.path[s - 1][1] - arrow.path[s - 2][1];
        final dr2 = arrow.path[s][0] - arrow.path[s - 1][0];
        final dc2 = arrow.path[s][1] - arrow.path[s - 1][1];
        if (dr1 != dr2 || dc1 != dc2) turns++;
      }
    }

    final blockedBy = List<int>.filled(arrows.length, -1);
    final blocks = List<List<int>>.generate(arrows.length, (_) => []);
    var opening = 0;
    var blocking = 0;

    for (var i = 0; i < arrows.length; i++) {
      final dir = arrows[i].direction.delta;
      var r = arrows[i].row + dir[0];
      var c = arrows[i].col + dir[1];
      var blocker = -1;
      while (r >= 0 && r < gridSize && c >= 0 && c < gridSize) {
        final id = occupied[r * 1000 + c];
        if (id != null && id != i) {
          blocker = id;
          break;
        }
        r += dir[0];
        c += dir[1];
      }
      blockedBy[i] = blocker;
      if (blocker == -1) {
        opening++;
      } else {
        blocking++;
        blocks[blocker].add(i);
      }
    }

    var participating = 0;
    for (var i = 0; i < arrows.length; i++) {
      if (blockedBy[i] >= 0 || blocks[i].isNotEmpty) participating++;
    }
    final participation =
        arrows.isEmpty ? 0.0 : participating / arrows.length;

    final depthMemo = List<int>.filled(arrows.length, 0);
    final seen = List<bool>.filled(arrows.length, false);

    int depthAt(int i) {
      if (seen[i]) return depthMemo[i];
      seen[i] = true;
      final blocker = blockedBy[i];
      final depth = blocker < 0 ? 1 : depthAt(blocker) + 1;
      depthMemo[i] = depth;
      return depth;
    }

    var depth = 0;
    for (var i = 0; i < arrows.length; i++) {
      final d = depthAt(i);
      if (d > depth) depth = d;
    }

    final density = maskCells == 0 ? 0.0 : cells / maskCells;
    final uniqueEdges = <int>{};
    for (var i = 0; i < arrows.length; i++) {
      final b = blockedBy[i];
      if (b >= 0) uniqueEdges.add(b * 10000 + i);
    }
    return LevelLayoutProfile(
      arrowCount: arrows.length,
      turnCount: turns,
      pathLength: cells,
      openingMoves: opening,
      blockingCount: blocking,
      dependencyDepth: depth,
      dependencyEdgeCount: uniqueEdges.length,
      participationRatio: participation,
      colorGroupCount: groups.length,
      densityScore: density,
      shapeType: shapeType,
    );
  }
}

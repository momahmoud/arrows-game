import 'package:arrow_escape/data/level_generator/solver.dart';
import 'package:arrow_escape/data/models/arrow.dart';
import 'package:arrow_escape/data/models/level.dart';

/// Text format for hand-authored candidate boards.
///
/// One character per cell:
/// * `' '` outside the playable mask
/// * `.` empty mask cell
/// * `A`–`Z` an arrow head, `a`–`z` that arrow's body; the head points away
///   from its single body neighbour
/// * `^ v < >` directional deflector dots
///
/// The drawing is centred in a `gridSize × gridSize` grid, so exits still run
/// to the real grid edge exactly as in the game.
class CandidateBoard {
  CandidateBoard._();

  static LevelModel parse({
    required int levelNumber,
    required int gridSize,
    required List<String> rows,
    required MaskShape maskShape,
    required Difficulty difficulty,
    required String patternName,
    List<String> pairs = const [],
  }) {
    final height = rows.length;
    final width = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    if (height > gridSize || width > gridSize) {
      throw ArgumentError('L$levelNumber: ${width}x$height board exceeds '
          'grid $gridSize');
    }
    final top = (gridSize - height) ~/ 2;
    final left = (gridSize - width) ~/ 2;

    final mask = <String>{};
    final dots = <OrphanDot>[];
    final heads = <String, List<int>>{};
    final bodies = <String, Set<int>>{};
    for (var r = 0; r < height; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        final ch = rows[r][c];
        if (ch == ' ') continue;
        final gr = r + top, gc = c + left;
        mask.add('$gr,$gc');
        final dot = _dotTypes[ch];
        if (dot != null) {
          dots.add(OrphanDot(row: gr, col: gc, type: dot));
        } else if (_isUpper(ch)) {
          if (ch == 'V') {
            throw ArgumentError('L$levelNumber: V is reserved (v is a dot)');
          }
          if (heads.containsKey(ch)) {
            throw ArgumentError('L$levelNumber: arrow $ch has two heads');
          }
          heads[ch] = [gr, gc];
        } else if (_isLower(ch)) {
          bodies
              .putIfAbsent(ch.toUpperCase(), () => {})
              .add(gr * gridSize + gc);
        } else if (ch != '.') {
          throw ArgumentError('L$levelNumber: unknown cell "$ch"');
        }
      }
    }
    for (final letter in bodies.keys) {
      if (!heads.containsKey(letter)) {
        throw ArgumentError('L$levelNumber: arrow $letter has no head');
      }
    }

    final letters = heads.keys.toList()..sort();
    final groupOf = <String, int>{};
    for (var g = 0; g < pairs.length; g++) {
      for (final ch in pairs[g].split('')) {
        if (!heads.containsKey(ch) || groupOf.containsKey(ch)) {
          throw ArgumentError('L$levelNumber: bad pair ${pairs[g]}');
        }
        groupOf[ch] = g;
      }
    }

    final arrows = <ArrowModel>[];
    for (var i = 0; i < letters.length; i++) {
      final letter = letters[i];
      final path = _walk(
          letter, heads[letter]!, bodies[letter] ?? {}, gridSize, levelNumber);
      final dr = path[0][0] - path[1][0], dc = path[0][1] - path[1][1];
      arrows.add(ArrowModel(
        id: 'a_${levelNumber}_$i',
        row: path[0][0],
        col: path[0][1],
        direction: _dirFor(dr, dc),
        colorGroup: groupOf[letter],
        mechanic: groupOf.containsKey(letter)
            ? SnakeMechanic.colorLock
            : SnakeMechanic.standard,
        path: path,
      ));
    }

    return LevelModel(
      levelNumber: levelNumber,
      gridSize: gridSize,
      arrows: arrows,
      patternName: patternName,
      difficulty: difficulty,
      maskShape: maskShape,
      mask: mask,
      orphanDots: dots,
    );
  }

  /// Stores a DFS-found order. One ID per pair, so the order replays with
  /// [CampaignAudit.replayStoredSolution].
  static LevelModel withSolution(LevelModel level, {int stateLimit = 400000}) {
    final outcome = LevelSolver.attempt(level, stateLimit);
    if (!outcome.isSolved) {
      throw StateError('L${level.levelNumber}: solver ${outcome.status.name}');
    }
    return level.copyWith(solutionOrder: outcome.solution);
  }

  /// Renders [level] in the same format [parse] reads, cropped to its content.
  /// Arrow letters follow arrow order (wrapping after 25; `v` is skipped).
  static List<String> render(LevelModel level) {
    final gs = level.gridSize;
    final grid = List.generate(gs, (_) => List.filled(gs, ' '));
    for (final key in level.mask) {
      final p = key.split(',');
      grid[int.parse(p[0])][int.parse(p[1])] = '.';
    }
    const alphabet = 'abcdefghijklmnopqrstuwxyz';
    for (var i = 0; i < level.arrows.length; i++) {
      final a = level.arrows[i];
      final ch = alphabet[i % alphabet.length];
      for (var s = 0; s < a.path.length; s++) {
        grid[a.path[s][0]][a.path[s][1]] = s == 0 ? ch.toUpperCase() : ch;
      }
    }
    for (final d in level.orphanDots) {
      grid[d.row][d.col] = switch (d.type) {
        OrphanDotType.up => '^',
        OrphanDotType.down => 'v',
        OrphanDotType.left => '<',
        OrphanDotType.right => '>',
        OrphanDotType.neutral => '+',
      };
    }
    var minR = gs, maxR = -1, minC = gs, maxC = -1;
    for (var r = 0; r < gs; r++) {
      for (var c = 0; c < gs; c++) {
        if (grid[r][c] == ' ') continue;
        if (r < minR) minR = r;
        if (r > maxR) maxR = r;
        if (c < minC) minC = c;
        if (c > maxC) maxC = c;
      }
    }
    if (maxR < 0) return const [];
    return [
      for (var r = minR; r <= maxR; r++)
        grid[r].sublist(minC, maxC + 1).join().replaceFirst(RegExp(r' +$'), ''),
    ];
  }

  static const _dotTypes = {
    '^': OrphanDotType.up,
    'v': OrphanDotType.down,
    '<': OrphanDotType.left,
    '>': OrphanDotType.right,
  };

  static bool _isUpper(String ch) =>
      ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90;
  static bool _isLower(String ch) =>
      ch.codeUnitAt(0) >= 97 && ch.codeUnitAt(0) <= 122 && ch != 'v';

  static List<List<int>> _walk(
      String letter, List<int> head, Set<int> body, int gs, int levelNumber) {
    final path = [head];
    final left = {...body};
    var cur = head;
    while (left.isNotEmpty) {
      final next = [
        for (final d in const [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1]
        ])
          if (left.contains((cur[0] + d[0]) * gs + cur[1] + d[1]))
            [cur[0] + d[0], cur[1] + d[1]],
      ];
      if (next.length != 1) {
        throw ArgumentError('L$levelNumber: arrow $letter body is not a single '
            'chain at (${cur[0]},${cur[1]})');
      }
      cur = next.single;
      left.remove(cur[0] * gs + cur[1]);
      path.add(cur);
    }
    if (path.length < 2) {
      throw ArgumentError('L$levelNumber: arrow $letter needs a body');
    }
    return path;
  }

  static ArrowDirection _dirFor(int dr, int dc) {
    if (dr == -1) return ArrowDirection.up;
    if (dr == 1) return ArrowDirection.down;
    if (dc == -1) return ArrowDirection.left;
    return ArrowDirection.right;
  }
}

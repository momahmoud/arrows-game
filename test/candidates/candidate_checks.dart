import 'dart:collection';
import 'dart:typed_data';

import 'package:arrow_escape/data/models/arrow.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:arrow_escape/game/game_state.dart';

/// Whether an order trap is a real decision on this board.
class TrapCheck {
  const TrapCheck({
    required this.decisionReachable,
    required this.complete,
    this.path = const [],
  });

  /// Taps (one ID per unit) that reach the decision state.
  final List<String> path;

  /// Some reachable state has the trap dot unused, both facing arrows still
  /// waiting, and the third arrow free to waste the dot.
  final bool decisionReachable;

  /// False when the search stopped at its cap before finding that state.
  final bool complete;
}

/// Result of exploring every board state reachable by legal taps.
class ReachableStates {
  const ReachableStates({
    required this.states,
    required this.deadEnds,
    required this.complete,
    this.deadEndExample,
  });

  final int states;

  /// Reachable states with arrows left but no legal tap.
  final int deadEnds;

  /// False when [states] hit the cap; then [deadEnds] is only a lower bound
  /// and "no dead end" is not proven.
  final bool complete;

  /// Taps (one ID per unit) that reach a dead end, when one was found.
  final List<String>? deadEndExample;
}

/// Exhaustive breadth-first search over (remaining units, remaining dots),
/// using the same exit rule as [GameState]. Small boards finish; large ones
/// stop at [cap] and report [ReachableStates.complete] = false.
ReachableStates exploreReachable(LevelModel level, {int cap = 400000}) =>
    _explore(level, cap, null).$1;

/// Breadth-first search for a reachable state where [z] can be tapped while
/// [x], [y] and the dot at ([dotRow], [dotCol]) are all still on the board.
TrapCheck checkTrap(
    LevelModel level, String x, String y, String z, int dotRow, int dotCol,
    {int cap = 400000}) {
  final (states, found) = _explore(level, cap, (x, y, z, dotRow, dotCol));
  return TrapCheck(
    decisionReachable: found,
    complete: found || states.complete,
    path: found ? states.deadEndExample ?? const [] : const [],
  );
}

/// With [trap] set, returns as soon as the trap decision is reachable; the
/// path to that state is then reported in [ReachableStates.deadEndExample].
(ReachableStates, bool) _explore(
    LevelModel level, int cap, (String, String, String, int, int)? trap) {
  final gs = level.gridSize;
  final arrows = level.arrows;
  final partner = List<int>.filled(arrows.length, -1);
  final groups = <int, List<int>>{};
  for (var i = 0; i < arrows.length; i++) {
    final g = arrows[i].colorGroup;
    if (g != null) groups.putIfAbsent(g, () => []).add(i);
  }
  for (final v in groups.values) {
    if (v.length == 2) {
      partner[v[0]] = v[1];
      partner[v[1]] = v[0];
    }
  }
  final units = <List<int>>[];
  final seenPair = <int>{};
  for (var i = 0; i < arrows.length; i++) {
    if (partner[i] == -1) {
      units.add([i]);
    } else if (seenPair.add(arrows[i].colorGroup!)) {
      units.add([i, partner[i]]);
    }
  }
  final dotIndex = <int, int>{};
  final dotType = <int>[];
  for (final d in level.orphanDots) {
    dotIndex[d.row * gs + d.col] = dotType.length;
    dotType.add(d.type.index);
  }
  if (units.length + dotType.length > 62) {
    return (
      const ReachableStates(states: 0, deadEnds: 0, complete: false),
      false
    );
  }
  int unitOfId(String id) =>
      units.indexWhere((u) => u.any((i) => arrows[i].id == id));
  final trapUnits = trap == null
      ? null
      : (
          unitOfId(trap.$1),
          unitOfId(trap.$2),
          unitOfId(trap.$3),
          dotIndex[trap.$4 * gs + trap.$5]!
        );

  final fullUnits = (1 << units.length) - 1;
  final fullDots = (1 << dotType.length) - 1;
  int key(int u, int d) => (u << dotType.length) | d;

  final parent = <int, (int, int)>{};
  final queue = Queue<(int, int)>()..add((fullUnits, fullDots));
  parent[key(fullUnits, fullDots)] = (-1, -1);
  var deadEnds = 0;
  int? deadKey;
  final board = Int16List(gs * gs);

  while (queue.isNotEmpty) {
    final (u, d) = queue.removeFirst();
    board.fillRange(0, board.length, -1);
    for (var k = 0; k < units.length; k++) {
      if (u & (1 << k) == 0) continue;
      for (final i in units[k]) {
        for (final p in arrows[i].path) {
          board[p[0] * gs + p[1]] = i;
        }
      }
    }
    var moves = 0;
    for (var k = 0; k < units.length; k++) {
      if (u & (1 << k) == 0) continue;
      var used = 0;
      var ok = true;
      for (final i in units[k]) {
        final c =
            _trace(arrows[i], i, partner[i], gs, board, d, dotIndex, dotType);
        if (c == null) {
          ok = false;
          break;
        }
        used |= c;
      }
      if (!ok) continue;
      moves++;
      if (trapUnits != null &&
          k == trapUnits.$3 &&
          u & (1 << trapUnits.$1) != 0 &&
          u & (1 << trapUnits.$2) != 0 &&
          d & (1 << trapUnits.$4) != 0 &&
          used & (1 << trapUnits.$4) != 0) {
        return (
          ReachableStates(
              states: parent.length,
              deadEnds: deadEnds,
              complete: false,
              deadEndExample: _pathTo(parent, key(u, d), units, arrows)),
          true
        );
      }
      final nu = u & ~(1 << k), nd = d & ~used;
      final nk = key(nu, nd);
      if (parent.containsKey(nk)) continue;
      if (parent.length >= cap) {
        return (
          ReachableStates(
              states: parent.length, deadEnds: deadEnds, complete: false),
          false
        );
      }
      parent[nk] = (key(u, d), k);
      queue.add((nu, nd));
    }
    if (moves == 0 && u != 0) {
      deadEnds++;
      deadKey ??= key(u, d);
    }
  }

  return (
    ReachableStates(
      states: parent.length,
      deadEnds: deadEnds,
      complete: true,
      deadEndExample:
          deadKey == null ? null : _pathTo(parent, deadKey, units, arrows),
    ),
    false
  );
}

List<String> _pathTo(Map<int, (int, int)> parent, int key,
    List<List<int>> units, List<ArrowModel> arrows) {
  final taps = <String>[];
  var k = key;
  while (true) {
    final (prev, unit) = parent[k]!;
    if (prev == -1) break;
    taps.add(arrows[units[unit].first].id);
    k = prev;
  }
  return taps.reversed.toList();
}

/// Replays [taps] in the real [GameState], then keeps tapping the first
/// arrow the game reports as free until none is. Returns whether the game
/// reported a deadlock and which arrows were left.
(bool, Set<String>) playOnInGame(LevelModel level, List<String> taps) {
  var deadlocked = false;
  final state = GameState(
    level: level,
    onLevelComplete: () {},
    onGameOver: () {},
    onLifeLost: () {},
    onDeadlock: () => deadlocked = true,
  );
  void tap(String id) {
    final group = state.arrows.firstWhere((a) => a.id == id).colorGroup;
    final unit = [
      for (final a in state.arrows)
        if (a.id == id || (group != null && a.colorGroup == group)) a.id,
    ];
    if (state.tapArrow(id) != TapResult.exited) {
      throw StateError('L${level.levelNumber}: $id did not exit');
    }
    for (final a in unit) {
      state.handleArrowExitCompleted(a);
    }
  }

  taps.forEach(tap);
  while (!deadlocked && !state.isComplete) {
    final free = state.arrows
        .where((a) => a.state == ArrowState.idle && !state.isArrowBlocked(a.id))
        .map((a) => a.id)
        .toList();
    if (free.isEmpty) break;
    tap(free.first);
  }
  return (
    deadlocked,
    {
      for (final a in state.arrows)
        if (a.state == ArrowState.idle) a.id
    }
  );
}

/// Consumed-dot bitmask, or null when the exit is blocked or loops.
int? _trace(ArrowModel a, int self, int partner, int gs, Int16List board,
    int dots, Map<int, int> dotIndex, List<int> dotType) {
  var dir = a.direction;
  var r = a.path[0][0] + dir.delta[0], c = a.path[0][1] + dir.delta[1];
  var used = 0;
  final seen = <int>{};
  while (r >= 0 && c >= 0 && r < gs && c < gs) {
    final f = r * gs + c;
    if (!seen.add(f)) return null;
    final di = dotIndex[f];
    if (di != null && dots & (1 << di) != 0) {
      used |= 1 << di;
      final t = dotType[di];
      if (t < 4) dir = ArrowDirection.values[t];
    } else {
      final o = board[f];
      if (o != -1 && o != self && o != partner) return null;
    }
    r += dir.delta[0];
    c += dir.delta[1];
  }
  return used;
}

/// Replays [taps] through the real [GameState]. Returns null when every tap
/// exits and the board clears, 'deadlock' when the game reports one, or a
/// description of the first tap that did not exit.
String? replayInGame(LevelModel level, List<String> taps) {
  var deadlocked = false;
  final state = GameState(
    level: level,
    onLevelComplete: () {},
    onGameOver: () {},
    onLifeLost: () {},
    onDeadlock: () => deadlocked = true,
  );
  for (final id in taps) {
    final group = state.arrows.firstWhere((a) => a.id == id).colorGroup;
    final unit = [
      for (final a in state.arrows)
        if (a.id == id || (group != null && a.colorGroup == group)) a.id,
    ];
    final result = state.tapArrow(id);
    if (result != TapResult.exited) return '$id -> ${result.name}';
    for (final a in unit) {
      state.handleArrowExitCompleted(a);
    }
  }
  if (deadlocked) return 'deadlock';
  return state.isComplete ? null : 'board not cleared';
}

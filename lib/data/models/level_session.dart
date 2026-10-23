import 'level.dart';

/// A campaign level the player left part-way through.
///
/// Stores what is left on the board, not how the player got there, so a
/// restore never has to replay taps. Only one session is kept: the level most
/// recently left unfinished.
class LevelSession {
  final int levelNumber;

  /// Fingerprint of the board this was saved on. A rebuilt `levels.bin` gives
  /// the level a new fingerprint, which makes the session unusable.
  final String signature;

  /// Ids of the arrows still on the board.
  final List<String> arrowIds;

  /// Keys (`row,col`) of the orphan dots still on the board.
  final List<String> dotKeys;

  final int lives;
  final int livesLost;
  final int movesUsed;
  final int powerUpsUsed;
  final int hintsUsed;

  /// Power-up counts by `PowerUpType.name`.
  final Map<String, int> powerUps;

  const LevelSession({
    required this.levelNumber,
    required this.signature,
    required this.arrowIds,
    required this.dotKeys,
    required this.lives,
    required this.livesLost,
    required this.movesUsed,
    required this.powerUpsUsed,
    required this.hintsUsed,
    required this.powerUps,
  });

  /// Cheap fingerprint of a level's arrows and dots.
  static String signatureOf(LevelModel level) {
    var h = level.gridSize;
    for (final a in level.arrows) {
      h = (h * 31 + a.id.hashCode) & 0x3fffffff;
      for (final p in a.path) {
        h = (h * 31 + p[0] * 100 + p[1]) & 0x3fffffff;
      }
    }
    for (final d in level.orphanDots) {
      h = (h * 31 + d.row * 100 + d.col + d.type.index * 7) & 0x3fffffff;
    }
    return '${level.arrows.length}:${level.orphanDots.length}:$h';
  }

  Map<String, dynamic> toJson() => {
        'level': levelNumber,
        'sig': signature,
        'arrows': arrowIds,
        'dots': dotKeys,
        'lives': lives,
        'livesLost': livesLost,
        'moves': movesUsed,
        'powerUpsUsed': powerUpsUsed,
        'hintsUsed': hintsUsed,
        'powerUps': powerUps,
      };

  /// Returns null for anything that is not a well-formed session.
  static LevelSession? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    try {
      return LevelSession(
        levelNumber: raw['level'] as int,
        signature: raw['sig'] as String,
        arrowIds: List<String>.from(raw['arrows'] as List),
        dotKeys: List<String>.from(raw['dots'] as List),
        lives: raw['lives'] as int,
        livesLost: raw['livesLost'] as int,
        movesUsed: raw['moves'] as int,
        powerUpsUsed: raw['powerUpsUsed'] as int,
        hintsUsed: raw['hintsUsed'] as int,
        powerUps: Map<String, int>.from(raw['powerUps'] as Map),
      );
    } catch (_) {
      return null;
    }
  }
}

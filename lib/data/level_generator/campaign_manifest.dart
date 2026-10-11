import '../models/level.dart';
import '../level_layout_profile.dart';
import '../../core/constants.dart';
import 'campaign_level_spec.dart';
import 'level_fingerprint.dart';

/// Development manifest row for a single campaign level.
class CampaignManifestEntry {
  final int level;
  final int chapter;
  final String levelType;
  final int arrowCount;
  final int boardSize;
  final int maskCells;
  final double density;
  final String shapeFamily;
  final int dependencyCount;
  final int dependencyDepth;
  final int initialMoves;
  final String difficulty;
  final int seed;
  final String fingerprint;

  const CampaignManifestEntry({
    required this.level,
    required this.chapter,
    required this.levelType,
    required this.arrowCount,
    required this.boardSize,
    required this.maskCells,
    required this.density,
    required this.shapeFamily,
    required this.dependencyCount,
    required this.dependencyDepth,
    required this.initialMoves,
    required this.difficulty,
    required this.seed,
    required this.fingerprint,
  });

  factory CampaignManifestEntry.fromLevel(LevelModel level) {
    final type = AppConstants.levelTypeFor(level.levelNumber);
    final profile = LevelLayoutProfile.analyze(
      arrows: level.arrows,
      gridSize: level.gridSize,
      maskCells: level.mask.length,
      shapeType: level.maskShape.name,
    );
    return CampaignManifestEntry(
      level: level.levelNumber,
      chapter: CampaignLevelSpec.chapterFor(level.levelNumber),
      levelType: type.name,
      arrowCount: level.arrows.length,
      boardSize: level.gridSize,
      maskCells: level.mask.length,
      density: profile.densityScore,
      shapeFamily: level.maskShape.name,
      dependencyCount: profile.dependencyEdgeCount,
      dependencyDepth: profile.dependencyDepth,
      initialMoves: profile.openingMoves,
      difficulty: level.difficulty.label,
      seed: level.levelNumber * 103 + 51,
      fingerprint: LevelFingerprint.canonicalHash(level),
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'chapter': chapter,
        'levelType': levelType,
        'arrowCount': arrowCount,
        'boardSize': boardSize,
        'maskCells': maskCells,
        'density': density,
        'shapeFamily': shapeFamily,
        'dependencyCount': dependencyCount,
        'dependencyDepth': dependencyDepth,
        'initialMoves': initialMoves,
        'difficulty': difficulty,
        'seed': seed,
        'fingerprint': fingerprint,
      };
}

import '../../core/constants.dart';
import 'campaign_composition.dart';
import 'campaign_roles.dart';

/// 1,000-level campaign targets for **normal** gameplay levels.
/// Boss/God use relaxed floors (still dense via mask fill).
class CampaignLevelSpec {
  CampaignLevelSpec._();

  static const int campaignGeneratorVersion = 7;

  static bool isCampaignLevel(int level, LevelType type) =>
      level > AppConstants.tutorialLevels && type == LevelType.normal;

  static (int min, int max) arrowBand(int level) {
    if (!CampaignComposition.hasBrief(level)) return (12, 120);
    final brief = CampaignComposition.briefFor(level);
    return (brief.minArrows, brief.maxArrows);
  }

  static int targetArrowCount(int level, LevelType type, int maskCells) {
    if (!isCampaignLevel(level, type)) {
      if (type == LevelType.tutorial) return 3;
      return (maskCells / 3.5).round().clamp(12, 120);
    }
    final brief = CampaignComposition.briefFor(level);
    final cap = (maskCells / 2.1).floor();
    final n = brief.targetArrows;
    if (cap > 0 && cap < n) return cap.clamp(3, brief.maxArrows);
    return n.clamp(brief.minArrows, brief.maxArrows);
  }

  static int minArrowCount(int level, LevelType type, {int maskCells = 999}) {
    if (type == LevelType.tutorial) return 2;
    if (isCampaignLevel(level, type)) {
      final bandMin = arrowBand(level).$1;
      final physicalMax = (maskCells / 2.1).floor();
      if (physicalMax < bandMin) {
        final floor = physicalMax < 3 ? 3 : physicalMax;
        return floor > bandMin ? bandMin : floor;
      }
      return bandMin;
    }
    if (level <= 100) return 14;
    if (level <= 500) return 22;
    return 30;
  }

  static int maxArrowCount(int level, LevelType type) {
    if (type == LevelType.tutorial) return 6;
    if (isCampaignLevel(level, type)) return arrowBand(level).$2;
    return 120;
  }

  static (double min, double max) occupancyBand(int level) {
    if (level <= 40) return (0.64, 0.94);
    if (level <= 200) return (0.70, 0.96);
    return (0.74, 0.97);
  }

  static double minOccupancy(int level, LevelType type) {
    if (type == LevelType.tutorial) return 0.20;
    if (type == LevelType.boss || type == LevelType.god) return 0.55;
    final role = CampaignRoles.roleFor(level);
    // Order puzzles need empty cells for direction dots to sit on.
    if (role == LevelRole.puzzle || role == LevelRole.teaching) return 0.58;
    return occupancyBand(level).$1;
  }

  static int chapterFor(int level) => ((level - 1) ~/ 50) + 1;

  static int avgPathLength(int level) {
    if (!CampaignComposition.hasBrief(level)) {
      if (level <= 50) return 4;
      return 5;
    }
    return CampaignComposition.briefFor(level).avgPath;
  }

  static double minParticipation(int level) {
    if (level <= 30) return 0.50;
    if (level <= 100) return 0.62;
    return 0.72;
  }

  static int maxOpeningMoves(int level, LevelType type) {
    // A breather is meant to start open.
    final extra = CampaignRoles.roleFor(level) == LevelRole.breather ? 4 : 0;
    if (type == LevelType.god) {
      if (level <= 50) return 5;
      if (level <= 200) return 3;
      return 2;
    }
    if (type == LevelType.boss) {
      if (level <= 50) return 5;
      return 3;
    }
    if (level <= 200) return 3 + extra;
    return 2 + extra;
  }

  static int minDependencyDepth(int level, LevelType type) {
    if (type == LevelType.tutorial) return 1;
    if (type == LevelType.normal && CampaignComposition.hasBrief(level)) {
      return CampaignComposition.briefFor(level).minDepth;
    }
    if (level <= 25) return 2;
    if (level <= 100) return 3;
    if (level <= 300) return 4;
    if (level <= 600) return 5;
    return 6;
  }
}

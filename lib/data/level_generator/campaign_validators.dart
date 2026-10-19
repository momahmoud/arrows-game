import '../models/arrow.dart';
import '../level_layout_profile.dart';
import '../../core/constants.dart';
import 'campaign_level_spec.dart';

class CampaignValidationIssue {
  final String code;
  final String message;
  const CampaignValidationIssue(this.code, this.message);
}

class CampaignValidators {
  CampaignValidators._();

  static List<CampaignValidationIssue> validateLevel({
    required int levelNumber,
    required LevelType type,
    required List<ArrowModel> arrows,
    required LevelLayoutProfile profile,
    required int maskCells,
    required int attempt,
  }) {
    final issues = <CampaignValidationIssue>[];
    issues.addAll(_geometry(arrows));

    if (type == LevelType.tutorial) return issues;

    final minArrows = CampaignLevelSpec.minArrowCount(
      levelNumber,
      type,
      maskCells: maskCells,
    );
    if (arrows.length < minArrows) {
      issues.add(CampaignValidationIssue(
        'ARROW_COUNT',
        '${arrows.length} arrows < min $minArrows',
      ));
    }

    if (CampaignLevelSpec.isCampaignLevel(levelNumber, type)) {
      final maxArrows = CampaignLevelSpec.maxArrowCount(levelNumber, type);
      if (arrows.length > maxArrows + 5) {
        issues.add(CampaignValidationIssue(
          'ARROW_COUNT',
          '${arrows.length} arrows > band max $maxArrows',
        ));
      }
    }

    if (attempt < 26) {
      final minOcc = CampaignLevelSpec.minOccupancy(levelNumber, type);
      if (profile.densityScore < minOcc - 0.06) {
        issues.add(CampaignValidationIssue(
          'DENSITY',
          'occupancy ${profile.densityScore.toStringAsFixed(2)} < $minOcc',
        ));
      }
    }

    if (CampaignLevelSpec.isCampaignLevel(levelNumber, type) && attempt < 22) {
      if (profile.participationRatio <
          CampaignLevelSpec.minParticipation(levelNumber)) {
        issues.add(CampaignValidationIssue(
          'DEPENDENCY',
          'participation ${profile.participationRatio.toStringAsFixed(2)} low',
        ));
      }
      if (profile.dependencyDepth <
          CampaignLevelSpec.minDependencyDepth(levelNumber, type)) {
        issues.add(CampaignValidationIssue(
          'DEPENDENCY',
          'depth ${profile.dependencyDepth} shallow',
        ));
      }
    }

    final maxOpen = CampaignLevelSpec.maxOpeningMoves(levelNumber, type);
    if (levelNumber >= 8 && profile.openingMoves > maxOpen && attempt < 35) {
      issues.add(CampaignValidationIssue(
        'DIFFICULTY',
        'opening moves ${profile.openingMoves} > $maxOpen',
      ));
    }

    if (profile.isImmediatelySolved && levelNumber >= 6 && attempt < 24) {
      issues.add(
          CampaignValidationIssue('DIFFICULTY', 'all arrows immediately free'));
    }

    return issues;
  }

  static List<CampaignValidationIssue> _geometry(List<ArrowModel> arrows) {
    final issues = <CampaignValidationIssue>[];
    for (final a in arrows) {
      if (a.path.isEmpty) {
        issues.add(const CampaignValidationIssue('GEOMETRY', 'empty path'));
        continue;
      }
      final seen = <String>{};
      for (var s = 0; s < a.path.length; s++) {
        final key = '${a.path[s][0]},${a.path[s][1]}';
        if (seen.contains(key)) {
          issues.add(
              CampaignValidationIssue('GEOMETRY', 'self intersect ${a.id}'));
          break;
        }
        seen.add(key);
        if (s >= 2) {
          final dr1 = a.path[s - 1][0] - a.path[s - 2][0];
          final dc1 = a.path[s - 1][1] - a.path[s - 2][1];
          final dr2 = a.path[s][0] - a.path[s - 1][0];
          final dc2 = a.path[s][1] - a.path[s - 1][1];
          if (dr1 + dr2 == 0 && dc1 + dc2 == 0) {
            issues.add(CampaignValidationIssue('GEOMETRY', '180 turn ${a.id}'));
            break;
          }
        }
      }
    }
    return issues;
  }
}

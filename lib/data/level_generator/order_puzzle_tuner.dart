import 'dart:math';

import '../models/level.dart';
import 'campaign_roles.dart';
import 'level_quality.dart';
import 'solver.dart';

/// Turns a generated board into an order puzzle by re-aiming its direction
/// dots.
///
/// The generator only places dots where empty cells happen to be, so it
/// rarely produces a board where tapping order matters. This keeps the arrows
/// exactly as generated and tries one dot change at a time. A change is kept
/// only if the board is still solvable and the dead-end rate does not drop.
class OrderPuzzleTuner {
  OrderPuzzleTuner._();

  /// Returns a board that fits the role of its level, or null when none was
  /// found within [tries] dot changes.
  static LevelModel? tune(LevelModel level, {int tries = 250}) {
    final dots = level.orphanDots;
    if (dots.isEmpty) return null;
    final rng = Random(level.levelNumber * 8191 + 17);

    var current = level;
    var currentProfile = LevelQuality.profile(current);
    if (CampaignRoles.issues(level.levelNumber, currentProfile).isEmpty) {
      return current;
    }

    for (var i = 0; i < tries; i++) {
      final next = List<OrphanDot>.of(current.orphanDots);
      final index = rng.nextInt(next.length);
      final old = next[index];
      final options = OrphanDotType.values.where((t) => t != old.type).toList();
      next[index] = OrphanDot(
        row: old.row,
        col: old.col,
        type: options[rng.nextInt(options.length)],
      );

      var candidate = current.copyWith(orphanDots: next);
      final outcome = LevelSolver.attempt(candidate, 6000);
      if (!outcome.isSolved) continue;
      candidate = candidate.copyWith(solutionOrder: outcome.solution);

      final profile = LevelQuality.profile(candidate);
      if (CampaignRoles.issues(level.levelNumber, profile).isEmpty) {
        return candidate;
      }
      if (profile.deadEndRate >= currentProfile.deadEndRate) {
        current = candidate;
        currentProfile = profile;
      }
    }
    return null;
  }
}

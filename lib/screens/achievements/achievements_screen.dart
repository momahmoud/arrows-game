import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../data/meta_rules.dart';
import '../../data/repositories/progress_repository.dart';
import '../../l10n/l10n.dart';
import '../../ui/game_ui.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressRepository>();
    final stats = progress.achievementSnapshot;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              GameScreenHeader(title: context.l10n.achievements),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (!MetaRules.achievements.any((item) => item.unlocked(stats)))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          context.l10n.awardsEmpty,
                          style: GameTypography.body(GameColors.textMuted),
                        ),
                      ),
                    for (final item in MetaRules.achievements) ...[
                      _AwardCard(item: item, stats: stats),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AwardCard extends StatelessWidget {
  const _AwardCard({required this.item, required this.stats});

  final AchievementDef item;
  final AchievementSnapshot stats;

  @override
  Widget build(BuildContext context) {
    final unlocked = item.unlocked(stats);
    final meter = _meter(item, stats);
    final current = meter.$1.clamp(0, meter.$2);
    final started = current > 0;
    return Opacity(
      opacity: unlocked || started ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: GameDecor.card(highlight: unlocked),
        child: Row(
          children: [
            GameIcon(
              kind: unlocked ? GameIconKind.trophy : GameIconKind.levelLocked,
              size: GameIconSizes.feature,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.achievementTitle(item),
                    style: GameTypography.section(GameColors.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.achievementDescription(item),
                    style: GameTypography.caption(GameColors.textMuted),
                  ),
                  if (!unlocked && meter.$2 > 1) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(GameRadius.sm),
                      child: LinearProgressIndicator(
                        value: current / meter.$2,
                        minHeight: 6,
                        backgroundColor: GameColors.line,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (unlocked) ...[
              const SizedBox(width: 8),
              const GameIcon(kind: GameIconKind.check, size: 22),
            ],
          ],
        ),
      ),
    );
  }

  /// Current and target taken from the existing unlock rule. No new goals.
  (int, int) _meter(AchievementDef item, AchievementSnapshot stats) {
    switch (item.id) {
      case 'hintless_50':
        return (stats.hintFreeClears, 50);
      case 'perfect_10':
        return (stats.perfectClears, 10);
      case 'collector':
        return (stats.shapesCollected, 10);
      case 'streak_7':
        return (stats.streakDays, 7);
      case 'coins_500':
        return (stats.lifetimeCoins, 500);
      case 'boss':
        return (stats.bossesCleared, 1);
      case 'god':
        return (stats.godsCleared, 1);
      case 'first_clear':
        return (stats.highestLevel > 1 ? 1 : 0, 1);
      default:
        return (item.unlocked(stats) ? 1 : 0, 1);
    }
  }
}

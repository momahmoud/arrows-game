import 'package:flutter/material.dart';
import '../../core/app_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/audio_manager.dart';
import '../../data/meta_rules.dart';
import '../../data/repositories/progress_repository.dart';
import '../../l10n/l10n.dart';

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
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      AudioManager.instance.playClick();
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textPrimary),
                  ),
                  Text(
                    context.l10n.achievements,
                    style: AppFonts.style(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: MetaRules.achievements.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = MetaRules.achievements[i];
                    final unlocked = item.unlocked(stats);
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? const Color(0xFFE2B93C).withValues(alpha: 0.18)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            unlocked ? Icons.emoji_events_rounded : Icons.lock_outline,
                            color: unlocked
                                ? const Color(0xFFE2B93C)
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.achievementTitle(item),
                                  style: AppFonts.style(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  context.l10n.achievementDescription(item),
                                  style: AppFonts.style(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

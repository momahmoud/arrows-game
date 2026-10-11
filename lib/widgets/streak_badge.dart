import 'package:flutter/material.dart';
import '../core/app_fonts.dart';
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../l10n/l10n.dart';
import '../ui/icons/game_assets.dart';
import '../ui/icons/game_icon.dart';

class StreakBadge extends StatelessWidget {
  final int days;

  const StreakBadge({super.key, required this.days});

  Color get _color {
    if (days >= AppConstants.streakMilestone3) return AppColors.accent;
    if (days >= AppConstants.streakMilestone2) return AppColors.accentOrange;
    if (days >= AppConstants.streakMilestone1) return AppColors.accentGold;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    if (days == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
        boxShadow: days >= AppConstants.streakMilestone1
            ? [
                BoxShadow(
                    color: _color.withValues(alpha: 0.25), blurRadius: 10),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GameIcon(
            kind: days >= AppConstants.streakMilestone1
                ? GameAssets.flame
                : GameAssets.daily,
            size: 22,
          ),
          const SizedBox(width: 6),
          Text('$days',
              style: AppFonts.style(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _color,
              )),
          const SizedBox(width: 2),
          Text(context.l10n.daysLabel,
              style: AppFonts.style(
                fontSize: 11,
                color: _color.withValues(alpha: 0.7),
              )),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_fonts.dart';

import '../core/board_style.dart';
import '../core/constants.dart';
import '../l10n/l10n.dart';

/// Full-screen banner played once when a boss or god level starts.
class BossIntroBanner extends StatelessWidget {
  final LevelType type;
  final VoidCallback onDismiss;

  const BossIntroBanner({
    super.key,
    required this.type,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final god = type == LevelType.god;
    final colors = BoardStyle.introColors(god);
    final title = god ? context.l10n.godLevel : context.l10n.bossLevel;
    return GestureDetector(
      onTap: onDismiss,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors[0].withValues(alpha: 0.94), colors[1].withValues(alpha: 0.92)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppFonts.style(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: colors[2],
                  shadows: [
                    Shadow(color: colors[2].withValues(alpha: 0.55), blurRadius: 18),
                  ],
                ),
              ).animate().scaleXY(
                    begin: 0.6,
                    end: 1,
                    duration: 420.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 8),
              Text(
                god ? context.l10n.godTagline : context.l10n.bossTagline,
                style: AppFonts.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

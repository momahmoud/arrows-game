import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/app_fonts.dart';

import '../core/constants.dart';
import '../l10n/l10n.dart';

/// Praise banner that pops over the board as the exit streak grows.
class ComboBanner extends StatelessWidget {
  final int combo;

  const ComboBanner({super.key, required this.combo});

  static (String, Color)? _tierFor(int combo, String perfect) {
    if (!AppConstants.isComboMilestone(combo)) return null;
    if (combo >= 15) return (perfect, const Color(0xFFE040FB));
    if (combo >= 10) return ('x$combo', const Color(0xFFFF6D00));
    if (combo >= 6) return ('x$combo', const Color(0xFF00C853));
    return ('x$combo', const Color(0xFF2979FF));
  }

  @override
  Widget build(BuildContext context) {
    final tier = _tierFor(combo, context.l10n.comboPerfect);
    if (tier == null) return const SizedBox.shrink();
    final (label, color) = tier;

    return Text(
      label,
      style: AppFonts.style(
        fontSize: combo >= 8 ? 34 : 40,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 1.2,
        shadows: [
          Shadow(color: color.withValues(alpha: 0.45), blurRadius: 14),
          const Shadow(color: Color(0x55000000), blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
    )
        .animate(key: ValueKey(combo))
        .scaleXY(begin: 0.5, end: 1.0, duration: 320.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 120.ms)
        .then(delay: 650.ms)
        .fadeOut(duration: 300.ms)
        .moveY(begin: 0, end: -12, duration: 300.ms);
  }
}

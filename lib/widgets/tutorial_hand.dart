import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bouncing pointer shown on the first tutorial levels until the player moves.
class TutorialHand extends StatelessWidget {
  const TutorialHand({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_rounded, size: 54, color: Color(0xFF3C4636))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: 14, duration: 650.ms, curve: Curves.easeInOut)
              .scaleXY(begin: 1, end: 0.92, duration: 650.ms),
          const SizedBox(height: 2),
          Text(
            'Tap an arrow',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF3C4636),
            ),
          ),
        ],
      ),
    );
  }
}

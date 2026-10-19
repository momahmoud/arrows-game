import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../widgets/lives_bar.dart';

/// Hearts for the gameplay HUD. Lives logic stays in [LivesBar].
class HeartDisplay extends StatelessWidget {
  const HeartDisplay({
    super.key,
    required this.lives,
    required this.maxLives,
    this.iconSize = 26,
    this.spacing = 3,
  });

  final int lives;
  final int maxLives;
  final double iconSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.heartsLeft(lives.clamp(0, maxLives), maxLives),
      child: ExcludeSemantics(
        child: LivesBar(
          lives: lives,
          maxLives: maxLives,
          iconSize: iconSize,
          spacing: spacing,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../icons/game_icon_kind.dart';
import '../theme/game_tokens.dart';
import 'icon_kit.dart';

/// Quiet secondary entry. It never outranks the screen's main action.
class BottomFeatureButton extends StatelessWidget {
  const BottomFeatureButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final GameIconKind icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: GameColors.surface,
        borderRadius: BorderRadius.circular(GameRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GameRadius.md),
          child: Ink(
            width: GameDims.featureWidth,
            decoration: GameDecor.card(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NavigationIcon(kind: icon),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GameTypography.caption(GameColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

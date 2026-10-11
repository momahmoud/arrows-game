import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../ui/icons/game_icon_kind.dart';
import '../ui/theme/game_tokens.dart';
import '../ui/widgets/booster_button.dart';

typedef PowerUpTap = void Function();

/// Bottom booster surface. Counts and taps stay with the caller.
class BoosterDock extends StatelessWidget {
  final int hintCount;
  final int eraserCount;
  final int wandCount;
  final int rulerCount;

  /// Highlights the eraser while it is waiting for an arrow to be tapped.
  final bool eraserActive;
  final bool enabled;

  /// When true, empty buttons stay tappable so the caller can offer a refill.
  final bool canRefill;
  final PowerUpTap? onHint;
  final PowerUpTap? onEraser;
  final PowerUpTap? onWand;
  final PowerUpTap? onRuler;

  const BoosterDock({
    super.key,
    required this.hintCount,
    required this.eraserCount,
    required this.wandCount,
    required this.rulerCount,
    this.eraserActive = false,
    this.enabled = true,
    this.canRefill = false,
    this.onHint,
    this.onEraser,
    this.onWand,
    this.onRuler,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final inset = GameplayMetrics.horizontalPadding(constraints.maxWidth);
        return Padding(
      padding: EdgeInsets.fromLTRB(inset, 0, inset, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(GameRadius.lg),
          border: Border.all(color: AppColors.surfaceLight),
          boxShadow: AppColors.isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
          child: Row(
            children: [
              Expanded(
                child: BoosterButton(
                  icon: GameIconKind.hint,
                  count: hintCount,
                  enabled: enabled,
                  canRefill: canRefill,
                  onTap: onHint,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BoosterButton(
                  icon: GameIconKind.remove,
                  count: eraserCount,
                  selected: eraserActive,
                  enabled: enabled,
                  canRefill: canRefill,
                  onTap: onEraser,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BoosterButton(
                  icon: GameIconKind.wand,
                  count: wandCount,
                  enabled: enabled,
                  canRefill: canRefill,
                  onTap: onWand,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BoosterButton(
                  icon: GameIconKind.ruler,
                  count: rulerCount,
                  enabled: enabled,
                  canRefill: canRefill,
                  onTap: onRuler,
                ),
              ),
            ],
          ),
        ),
      ),
        );
      },
    );
  }
}

/// Existing call sites keep this name.
typedef PowerUpBar = BoosterDock;

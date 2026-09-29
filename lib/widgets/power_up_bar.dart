import 'package:flutter/material.dart';
import '../core/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/app_colors.dart';

typedef PowerUpTap = void Function();

class PowerUpBar extends StatelessWidget {
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

  const PowerUpBar({
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _PowerUpButton(
            icon: Icons.lightbulb_rounded,
            iconColor: const Color(0xFFFFD54F),
            count: hintCount,
            enabled: enabled,
            canRefill: canRefill,
            onTap: onHint,
          ),
          _PowerUpButton(
            icon: LucideIcons.eraser,
            iconColor: const Color(0xFFFF8A80),
            count: eraserCount,
            active: eraserActive,
            enabled: enabled,
            canRefill: canRefill,
            onTap: onEraser,
          ),
          _PowerUpButton(
            icon: Icons.auto_fix_high_rounded,
            iconColor: const Color(0xFFFFD740),
            count: wandCount,
            enabled: enabled,
            canRefill: canRefill,
            onTap: onWand,
          ),
          _PowerUpButton(
            icon: Icons.square_foot_rounded,
            iconColor: const Color(0xFF64B5F6),
            count: rulerCount,
            enabled: enabled,
            canRefill: canRefill,
            onTap: onRuler,
          ),
        ],
      ),
    );
  }
}

class _PowerUpButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int count;
  final bool enabled;
  final bool canRefill;
  final bool active;
  final PowerUpTap? onTap;

  const _PowerUpButton({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.enabled,
    required this.canRefill,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canUse = enabled && count > 0 && onTap != null;
    final tappable = canUse || (enabled && canRefill && onTap != null);
    return Material(
      color: AppColors.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: tappable ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 72,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? iconColor
                  : canUse
                      ? AppColors.surfaceLight
                      : AppColors.surfaceLight.withValues(alpha: 0.5),
              width: active ? 2.5 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.45),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: canUse
                    ? iconColor
                    : iconColor.withValues(alpha: 0.35),
                size: 28,
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 0 ? '$count' : '+',
                    style: AppFonts.style(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

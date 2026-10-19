import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_colors.dart';
import '../../core/app_fonts.dart';
import '../../l10n/l10n.dart';
import '../icons/game_icon_kind.dart';
import '../theme/game_tokens.dart';
import 'icon_kit.dart';

/// One booster in the shared dock. Behavior stays with the caller.
class BoosterButton extends StatefulWidget {
  const BoosterButton({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.enabled,
    required this.canRefill,
    this.selected = false,
    this.onTap,
  });

  final GameIconKind icon;

  /// Short visible name, also read by screen readers with the count.
  final String label;
  final int count;
  final bool enabled;
  final bool canRefill;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<BoosterButton> createState() => _BoosterButtonState();
}

class _BoosterButtonState extends State<BoosterButton> {
  bool _pressed = false;
  int _useKey = 0;

  @override
  void didUpdateWidget(covariant BoosterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count < oldWidget.count) _useKey++;
  }

  @override
  Widget build(BuildContext context) {
    final canUse = widget.enabled && widget.count > 0 && widget.onTap != null;
    final tappable =
        canUse || (widget.enabled && widget.canRefill && widget.onTap != null);

    Widget icon = BoosterIcon(
      kind: widget.icon,
      size: 42,
      enabled: widget.enabled,
      empty: widget.count <= 0,
    );
    final artScale = switch (widget.icon) {
      GameIconKind.remove => 1.45,
      GameIconKind.wand => 1.15,
      GameIconKind.ruler => 1.28,
      _ => 1.0,
    };
    if (artScale != 1) {
      icon = Transform.scale(scale: artScale, child: icon);
    }
    if (_useKey > 0 && !GameMotion.reduce(context)) {
      icon = icon.animate(key: ValueKey('use_$_useKey')).scaleXY(
            begin: 1.12,
            end: 1,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
          );
    }

    final l10n = context.l10n;
    return Semantics(
      button: true,
      enabled: tappable,
      selected: widget.selected,
      label: widget.count > 0
          ? l10n.boosterLeft(widget.label, widget.count)
          : l10n.boosterEmpty(widget.label),
      child: ExcludeSemantics(
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: GameMotion.tap,
          curve: Curves.easeOut,
          child: Material(
            color: widget.selected
                ? Color.alphaBlend(
                    AppColors.primary.withValues(alpha: 0.10),
                    AppColors.surface,
                  )
                : AppColors.surface,
            borderRadius: BorderRadius.circular(GameRadius.md),
            child: InkWell(
              onTap: tappable ? widget.onTap : null,
              onHighlightChanged: (v) {
                if (_pressed != v) setState(() => _pressed = v);
              },
              borderRadius: BorderRadius.circular(GameRadius.md),
              child: Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(GameRadius.md),
                  border: Border.all(
                    color: widget.selected
                        ? AppColors.primary
                        : canUse
                            ? AppColors.surfaceLight
                            : AppColors.surfaceLight.withValues(alpha: 0.6),
                    width: widget.selected ? 2.5 : 1.25,
                  ),
                  boxShadow: widget.selected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 42 * GameIconSizes.scale,
                      height: 42 * GameIconSizes.scale,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          icon,
                          PositionedDirectional(
                            top: -4,
                            end: -10,
                            child: QuantityBadge(
                              label: widget.count > 0 ? '${widget.count}' : '+',
                              filled: widget.count > 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: AppFonts.style(
                            fontSize: 11,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                            color: canUse || widget.selected
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

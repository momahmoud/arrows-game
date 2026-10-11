import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/app_colors.dart';
import '../theme/game_tokens.dart';
import 'game_assets.dart';
import 'game_icon_kind.dart';
import 'game_icon_painter.dart';

const _emptyArt = ColorFilter.matrix(<double>[
  0.4,
  0.35,
  0.1,
  0,
  24,
  0.2,
  0.45,
  0.1,
  0,
  24,
  0.15,
  0.25,
  0.35,
  0,
  24,
  0,
  0,
  0,
  0.7,
  0,
]);

/// Scalable vector icon. Directional kinds flip for Arabic.
class GameIcon extends StatelessWidget {
  const GameIcon({
    super.key,
    required this.kind,
    this.size = GameIconSizes.md,
    this.semanticLabel,
    this.mirror,
  });

  final GameIconKind kind;
  final double size;
  final String? semanticLabel;

  /// Null follows [GameIconKindDirection.mirrorsInRtl].
  final bool? mirror;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final flip = mirror ?? (rtl && kind.mirrorsInRtl);
    final icon = _buildIcon();
    return Semantics(
      label: semanticLabel,
      image: semanticLabel != null,
      excludeSemantics: semanticLabel == null,
      child: flip ? Transform.flip(flipX: true, child: icon) : icon,
    );
  }

  Widget _buildIcon() {
    final art = gameArt[kind];
    if (art == null) {
      return CustomPaint(
        size: Size.square(size),
        painter: GameIconPainter(kind),
      );
    }
    Widget image = art.asset.endsWith('.svg')
        ? SvgPicture.asset(
            art.asset,
            width: size,
            height: size,
            excludeFromSemantics: true,
          )
        : Image.asset(
            art.asset,
            width: size,
            height: size,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            excludeFromSemantics: true,
          );
    if (art.tone == GameArtTone.empty) {
      image = ColorFiltered(colorFilter: _emptyArt, child: image);
    } else if (art.tone == GameArtTone.dim) {
      image = Opacity(opacity: 0.4, child: image);
    }
    return image;
  }
}

/// Icon button with a 48px touch target and a short press scale.
class GameIconButton extends StatefulWidget {
  const GameIconButton({
    super.key,
    required this.kind,
    required this.tooltip,
    required this.onPressed,
    this.iconSize = GameIconSizes.nav,
    this.selected = false,
  });

  final GameIconKind kind;
  final String tooltip;
  final VoidCallback onPressed;
  final double iconSize;
  final bool selected;

  @override
  State<GameIconButton> createState() => _GameIconButtonState();
}

class _GameIconButtonState extends State<GameIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: AnimatedScale(
        scale: _down ? 0.95 : 1,
        duration: GameMotion.tap,
        curve: Curves.easeOut,
        child: Material(
          color: widget.selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppSurface.of(context),
          borderRadius: BorderRadius.circular(GameRadius.sm),
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (v) {
              if (_down != v) setState(() => _down = v);
            },
            borderRadius: BorderRadius.circular(GameRadius.sm),
            child: SizedBox(
              width: GameSpacing.touch,
              height: GameSpacing.touch,
              child: Center(
                child: GameIcon(
                  kind: widget.kind,
                  size: widget.iconSize,
                  semanticLabel: widget.tooltip,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Local indirection so the button tracks light and dark surfaces.
class AppSurface {
  static Color of(BuildContext context) => GameColors.surface;
}

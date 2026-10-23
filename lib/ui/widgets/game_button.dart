import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/app_colors.dart';
import '../../l10n/l10n.dart';
import '../format/coin_format.dart';
import '../icons/game_icon.dart';
import '../icons/game_icon_kind.dart';
import '../theme/game_tokens.dart';
import 'icon_kit.dart';

enum GameButtonVariant { primary, secondary, reward, premium }

/// Depth, highlight, and a small press scale. Shared by every game button.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GameButtonVariant.primary,
    this.icon,
    this.leading,
    this.trailing,
    this.subtitle,
    this.expand = true,
    this.compact = false,
    this.pulse = false,
    this.colors,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final GameButtonVariant variant;
  final GameIconKind? icon;
  final Widget? leading;
  final Widget? trailing;
  final String? subtitle;
  final bool expand;
  final bool compact;
  final bool pulse;
  final List<Color>? colors;
  final String? semanticLabel;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;

  List<Color> get _colors {
    final override = widget.colors;
    if (override != null && override.length >= 3) return override;
    switch (widget.variant) {
      case GameButtonVariant.primary:
        return GameButtonStyles.primary;
      case GameButtonVariant.secondary:
        return GameButtonStyles.secondary;
      case GameButtonVariant.reward:
        return GameButtonStyles.reward;
      case GameButtonVariant.premium:
        return GameButtonStyles.premium;
    }
  }

  Color get _labelColor {
    switch (widget.variant) {
      case GameButtonVariant.secondary:
        return AppColors.textPrimary;
      case GameButtonVariant.reward:
        return GameColors.coinInk;
      case GameButtonVariant.primary:
      case GameButtonVariant.premium:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final colors = _colors;
    final lip = enabled ? 4.0 : 2.0;
    final pressed = _down && enabled;
    final text = _labelColor;
    final radius = widget.compact ? GameRadius.md : GameRadius.xl;

    // Long translations shrink a little before they would be cut off.
    final label = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        widget.label,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: GameTypography.button(text),
      ),
    );

    final row = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: GameSpacing.xs),
        ] else if (widget.icon != null) ...[
          GameIcon(kind: widget.icon!, size: widget.compact ? 22 : 26),
          const SizedBox(width: GameSpacing.xs),
        ],
        if (widget.expand)
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                label,
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GameTypography.caption(text.withValues(alpha: 0.85)),
                  ),
              ],
            ),
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              label,
              if (widget.subtitle != null)
                Text(
                  widget.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameTypography.caption(text.withValues(alpha: 0.85)),
                ),
            ],
          ),
        if (widget.trailing != null) ...[
          const SizedBox(width: GameSpacing.xs),
          widget.trailing!,
        ],
      ],
    );

    Widget face = AnimatedContainer(
      duration: GameMotion.tap,
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, pressed ? 2 : 0, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors[2],
          borderRadius: BorderRadius.circular(radius),
          boxShadow: pressed || !enabled ? null : GameShadows.lift(colors[2]),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: pressed ? 1 : lip),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors[0], colors[1]],
              ),
              borderRadius: BorderRadius.circular(radius),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
              ),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    widget.compact ? GameSpacing.touch : GameDims.playHeight,
                minWidth: widget.expand ? double.infinity : GameSpacing.touch,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: GameSpacing.md,
                  vertical: widget.compact ? GameSpacing.xs : GameSpacing.sm,
                ),
                child: row,
              ),
            ),
          ),
        ),
      ),
    );

    if (!enabled) {
      face = Opacity(opacity: 0.5, child: face);
    } else if (widget.pulse && !GameMotion.reduce(context)) {
      face = face
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(
            begin: 1,
            end: 1.025,
            duration: GameMotion.ctaPulse,
            curve: Curves.easeInOut,
          );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: enabled ? () => setState(() => _down = false) : null,
          onTapUp: enabled
              ? (_) {
                  setState(() => _down = false);
                  widget.onPressed?.call();
                }
              : null,
          child: face,
        ),
      ),
    );
  }
}

/// Watch-ad style button: action label plus a coin amount.
/// The screen's one strong action. Purple, rounded, and quietly alive.
class PrimaryGameButton extends StatelessWidget {
  const PrimaryGameButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon = GameIconKind.play,
    this.leading,
    this.subtitle,
    this.pulse = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final GameIconKind? icon;
  final Widget? leading;
  final String? subtitle;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      leading: leading,
      subtitle: subtitle,
      pulse: pulse,
      variant: GameButtonVariant.primary,
    );
  }
}

class RewardButton extends StatelessWidget {
  const RewardButton({
    super.key,
    required this.label,
    required this.coins,
    this.onPressed,
    this.icon = GameIconKind.watchAd,
    this.pulse = true,
  });

  final String label;
  final int coins;
  final VoidCallback? onPressed;
  final GameIconKind icon;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return GameButton(
      label: label,
      semanticLabel: '$label, ${formatCoins(context, coins, signed: true)}',
      icon: icon,
      variant: GameButtonVariant.reward,
      pulse: pulse && onPressed != null,
      onPressed: onPressed,
      trailing: CoinChip(amount: coins, signed: true),
    );
  }
}

class CoinChip extends StatelessWidget {
  const CoinChip({
    super.key,
    required this.amount,
    this.signed = false,
  });

  final int amount;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(GameRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CoinIcon(size: GameIconSizes.small),
            const SizedBox(width: 4),
            Text(
              formatCoins(context, amount, signed: signed),
              style: GameTypography.caption(GameColors.coinInk),
            ),
          ],
        ),
      ),
    );
  }
}

/// Coin balance. [anchor] is the target for reward flights.
class CoinDisplay extends StatefulWidget {
  const CoinDisplay({
    super.key,
    required this.amount,
    this.compact = false,
    this.anchor = false,
    this.onTap,
    this.icon = GameIconKind.coin,
  });

  final int amount;
  final bool compact;
  final bool anchor;
  final VoidCallback? onTap;
  final GameIconKind icon;

  @override
  State<CoinDisplay> createState() => _CoinDisplayState();
}

class _CoinDisplayState extends State<CoinDisplay> {
  @override
  Widget build(BuildContext context) {
    final iconSize = widget.compact ? GameIconSizes.small : GameIconSizes.nav;
    final child = Material(
      color: GameColors.surface,
      borderRadius: BorderRadius.circular(GameRadius.pill),
      elevation: 0,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(GameRadius.pill),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: widget.onTap == null ? 32 : GameSpacing.touch,
            minWidth: widget.onTap == null ? 0 : GameSpacing.touch,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? GameSpacing.xs : GameSpacing.sm,
              vertical: GameSpacing.xxs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameIcon(kind: widget.icon, size: iconSize),
                const SizedBox(width: GameSpacing.xxs),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutBack,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Text(
                    formatCoins(context, widget.amount),
                    key: ValueKey(widget.amount),
                    style: GameTypography.amount(GameColors.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final keyed = widget.anchor ? CoinAnchor(child: child) : child;
    return Semantics(
      button: widget.onTap != null,
      label: context.l10n.coinsAmount(widget.amount),
      child: ExcludeSemantics(child: keyed),
    );
  }
}

/// Where flying coins land. Several balances can be mounted; the latest wins.
class CoinAnchor extends StatefulWidget {
  const CoinAnchor({super.key, required this.child});

  final Widget child;

  static final List<GlobalKey> _keys = [];
  static final List<_CoinAnchorState> _states = [];

  /// A flying coin reached the balance: it pops. Does nothing when no
  /// balance is on screen.
  static void landed() {
    if (_states.isNotEmpty) _states.last._pop();
  }

  static Offset? get target {
    for (final key in _keys.reversed) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.attached && box.hasSize) {
        return box.localToGlobal(box.size.center(Offset.zero));
      }
    }
    return null;
  }

  @override
  State<CoinAnchor> createState() => _CoinAnchorState();
}

class _CoinAnchorState extends State<CoinAnchor>
    with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  late final AnimationController _popCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void initState() {
    super.initState();
    CoinAnchor._keys.add(_key);
    CoinAnchor._states.add(this);
  }

  @override
  void dispose() {
    CoinAnchor._keys.remove(_key);
    CoinAnchor._states.remove(this);
    _popCtl.dispose();
    super.dispose();
  }

  void _pop() {
    if (mounted) _popCtl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _popCtl,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.1 * (1 - (_popCtl.value * 2 - 1).abs()),
        child: child,
      ),
      child: KeyedSubtree(key: _key, child: widget.child),
    );
  }
}

class ShinyCoin extends StatefulWidget {
  const ShinyCoin({
    super.key,
    required this.size,
    this.kind = GameIconKind.coin,
    this.animate = true,
  });

  final double size;
  final GameIconKind kind;
  final bool animate;

  @override
  State<ShinyCoin> createState() => _ShinyCoinState();
}

class _ShinyCoinState extends State<ShinyCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.repeat(period: const Duration(milliseconds: 2600));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = GameIcon(kind: widget.kind, size: widget.size);
    if (!widget.animate || GameMotion.reduce(context)) return icon;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                child!,
                Positioned(
                  left: widget.size * (t * 2 - 0.6),
                  width: widget.size * 0.35,
                  top: 0,
                  bottom: 0,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x00FFFFFF),
                          Color(0x99FFFFFF),
                          Color(0x00FFFFFF),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: icon,
      ),
    );
  }
}

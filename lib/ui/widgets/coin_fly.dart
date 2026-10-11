import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../icons/game_icon.dart';
import '../icons/game_icon_kind.dart';
import 'game_button.dart';

/// Coins travel from a reward toward [CoinAnchor] when it is on screen.
class CoinFly {
  CoinFly._();

  static void burst(BuildContext context,
      {required Offset from, int count = 6}) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    final target = CoinAnchor.target;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _CoinFlyLayer(
        from: from,
        to: target ?? from + const Offset(0, -120),
        count: count.clamp(4, 8),
        onDone: () {
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }

  static Offset? of(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }
}

class _CoinFlyLayer extends StatefulWidget {
  const _CoinFlyLayer({
    required this.from,
    required this.to,
    required this.count,
    required this.onDone,
  });

  final Offset from;
  final Offset to;
  final int count;
  final VoidCallback onDone;

  @override
  State<_CoinFlyLayer> createState() => _CoinFlyLayerState();
}

class _CoinFlyLayerState extends State<_CoinFlyLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              for (var i = 0; i < widget.count; i++) _coin(i),
            ],
          );
        },
      ),
    );
  }

  Widget _coin(int index) {
    final start = (index * 0.08).clamp(0.0, 0.4);
    final t = ((_controller.value - start) / (1 - start)).clamp(0.0, 1.0);
    final travel = Curves.easeInOut.transform(t);
    final base = Offset.lerp(widget.from, widget.to, travel)!;
    final arc = math.sin(travel * math.pi) * 36;
    final spread = (index - widget.count / 2) * 10 * (1 - travel);
    final pos = base + Offset(spread, -arc);
    return Positioned(
      left: pos.dx - 12,
      top: pos.dy - 12,
      child: Opacity(
        opacity: t < 0.08
            ? t / 0.08
            : (1 - t).clamp(0.0, 1.0) < 0.15
                ? (1 - t) / 0.15
                : 1,
        child: const GameIcon(kind: GameIconKind.coinFlying, size: 28),
      ),
    );
  }
}

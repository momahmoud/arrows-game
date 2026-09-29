import 'package:flutter/material.dart';
import '../core/app_fonts.dart';

import '../data/models/level.dart';
import '../l10n/l10n.dart';

/// Fills the level silhouette in and shows its name when the board clears.
class ShapeReveal extends StatefulWidget {
  final LevelModel level;

  const ShapeReveal({super.key, required this.level});

  @override
  State<ShapeReveal> createState() => _ShapeRevealState();
}

class _ShapeRevealState extends State<ShapeReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = context.l10n.shapeName(widget.level.maskShape);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 132,
          height: 132,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _SilhouettePainter(
                mask: widget.level.mask,
                gridSize: widget.level.gridSize,
                reveal: Curves.easeOut.transform(_controller.value),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: AppFonts.style(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF5E6B56),
          ),
        ),
      ],
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final Set<String> mask;
  final int gridSize;
  final double reveal;

  _SilhouettePainter({
    required this.mask,
    required this.gridSize,
    required this.reveal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cells = mask.isEmpty
        ? [
            for (var r = 0; r < gridSize; r++)
              for (var c = 0; c < gridSize; c++) '$r,$c',
          ]
        : mask.toList()
          ..sort();
    if (cells.isEmpty) return;

    var minR = gridSize, maxR = 0, minC = gridSize, maxC = 0;
    final parsed = <(int, int)>[];
    for (final key in cells) {
      final parts = key.split(',');
      if (parts.length != 2) continue;
      final r = int.tryParse(parts[0]);
      final c = int.tryParse(parts[1]);
      if (r == null || c == null) continue;
      parsed.add((r, c));
      if (r < minR) minR = r;
      if (r > maxR) maxR = r;
      if (c < minC) minC = c;
      if (c > maxC) maxC = c;
    }
    if (parsed.isEmpty) return;

    final rows = (maxR - minR + 1).clamp(1, 999);
    final cols = (maxC - minC + 1).clamp(1, 999);
    final cell = (size.shortestSide / (rows > cols ? rows : cols)) * 0.92;
    final origin = Offset(
      (size.width - cols * cell) / 2,
      (size.height - rows * cell) / 2,
    );
    final shown = (parsed.length * reveal).ceil().clamp(0, parsed.length);
    final fill = Paint()..color = const Color(0xFF7D9B76);
    final ghost = Paint()..color = const Color(0x337D9B76);
    for (var i = 0; i < parsed.length; i++) {
      final (r, c) = parsed[i];
      final rect = Rect.fromLTWH(
        origin.dx + (c - minC) * cell,
        origin.dy + (r - minR) * cell,
        cell * 0.92,
        cell * 0.92,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(cell * 0.18)),
        i < shown ? fill : ghost,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SilhouettePainter oldDelegate) =>
      oldDelegate.reveal != reveal || oldDelegate.mask != mask;
}

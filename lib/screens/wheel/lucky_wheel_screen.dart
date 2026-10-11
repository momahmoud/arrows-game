import 'dart:math';

import 'package:flutter/material.dart';
import '../../core/app_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/audio_manager.dart';
import '../../data/meta_rules.dart';
import '../../game/game_state.dart';
import '../../data/repositories/progress_repository.dart';
import '../../l10n/l10n.dart';
import '../../ui/game_ui.dart';

class LuckyWheelScreen extends StatefulWidget {
  const LuckyWheelScreen({super.key});

  @override
  State<LuckyWheelScreen> createState() => _LuckyWheelScreenState();
}

class _LuckyWheelScreenState extends State<LuckyWheelScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  Animation<double>? _turn;
  WheelSlice? _result;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _spinWheel() async {
    final progress = context.read<ProgressRepository>();
    if (!progress.canSpinWheel || _busy) return;
    final index = Random().nextInt(MetaRules.wheel.length);
    final slice = progress.spinWheel(index);
    if (slice == null) return;
    setState(() {
      _busy = true;
      _result = null;
    });
    final sweep = 2 * pi / MetaRules.wheel.length;
    final target = 6 * 2 * pi + (-pi / 2 - (index + 0.5) * sweep);
    _turn = Tween<double>(begin: 0, end: target).animate(
      CurvedAnimation(parent: _spin, curve: Curves.easeOutCubic),
    );
    _spin.reset();
    await _spin.forward();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = slice;
    });
    AudioManager.instance.playClick();
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressRepository>();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              GameScreenHeader(title: context.l10n.luckyWheel),
              Text(
                progress.canSpinWheel
                    ? context.l10n.freeSpinToday
                    : context.l10n.spunToday,
                style: GameTypography.body(GameColors.textMuted),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final side = min(280.0, constraints.maxWidth - 48);
                    final room = constraints.maxHeight;
                    final box = min(side + 16, room);
                    final wheel = max(0.0, box - 16);
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: wheel,
                          height: box,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              const GameIcon(
                                  kind: GameIconKind.chevronDown, size: 36),
                              Positioned(
                                top: 16,
                                child: AnimatedBuilder(
                                  animation: _spin,
                                  builder: (context, child) {
                                    return Transform.rotate(
                                      angle: _turn?.value ?? 0,
                                      child: child,
                                    );
                                  },
                                  child: CustomPaint(
                                    size: Size.square(wheel),
                                    painter: _WheelPainter(
                                      labels: [
                                        for (final s in MetaRules.wheel)
                                          context.l10n.wheelSliceLabel(s),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (_result != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _WheelResult(slice: _result!),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GameButton(
                  icon: GameIconKind.wheel,
                  label: context.l10n.spin,
                  onPressed:
                      progress.canSpinWheel && !_busy ? _spinWheel : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelResult extends StatelessWidget {
  const _WheelResult({required this.slice});

  final WheelSlice slice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: GameDecor.card(highlight: true),
      child: Row(
        children: [
          GameIcon(kind: _icon(slice), size: GameIconSizes.feature),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.youWon(context.l10n.wheelPrize(slice)),
              style: GameTypography.section(GameColors.text),
            ),
          ),
        ],
      ),
    );
  }

  GameIconKind _icon(WheelSlice slice) {
    if (slice.heart) return GameIconKind.heart;
    if (slice.coins > 0) return GameIconKind.coin;
    switch (slice.powerUp) {
      case PowerUpType.hint:
        return GameIconKind.hint;
      case PowerUpType.eraser:
        return GameIconKind.remove;
      case PowerUpType.wand:
        return GameIconKind.wand;
      case PowerUpType.ruler:
        return GameIconKind.ruler;
      case null:
        return GameIconKind.gift;
    }
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> labels;

  _WheelPainter({required this.labels});

  static const _colors = [
    Color(0xFF5E6B56),
    Color(0xFF8E44AD),
    Color(0xFF2979FF),
    Color(0xFFE53935),
    Color(0xFFE2B93C),
    Color(0xFF00897B),
    Color(0xFFFF6D00),
    Color(0xFF6D4C41),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final sweep = 2 * pi / MetaRules.wheel.length;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < MetaRules.wheel.length; i++) {
      final paint = Paint()..color = _colors[i % _colors.length];
      canvas.drawArc(rect, i * sweep, sweep, true, paint);
      final angle = (i + 0.5) * sweep;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: AppFonts.style(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(radius * 0.62, 0);
      canvas.rotate(pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.labels.join() != labels.join();
}

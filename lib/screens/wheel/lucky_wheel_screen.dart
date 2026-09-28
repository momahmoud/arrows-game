import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/audio_manager.dart';
import '../../data/meta_rules.dart';
import '../../data/repositories/progress_repository.dart';

class LuckyWheelScreen extends StatefulWidget {
  const LuckyWheelScreen({super.key});

  @override
  State<LuckyWheelScreen> createState() => _LuckyWheelScreenState();
}

class _LuckyWheelScreenState extends State<LuckyWheelScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  Animation<double>? _turn;
  String? _result;
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
      _result = slice.label;
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
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    AudioManager.instance.playClick();
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary),
                ),
              ),
              Text(
                'Lucky Wheel',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                progress.canSpinWheel ? 'One free spin today' : 'Spun for today',
                style: GoogleFonts.nunito(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 260,
                height: 280,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    const Icon(Icons.arrow_drop_down, size: 36, color: Color(0xFFE2B93C)),
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
                          size: const Size.square(260),
                          painter: _WheelPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_result != null)
                Text(
                  'You won $_result',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton(
                  onPressed: progress.canSpinWheel && !_busy ? _spinWheel : null,
                  child: const Text('Spin'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
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
          text: MetaRules.wheel[i].label,
          style: GoogleFonts.nunito(
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

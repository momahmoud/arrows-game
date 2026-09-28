import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';

/// Particle burst effect when an arrow exits the grid.
class ExitParticleEffect extends ParticleSystemComponent {
  ExitParticleEffect({
    required Vector2 position,
    required Color color,
    double scale = 1.0,
  }) : super(
          position: position,
          priority: 10,
          particle: Particle.generate(
            count: 14,
            lifespan: 0.55,
            generator: (i) {
              final rng = Random();
              final angle = (i / 14) * 2 * pi + rng.nextDouble() * 0.4;
              final speed = (40 + rng.nextDouble() * 90) * scale;
              final tint = i.isEven ? color : _accentColors[i % _accentColors.length];
              return AcceleratedParticle(
                position: Vector2.zero(),
                speed: Vector2(cos(angle) * speed, sin(angle) * speed),
                acceleration: Vector2(0, 160 * scale),
                child: ComputedParticle(
                  renderer: (canvas, particle) {
                    final fade = (1 - particle.progress).clamp(0.0, 1.0);
                    canvas.drawCircle(
                      Offset.zero,
                      (2.0 + (i % 3)) * scale * (0.4 + 0.6 * fade),
                      Paint()..color = tint.withValues(alpha: 0.95 * fade),
                    );
                  },
                ),
              );
            },
          ),
        );

  static final _accentColors = [
    AppColors.accentGold,
    AppColors.accentGreen,
    AppColors.primaryLight,
    AppColors.accent,
  ];
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../ui/game_ui.dart';
import '../../core/constants.dart';
import '../../ads/ad_manager.dart';
import '../../core/audio_manager.dart';
import '../../l10n/l10n.dart';

/// Full-screen game over overlay (alternative to dialog — used as a route).
class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final levelNumber = args?['level'] as int? ?? 1;
    final adManager = context.read<AdManager>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Broken heart
                const GameIcon(kind: GameIconKind.heartBroken, size: 80)
                    .animate()
                    .shake(duration: 600.ms)
                    .then()
                    .fadeIn(),

                const SizedBox(height: 24),

                Text(
                  context.l10n.outOfLives,
                  style: AppFonts.style(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3),

                const SizedBox(height: 8),

                Text(
                  context.l10n.levelNumber(levelNumber),
                  style: AppFonts.style(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ).animate(delay: 300.ms).fadeIn(),

                const SizedBox(height: 40),

                // Lives display (all empty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                      3,
                      (_) => const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Opacity(
                              opacity: 0.35,
                              child: GameIcon(
                                kind: GameIconKind.heartEmpty,
                                size: 32,
                              ),
                            ),
                          )),
                ).animate(delay: 400.ms).fadeIn(),

                const SizedBox(height: 48),

                _ActionButton(
                  icon: GameIconKind.watchAd,
                  variant: GameButtonVariant.reward,
                  label: context.l10n.getOneMoreLife,
                  subtitle: context.l10n.watchAdForLife,
                  onTap: () {
                    bool rewarded = false;
                    adManager.showRewardedWithLoader(
                      context,
                      onRewarded: () {
                        rewarded = true;
                        if (!context.mounted) return;
                        Navigator.pushReplacementNamed(context, '/game',
                            arguments: {'level': levelNumber, 'revived': true});
                      },
                      onDismissed: () {
                        if (!rewarded && context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.l10n.adNotCompletedRestartLevel,
                                style: AppFonts.style(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: const Color(0xFFC0392B),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.3),

                const SizedBox(height: 14),

                // Restart level (full lives)
                _ActionButton(
                  icon: GameIconKind.restart,
                  variant: GameButtonVariant.secondary,
                  label: context.l10n.restartLevel,
                  subtitle: context.l10n.startOverWithLives(AppConstants.maxLives),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/game',
                        arguments: {'level': levelNumber});
                  },
                ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3),

                const SizedBox(height: 14),

                // Back to menu
                GameButton(
                  icon: GameIconKind.home,
                  variant: GameButtonVariant.secondary,
                  label: context.l10n.mainMenu,
                  onPressed: () {
                    AudioManager.instance.playClick();
                    Navigator.pushReplacementNamed(context, '/menu');
                  },
                ).animate(delay: 700.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final GameIconKind icon;
  final GameButtonVariant variant;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.variant,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GameButton(
      icon: icon,
      variant: variant,
      label: label,
      subtitle: subtitle,
      onPressed: () {
        AudioManager.instance.playClick();
        onTap();
      },
    );
  }
}

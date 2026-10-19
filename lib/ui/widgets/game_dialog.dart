import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_fonts.dart';
import '../../core/audio_manager.dart';
import '../icons/game_icon.dart';
import '../icons/game_icon_kind.dart';
import '../theme/game_tokens.dart';
import 'game_button.dart';
import 'level_result.dart';

/// One layout for every short in-game decision: optional mark, title,
/// message, optional content, then actions with the first one strongest.
class GameDialog extends StatelessWidget {
  const GameDialog({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.iconSize = GameIconSizes.lg,
    this.eyebrow,
    this.note,
    this.body,
    required this.actions,
    this.dismissLabel,
    this.onDismiss,
  });

  static const EdgeInsets insetPadding =
      EdgeInsets.symmetric(horizontal: 20, vertical: 24);

  final String title;
  final String? message;
  final GameIconKind? icon;
  final double iconSize;

  /// Small label above the title, such as a tutorial step.
  final String? eyebrow;
  final String? note;
  final Widget? body;
  final List<Widget> actions;
  final String? dismissLabel;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: insetPadding,
      child: SingleChildScrollView(
        child: ResultCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!,
                  textAlign: TextAlign.center,
                  style: GameTypography.caption(AppColors.primary),
                ),
                const SizedBox(height: GameSpacing.xs),
              ],
              if (icon != null) ...[
                GameIcon(kind: icon!, size: iconSize),
                const SizedBox(height: GameSpacing.sm),
              ],
              Semantics(
                header: true,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GameTypography.title(GameColors.text),
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: GameSpacing.xs),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: GameTypography.body(GameColors.textMuted),
                ),
              ],
              if (note != null) ...[
                const SizedBox(height: GameSpacing.xs),
                Text(
                  note!,
                  textAlign: TextAlign.center,
                  style: GameTypography.caption(GameColors.textMuted),
                ),
              ],
              if (body != null) ...[
                const SizedBox(height: GameSpacing.sm),
                body!,
              ],
              const SizedBox(height: GameSpacing.md),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(height: GameSpacing.xs),
                actions[i],
              ],
              if (dismissLabel != null) ...[
                const SizedBox(height: GameSpacing.xxs),
                TextButton(
                  onPressed: () {
                    AudioManager.instance.playClick();
                    onDismiss?.call();
                  },
                  style: TextButton.styleFrom(
                    minimumSize:
                        const Size(GameSpacing.touch, GameSpacing.touch),
                  ),
                  child: Text(
                    dismissLabel!,
                    style: AppFonts.style(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Asks before an action that discards the current board. The safe choice
/// is the primary button, and dismissing the dialog counts as "no".
Future<bool> showGameConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required GameIconKind confirmIcon,
  required String cancelLabel,
  GameIconKind? icon,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => GameDialog(
      icon: icon,
      title: title,
      message: message,
      actions: [
        GameButton(
          label: cancelLabel,
          icon: GameIconKind.play,
          onPressed: () {
            AudioManager.instance.playClick();
            Navigator.pop(dialogContext, false);
          },
        ),
        GameButton(
          label: confirmLabel,
          icon: confirmIcon,
          variant: GameButtonVariant.secondary,
          compact: true,
          onPressed: () {
            AudioManager.instance.playClick();
            Navigator.pop(dialogContext, true);
          },
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

import 'package:flutter/material.dart';

import '../core/audio_manager.dart';
import '../l10n/l10n.dart';
import '../ui/icons/game_icon_kind.dart';
import '../ui/widgets/game_button.dart';
import '../ui/widgets/game_dialog.dart';
import 'prompts/ad_consent.dart';

String _language(BuildContext context) =>
    Localizations.localeOf(context).languageCode;

/// The ad choice: allow personalized ads, or keep them non-personalized.
/// Can't be dismissed without choosing; true means personalized.
Future<bool?> showAdConsentDialog(BuildContext context) {
  final lang = _language(context);
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: GameDialog(
        icon: GameIconKind.settings,
        title: AdConsentCopy.title(lang),
        message: AdConsentCopy.body(lang, context.l10n.appTitle),
        actions: [
          GameButton(
            label: AdConsentCopy.allow(lang),
            icon: GameIconKind.play,
            onPressed: () {
              AudioManager.instance.playClick();
              Navigator.pop(dialogContext, true);
            },
          ),
          GameButton(
            label: AdConsentCopy.decline(lang),
            icon: GameIconKind.settings,
            variant: GameButtonVariant.secondary,
            compact: true,
            onPressed: () {
              AudioManager.instance.playClick();
              Navigator.pop(dialogContext, false);
            },
          ),
        ],
      ),
    ),
  );
}

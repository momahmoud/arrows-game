import 'package:flutter/material.dart';

import '../core/audio_manager.dart';
import '../l10n/l10n.dart';
import '../ui/icons/game_icon_kind.dart';
import '../ui/theme/game_tokens.dart';
import '../ui/widgets/bottom_feature_button.dart';

class MetaShortcuts extends StatelessWidget {
  const MetaShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (GameIconKind.album, l10n.navAlbum, '/album'),
      (GameIconKind.calendar, l10n.navDaily, '/daily'),
      (GameIconKind.shop, l10n.navShop, '/shop'),
      (GameIconKind.wheel, l10n.navWheel, '/wheel'),
      (GameIconKind.medal, l10n.navAwards, '/achievements'),
    ];
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: GameSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: GameSpacing.xs),
        itemBuilder: (context, i) {
          final item = items[i];
          return BottomFeatureButton(
            icon: item.$1,
            label: item.$2,
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.pushNamed(context, item.$3);
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../core/app_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/app_colors.dart';
import '../core/audio_manager.dart';
import '../l10n/l10n.dart';

class MetaShortcuts extends StatelessWidget {
  const MetaShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = [
      (LucideIcons.image, l10n.navAlbum, '/album'),
      (LucideIcons.calendar, l10n.navDaily, '/daily'),
      (LucideIcons.gift, l10n.navShop, '/shop'),
      (LucideIcons.ferrisWheel, l10n.navWheel, '/wheel'),
      (LucideIcons.medal, l10n.navAwards, '/achievements'),
    ];
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          return GestureDetector(
            onTap: () {
              AudioManager.instance.playClick();
              Navigator.pushNamed(context, item.$3);
            },
            child: Container(
              width: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceLight),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.$1, size: 20, color: AppColors.primary),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    style: AppFonts.style(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

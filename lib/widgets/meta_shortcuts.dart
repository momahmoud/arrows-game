import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/app_colors.dart';
import '../core/audio_manager.dart';

class MetaShortcuts extends StatelessWidget {
  const MetaShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (LucideIcons.image, 'Album', '/album'),
      (LucideIcons.calendar, 'Daily', '/daily'),
      (LucideIcons.gift, 'Shop', '/shop'),
      (LucideIcons.ferrisWheel, 'Wheel', '/wheel'),
      (LucideIcons.medal, 'Awards', '/achievements'),
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
                    style: GoogleFonts.nunito(
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

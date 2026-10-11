import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool isDark = false;

  static void updateTheme(bool dark) {
    isDark = dark;
  }

  // Brand. Light and dark share one purple primary and one gold accent.
  static Color get primary =>
      isDark ? const Color(0xFFA83ED1) : const Color(0xFF9C3ED1);
  static Color get primaryLight =>
      isDark ? const Color(0xFFC56EE8) : const Color(0xFFB45ADF);
  static Color get primaryDark =>
      isDark ? const Color(0xFF7A249E) : const Color(0xFF6E1F9A);
  static Color get accent => const Color(0xFFF5B82E);
  static Color get accentGold => const Color(0xFFF5B82E);
  static Color get accentGreen =>
      isDark ? const Color(0xFF35C96B) : const Color(0xFF32C768);
  static Color get accentOrange => const Color(0xFFE39B2B);

  // Backgrounds. Dark mode stays a deep green, never pure black.
  static Color get background =>
      isDark ? const Color(0xFF101610) : const Color(0xFFF7F4EC);
  static Color get surface =>
      isDark ? const Color(0xFF1D241E) : const Color(0xFFFFFFFF);
  static Color get elevated =>
      isDark ? const Color(0xFF252D26) : const Color(0xFFF0F0E9);
  static Color get surfaceLight =>
      isDark ? const Color(0xFF3A443C) : const Color(0xFFE4E1D6);
  static Color get gridBg => background;

  // Arrow direction colors — solid dark green for maximum legibility in light, clean cream/sage in dark
  static Color get arrowUp =>
      isDark ? const Color(0xFFECF0EB) : const Color(0xFF3C4636);
  static Color get arrowDown =>
      isDark ? const Color(0xFFECF0EB) : const Color(0xFF3C4636);
  static Color get arrowLeft =>
      isDark ? const Color(0xFFECF0EB) : const Color(0xFF3C4636);
  static Color get arrowRight =>
      isDark ? const Color(0xFFECF0EB) : const Color(0xFF3C4636);

  // Difficulty labels. The play button itself stays the purple primary.
  static Color get easy => accentGreen;
  static Color get medium => const Color(0xFF2E9A8A);
  static Color get hard => primary;
  static Color get expert => primaryDark;
  static Color get master => textPrimary;

  // Text
  static Color get textPrimary =>
      isDark ? const Color(0xFFF4F5EF) : const Color(0xFF263127);
  static Color get textSecondary =>
      isDark ? const Color(0xFFAAB2A8) : const Color(0xFF667064);
  static Color get textMuted =>
      isDark ? const Color(0xFF8E988C) : const Color(0xFF7A8478);

  // UI Elements
  static Color get heartRed => const Color(0xFFFF5A73);
  static Color get heartEmpty =>
      isDark ? const Color(0xFF3A443C) : const Color(0xFFD9D6CC);
  static Color get streakFire => const Color(0xFFF08A2A);
  static Color get coinGold => accent;
  static Color get starYellow => accent;
  static Color get borderGlow => primary;

  // ── Theme-aware Arrow Pair / Group Colors (12 Maximally Distant, Unconfusable Colors) ───
  // Ordered around the color wheel with max hue separation so pairs 0..N receive zero-confusion colors:
  // 0: Crimson Red, 1: Cobalt Blue, 2: Emerald Green, 3: Royal Purple, 4: Tangerine Orange, 5: Aqua Cyan,
  // 6: Hot Pink, 7: Sunflower Yellow, 8: Neon Lime Green, 9: Vibrant Teal, 10: Deep Indigo, 11: Rose Magenta
  static const List<Color> _groupColorsLight = [
    Color(0xFFE50914), // 0: Pure Crimson Red (Hue 0°)
    Color(0xFF0055FF), // 1: Electric Cobalt Blue (Hue 215°)
    Color(0xFF00A859), // 2: Emerald Mint Green (Hue 140°)
    Color(0xFF8E24AA), // 3: Deep Royal Purple (Hue 285°)
    Color(0xFFFF6D00), // 4: Pure Tangerine Orange (Hue 30°)
    Color(0xFF00B4D8), // 5: Bright Aqua Cyan (Hue 175°)
    Color(0xFFFF2A8D), // 6: Hot Bubblegum Pink (Hue 320°)
    Color(0xFFFFA000), // 7: Golden Sunflower Yellow (Hue 55°)
    Color(0xFF558B2F), // 8: Neon Lime Green (Hue 90°)
    Color(0xFF00897B), // 9: Vibrant Teal (Hue 160°)
    Color(0xFF3D5AFE), // 10: Deep Indigo Periwinkle (Hue 250°)
    Color(0xFFC2185B), // 11: Rose Magenta (Hue 345°)
  ];

  static const List<Color> _groupColorsDark = [
    Color(0xFFFF2A4B), // 0: Pure Crimson Red (Hue 0°)
    Color(0xFF2979FF), // 1: Electric Cobalt Blue (Hue 215°)
    Color(0xFF00E676), // 2: Emerald Mint Green (Hue 140°)
    Color(0xFFD500F9), // 3: Deep Royal Purple (Hue 285°)
    Color(0xFFFF8B00), // 4: Pure Tangerine Orange (Hue 30°)
    Color(0xFF00E5FF), // 5: Bright Aqua Cyan (Hue 175°)
    Color(0xFFFF52A1), // 6: Hot Bubblegum Pink (Hue 320°)
    Color(0xFFFFD600), // 7: Bright Sunflower Yellow (Hue 55°)
    Color(0xFFAEEA00), // 8: Neon Lime Green (Hue 90°)
    Color(0xFF1DE9B6), // 9: Vibrant Teal (Hue 160°)
    Color(0xFF7575FF), // 10: Deep Indigo Periwinkle (Hue 250°)
    Color(0xFFFF4081), // 11: Rose Magenta (Hue 345°)
  ];

  static Color getGroupColor(int groupIndex) {
    final list = isDark ? _groupColorsDark : _groupColorsLight;
    return list[groupIndex % list.length];
  }

  // Gradients
  static LinearGradient get primaryGradient => LinearGradient(
        colors: isDark
            ? [const Color(0xFFC56EE8), const Color(0xFFA83ED1)]
            : [const Color(0xFFB45ADF), const Color(0xFF9C3ED1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get secondaryGradient => LinearGradient(
        colors: isDark
            ? [const Color(0xFF2C352D), const Color(0xFF1D241E)]
            : [const Color(0xFFFFFFFF), const Color(0xFFF0F0E9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get bgGradient => LinearGradient(
        colors: isDark
            ? [const Color(0xFF182018), const Color(0xFF101610)]
            : [const Color(0xFFF7F4EC), const Color(0xFFEFEADF)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get successGradient => LinearGradient(
        colors: isDark
            ? [const Color(0xFF4AD67C), const Color(0xFF35C96B)]
            : [const Color(0xFF46D478), const Color(0xFF32C768)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get dangerGradient => const LinearGradient(
        colors: [Color(0xFFE15B5B), Color(0xFFC73E3E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

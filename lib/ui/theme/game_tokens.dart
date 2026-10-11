import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_fonts.dart';

/// Spacing on an 8px grid, plus the 4px and 12px half-steps used for tight UI.
class GameSpacing {
  GameSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
  static const double huge = 64;

  /// Smallest comfortable touch target.
  static const double touch = 48;
}

class GameMotion {
  GameMotion._();

  static const Duration press = Duration(milliseconds: 220);
  static const Duration tap = Duration(milliseconds: 140);
  static const Duration ctaPulse = Duration(milliseconds: 1100);
  static const Duration levelPulse = Duration(milliseconds: 1400);
  static const Duration badge = Duration(milliseconds: 900);
  static const Duration coin = Duration(milliseconds: 450);
  static const Duration starStep = Duration(milliseconds: 140);

  static bool reduce(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);
}

/// Gameplay header rhythm. Values scale with width so small phones still breathe.
class GameplayMetrics {
  GameplayMetrics._();

  static const double headerControlGap = 12;
  static const double coinPillPadding = 10;
  static const double heartSpacing = 10;
  static const double progressSpacing = 10;

  static double horizontalPadding(double width) {
    if (width <= 360) return GameSpacing.md;
    if (width >= 480) return GameSpacing.lg;
    return GameSpacing.md + (width - 360) / 120 * 8;
  }
}

class GameDims {
  GameDims._();

  static const double playHeight = 64;
  static const double journeyItem = 56;
  static const double journeyHeight = 92;
  static const double node = 36;
  static const double nodeCurrent = 52;
  static const double boosterWidth = 72;
  static const double boosterHeight = 64;
  static const double featureWidth = 76;
}

class GameRadius {
  GameRadius._();

  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

class GameIconSizes {
  GameIconSizes._();

  static const double xs = 18;
  static const double small = 26;
  static const double sm = 28;
  static const double nav = 30;
  static const double feature = 36;
  static const double md = 36;
  static const double booster = 40;
  static const double reward = 56;
  static const double lg = 56;
  static const double xl = 72;
  static const double xxl = 96;
}

/// Coin, reward, and button colors. Board ink stays in [AppColors].
class GameColors {
  GameColors._();

  static const Color coinHi = Color(0xFFFFF3C4);
  static const Color coin = Color(0xFFFFC83D);
  static const Color coinMid = Color(0xFFF0A51E);
  static const Color coinDeep = Color(0xFFC47A10);
  static const Color coinInk = Color(0xFF6B4108);

  static const Color leafHi = Color(0xFFD7F5C8);
  static const Color leaf = Color(0xFF3EAF62);
  static const Color leafDeep = Color(0xFF146B38);

  static const Color rewardHi = Color(0xFFFFE7A3);
  static const Color reward = Color(0xFFF5C14A);
  static const Color rewardDeep = Color(0xFFC47A10);

  static const Color premiumHi = Color(0xFFB7B0FF);
  static const Color premium = Color(0xFF5B4FE0);
  static const Color premiumDeep = Color(0xFF3226A0);

  static const Color heartHi = Color(0xFFFFB3C0);
  static const Color heart = Color(0xFFFF5A73);
  static const Color heartDeep = Color(0xFFD12648);

  static const Color gift = Color(0xFFFF5D6C);
  static const Color giftDeep = Color(0xFFD63A52);
  static const Color ribbon = Color(0xFFFFD15C);

  static const Color chest = Color(0xFFE39A45);
  static const Color chestDeep = Color(0xFFB56A22);

  static const Color sky = Color(0xFF7EC8FF);
  static const Color skyDeep = Color(0xFF2E86DE);

  static const Color cream = Color(0xFFFFF8EE);
  static const Color ink = Color(0xFF3C4636);

  static const Color missed = Color(0xFFB7A48A);

  static Color get text => AppColors.textPrimary;
  static Color get textMuted => AppColors.textMuted;
  static Color get surface => AppColors.surface;
  static Color get line => AppColors.surfaceLight;
}

class GameShadows {
  GameShadows._();

  static List<BoxShadow> lift(Color color, {double alpha = 0.28}) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> card() => [
        BoxShadow(
          color: Colors.black.withValues(alpha: AppColors.isDark ? 0.28 : 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
}

class GameButtonStyles {
  GameButtonStyles._();

  /// Highlight, face, depth lip. Primary follows the theme purple.
  static List<Color> get primary {
    final face = AppColors.primary;
    return [
      Color.lerp(face, Colors.white, 0.28)!,
      face,
      AppColors.primaryDark,
    ];
  }

  static List<Color> get secondary => AppColors.isDark
      ? const [
          Color(0xFF323B33),
          Color(0xFF252D26),
          Color(0xFF161C17),
        ]
      : const [
          Color(0xFFFFFFFF),
          Color(0xFFF0F0E9),
          Color(0xFFD5D4CB),
        ];

  static const List<Color> reward = [
    Color(0xFFFFE08A),
    Color(0xFFF5B82E),
    Color(0xFFC47A10),
  ];

  static const List<Color> premium = [
    Color(0xFFC56EE8),
    Color(0xFF9C3ED1),
    Color(0xFF6E1F9A),
  ];
}

class GameTypography {
  GameTypography._();

  static TextStyle display(Color color) => AppFonts.style(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
      );

  static TextStyle title(Color color) => AppFonts.style(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.15,
      );

  static TextStyle level(Color color) => AppFonts.style(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
      );

  static TextStyle section(Color color) => AppFonts.style(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.2,
      );

  static TextStyle button(Color color) => AppFonts.style(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
      );

  static TextStyle body(Color color) => AppFonts.style(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static TextStyle caption(Color color) => AppFonts.style(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );

  static TextStyle amount(Color color) => AppFonts.style(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1,
      );
}

class GameDecor {
  GameDecor._();

  static BoxDecoration card({bool highlight = false, Color? tint}) {
    return BoxDecoration(
      color: tint ?? GameColors.surface,
      borderRadius: BorderRadius.circular(GameRadius.lg),
      border: Border.all(
        color: highlight ? GameColors.coinDeep : GameColors.line,
        width: highlight ? 2 : 1,
      ),
      boxShadow: GameShadows.card(),
    );
  }
}

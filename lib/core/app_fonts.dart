import 'package:flutter/material.dart';

/// Single app typeface; covers both Latin and Arabic glyphs.
class AppFonts {
  AppFonts._();

  static const String family = 'PlaypenSansArabic';

  /// Set from the active locale; tracking pulls Arabic's joined letters apart.
  static bool isArabic = false;

  static TextStyle style({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
    TextDecoration? decoration,
  }) {
    return (textStyle ?? const TextStyle()).copyWith(
      fontFamily: family,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: isArabic ? 0 : letterSpacing,
      height: height,
      shadows: shadows,
      decoration: decoration,
    );
  }

  static TextTheme textTheme(TextTheme base) =>
      base.apply(fontFamily: family);
}

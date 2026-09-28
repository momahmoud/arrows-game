import 'package:flutter/material.dart';

/// Arrow body looks. Classic keeps the default puzzle colors.
enum ArrowSkin { classic, neon, wood, candy, space }

/// Playfield wash behind the dots.
enum BoardTheme { classic, neon, wood, candy, space }

class CosmeticOffer {
  final String id;
  final String name;
  final String blurb;
  final int coinCost;
  final int unlockLevel;
  final bool isSkin;
  final ArrowSkin? skin;
  final BoardTheme? theme;

  const CosmeticOffer({
    required this.id,
    required this.name,
    required this.blurb,
    required this.coinCost,
    required this.unlockLevel,
    required this.isSkin,
    this.skin,
    this.theme,
  });
}

/// Unlock costs and palettes for arrow skins and board themes.
class BoardStyle {
  BoardStyle._();

  static const offers = <CosmeticOffer>[
    CosmeticOffer(
      id: 'skin_classic',
      name: 'Classic arrows',
      blurb: 'The original ink',
      coinCost: 0,
      unlockLevel: 1,
      isSkin: true,
      skin: ArrowSkin.classic,
    ),
    CosmeticOffer(
      id: 'skin_neon',
      name: 'Neon arrows',
      blurb: 'Glow-stick colors',
      coinCost: 500,
      unlockLevel: 10,
      isSkin: true,
      skin: ArrowSkin.neon,
    ),
    CosmeticOffer(
      id: 'skin_wood',
      name: 'Wood arrows',
      blurb: 'Carved timber',
      coinCost: 800,
      unlockLevel: 25,
      isSkin: true,
      skin: ArrowSkin.wood,
    ),
    CosmeticOffer(
      id: 'skin_candy',
      name: 'Candy arrows',
      blurb: 'Sugar-bright',
      coinCost: 1200,
      unlockLevel: 50,
      isSkin: true,
      skin: ArrowSkin.candy,
    ),
    CosmeticOffer(
      id: 'skin_space',
      name: 'Space arrows',
      blurb: 'Deep-orbit glow',
      coinCost: 2000,
      unlockLevel: 100,
      isSkin: true,
      skin: ArrowSkin.space,
    ),
    CosmeticOffer(
      id: 'theme_classic',
      name: 'Classic board',
      blurb: 'Quiet paper',
      coinCost: 0,
      unlockLevel: 1,
      isSkin: false,
      theme: BoardTheme.classic,
    ),
    CosmeticOffer(
      id: 'theme_neon',
      name: 'Neon board',
      blurb: 'Night-market grid',
      coinCost: 500,
      unlockLevel: 10,
      isSkin: false,
      theme: BoardTheme.neon,
    ),
    CosmeticOffer(
      id: 'theme_wood',
      name: 'Wood board',
      blurb: 'Warm tabletop',
      coinCost: 800,
      unlockLevel: 25,
      isSkin: false,
      theme: BoardTheme.wood,
    ),
    CosmeticOffer(
      id: 'theme_candy',
      name: 'Candy board',
      blurb: 'Pastel sugar',
      coinCost: 1200,
      unlockLevel: 50,
      isSkin: false,
      theme: BoardTheme.candy,
    ),
    CosmeticOffer(
      id: 'theme_space',
      name: 'Space board',
      blurb: 'Starfield',
      coinCost: 2000,
      unlockLevel: 100,
      isSkin: false,
      theme: BoardTheme.space,
    ),
  ];

  static CosmeticOffer? offerById(String id) {
    for (final offer in offers) {
      if (offer.id == id) return offer;
    }
    return null;
  }

  static String skinId(ArrowSkin skin) => 'skin_${skin.name}';

  static String themeId(BoardTheme theme) => 'theme_${theme.name}';

  static bool unlockedByProgress(CosmeticOffer offer, int highestLevel) =>
      highestLevel >= offer.unlockLevel;

  static const _neon = [
    Color(0xFF00E5FF),
    Color(0xFFFF2BD6),
    Color(0xFFB2FF59),
    Color(0xFFFFEA00),
  ];
  static const _wood = [
    Color(0xFF8D6E63),
    Color(0xFF6D4C41),
    Color(0xFFA1887F),
    Color(0xFF5D4037),
  ];
  static const _candy = [
    Color(0xFFFF4081),
    Color(0xFF7C4DFF),
    Color(0xFF18FFFF),
    Color(0xFFFFAB40),
  ];
  static const _space = [
    Color(0xFF7C4DFF),
    Color(0xFF18FFFF),
    Color(0xFFE040FB),
    Color(0xFF536DFE),
  ];

  static List<Color> _palette(ArrowSkin skin) {
    switch (skin) {
      case ArrowSkin.classic:
        return const [];
      case ArrowSkin.neon:
        return _neon;
      case ArrowSkin.wood:
        return _wood;
      case ArrowSkin.candy:
        return _candy;
      case ArrowSkin.space:
        return _space;
    }
  }

  /// Recolors an arrow. Paired arrows keep enough of their group hue to match.
  static Color tintArrow(
    ArrowSkin skin,
    Color base, {
    int salt = 0,
    bool paired = false,
  }) {
    if (skin == ArrowSkin.classic) return base;
    final palette = _palette(skin);
    final accent = palette[salt.abs() % palette.length];
    if (paired) return Color.lerp(base, accent, 0.42)!;
    return accent;
  }

  static Color cellWash(BoardTheme theme) {
    switch (theme) {
      case BoardTheme.classic:
        return const Color(0x00000000);
      case BoardTheme.neon:
        return const Color(0x3300E5FF);
      case BoardTheme.wood:
        return const Color(0x33A1887F);
      case BoardTheme.candy:
        return const Color(0x33FF80AB);
      case BoardTheme.space:
        return const Color(0x337C4DFF);
    }
  }

  static Color dotColor(BoardTheme theme, bool dark) {
    switch (theme) {
      case BoardTheme.classic:
        return dark ? const Color(0x3CFFFFFF) : const Color(0xFFC8BFB0);
      case BoardTheme.neon:
        return const Color(0xFF39FF14);
      case BoardTheme.wood:
        return const Color(0xFF6D4C41);
      case BoardTheme.candy:
        return const Color(0xFFFF80AB);
      case BoardTheme.space:
        return const Color(0xFFB388FF);
    }
  }

  static LinearGradient playfield(BoardTheme theme) {
    switch (theme) {
      case BoardTheme.classic:
        return const LinearGradient(colors: [Color(0xFFFAF6F0), Color(0xFFF3EDE3)]);
      case BoardTheme.neon:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1026), Color(0xFF141A3A)],
        );
      case BoardTheme.wood:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE7D3B0), Color(0xFFC4A574)],
        );
      case BoardTheme.candy:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF1F6), Color(0xFFE8F7FF)],
        );
      case BoardTheme.space:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF070B18), Color(0xFF1A1030)],
        );
    }
  }

  static List<Color> introColors(bool god) {
    if (god) {
      return const [Color(0xFF1A0A12), Color(0xFF6A1B2A), Color(0xFFE2B93C)];
    }
    return const [Color(0xFF14081F), Color(0xFF4A148C), Color(0xFFCE93D8)];
  }
}

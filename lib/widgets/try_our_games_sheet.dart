// Portable "Try our games" bottom sheet — copy this file to any Fluxy game.
// Dependencies: flutter, url_launcher
//
// 1. Edit [TryOurGamesConfig] below (current app ids, colors, games list, copy).
// 2. Optional: [TryOurGamesIntroButton] on intro (optional [glowAnimation]).
// 3. Add [TryOurGamesGridTile] to your categories grid (e.g. last unlocked slot).

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── CONFIG — edit when copying to another game ───────────────────────────

abstract final class TryOurGamesConfig {
  /// This app's package / App Store id (excluded from the promo list).
  static const String currentAndroidPackage = 'com.arrows.fluxylabs';
  static const String currentIosAppId = '';

  static const String publisherSearchQuery = 'Fluxy';
  static const String websiteUrl = 'https://fluxy.com';
  static const String androidDeveloperUrl =
      'https://play.google.com/store/apps/dev?id=8242447087586573484';

  static const Color sheetBackground = Color(0xFF261852);
  static const Color accent = Color(0xFFFF6B35);
  static const Color accentSecondary = Color(0xFF06D6A0);
  static const Color accentTertiary = Color(0xFF3A86FF);

  static const String titleEn = 'Try our games';
  static const String titleAr = 'جرّب ألعابنا';
  static const String subtitleEn = 'Discover more games from Fluxy';
  static const String subtitleAr = 'اكتشف المزيد من ألعاب Fluxy';
  static const String comingSoonEn = 'More games coming soon';
  static const String comingSoonAr = 'المزيد من الألعاب قريباً';
  static const String browseAllEn = 'Browse all on Store';
  static const String browseAllAr = 'تصفّح الكل في المتجر';
  static const String getEn = 'Get';
  static const String getAr = 'حمّل';
  static const String comingSoonItemEn = 'Coming soon';
  static const String comingSoonItemAr = 'قريباً';
  static const String featuredEn = 'Featured';
  static const String featuredAr = 'مميّزة';
  static const String allGamesEn = 'All games';
  static const String allGamesAr = 'كل الألعاب';

  static const String _gamesIconBase = 'assets/images/games';

  /// Fluxy games catalog. [promotableGames] hides the current app automatically.
  static const List<FluxyGameEntry> games = <FluxyGameEntry>[
    FluxyGameEntry(
      androidPackageName: 'com.fluxy.salfah',
      iosAppId: '6758549313',
      nameEn: 'Salfah: Spy Party',
      nameAr: 'الجاسوس: برا السالفة & امبوستر',
      subtitleEn: 'Imposter & spy word game',
      subtitleAr: 'لعبة الجاسوس والكلمات',
      iconAsset: '$_gamesIconBase/salfah.png',
    ),
    FluxyGameEntry(
      androidPackageName: 'com.fluxy.x_blocks',
      iosAppId: '',
      nameEn: '2248: Number Match',
      nameAr: '2248: العاب ارقام',
      subtitleEn: 'Merge numbers puzzle',
      subtitleAr: 'لغز دمج الأرقام',
      iconAsset: '$_gamesIconBase/x_blocks.png',
      featured: true,
    ),
    FluxyGameEntry(
      androidPackageName: 'com.arrows.fluxylabs',
      iosAppId: '',
      nameEn: 'Arrow Puzzle',
      nameAr: 'Arrow Puzzle: لغز الأسهم',
      subtitleEn: 'Brain-teasing arrow puzzles',
      subtitleAr: 'ألغاز الأسهم لتدريب العقل',
      iconAsset: '$_gamesIconBase/arrow_puzzle.png',
    ),
    FluxyGameEntry(
      androidPackageName: 'com.fluxy.knowledge_challenge',
      iosAppId: '',
      nameEn: 'Quizzy',
      nameAr: 'Quizzy: عرب كويز الغاز عبقري',
      subtitleEn: 'Arabic quiz & trivia',
      subtitleAr: 'أسئلة ثقافة عامة وتحديات',
      iconAsset: '$_gamesIconBase/knowledge_challenge.png',
    ),
    FluxyGameEntry(
      androidPackageName: 'com.elaskry.dream_sort',
      iosAppId: '',
      nameEn: 'Ball Sort',
      nameAr: 'ترتيب الألوان: لغز فرز الكرات',
      subtitleEn: 'Color ball sort puzzle',
      subtitleAr: 'لغز فرز الكرات والألوان',
      iconAsset: '$_gamesIconBase/dream_sort.png',
    ),
    FluxyGameEntry(
      androidPackageName: 'com.fluxy.kalema_iq',
      iosAppId: '',
      nameEn: 'Kalema IQ',
      nameAr: 'كلمة وذكاء: تحدي الكلمات',
      subtitleEn: 'Word & brain challenge',
      subtitleAr: 'تحدي الكلمات والذكاء',
      iconAsset: '$_gamesIconBase/kalema_iq.png',
    ),
    // In closed testing: shown as "Coming soon" with no store link. Remove
    // `comingSoon: true` when a game goes to production.
    FluxyGameEntry(
      androidPackageName: 'com.fluxylabs.animals_match',
      iosAppId: '',
      nameEn: 'Animal Match',
      nameAr: 'مطابقة الحيوانات',
      subtitleEn: 'Match the animal pairs',
      subtitleAr: 'طابق أزواج الحيوانات',
      iconAsset: '$_gamesIconBase/animals_match.png',
      comingSoon: true,
    ),
    FluxyGameEntry(
      androidPackageName: 'com.fluxylabs.block_move',
      iosAppId: '',
      nameEn: 'Block Out',
      nameAr: 'Block Out: ألغاز البلوكات',
      subtitleEn: 'Block-sliding puzzles',
      subtitleAr: 'ألغاز تحريك البلوكات',
      iconAsset: '$_gamesIconBase/block_move.png',
      comingSoon: true,
    ),
    FluxyGameEntry(
      androidPackageName: 'com.fluxylabs.word_connect',
      iosAppId: '',
      nameEn: 'Hallaha',
      nameAr: 'حلّها: ألغاز الكلمات',
      subtitleEn: 'Arabic word puzzles',
      subtitleAr: 'كلمات وألغاز عربية',
      iconAsset: '$_gamesIconBase/word_connect.png',
      comingSoon: true,
    ),
  ];

  static String title(String languageCode) =>
      _isEnglish(languageCode) ? titleEn : titleAr;

  static String subtitle(String languageCode) =>
      _isEnglish(languageCode) ? subtitleEn : subtitleAr;

  static String comingSoon(String languageCode) =>
      _isEnglish(languageCode) ? comingSoonEn : comingSoonAr;

  static String browseAll(String languageCode) =>
      _isEnglish(languageCode) ? browseAllEn : browseAllAr;

  static String getLabel(String languageCode) =>
      _isEnglish(languageCode) ? getEn : getAr;

  static String comingSoonItemLabel(String languageCode) =>
      _isEnglish(languageCode) ? comingSoonItemEn : comingSoonItemAr;

  static String featuredLabel(String languageCode) =>
      _isEnglish(languageCode) ? featuredEn : featuredAr;

  static String allGamesLabel(String languageCode) =>
      _isEnglish(languageCode) ? allGamesEn : allGamesAr;

  static List<FluxyGameEntry> get promotableGames {
    bool isCurrentApp(FluxyGameEntry game) =>
        game.androidPackageName == currentAndroidPackage ||
        (game.iosAppId.isNotEmpty && game.iosAppId == currentIosAppId);

    final Iterable<FluxyGameEntry> visible = games.where(
      (FluxyGameEntry game) => !isCurrentApp(game),
    );

    final List<FluxyGameEntry> released = visible
        .where((FluxyGameEntry game) => !game.comingSoon)
        .toList(growable: false);
    final List<FluxyGameEntry> comingSoonGames = visible
        .where((FluxyGameEntry game) => game.comingSoon)
        .toList(growable: false);

    return <FluxyGameEntry>[...released, ...comingSoonGames];
  }

  /// Games that are live on the store (everything except coming soon).
  static List<FluxyGameEntry> get releasedGames => promotableGames
      .where((FluxyGameEntry game) => !game.comingSoon)
      .toList(growable: false);

  /// Games still in testing; shown dimmed with no store link.
  static List<FluxyGameEntry> get upcomingGames => promotableGames
      .where((FluxyGameEntry game) => game.comingSoon)
      .toList(growable: false);

  /// The hero card at the top of the sheet: the released game marked
  /// `featured`, else the first released one.
  static FluxyGameEntry? get featuredGame {
    final List<FluxyGameEntry> released = releasedGames;
    for (final FluxyGameEntry game in released) {
      if (game.featured) return game;
    }
    return released.isEmpty ? null : released.first;
  }

  /// Up to 3 icons for promo buttons (released games with assets first).
  static List<FluxyGameEntry> get featuredPromoGames {
    final List<FluxyGameEntry> withIcons = promotableGames
        .where(
          (FluxyGameEntry g) => g.iconAsset != null && g.iconAsset!.isNotEmpty,
        )
        .toList(growable: false);
    final List<FluxyGameEntry> released = withIcons
        .where((FluxyGameEntry g) => !g.comingSoon)
        .toList(growable: false);
    if (released.length >= 2) {
      return released.take(3).toList(growable: false);
    }
    return withIcons.take(3).toList(growable: false);
  }

  static String gamesCountLabel(String languageCode, int count) =>
      _isEnglish(languageCode) ? '$count games' : '$count ألعاب';

  static bool _isEnglish(String languageCode) =>
      languageCode.toLowerCase().startsWith('en');

  static bool isRtlLanguage(String languageCode) =>
      languageCode.toLowerCase().startsWith('ar');
}

// ─── Model ──────────────────────────────────────────────────────────────────

class FluxyGameEntry {
  const FluxyGameEntry({
    required this.androidPackageName,
    required this.iosAppId,
    required this.nameEn,
    required this.nameAr,
    required this.subtitleEn,
    required this.subtitleAr,
    this.iconAsset,
    this.comingSoon = false,
    this.featured = false,
  });

  final String androidPackageName;
  final String iosAppId;
  final String nameEn;
  final String nameAr;
  final String subtitleEn;
  final String subtitleAr;
  final String? iconAsset;
  final bool comingSoon;
  final bool featured;

  String nameFor(String languageCode) =>
      TryOurGamesConfig._isEnglish(languageCode) ? nameEn : nameAr;

  String subtitleFor(String languageCode) =>
      TryOurGamesConfig._isEnglish(languageCode) ? subtitleEn : subtitleAr;
}

// ─── Store links ────────────────────────────────────────────────────────────

abstract final class _TryOurGamesStore {
  static Future<void> openGame(FluxyGameEntry game) async {
    if (game.comingSoon) return;

    if (Platform.isIOS) {
      final Uri url = game.iosAppId.isNotEmpty
          ? Uri.parse('https://apps.apple.com/app/id${game.iosAppId}')
          : Uri.parse(
              'https://apps.apple.com/us/search?term='
              '${Uri.encodeComponent(game.nameEn)}',
            );
      await _launch(url);
      return;
    }

    final String package = game.androidPackageName;
    final Uri marketUrl = Uri.parse('market://details?id=$package');
    if (await canLaunchUrl(marketUrl)) {
      await launchUrl(marketUrl, mode: LaunchMode.externalApplication);
      return;
    }

    await _launch(
      Uri.parse('https://play.google.com/store/apps/details?id=$package'),
    );
  }

  static Future<void> openCatalog() async {
    final Uri url;
    if (Platform.isAndroid) {
      url = Uri.parse(TryOurGamesConfig.androidDeveloperUrl);
    } else if (Platform.isIOS) {
      url = Uri.parse(
        'https://apps.apple.com/us/search?term='
        '${Uri.encodeComponent(TryOurGamesConfig.publisherSearchQuery)}',
      );
    } else {
      url = Uri.parse(TryOurGamesConfig.websiteUrl);
    }
    await _launch(url);
  }

  static Future<void> _launch(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return;
    }
    if (kDebugMode) {
      debugPrint('TryOurGamesSheet: Could not launch $url');
    }
  }
}

/// Stable accent per game. Sums code units: String.hashCode isn't
/// guaranteed to be the same between runs.
Color _gameAccent(String packageName) {
  const List<Color> accents = <Color>[
    TryOurGamesConfig.accentSecondary,
    TryOurGamesConfig.accentTertiary,
    TryOurGamesConfig.accent,
  ];
  final int sum = packageName.codeUnits.fold<int>(0, (int a, int b) => a + b);
  return accents[sum % accents.length];
}

// ─── UI ─────────────────────────────────────────────────────────────────────

class TryOurGamesSheet extends StatelessWidget {
  const TryOurGamesSheet({super.key, this.languageCode, this.isRtl});

  final String? languageCode;
  final bool? isRtl;

  /// Opens the bottom sheet. Pass [languageCode] / [isRtl] to override locale.
  static Future<void> show(
    BuildContext context, {
    String? languageCode,
    bool? isRtl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) =>
          TryOurGamesSheet(languageCode: languageCode, isRtl: isRtl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String lang =
        languageCode ?? Localizations.localeOf(context).languageCode;
    final bool rtl = isRtl ?? Directionality.of(context) == TextDirection.rtl;

    final FluxyGameEntry? featured = TryOurGamesConfig.featuredGame;
    final List<FluxyGameEntry> released = TryOurGamesConfig.releasedGames
        .where((FluxyGameEntry g) => g != featured)
        .toList(growable: false);
    final List<FluxyGameEntry> upcoming = TryOurGamesConfig.upcomingGames;
    final bool isEmpty =
        featured == null && released.isEmpty && upcoming.isEmpty;

    // Running index so the entrance stagger continues across sections.
    int step = 0;
    int next() => step++;

    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color.lerp(
                  TryOurGamesConfig.sheetBackground,
                  TryOurGamesConfig.accent,
                  0.07,
                )!,
                TryOurGamesConfig.sheetBackground,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _SheetHeader(languageCode: lang),
                Flexible(
                  child: isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            TryOurGamesConfig.comingSoon(lang),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            20,
                            4,
                            20,
                            8,
                          ),
                          children: <Widget>[
                            if (featured != null)
                              _Entrance(
                                step: next(),
                                child: _FeaturedGameCard(
                                  game: featured,
                                  languageCode: lang,
                                ),
                              ),
                            if (released.isNotEmpty) ...<Widget>[
                              _SectionLabel(
                                TryOurGamesConfig.allGamesLabel(lang),
                              ),
                              for (final FluxyGameEntry game in released)
                                _Entrance(
                                  step: next(),
                                  child: _GameRow(
                                    game: game,
                                    languageCode: lang,
                                  ),
                                ),
                            ],
                            if (upcoming.isNotEmpty) ...<Widget>[
                              _SectionLabel(
                                TryOurGamesConfig.comingSoonItemLabel(lang),
                              ),
                              for (final FluxyGameEntry game in upcoming)
                                _Entrance(
                                  step: next(),
                                  child: _GameRow(
                                    game: game,
                                    languageCode: lang,
                                  ),
                                ),
                            ],
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _TryOurGamesStore.openCatalog,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.storefront_rounded, size: 20),
                      label: Text(
                        TryOurGamesConfig.browseAll(lang),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 8, 14),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  TryOurGamesConfig.accent,
                  Color.lerp(
                    TryOurGamesConfig.accent,
                    TryOurGamesConfig.accentSecondary,
                    0.55,
                  )!,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  TryOurGamesConfig.title(languageCode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  TryOurGamesConfig.subtitle(languageCode),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, top: 20, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Fades and lifts a child in, one step after the previous one.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.step, required this.child});

  final int step;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 40 * step),
          duration: const Duration(milliseconds: 280),
        )
        .slideY(
          begin: 0.08,
          end: 0,
          delay: Duration(milliseconds: 40 * step),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
  }
}

/// Tap target with a small press-down scale and a haptic tick.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.onTap,
    required this.radius,
    required this.child,
    this.splash,
  });

  final VoidCallback? onTap;
  final double radius;
  final Widget child;
  final Color? splash;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap != null && _pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(widget.radius),
        child: InkWell(
          onTap: widget.onTap == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  widget.onTap!();
                },
          onTapDown: (_) => _set(true),
          onTapUp: (_) => _set(false),
          onTapCancel: () => _set(false),
          borderRadius: BorderRadius.circular(widget.radius),
          splashColor: widget.splash,
          highlightColor: Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Rounded app icon with a soft accent glow.
class _GameIconBox extends StatelessWidget {
  const _GameIconBox({
    required this.game,
    required this.accent,
    required this.size,
  });

  final FluxyGameEntry game;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Color accentAlt = Color.lerp(accent, Colors.white, 0.35)!;
    final double radius = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: game.comingSoon ? 0.12 : 0.32),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: _GameIconImage(
          iconAsset: game.iconAsset,
          accent: accent,
          accentAlt: accentAlt,
          size: size,
        ),
      ),
    );
  }
}

/// Hero card for the featured game: big icon, short pitch, Get button.
class _FeaturedGameCard extends StatelessWidget {
  const _FeaturedGameCard({required this.game, required this.languageCode});

  final FluxyGameEntry game;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final Color accent = _gameAccent(game.androidPackageName);
    final String name = game.nameFor(languageCode);
    final String subtitle = game.subtitleFor(languageCode);

    return Semantics(
      button: true,
      label: '$name. $subtitle',
      excludeSemantics: true,
      child: _Pressable(
        onTap: () => _TryOurGamesStore.openGame(game),
        radius: 24,
        splash: accent.withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.lerp(TryOurGamesConfig.sheetBackground, accent, 0.34)!,
                Color.lerp(TryOurGamesConfig.sheetBackground, accent, 0.1)!,
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.5)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: accent.withValues(alpha: 0.22),
                blurRadius: 22,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _GameIconBox(game: game, accent: accent, size: 84),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFFFC107,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: Color(0xFFFFD54F),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                TryOurGamesConfig.featuredLabel(languageCode),
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 13.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _GetButton(
                label: TryOurGamesConfig.getLabel(languageCode),
                accent: accent,
                expand: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One game: icon, name, one-line pitch, and Get / Coming soon on the end.
class _GameRow extends StatelessWidget {
  const _GameRow({required this.game, required this.languageCode});

  final FluxyGameEntry game;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final bool comingSoon = game.comingSoon;
    final Color accent = _gameAccent(game.androidPackageName);
    final String name = game.nameFor(languageCode);
    final String subtitle = game.subtitleFor(languageCode);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: !comingSoon,
        label: comingSoon
            ? '$name. $subtitle. ${TryOurGamesConfig.comingSoonItemLabel(languageCode)}'
            : '$name. $subtitle',
        excludeSemantics: true,
        child: Opacity(
          opacity: comingSoon ? 0.78 : 1,
          child: _Pressable(
            onTap: comingSoon ? null : () => _TryOurGamesStore.openGame(game),
            radius: 20,
            splash: accent.withValues(alpha: 0.12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: comingSoon
                      ? Colors.white.withValues(alpha: 0.06)
                      : accent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: <Widget>[
                  _GameIconBox(game: game, accent: accent, size: 58),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.62),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (comingSoon)
                    _GameStatusChip(languageCode: languageCode)
                  else
                    _GetButton(
                      label: TryOurGamesConfig.getLabel(languageCode),
                      accent: accent,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Visual "Get" button. The whole card/row is the tap target, so this only
/// draws; it doesn't handle taps itself.
class _GetButton extends StatelessWidget {
  const _GetButton({
    required this.label,
    required this.accent,
    this.expand = false,
  });

  final String label;
  final Color accent;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final Widget content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.download_rounded, size: 18, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ],
    );
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: expand ? 16 : 14,
        vertical: expand ? 13 : 9,
      ),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(expand ? 16 : 14),
      ),
      child: content,
    );
  }
}

// ─── Shared promo visuals ─────────────────────────────────────────────────────

enum _PromoIconClusterLayout { stack, fan }

class _PromoGamesIconCluster extends StatelessWidget {
  const _PromoGamesIconCluster({
    required this.iconSize,
    this.overlap = 16,
    this.fallbackColor = TryOurGamesConfig.accentSecondary,
    this.layout = _PromoIconClusterLayout.stack,
  });

  final double iconSize;
  final double overlap;
  final Color fallbackColor;
  final _PromoIconClusterLayout layout;

  @override
  Widget build(BuildContext context) {
    final List<FluxyGameEntry> featured = TryOurGamesConfig.featuredPromoGames;

    if (featured.isEmpty) {
      return _fallbackIcon();
    }

    if (layout == _PromoIconClusterLayout.fan && featured.length > 1) {
      return _buildFanLayout(context, featured);
    }

    final double width = iconSize + overlap * (featured.length - 1);

    return SizedBox(
      width: width,
      height: iconSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (int i = 0; i < featured.length; i++)
            PositionedDirectional(
              start: i * overlap,
              child: _miniIcon(featured[i], i),
            ),
        ],
      ),
    );
  }

  Widget _buildFanLayout(BuildContext context, List<FluxyGameEntry> featured) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final double sideScale = 0.86;
    final double sideIconSize = iconSize * sideScale;
    final double width = iconSize + sideIconSize * 0.92;
    final double height = iconSize * 1.08;

    Widget sideIcon(FluxyGameEntry game, {required bool isStart}) {
      final double tilt = isStart ? -0.14 : 0.14;
      return Transform.rotate(
        angle: rtl ? -tilt : tilt,
        child: _miniIcon(game, 0, scale: sideScale),
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          if (featured.length >= 2)
            PositionedDirectional(
              start: 0,
              bottom: 2,
              child: sideIcon(featured[1], isStart: true),
            ),
          if (featured.length >= 3)
            PositionedDirectional(
              end: 0,
              bottom: 2,
              child: sideIcon(featured[2], isStart: false),
            ),
          Transform.translate(
            offset: const Offset(0, -3),
            child: _miniIcon(featured.first, 2),
          ),
        ],
      ),
    );
  }

  Widget _miniIcon(FluxyGameEntry game, int index, {double scale = 1}) {
    final double size = iconSize * scale;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: Colors.white.withValues(alpha: index >= 2 ? 0.38 : 0.24),
          width: index >= 2 ? 2 : 1.5,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: index >= 2 ? 10 : 6,
            offset: Offset(0, 2 + index.toDouble()),
          ),
          if (index >= 2)
            BoxShadow(
              color: fallbackColor.withValues(alpha: 0.22),
              blurRadius: 14,
              spreadRadius: -2,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: game.iconAsset != null
            ? Image.asset(
                game.iconAsset!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _fallbackIcon(small: true, scale: scale),
              )
            : _fallbackIcon(small: true, scale: scale),
      ),
    );
  }

  Widget _fallbackIcon({bool small = false, double scale = 1}) {
    final double size = iconSize * (small ? scale : 1);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[TryOurGamesConfig.accentTertiary, fallbackColor],
        ),
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      child: Icon(
        Icons.sports_esports_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }
}

class _PromoTileBackdrop extends StatelessWidget {
  const _PromoTileBackdrop({required this.accent, required this.accentAlt});

  final Color accent;
  final Color accentAlt;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          top: -28,
          left: -18,
          child: Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  accentAlt.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -16,
          right: -12,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: <Color>[
                  accent.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 18,
          right: 14,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 11,
            color: TryOurGamesConfig.accentTertiary.withValues(alpha: 0.35),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 16,
          child: Icon(
            Icons.circle,
            size: 4,
            color: accent.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _PromoGamesCountBadge extends StatelessWidget {
  const _PromoGamesCountBadge({
    required this.languageCode,
    required this.accent,
    this.compact = false,
    this.prominent = false,
  });

  final String languageCode;
  final Color accent;
  final bool compact;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final int count = TryOurGamesConfig.releasedGames.length;
    final double fontSize = prominent ? 10 : (compact ? 9 : 10);
    final double iconSize = prominent ? 12 : (compact ? 10 : 12);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          prominent ? 12 : (compact ? 8 : 10),
        ),
        gradient: prominent
            ? LinearGradient(
                colors: <Color>[
                  accent.withValues(alpha: 0.28),
                  TryOurGamesConfig.accentTertiary.withValues(alpha: 0.18),
                ],
              )
            : null,
        color: prominent ? null : accent.withValues(alpha: 0.18),
        border: Border.all(
          color: accent.withValues(alpha: prominent ? 0.55 : 0.4),
        ),
        boxShadow: prominent
            ? <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: prominent ? 8 : (compact ? 6 : 8),
          vertical: prominent ? 4 : (compact ? 2 : 3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.grid_view_rounded, size: iconSize, color: accent),
            SizedBox(width: prominent ? 4 : (compact ? 3 : 4)),
            Text(
              TryOurGamesConfig.gamesCountLabel(languageCode, count),
              style: TextStyle(
                color: accent,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: prominent ? 0.2 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Intro promo button ─────────────────────────────────────────────────────

class TryOurGamesIntroButton extends StatelessWidget {
  const TryOurGamesIntroButton({
    super.key,
    this.glowAnimation,
    this.languageCode,
    this.isRtl,
  });

  /// Optional pulse synced with intro logo glow; defaults to a steady look.
  final Animation<double>? glowAnimation;
  final String? languageCode;
  final bool? isRtl;

  @override
  Widget build(BuildContext context) {
    final String resolvedLanguageCode =
        languageCode ?? Localizations.localeOf(context).languageCode;
    final bool rtl =
        isRtl ?? TryOurGamesConfig.isRtlLanguage(resolvedLanguageCode);

    Widget buildCard(double glow) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            TryOurGamesSheet.show(
              context,
              languageCode: resolvedLanguageCode,
              isRtl: rtl,
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  Color.lerp(
                    TryOurGamesConfig.sheetBackground,
                    TryOurGamesConfig.accentTertiary,
                    0.35 + (glow * 0.08),
                  )!,
                  Color.lerp(
                    TryOurGamesConfig.sheetBackground,
                    TryOurGamesConfig.accentSecondary,
                    0.2 + (glow * 0.06),
                  )!,
                ],
              ),
              border: Border.all(
                color: TryOurGamesConfig.accentSecondary.withValues(
                  alpha: 0.38 + (glow * 0.25),
                ),
                width: 1.5,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: TryOurGamesConfig.accentSecondary.withValues(
                    alpha: 0.12 + (glow * 0.14),
                  ),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          TryOurGamesConfig.accentTertiary,
                          TryOurGamesConfig.accentSecondary,
                          TryOurGamesConfig.accent,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Directionality(
                      textDirection:
                          rtl ? TextDirection.rtl : TextDirection.ltr,
                      child: Row(
                        children: <Widget>[
                          _PromoGamesIconCluster(iconSize: 40, overlap: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        TryOurGamesConfig.title(
                                          resolvedLanguageCode,
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    _PromoGamesCountBadge(
                                      languageCode: resolvedLanguageCode,
                                      accent: TryOurGamesConfig.accentSecondary,
                                      compact: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  TryOurGamesConfig.subtitle(
                                    resolvedLanguageCode,
                                  ),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.72),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: TryOurGamesConfig.accentSecondary
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: TryOurGamesConfig.accentSecondary
                                  .withValues(alpha: 0.95),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (glowAnimation == null) {
      return buildCard(0.6);
    }

    return AnimatedBuilder(
      animation: glowAnimation!,
      builder: (BuildContext context, Widget? child) {
        return buildCard(glowAnimation!.value);
      },
    );
  }
}

// ─── Categories grid tile ───────────────────────────────────────────────────

class TryOurGamesGridTile extends StatefulWidget {
  const TryOurGamesGridTile({
    super.key,
    this.languageCode,
    this.isRtl,
    this.borderRadius = 22,
  });

  final String? languageCode;
  final bool? isRtl;
  final double borderRadius;

  @override
  State<TryOurGamesGridTile> createState() => _TryOurGamesGridTileState();
}

class _TryOurGamesGridTileState extends State<TryOurGamesGridTile>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String resolvedLanguageCode =
        widget.languageCode ?? Localizations.localeOf(context).languageCode;
    final bool rtl =
        widget.isRtl ?? TryOurGamesConfig.isRtlLanguage(resolvedLanguageCode);
    final Color accent = TryOurGamesConfig.accentSecondary;
    final Color accentAlt = TryOurGamesConfig.accentTertiary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (BuildContext context, Widget? child) {
            final double pulse = _pulseController.value;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  TryOurGamesSheet.show(
                    context,
                    languageCode: resolvedLanguageCode,
                    isRtl: rtl,
                  );
                },
                borderRadius: BorderRadius.circular(widget.borderRadius),
                splashColor: accent.withValues(alpha: 0.12),
                highlightColor: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color.lerp(
                          TryOurGamesConfig.sheetBackground,
                          accentAlt,
                          0.08 + (pulse * 0.04),
                        )!,
                        Color.lerp(
                          TryOurGamesConfig.sheetBackground,
                          accent,
                          0.14 + (pulse * 0.05),
                        )!,
                      ],
                    ),
                    border: Border.all(
                      color: Color.lerp(
                        accent.withValues(alpha: 0.32),
                        accent.withValues(alpha: 0.58),
                        pulse,
                      )!,
                      width: 1.5,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      if (!_isPressed)
                        BoxShadow(
                          color: accent.withValues(
                            alpha: 0.14 + (pulse * 0.12),
                          ),
                          blurRadius: 22,
                          offset: const Offset(0, 6),
                          spreadRadius: -3,
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: const <Color>[
                                TryOurGamesConfig.accentTertiary,
                                TryOurGamesConfig.accentSecondary,
                                TryOurGamesConfig.accent,
                                TryOurGamesConfig.accentSecondary,
                              ],
                              stops: <double>[0, 0.35 + (pulse * 0.1), 0.7, 1],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Directionality(
                            textDirection:
                                rtl ? TextDirection.rtl : TextDirection.ltr,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                _PromoTileBackdrop(
                                  accent: accent,
                                  accentAlt: accentAlt,
                                ),
                                Center(
                                  child: _PromoGamesIconCluster(
                                    iconSize: 42,
                                    fallbackColor: accent,
                                    layout: _PromoIconClusterLayout.fan,
                                  )
                                      .animate(
                                        onPlay: (AnimationController c) {
                                          c.repeat(reverse: true);
                                        },
                                      )
                                      .moveY(
                                        begin: 0,
                                        end: -5,
                                        duration: 2200.ms,
                                        curve: Curves.easeInOut,
                                      )
                                      .scale(
                                        begin: const Offset(0.98, 0.98),
                                        end: const Offset(1, 1),
                                        duration: 2200.ms,
                                        curve: Curves.easeInOut,
                                      ),
                                ),
                                PositionedDirectional(
                                  top: 8,
                                  end: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: <Color>[
                                          TryOurGamesConfig.accent.withValues(
                                            alpha: 0.9,
                                          ),
                                          TryOurGamesConfig.accentTertiary
                                              .withValues(alpha: 0.85),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: TryOurGamesConfig.accent
                                              .withValues(alpha: 0.35),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(
                                          Icons.auto_awesome_rounded,
                                          color: Colors.white,
                                          size: 11,
                                        ),
                                        SizedBox(width: 3),
                                        Text(
                                          'Fluxy',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            height: 1,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: _PromoGamesCountBadge(
                                      languageCode: resolvedLanguageCode,
                                      accent: accent,
                                      prominent: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            border: Border(
                              top: BorderSide(
                                color: accent.withValues(alpha: 0.24),
                              ),
                            ),
                          ),
                          child: Text(
                            TryOurGamesConfig.title(resolvedLanguageCode),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _GameIconImage extends StatelessWidget {
  const _GameIconImage({
    required this.iconAsset,
    required this.accent,
    required this.accentAlt,
    this.size = 52,
  });

  final String? iconAsset;
  final Color accent;
  final Color accentAlt;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (iconAsset == null || iconAsset!.isEmpty) {
      return _fallbackIcon();
    }

    return Image.asset(
      iconAsset!,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accentAlt.withValues(alpha: 0.95),
            accent.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Icon(
        Icons.sports_esports_rounded,
        color: Colors.white.withValues(alpha: 0.95),
        size: size * 0.48,
      ),
    );
  }
}

/// "Coming soon" chip for games still in testing.
class _GameStatusChip extends StatelessWidget {
  const _GameStatusChip({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            TryOurGamesConfig.accent.withValues(alpha: 0.42),
            const Color(0xFFFFB703).withValues(alpha: 0.32),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD166).withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.hourglass_top_rounded,
            size: 13,
            color: Color(0xFFFFF3BF),
          ),
          const SizedBox(width: 4),
          Text(
            TryOurGamesConfig.comingSoonItemLabel(languageCode),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact text link that opens the sheet, for screens without room for
/// the full [TryOurGamesIntroButton] card.
class TryOurGamesLink extends StatelessWidget {
  const TryOurGamesLink({
    super.key,
    this.languageCode,
    this.isRtl,
    this.color = Colors.white70,
  });

  final String? languageCode;
  final bool? isRtl;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final String resolvedLanguageCode =
        languageCode ?? Localizations.localeOf(context).languageCode;
    final bool rtl =
        isRtl ?? TryOurGamesConfig.isRtlLanguage(resolvedLanguageCode);
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        TryOurGamesSheet.show(
          context,
          languageCode: resolvedLanguageCode,
          isRtl: rtl,
        );
      },
      icon: const Icon(Icons.apps_rounded, size: 18),
      label: Text(TryOurGamesConfig.title(resolvedLanguageCode)),
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

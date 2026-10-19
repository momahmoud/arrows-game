import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:arrow_escape/ads/ad_manager.dart';
import 'package:arrow_escape/core/app_colors.dart';
import 'package:arrow_escape/core/app_fonts.dart';
import 'package:arrow_escape/core/audio_manager.dart';
import 'package:arrow_escape/data/repositories/level_repository.dart';
import 'package:arrow_escape/data/repositories/progress_repository.dart';
import 'package:arrow_escape/l10n/generated/app_localizations.dart';
import 'package:arrow_escape/monetization/monetization_policy.dart';
import 'package:arrow_escape/monetization/play_billing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mounts real screens with real providers, fonts and image assets.
class UiHarness {
  UiHarness._(this.progress, this.levels);

  final ProgressRepository progress;
  final LevelRepository levels;

  static final boundaryKey = GlobalKey();
  static bool _fontsLoaded = false;

  static Future<void> loadFonts() async {
    if (_fontsLoaded) return;
    _fontsLoaded = true;
    final loader = FontLoader(AppFonts.family);
    for (final w in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      loader.addFont(rootBundle
          .load('assets/fonts/PlaypenSansArabic/PlaypenSansArabic-$w.ttf'));
    }
    await loader.load();
  }

  static void mockPlugins() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final name in const [
      'plugins.flutter.io/google_mobile_ads',
      'com.rebeloid.unity_ads',
      'com.rebeloid.unity_ads/banner',
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global',
      'dev.fluttercommunity.plus/package_info',
      'plugins.flutter.io/in_app_purchase',
      'de.ffuf.in_app_update/methods',
      'plugins.flutter.io/url_launcher',
    ]) {
      // Raw reply: some plugins use custom codecs the mock cannot decode.
      messenger.setMockMessageHandler(name,
          (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null));
    }
  }

  static bool _storeTouched = false;

  /// The Play Billing client connects once per process over a channel that
  /// has no host in tests. Start it in a zone that swallows that failure.
  static void _touchStore() {
    if (_storeTouched) return;
    _storeTouched = true;
    runZonedGuarded(() => InAppPurchase.instance, (_, __) {});
  }

  static Future<UiHarness> create({
    Map<String, Object> prefs = const {},
  }) async {
    mockPlugins();
    _touchStore();
    AudioManager.instance.setSoundEnabled(false);
    AudioManager.instance.setMusicEnabled(false);
    SharedPreferences.setMockInitialValues({
      'soundEnabled': false,
      'musicEnabled': false,
      ...prefs,
    });
    final sp = await SharedPreferences.getInstance();
    final progress = ProgressRepository(sp);
    final levels = LevelRepository(sp);
    levels.debugAttachBinaryBytes(File('assets/levels.bin').readAsBytesSync());
    return UiHarness._(progress, levels);
  }

  Widget app({
    required Locale locale,
    required bool dark,
    Widget? home,
    RouteSettings? initial,
    Map<String, WidgetBuilder> routes = const {},
  }) {
    AppColors.updateTheme(dark);
    ThemeData theme(Brightness b) => ThemeData(
          useMaterial3: true,
          fontFamily: AppFonts.family,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9C3ED1),
            brightness: b,
          ),
          scaffoldBackgroundColor: b == Brightness.dark
              ? const Color(0xFF101610)
              : const Color(0xFFF7F4EC),
        );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: progress),
        Provider<LevelRepository>.value(value: levels),
        Provider<AdManager>(create: (_) => AdManager()),
        ChangeNotifierProvider(create: (_) => MonetizationPolicy()),
        ChangeNotifierProvider(create: (_) => PlayBilling(progress)),
      ],
      child: RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) {
            AppFonts.isArabic =
                Localizations.localeOf(context).languageCode == 'ar';
            return child!;
          },
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          theme: theme(Brightness.light),
          darkTheme: theme(Brightness.dark),
          home: home,
          routes: routes,
          onGenerateInitialRoutes: initial == null
              ? null
              : (_) => [
                    MaterialPageRoute(
                      settings: initial,
                      builder: routes[initial.name]!,
                    ),
                  ],
        ),
      ),
    );
  }

  /// Runs [body] while ignoring platform plugins that are absent in tests
  /// (audio players open event channels with generated names).
  static Future<void> withoutPlugins(Future<void> Function() body) async {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      final e = details.exception;
      if (e is MissingPluginException) return;
      // Play Billing talks over pigeon channels that have no host in tests.
      if (e is PlatformException && e.code == 'channel-error') return;
      original?.call(details);
    };
    try {
      await body();
    } finally {
      FlutterError.onError = original;
    }
  }

  /// Decodes every image currently in the tree so the capture shows them.
  static Future<void> settleImages(WidgetTester tester) async {
    for (var round = 0; round < 3; round++) {
      final elements = find.byType(Image).evaluate().toList();
      await tester.runAsync(() async {
        for (final e in elements) {
          final image = e.widget as Image;
          await precacheImage(image.image, e);
        }
        // SVG pictures load on their own futures.
        await Future<void>.delayed(const Duration(milliseconds: 60));
      });
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  static Future<void> capture(
      WidgetTester tester, String? outDir, String name) async {
    if (outDir == null) return;
    await settleImages(tester);
    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory(outDir).createSync(recursive: true);
      File('$outDir/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:arrow_escape/data/models/level.dart';
import 'package:arrow_escape/data/shape_catalog.dart';
import 'package:arrow_escape/data/shape_names_ar.dart';
import 'package:arrow_escape/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Arabic ARB translates every English key', () {
    Map<String, dynamic> read(String path) =>
        jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
    final keys = (Map<String, dynamic> m) =>
        m.keys.where((k) => !k.startsWith('@')).toSet();
    final en = read('lib/l10n/app_en.arb');
    final ar = read('lib/l10n/app_ar.arb');
    expect(keys(ar), keys(en));
    for (final k in keys(en)) {
      expect((ar[k] as String).trim(), isNotEmpty, reason: k);
    }
  });

  test('every shape has an Arabic name', () {
    final missing = MaskShape.values
        .where((s) => !shapeNamesAr.containsKey(s.name))
        .map((s) => s.name)
        .toList();
    expect(missing, isEmpty);
    expect(ShapeCatalog.displayName(MaskShape.seaTurtle, languageCode: 'ar'),
        'سلحفاة بحرية');
    expect(ShapeCatalog.displayName(MaskShape.seaTurtle), 'Sea Turtle');
  });

  testWidgets('Arabic locale resolves and lays out right-to-left',
      (tester) async {
    late AppLocalizations l10n;
    late TextDirection direction;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(builder: (context) {
        l10n = context.l10n;
        direction = Directionality.of(context);
        return const SizedBox();
      }),
    ));
    expect(direction, TextDirection.rtl);
    expect(l10n.levelNumber(12), 'المرحلة 12');
    expect(l10n.bossLoadingMessages.length, 10);
  });
}

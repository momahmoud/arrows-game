import 'dart:convert';
import 'dart:io';

import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/ui/icons/game_assets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Campaign-size claims such as "1000 pre-generated", "1,000-level",
/// "All 1000 levels" or "level count (1000)". Counts below 500 (batch sizes,
/// level thresholds) are not campaign claims.
final _levelCountClaim = RegExp(
  r'\b(\d[\d,]*\d)(?=[- ](?:level|pre-generated|levels)\b)'
  r'|level count \((\d+)\)',
  caseSensitive: false,
);

List<File> _docs() => [
      File('README.md'),
      ...Directory('docs/dev')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.md')),
    ];

Map<String, dynamic> _arb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  test('docs state the shipped campaign size', () {
    final stale = <String>[];
    var claims = 0;
    for (final doc in _docs()) {
      final lines = doc.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final m in _levelCountClaim.allMatches(lines[i])) {
          final n = int.parse((m.group(1) ?? m.group(2)!).replaceAll(',', ''));
          if (n < 500) continue;
          claims++;
          if (n != AppConstants.totalLevels) {
            stale.add('${doc.path}:${i + 1}: claims $n levels');
          }
        }
      }
    }
    expect(claims, greaterThan(0), reason: 'README should state level count');
    expect(stale, isEmpty,
        reason: 'AppConstants.totalLevels is ${AppConstants.totalLevels}');
  });

  test('README binary size matches assets/levels.bin', () {
    final kb = File('assets/levels.bin').lengthSync() / 1024;
    final claim = RegExp(r'~(\d+) KB\*\* binary')
        .firstMatch(File('README.md').readAsStringSync());
    expect(claim, isNotNull, reason: 'README should state levels.bin size');
    expect((int.parse(claim!.group(1)!) - kb).abs(), lessThan(1.0),
        reason: 'assets/levels.bin is ${kb.toStringAsFixed(1)} KB');
  });

  test('Arabic messages use every placeholder declared in English', () {
    final en = _arb('en');
    final ar = _arb('ar');
    final missing = <String>[];
    for (final entry in en.entries) {
      final meta = entry.value;
      if (!entry.key.startsWith('@') || meta is! Map) continue;
      final key = entry.key.substring(1);
      final placeholders = meta['placeholders'] as Map?;
      final message = ar[key];
      if (placeholders == null || message is! String) continue;
      for (final name in placeholders.keys) {
        if (!message.contains('{$name')) missing.add('$key: {$name}');
      }
    }
    expect(missing, isEmpty);
  });

  test('referenced image assets exist', () {
    final paths = {
      for (final art in gameArt.values) art.asset,
      'assets/images/splash.png',
      'assets/levels.bin',
    };
    expect(paths.where((p) => !File(p).existsSync()), isEmpty);
  });
}

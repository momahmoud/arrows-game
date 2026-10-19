// ignore_for_file: avoid_print
/// One-shot probe: prod vs first_500_quality density / bends.
@Tags(['candidates'])
library;

import 'dart:io';

import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

int bends(List<List<int>> path) {
  if (path.length < 3) return 0;
  var b = 0;
  for (var i = 1; i < path.length - 1; i++) {
    final dr1 = path[i][0] - path[i - 1][0];
    final dc1 = path[i][1] - path[i - 1][1];
    final dr2 = path[i + 1][0] - path[i][0];
    final dc2 = path[i + 1][1] - path[i][1];
    if (dr1 != dr2 || dc1 != dc2) b++;
  }
  return b;
}

void dump(String tag, LevelModel L) {
  var cells = 0, lenSum = 0, b0 = 0, b1 = 0, b2 = 0, b3 = 0;
  for (final a in L.arrows) {
    cells += a.path.length;
    lenSum += a.path.length;
    final b = bends(a.path);
    if (b == 0) {
      b0++;
    } else if (b == 1) {
      b1++;
    } else if (b == 2) {
      b2++;
    } else {
      b3++;
    }
  }
  final n = L.arrows.length;
  print('$tag n=$n cells=$cells avgLen=${n == 0 ? 0 : (lenSum / n).toStringAsFixed(2)} '
      'b0=$b0 b1=$b1 b2=$b2 b3+=$b3 grid=${L.gridSize} '
      'diff=${L.difficulty} mask=${L.maskShape.name}');
}

void main() {
  test('density probe', () {
    final prod = LevelBinaryDecoder.fromBytes(
            File('assets/levels.bin').readAsBytesSync())
        .decodeAll()
        .toList();
    final cand = LevelBinaryDecoder.fromBytes(File(
            'build/candidates/first_500_quality/levels_candidate.bin')
        .readAsBytesSync())
        .decodeAll()
        .toList();
    expect(prod.length, 1000);
    expect(cand.length, 1000);

    dump('L50 PROD', prod[49]);
    dump('L50 CAND', cand[49]);

    void band(String name, int a, int b) {
      final ps = [for (var i = a; i <= b; i++) prod[i - 1].arrows.length]
        ..sort();
      final cs = [for (var i = a; i <= b; i++) cand[i - 1].arrows.length]
        ..sort();
      int med(List<int> s) => s[s.length ~/ 2];
      print('$name prodMed=${med(ps)} candMed=${med(cs)} '
          'ratio=${(med(cs) / med(ps)).toStringAsFixed(2)}');
    }

    band('1-24', 1, 24);
    band('25-100', 25, 100);
    band('101-150', 101, 150);
    band('151-200', 151, 200);
    band('201-250', 201, 250);
    band('251-300', 251, 300);
    band('301-350', 301, 350);
    band('351-400', 351, 400);
    band('401-450', 401, 450);
    band('451-500', 451, 500);

    // Multi-turn share 251-300
    double multiShare(List<LevelModel> all, int a, int b) {
      var multi = 0, total = 0;
      for (var i = a; i <= b; i++) {
        for (final ar in all[i - 1].arrows) {
          total++;
          if (bends(ar.path) >= 1) multi++;
        }
      }
      return total == 0 ? 0 : multi / total;
    }

    print('multiTurn 251-300 prod=${multiShare(prod, 251, 300).toStringAsFixed(2)} '
        'cand=${multiShare(cand, 251, 300).toStringAsFixed(2)}');
    print('multiTurn 301-500 prod=${multiShare(prod, 301, 500).toStringAsFixed(2)} '
        'cand=${multiShare(cand, 301, 500).toStringAsFixed(2)}');

    final drops = <(int, int, int)>[];
    for (var i = 1; i <= 500; i++) {
      final d = prod[i - 1].arrows.length - cand[i - 1].arrows.length;
      if (d > 0) {
        drops.add((i, prod[i - 1].arrows.length, cand[i - 1].arrows.length));
      }
    }
    drops.sort((a, b) => (b.$2 - b.$3).compareTo(a.$2 - a.$3));
    print('Top arrow drops:');
    for (final t in drops.take(25)) {
      print('  L${t.$1}: ${t.$2}->${t.$3} (${t.$2 - t.$3}) '
          'ratio=${(t.$3 / t.$2).toStringAsFixed(2)}');
    }

    // Count how many changed levels are under 75% of prod
    var changed = 0, under75 = 0;
    for (var i = 1; i <= 500; i++) {
      final p = prod[i - 1];
      final c = cand[i - 1];
      if (p.arrows.length == c.arrows.length &&
          p.arrows.every((a) => true)) {
        // cheap identity: encode compare
      }
      final pe = encodeLevels([p]);
      final ce = encodeLevels([c]);
      final same = pe.length == ce.length;
      // better: fingerprint via arrow count + first path
      final identical = p.arrows.length == c.arrows.length &&
          p.arrows.asMap().entries.every((e) {
            final a = e.value;
            final b = c.arrows[e.key];
            return a.path.length == b.path.length &&
                a.direction == b.direction;
          });
      if (!identical) {
        changed++;
        if (c.arrows.length < 0.75 * p.arrows.length) under75++;
      }
    }
    print('approx changed(loose)=$changed under75=$under75');
  });
}

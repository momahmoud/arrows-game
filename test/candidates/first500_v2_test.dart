// ignore_for_file: avoid_print

/// Builds and validates first_500_quality_v2 (density + zigzag revision).
///
///   flutter test test/candidates/first500_v2_test.dart
///
/// Does not write assets/levels.bin or overwrite first_500_quality/.
@Tags(['candidates'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:arrow_escape/core/audio_manager.dart';
import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/level_generator/campaign_audit.dart';
import 'package:arrow_escape/data/level_generator/level_fingerprint.dart';
import 'package:arrow_escape/data/level_generator/level_quality.dart';
import 'package:arrow_escape/data/level_generator/solver.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'candidate_builder.dart';
import 'candidate_checks.dart';
import 'density_policy.dart';
import 'early_phase1.dart';
import 'first500_integrate.dart';
import 'first500_mid.dart';
import 'first500_v2.dart';
import 'phase2a.dart';
import 'phase2b.dart';
import 'phase2c.dart';
import 'phase2d.dart';
import 'phase2e.dart';

const _out = First500V2.outDir;

bool _sameLevel(LevelModel a, LevelModel b) =>
    listEquals(encodeLevels([a]), encodeLevels([b]));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AudioManager.instance.setSoundEnabled(false);

  test('build density+zigzag v2 candidate and validate', () {
    final originalBytes = File('assets/levels.bin').readAsBytesSync();
    final production =
        LevelBinaryDecoder.fromBytes(originalBytes).decodeAll().toList();
    expect(
      File('build/candidates/first_500_quality/levels_candidate.bin')
          .existsSync(),
      isTrue,
    );
    final v1 = First500Integrate.loadBin(
        'build/candidates/first_500_quality/levels_candidate.bin');
    final phase1b = First500Integrate.loadBin(
        'build/candidates/early_phase1b/levels_candidate.bin');

    Directory(_out).createSync(recursive: true);
    final integrated = List<LevelModel>.from(production);
    final sources = <int, String>{
      for (var n = 1; n <= AppConstants.totalLevels; n++) n: 'production',
    };
    final profile = <int, Map<String, Object?>>{};
    final exceptions = <String>[];

    CandidateChoice? take(CandidateChoice c, LevelModel prod, String tag) {
      if (c.rejected != null) {
        print('L${prod.levelNumber} $tag REJECTED ${c.rejected}');
        return null;
      }
      final level = c.built.level;
      final breather = tag.contains('breather');
      final target =
          DensityPolicy.targetArrows(prod, breather: breather);
      final ex = DensityPolicy.exceptionReason(prod, level.arrows.length);
      final v1Level = v1[prod.levelNumber - 1];
      final specialCap = DensityPolicy.isSpecial(prod.levelNumber) &&
          prod.arrows.length >= DensityPolicy.overcrowdedSpecialFloor;
      // Do not silently accept underfilled builds — target is a hard intent.
      if (!specialCap && level.arrows.length < (target * 0.78).floor()) {
        print(
            'L${prod.levelNumber} $tag underfilled '
            '${level.arrows.length}/target $target — skip');
        return null;
      }
      if (!DensityPolicy.meetsRetainFloor(prod, level)) {
        if (specialCap) {
          exceptions.add('L${prod.levelNumber}: $ex (accepted readable cap)');
        } else if (DensityPolicy.acceptableVsV1(
            production: prod, candidate: level, v1: v1Level)) {
          exceptions.add(
              'L${prod.levelNumber}: below 75% floor but denser than v1 '
              '(${level.arrows.length} vs v1 ${v1Level.arrows.length} / '
              'prod ${prod.arrows.length})');
        } else {
          print(
              'L${prod.levelNumber} $tag under floor '
              '${level.arrows.length}/${prod.arrows.length} — skip');
          return null;
        }
      } else if (ex != null) {
        exceptions.add('L${prod.levelNumber}: $ex');
      }
      final multi = DensityPolicy.multiTurnShare(level);
      final need = DensityPolicy.multiTurnTarget(prod);
      if (multi + 0.001 < need && prod.gridSize >= 20) {
        print(
            'L${prod.levelNumber} $tag multiTurn '
            '${multi.toStringAsFixed(2)} < $need (kept if otherwise OK)');
      }
      profile[prod.levelNumber] = {
        'source': tag,
        'prodArrows': prod.arrows.length,
        'candArrows': level.arrows.length,
        'targetArrows': target,
        'ratio': level.arrows.length / math.max(1, prod.arrows.length),
        'multiTurn': multi,
        'peel': c.profile.peelRounds,
        'crowd': c.profile.headCrowding,
        'fill': c.profile.fill,
        'open': c.profile.openingMoves,
        'seed': c.built.seed,
      };
      return c;
    }

    void put(int n, LevelModel level, String source) {
      integrated[n - 1] = level;
      sources[n] = source;
    }

    for (var n = EarlyPhase1.first; n <= EarlyPhase1.last; n++) {
      final prod = production[n - 1];
      final c = take(First500V2.buildEarly(n, prod), prod, 'early_v2');
      if (c != null) {
        put(n, c.built.level, 'early_v2');
      } else {
        put(n, phase1b[n - 1], 'phase1b_fallback');
        exceptions.add(
            'L$n: early densify failed — kept Phase 1B '
            '(${phase1b[n - 1].arrows.length}/${prod.arrows.length} arrows)');
      }
      print(
          'early L$n -> ${sources[n]} arrows=${integrated[n - 1].arrows.length}');
    }

    for (final n in First500Mid.replaced) {
      final prod = production[n - 1];
      final role = First500Mid.designFor(n).role;
      final c = take(First500V2.buildMid(n, prod), prod, 'mid_v2');
      if (c != null) {
        put(n, c.built.level, 'mid_v2');
      } else if (role == MidRole.breather || role == MidRole.chain) {
        // Prefer production density over sparse v1 shallow repairs.
        put(n, prod, 'production_fallback');
        exceptions.add(
            'L$n: mid densify failed — production fallback '
            '(role=$role, v1 had ${v1[n - 1].arrows.length})');
      } else {
        // Keep v1 trap/special repairs rather than restoring overcrowded/unfair.
        put(n, v1[n - 1], 'v1_mid_fallback');
        exceptions.add(
            'L$n: mid densify failed — kept v1 mid '
            '(${v1[n - 1].arrows.length}/${prod.arrows.length})');
      }
      print(
          'mid L$n -> ${sources[n]} arrows=${integrated[n - 1].arrows.length}');
    }

    CandidateChoice Function(int, LevelModel) builderFor(int n) {
      if (n <= Phase2A.last) return First500V2.build2A;
      if (n <= Phase2B.last) return First500V2.build2B;
      if (n <= Phase2C.last) return First500V2.build2C;
      if (n <= Phase2D.last) return First500V2.build2D;
      return First500V2.build2E;
    }

    String tagFor(int n) {
      if (n <= Phase2A.last) return 'phase2a_v2';
      if (n <= Phase2B.last) return 'phase2b_v2';
      if (n <= Phase2C.last) return 'phase2c_v2';
      if (n <= Phase2D.last) return 'phase2d_v2';
      return 'phase2e_v2';
    }

    for (var n = Phase2A.first; n <= Phase2E.last; n++) {
      final prod = production[n - 1];
      final tag = tagFor(n);
      final c = take(builderFor(n)(n, prod), prod, tag);
      if (c != null) {
        put(n, c.built.level, tag);
      } else if (DensityPolicy.isSpecial(n) &&
          prod.arrows.length >= DensityPolicy.overcrowdedSpecialFloor) {
        final retry = builderFor(n)(n, prod);
        if (retry.rejected == null &&
            retry.built.level.arrows.length >= 56) {
          put(n, retry.built.level, '${tag}_special');
          exceptions.add(
              'L$n: overcrowded special cap '
              '(${retry.built.level.arrows.length}/${prod.arrows.length})');
        } else {
          put(n, prod, 'production_fallback');
          exceptions.add('L$n: $tag failed — production fallback');
        }
      } else {
        // Prefer production density over sparse v1 when densify fails.
        put(n, prod, 'production_fallback');
        exceptions.add(
            'L$n: $tag failed — production fallback '
            '(v1 had ${v1[n - 1].arrows.length} arrows)');
      }
      if (n % 10 == 0 || n == Phase2A.first) {
        print(
            '$tag L$n -> ${sources[n]} '
            'arrows=${integrated[n - 1].arrows.length}/'
            '${prod.arrows.length}');
      }
    }

    final bytes = encodeLevels(integrated);
    File('$_out/levels_candidate.bin').writeAsBytesSync(bytes);
    File('$_out/level_profile.json')
        .writeAsStringSync(const JsonEncoder.withIndent(' ').convert({
      for (var n = 1; n <= 500; n++)
        '$n': {
          'source': sources[n],
          'prodArrows': production[n - 1].arrows.length,
          'candArrows': integrated[n - 1].arrows.length,
          'ratio': integrated[n - 1].arrows.length /
              math.max(1, production[n - 1].arrows.length),
          'multiTurn': DensityPolicy.multiTurnShare(integrated[n - 1]),
          'v1Arrows': v1[n - 1].arrows.length,
          if (profile[n] != null) ...profile[n]!,
        },
    }));
    File('$_out/source_map.json').writeAsStringSync(
        const JsonEncoder.withIndent(' ').convert({
      for (final e in sources.entries) '${e.key}': e.value,
    }));
    File('$_out/exceptions.json').writeAsStringSync(
        const JsonEncoder.withIndent(' ').convert(exceptions));
    print(
        'Wrote $_out (${bytes.length} bytes), exceptions=${exceptions.length}');

    // --- validation ---
    expect(File('assets/levels.bin').readAsBytesSync(), originalBytes);
    expect(integrated.length, 1000);
    for (var n = 501; n <= 1000; n++) {
      expect(_sameLevel(integrated[n - 1], production[n - 1]), isTrue,
          reason: 'L$n');
    }

    var changed = 0;
    final badFloor = <int>[];
    for (var n = 1; n <= 500; n++) {
      if (_sameLevel(integrated[n - 1], production[n - 1])) continue;
      changed++;
      if (!DensityPolicy.meetsRetainFloor(
          production[n - 1], integrated[n - 1])) {
        final allowed = exceptions.any((e) => e.startsWith('L$n:'));
        if (!allowed) badFloor.add(n);
      }
    }
    print('changed=$changed undocumentedUnderFloor=${badFloor.length}');
    expect(badFloor, isEmpty);

    int med(List<int> xs) {
      final s = [...xs]..sort();
      return s[s.length ~/ 2];
    }

    for (final (a, b) in [
      (251, 300),
      (301, 350),
      (351, 400),
      (401, 450),
      (451, 500),
    ]) {
      final p =
          med([for (var i = a; i <= b; i++) production[i - 1].arrows.length]);
      final c1 = med([for (var i = a; i <= b; i++) v1[i - 1].arrows.length]);
      final c2 =
          med([for (var i = a; i <= b; i++) integrated[i - 1].arrows.length]);
      print('band $a-$b prod=$p v1=$c1 v2=$c2');
      expect(c2, greaterThanOrEqualTo(c1), reason: '$a–$b');
      expect(c2 / p, greaterThanOrEqualTo(0.65), reason: '$a–$b retain');
    }

    final p50 = production[49].arrows.length;
    final v1_50 = v1[49].arrows.length;
    final v2_50 = integrated[49].arrows.length;
    print('L50 prod=$p50 v1=$v1_50 v2=$v2_50 source=${sources[50]}');
    expect(v2_50, greaterThanOrEqualTo(v1_50));
    expect(v2_50 / p50, greaterThanOrEqualTo(0.75),
        reason: 'L50 must not stay sparse');

    final report = CampaignAudit.auditBytes(bytes);
    print(report.summary());
    File('$_out/campaign_audit.json').writeAsStringSync(
        const JsonEncoder.withIndent(' ').convert(report.toJson()));
    expect(report.blockers(strict: true), isEmpty);

    final fingerprints = <String, int>{};
    for (final c in integrated) {
      fingerprints.putIfAbsent(
          LevelFingerprint.canonicalHash(c), () => c.levelNumber);
    }

    for (var n = 1; n <= 500; n++) {
      if (_sameLevel(integrated[n - 1], production[n - 1])) continue;
      final c = integrated[n - 1];
      expect(CampaignAudit.replayStoredSolution(c), isTrue, reason: 'L$n');
      expect(replayInGame(c, c.solutionOrder), isNull, reason: 'L$n');
      final dfs = LevelSolver.attempt(c, 400000);
      expect(dfs.status, SolveStatus.solved, reason: 'L$n DFS');
      expect(fingerprints[LevelFingerprint.canonicalHash(c)], n,
          reason: 'L$n dup');
    }

    for (final name in [
      'early_phase1b',
      'phase2a_251_300',
      'phase2b_301_350',
      'phase2c_351_400',
      'phase2d_401_450',
      'phase2e_451_500',
      'first_500_quality',
    ]) {
      expect(
          File('build/candidates/$name/levels_candidate.bin').existsSync(),
          isTrue,
          reason: name);
    }

    // Soft 2A trap thinning signal
    var v1Trapish = 0, v2Trapish = 0;
    for (var n = Phase2A.first; n <= Phase2A.last; n++) {
      if (LevelQuality.profile(v1[n - 1]).deadEndRate > 0.05) v1Trapish++;
      if (LevelQuality.profile(integrated[n - 1]).deadEndRate > 0.05) {
        v2Trapish++;
      }
    }
    print('2A trap-ish v1=$v1Trapish v2=$v2Trapish');
    expect(v2Trapish, lessThanOrEqualTo(v1Trapish + 5));
  }, timeout: const Timeout(Duration(hours: 6)));
}

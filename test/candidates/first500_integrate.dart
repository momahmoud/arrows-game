import 'dart:io';

import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:flutter/foundation.dart';

/// Source tag for each level in the first-500 integrated candidate.
enum First500Source {
  production,
  phase1b,
  mid25_250,
  phase2a,
  phase2b,
  phase2c,
  phase2d,
  phase2e,
}

/// Assembles the integrated first-500 quality candidate from production plus
/// validated phase binaries and mid-band replacements.
///
/// Uses decoded [LevelModel] records + [encodeLevels] — never raw byte splices.
class First500Integrate {
  First500Integrate._();

  static const String outDir = 'build/candidates/first_500_quality';

  static const Map<String, (int, int)> phaseRanges = {
    'early_phase1b': (4, 24),
    'phase2a_251_300': (251, 300),
    'phase2b_301_350': (301, 350),
    'phase2c_351_400': (351, 400),
    'phase2d_401_450': (401, 450),
    'phase2e_451_500': (451, 500),
  };

  static const Map<String, First500Source> phaseSources = {
    'early_phase1b': First500Source.phase1b,
    'phase2a_251_300': First500Source.phase2a,
    'phase2b_301_350': First500Source.phase2b,
    'phase2c_351_400': First500Source.phase2c,
    'phase2d_401_450': First500Source.phase2d,
    'phase2e_451_500': First500Source.phase2e,
  };

  /// Load a candidate binary and return all 1000 levels.
  static List<LevelModel> loadBin(String path) {
    final bytes = File(path).readAsBytesSync();
    return LevelBinaryDecoder.fromBytes(bytes).decodeAll().toList();
  }

  /// Verify a phase binary only differs from production in [first]–[last].
  static void assertPhaseRangeOnly({
    required List<LevelModel> production,
    required List<LevelModel> phase,
    required int first,
    required int last,
    required String label,
  }) {
    if (phase.length != AppConstants.totalLevels) {
      throw StateError('$label: expected 1000 levels, got ${phase.length}');
    }
    for (var i = 0; i < production.length; i++) {
      final n = i + 1;
      final same =
          listEquals(encodeLevels([phase[i]]), encodeLevels([production[i]]));
      if (n >= first && n <= last) {
        if (same) {
          throw StateError('$label: L$n should differ from production');
        }
      } else {
        if (!same) {
          throw StateError('$label: L$n must match production');
        }
      }
    }
  }

  /// Merge production with phase overlays and mid replacements.
  static ({
    List<LevelModel> levels,
    Map<int, First500Source> sources,
  }) assemble({
    required List<LevelModel> production,
    required Map<String, List<LevelModel>> phases,
    required Map<int, LevelModel> midReplacements,
  }) {
    final out = List<LevelModel>.from(production);
    final sources = <int, First500Source>{
      for (var n = 1; n <= AppConstants.totalLevels; n++)
        n: First500Source.production,
    };

    for (final e in phaseRanges.entries) {
      final name = e.key;
      final (first, last) = e.value;
      final phase = phases[name]!;
      assertPhaseRangeOnly(
        production: production,
        phase: phase,
        first: first,
        last: last,
        label: name,
      );
      final src = phaseSources[name]!;
      for (var n = first; n <= last; n++) {
        out[n - 1] = phase[n - 1];
        sources[n] = src;
      }
    }

    for (final e in midReplacements.entries) {
      final n = e.key;
      if (n < 25 || n > 250) {
        throw StateError('mid replacement L$n outside 25–250');
      }
      out[n - 1] = e.value;
      sources[n] = First500Source.mid25_250;
    }

    // Invariants
    for (var n = 501; n <= AppConstants.totalLevels; n++) {
      if (sources[n] != First500Source.production) {
        throw StateError('L$n must stay production');
      }
      if (!listEquals(
          encodeLevels([out[n - 1]]), encodeLevels([production[n - 1]]))) {
        throw StateError('L$n record changed');
      }
    }
    for (var n = 1; n <= 3; n++) {
      if (!listEquals(
          encodeLevels([out[n - 1]]), encodeLevels([production[n - 1]]))) {
        throw StateError('tutorial L$n changed');
      }
    }

    return (levels: out, sources: sources);
  }
}

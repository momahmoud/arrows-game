import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../level_binary_codec.dart';
import '../level_generator/level_generator_v2.dart';
import '../models/level.dart';

// Top-level function required by compute() to run in a background isolate.
LevelModel _generateLevelIsolate(int levelNumber) {
  return LevelGeneratorV2.generateLevel(levelNumber);
}

/// Caches generated levels and provides access by level number.
///
/// Level loading priority:
///   1. In-memory cache  (instant)
///   2. levels.bin binary asset  (O(1) seek, microseconds)
///   3. SharedPreferences disk cache
///   4. On-the-fly generation  (only when packaged/cached data is unavailable)
///
/// A failed binary decode never returns a partial level. Generation is an
/// emergency fallback and is not claimed to be campaign-verified.
class LevelRepository {
  LevelRepository([
    this._prefs,
    LevelModel Function(int levelNumber)? generateLevel,
  ])  : _usesDefaultGenerator = generateLevel == null,
        _generate = generateLevel ?? LevelGeneratorV2.generateLevel;

  final SharedPreferences? _prefs;
  final LevelModel Function(int levelNumber) _generate;
  final bool _usesDefaultGenerator;
  final Map<int, LevelModel> _cache = {};
  final Map<int, Future<LevelModel>> _inflight = {};

  LevelBinaryDecoder? _binaryDecoder;
  bool _binaryLoaded = false;

  /// When true, skip SharedPreferences `cached_level_*` layout cache so a
  /// playtest binary cannot be mixed with stale production layouts. Progress
  /// keys are never touched by this flag.
  bool _skipDiskLevelCache = false;

  /// True after [loadPregeneratedLevels] (or a test attach) has finished,
  /// whether or not a usable decoder is available.
  bool get isBinaryLoaded => _binaryLoaded;

  /// Packaged level count when the binary asset loaded successfully.
  int? get packagedLevelCount => _binaryDecoder?.levelCount;

  /// True while a playtest attach is active (disk layout cache bypassed).
  bool get isPlaytestBinaryAttached => _skipDiskLevelCache;

  /// Load the binary level asset. Header + index are validated up front;
  /// individual levels decode lazily on demand.
  Future<void> loadPregeneratedLevels() async {
    if (_binaryLoaded) return;
    try {
      final byteData = await rootBundle.load('assets/levels.bin');
      final bytes = byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      _attachBinary(bytes, clearDiskCache: true);
    } catch (e) {
      _binaryDecoder = null;
      _binaryLoaded = true;
      debugPrint('Error loading levels.bin: $e');
    }
  }

  /// Test/helper entry to install or clear packaged bytes without rootBundle.
  @visibleForTesting
  void debugAttachBinaryBytes(Uint8List? bytes, {bool clearDiskCache = false}) {
    if (bytes == null) {
      _binaryDecoder = null;
      _binaryLoaded = true;
      _skipDiskLevelCache = false;
      return;
    }
    _attachBinary(bytes, clearDiskCache: clearDiskCache);
  }

  /// Development playtest attach: swap the packaged decoder without clearing
  /// SharedPreferences progress keys and without wiping `cached_level_*`
  /// entries on disk. Memory cache is replaced; disk layout cache is ignored
  /// while attached so candidate boards cannot mix with stale prefs layouts.
  ///
  /// Prefer a repository constructed with `prefs == null` so playtest never
  /// writes layout cache either. Intended for the gated first-500 playtest
  /// sandbox and tests — not for production campaign loading.
  void debugAttachPlaytestBinary(Uint8List bytes) {
    _cache.clear();
    _inflight.clear();
    _skipDiskLevelCache = true;
    _attachBinary(bytes, clearDiskCache: false);
  }

  /// Clears a playtest attach flag and decoder. Does not restore production
  /// bytes; call [loadPregeneratedLevels] or [debugAttachBinaryBytes] after.
  void debugDetachPlaytestBinary() {
    _cache.clear();
    _inflight.clear();
    _binaryDecoder = null;
    _binaryLoaded = false;
    _skipDiskLevelCache = false;
  }

  void _attachBinary(Uint8List bytes, {required bool clearDiskCache}) {
    final decoder = LevelBinaryDecoder.fromBytes(bytes);
    _binaryDecoder = decoder;
    _binaryLoaded = true;

    if (clearDiskCache) {
      _cache.clear();
      // Only removes layout cache keys — never progress / economy keys.
      if (_prefs != null) {
        for (int i = 1; i <= AppConstants.totalLevels; i++) {
          _prefs!.remove('cached_level_$i');
        }
      }
    }

    debugPrint(
      'Loaded levels.bin (${(bytes.length / 1024).toStringAsFixed(0)} KB, '
      '${decoder.levelCount} levels, v${decoder.version})',
    );
  }

  /// Get a level synchronously. Always returns a level model.
  LevelModel getLevel(int levelNumber) {
    return _lookup(levelNumber) ?? _generateAndCache(levelNumber);
  }

  /// Asynchronously warm up [levelNumber]. Safe to call multiple times.
  Future<void> preGenerateAsync(int levelNumber) async {
    if (isCached(levelNumber) && _cache.containsKey(levelNumber)) return;
    try {
      await getLevelAsync(levelNumber);
    } catch (e) {
      debugPrint('preGenerateAsync($levelNumber) failed: $e');
    }
  }

  /// Asynchronously warm up a range of levels.
  Future<void> preGenerateRangeAsync(int from, int count) async {
    for (int i = from; i < from + count; i++) {
      unawaited(preGenerateAsync(i));
    }
  }

  /// Async get — same sources as [getLevel], with shared in-flight work.
  /// Completes even when background generation fails (sync emergency fallback).
  Future<LevelModel> getLevelAsync(int levelNumber) async {
    final hit = _lookup(levelNumber);
    if (hit != null) return hit;

    final pending = _inflight[levelNumber];
    if (pending != null) return pending;

    final future = _loadGenerated(levelNumber);
    _inflight[levelNumber] = future;
    try {
      return await future;
    } finally {
      if (identical(_inflight[levelNumber], future)) {
        _inflight.remove(levelNumber);
      }
    }
  }

  Future<LevelModel> _loadGenerated(int levelNumber) async {
    // Another caller may have filled cache while we waited to start.
    final raced = _lookup(levelNumber);
    if (raced != null) return raced;

    // Custom generators (tests) stay on the calling isolate.
    if (!_usesDefaultGenerator) {
      return _generateAndCache(levelNumber);
    }

    try {
      final level = await compute(_generateLevelIsolate, levelNumber);
      _cache[levelNumber] = level;
      _saveToDisk(levelNumber, level);
      return level;
    } catch (e) {
      debugPrint('Async generate failed for level $levelNumber: $e');
      // Emergency fallback — not campaign-verified packaged data.
      return _generateAndCache(levelNumber);
    }
  }

  LevelModel? _lookup(int levelNumber) {
    // 1. In-memory cache
    final cached = _cache[levelNumber];
    if (cached != null) return cached;

    // 2. Packaged binary asset
    final decoder = _binaryDecoder;
    if (_binaryLoaded && decoder != null) {
      try {
        final level = decoder.decodeLevelByNumber(levelNumber);
        if (level != null) {
          _cache[levelNumber] = level;
          return level;
        }
      } on FormatException catch (e) {
        debugPrint('Binary level $levelNumber rejected: $e');
      } catch (e) {
        debugPrint('Binary level $levelNumber decode error: $e');
      }
    }

    // 3. Disk cache (skipped during playtest attach)
    if (!_skipDiskLevelCache && _prefs != null) {
      final jsonStr = _prefs!.getString('cached_level_$levelNumber');
      if (jsonStr != null) {
        try {
          final level = LevelModel.fromJson(jsonDecode(jsonStr));
          _cache[levelNumber] = level;
          return level;
        } catch (e) {
          debugPrint('Error decoding cached level $levelNumber: $e');
        }
      }
    }

    return null;
  }

  LevelModel _generateAndCache(int levelNumber) {
    final level = _generate(levelNumber);
    _cache[levelNumber] = level;
    _saveToDisk(levelNumber, level);
    return level;
  }

  /// True if [levelNumber] is available without starting a new generate job.
  bool isCached(int levelNumber) {
    if (_cache.containsKey(levelNumber)) return true;
    if (_binaryLoaded && _binaryDecoder != null) {
      final idx = levelNumber - 1;
      return idx >= 0 && idx < _binaryDecoder!.levelCount;
    }
    if (!_skipDiskLevelCache &&
        _prefs != null &&
        _prefs!.containsKey('cached_level_$levelNumber')) {
      return true;
    }
    return false;
  }

  /// Trim in-memory cache, keeping levels around [currentLevel].
  void trimCache(int currentLevel) {
    final keys = _cache.keys.toList();
    for (final key in keys) {
      if (key < currentLevel - 5 || key > currentLevel + 10) {
        _cache.remove(key);
      }
    }
  }

  void _saveToDisk(int levelNumber, LevelModel level) {
    if (_prefs == null || _skipDiskLevelCache) return;
    try {
      _prefs!
          .setString('cached_level_$levelNumber', jsonEncode(level.toJson()));
    } catch (e) {
      debugPrint('Error saving level to disk: $e');
    }
  }

  static int get totalLevels => AppConstants.totalLevels;
}

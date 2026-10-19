import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:arrow_escape/core/constants.dart';
import 'package:arrow_escape/data/level_binary_codec.dart';
import 'package:arrow_escape/data/models/arrow.dart';
import 'package:arrow_escape/data/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

LevelModel _sampleLevel({
  int levelNumber = 1,
  int gridSize = 4,
  MaskShape shape = MaskShape.square,
}) {
  final arrows = [
    ArrowModel(
      id: 'a_${levelNumber}_0',
      row: 1,
      col: 1,
      direction: ArrowDirection.right,
      path: const [
        [1, 1],
        [1, 2],
      ],
    ),
  ];
  return LevelModel(
    levelNumber: levelNumber,
    gridSize: gridSize,
    arrows: arrows,
    patternName: 'sample',
    difficulty: Difficulty.easy,
    solutionOrder: ['a_${levelNumber}_0'],
    maskShape: shape,
    mask: {'1,1', '1,2'},
  );
}

Uint8List _header({
  required int version,
  required int count,
  List<int> magic = const [0x4C, 0x56, 0x4C, 0x42],
}) {
  final out = ByteData(8);
  for (var i = 0; i < 4; i++) {
    out.setUint8(i, magic[i]);
  }
  out.setUint16(4, version, Endian.little);
  out.setUint16(6, count, Endian.little);
  return out.buffer.asUint8List();
}

/// Minimal legacy v2 record: empty arrows, empty solution, empty mask/orphans.
Uint8List _legacyV2Bundle({
  required int levelNumber,
  required int gridSize,
  int shapeIndex = 0,
  int difficultyIndex = 1,
}) {
  final maskBytes = (gridSize * gridSize + 7) ~/ 8;
  final name = utf8.encode('legacy');
  final record = BytesBuilder();
  void u8(int v) => record.addByte(v & 0xFF);
  void u16(int v) {
    u8(v);
    u8(v >> 8);
  }

  u16(levelNumber);
  u8(gridSize);
  u8(shapeIndex); // v2: 1-byte shape
  u8(difficultyIndex);
  u8(name.length);
  record.add(name);
  u16(0); // arrows
  u16(0); // solution
  record.add(Uint8List(maskBytes));
  u16(0); // orphans

  final body = record.toBytes();
  final out = BytesBuilder();
  out.add(_header(version: 2, count: 1));
  final index = ByteData(4)..setUint32(0, 0, Endian.little);
  out.add(index.buffer.asUint8List());
  out.add(body);
  return out.toBytes();
}

void main() {
  group('LevelBinaryDecoder hardening', () {
    test('decodes a valid current-version (v3) bundle', () {
      final original = _sampleLevel(levelNumber: 9, gridSize: 6);
      final bytes = encodeLevels([original]);
      final decoder = LevelBinaryDecoder.fromBytes(bytes);
      expect(decoder.version, 3);
      expect(decoder.levelCount, 1);
      final decoded = decoder.decodeLevelByNumber(1);
      expect(decoded, isNotNull);
      expect(decoded!.levelNumber, original.levelNumber);
      expect(decoded.gridSize, original.gridSize);
      expect(decoded.arrows.length, original.arrows.length);
      expect(decoded.mask, original.mask);
      expect(decoded.patternName, original.patternName);
    });

    test('decodes a supported legacy v2 bundle', () {
      final bytes = _legacyV2Bundle(levelNumber: 4, gridSize: 5);
      final decoder = LevelBinaryDecoder.fromBytes(bytes);
      expect(decoder.version, 2);
      expect(decoder.levelCount, 1);
      final level = decoder.decodeLevelByNumber(1);
      expect(level, isNotNull);
      expect(level!.levelNumber, 4);
      expect(level.gridSize, 5);
      expect(level.arrows, isEmpty);
      expect(level.maskShape, MaskShape.square);
    });

    test('rejects invalid magic', () {
      final bad = _header(version: 3, count: 0, magic: [1, 2, 3, 4]);
      expect(
        () => LevelBinaryDecoder.fromBytes(bad),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('bad magic'),
        )),
      );
    });

    test('rejects unsupported version', () {
      final bad = _header(version: 99, count: 0);
      expect(
        () => LevelBinaryDecoder.fromBytes(bad),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('Unsupported'),
        )),
      );
    });

    test('rejects truncated header', () {
      expect(
        () => LevelBinaryDecoder.fromBytes(Uint8List.fromList([0x4C, 0x56])),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('truncated header'),
        )),
      );
    });

    test('rejects truncated index table', () {
      final bytes = BytesBuilder()
        ..add(_header(version: 3, count: 2))
        ..add([0, 0]); // only 2 of 8 index bytes
      expect(
        () => LevelBinaryDecoder.fromBytes(bytes.toBytes()),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('truncated index'),
        )),
      );
    });

    test('rejects offset past data section', () {
      final out = BytesBuilder()..add(_header(version: 3, count: 1));
      final index = ByteData(4)..setUint32(0, 50, Endian.little);
      out.add(index.buffer.asUint8List());
      // data section shorter than offset
      out.add([1, 2, 3]);
      expect(
        () => LevelBinaryDecoder.fromBytes(out.toBytes()),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('offset'),
        )),
      );
    });

    test('rejects truncated level payload', () {
      final out = BytesBuilder()..add(_header(version: 3, count: 1));
      final index = ByteData(4)..setUint32(0, 0, Endian.little);
      out.add(index.buffer.asUint8List());
      out.add([1, 0]); // only levelNumber bytes
      final decoder = LevelBinaryDecoder.fromBytes(out.toBytes());
      expect(
        () => decoder.decodeLevelByNumber(1),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('truncated'),
        )),
      );
    });

    test('rejects impossible gridSize', () {
      final level = _sampleLevel(gridSize: 4);
      final bytes = encodeLevels([level]);
      // Patch gridSize byte (offset: dataStart + 2 after levelNumber u16)
      final dataStart = 8 + 4;
      bytes[dataStart + 2] = 0;
      expect(
        () => LevelBinaryDecoder.fromBytes(bytes).decodeLevelByNumber(1),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('gridSize'),
        )),
      );
    });

    test('rejects oversized arrowCount', () {
      final level = _sampleLevel(gridSize: 4);
      final bytes = encodeLevels([level]);
      final dataStart = 8 + 4;
      // layout: u16 level, u8 grid, u16 shape, u8 diff, u8 nameLen, name, u16 arrows
      final nameLen = bytes[dataStart + 2 + 1 + 2 + 1];
      final arrowCountAt = dataStart + 2 + 1 + 2 + 1 + 1 + nameLen;
      bytes[arrowCountAt] = 0xFF;
      bytes[arrowCountAt + 1] = 0xFF;
      expect(
        () => LevelBinaryDecoder.fromBytes(bytes).decodeLevelByNumber(1),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('arrowCount'),
        )),
      );
    });

    test('returns null for a level absent from the packaged index', () {
      final bytes = encodeLevels([_sampleLevel(levelNumber: 1)]);
      final decoder = LevelBinaryDecoder.fromBytes(bytes);
      expect(decoder.decodeLevelByNumber(2), isNull);
      expect(decoder.decodeLevelByNumber(0), isNull);
    });
  });

  group('packaged assets/levels.bin', () {
    test('matches LVLB v3 with totalLevels decodable records', () {
      final file = File('assets/levels.bin');
      expect(file.existsSync(), isTrue);
      final bytes = file.readAsBytesSync();
      final decoder = LevelBinaryDecoder.fromBytes(bytes);
      expect(decoder.version, 3);
      expect(decoder.levelCount, AppConstants.totalLevels);

      for (final n in [1, 2, 3, 4, 7, 10, 500, 1000]) {
        final level = decoder.decodeLevelByNumber(n);
        expect(level, isNotNull, reason: 'level $n');
        expect(level!.levelNumber, n);
        expect(level.gridSize, inInclusiveRange(1, 64));
        expect(level.arrows, isNotEmpty);
      }
      expect(decoder.decodeLevelByNumber(AppConstants.totalLevels + 1), isNull);
    });
  });
}

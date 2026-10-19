import 'dart:convert';
import 'dart:typed_data';

import 'models/arrow.dart';
import 'models/level.dart';

// ─── Binary Format Spec (v3) ──────────────────────────────────────────────────
//
// HEADER         (8 bytes)
//   4 bytes  magic: 0x4C 0x56 0x4C 0x42  ('LVLB')
//   2 bytes  version: uint16 = 3  (v2 files are still readable)
//   2 bytes  levelCount: uint16
//
// INDEX TABLE    (levelCount × 4 bytes)
//   uint32   byte offset of each level's data, relative to start of DATA SECTION
//
// DATA SECTION   (variable)
//   For each level:
//     2 bytes  levelNumber (uint16)
//     1 byte   gridSize
//     2 bytes  maskShape index (uint16; 1 byte in v2)
//     1 byte   difficulty index
//     1 byte   patternName length (in bytes)
//     N bytes  patternName (UTF-8)
//     2 bytes  arrowCount (uint16)
//
//     [ARROWS] × arrowCount
//       1 byte  row
//       1 byte  col
//       1 byte  packed: direction(2b) | mechanic(2b) | isPartOfPattern(1b) | reserved(3b)
//       1 byte  colorGroup (0xFF = null)
//       1 byte  pathStepCount  (steps AFTER the head cell)
//       pathStepCount bytes: step direction (0=up,1=down,2=left,3=right)
//
//     2 bytes  solutionOrderCount (uint16)
//     [SOLUTION ORDER] × solutionOrderCount: arrow index (uint16; uint8 in v2)
//
//     ceil(gridSize²/8) bytes: mask bitmask, row-major, MSB first
//
//     2 bytes  orphanDotCount (uint16)
//     [ORPHAN DOTS] × orphanDotCount × 3 bytes:
//       1 byte  row
//       1 byte  col
//       1 byte  type index
//
// ─────────────────────────────────────────────────────────────────────────────

const _kMagic = [0x4C, 0x56, 0x4C, 0x42]; // 'LVLB'
const _kVersion = 3;
const _kLegacyVersion = 2;
const _kHeaderSize = 8;

/// Hard ceiling for structural decode safety (campaign grids are ≤ 40).
const _kDecodeMaxGridSize = 64;

// ─── Encoder ─────────────────────────────────────────────────────────────────

/// Encodes a list of [LevelModel] objects into a compact binary [Uint8List].
Uint8List encodeLevels(List<LevelModel> levels) {
  // 1. Encode each level individually, collect byte arrays.
  final encodedLevels = levels.map(_encodeLevel).toList();

  final headerSize = _kHeaderSize;
  final indexSize = levels.length * 4;
  final dataSize = encodedLevels.fold<int>(0, (sum, b) => sum + b.length);
  final totalSize = headerSize + indexSize + dataSize;

  final out = ByteData(totalSize);
  int pos = 0;

  // Header
  for (final b in _kMagic) {
    out.setUint8(pos++, b);
  }
  out.setUint16(pos, _kVersion, Endian.little);
  pos += 2;
  out.setUint16(pos, levels.length, Endian.little);
  pos += 2;

  // Index table — offsets relative to start of data section
  int dataOffset = 0;
  for (final encoded in encodedLevels) {
    out.setUint32(pos, dataOffset, Endian.little);
    pos += 4;
    dataOffset += encoded.length;
  }

  // Data section
  for (final encoded in encodedLevels) {
    for (int i = 0; i < encoded.length; i++) {
      out.setUint8(pos++, encoded[i]);
    }
  }

  return out.buffer.asUint8List();
}

Uint8List _encodeLevel(LevelModel level) {
  final buf = _ByteWriter();

  buf.writeUint16(level.levelNumber);
  buf.writeUint8(level.gridSize);
  buf.writeUint16(level.maskShape.index);
  buf.writeUint8(level.difficulty.index);
  buf.writeString(level.patternName);
  buf.writeUint16(level.arrows.length);

  for (final arrow in level.arrows) {
    buf.writeUint8(arrow.row);
    buf.writeUint8(arrow.col);

    // packed byte: direction(2b) | mechanic(2b) | isPartOfPattern(1b) | 0(3b)
    final packed = (arrow.direction.index & 0x3) |
        ((arrow.mechanic.index & 0x3) << 2) |
        ((arrow.isPartOfPattern ? 1 : 0) << 4);
    buf.writeUint8(packed);

    buf.writeUint8(arrow.colorGroup ?? 0xFF);

    // Path: head is at path[0], each subsequent step encoded as a delta direction.
    final steps = _encodePathSteps(arrow.path);
    buf.writeUint8(steps.length); // max path length ~255 in practice
    for (final s in steps) {
      buf.writeUint8(s);
    }
  }

  // Solution order: stored as arrow indices
  final arrowIdToIndex = <String, int>{};
  for (int i = 0; i < level.arrows.length; i++) {
    arrowIdToIndex[level.arrows[i].id] = i;
  }
  buf.writeUint16(level.solutionOrder.length);
  for (final id in level.solutionOrder) {
    buf.writeUint16(arrowIdToIndex[id] ?? 0);
  }

  // Mask as bitmask (row-major, MSB first within each byte)
  final gs = level.gridSize;
  final maskBitCount = gs * gs;
  final maskByteCount = (maskBitCount + 7) ~/ 8;
  final maskBytes = Uint8List(maskByteCount);
  for (final cell in level.mask) {
    final comma = cell.indexOf(',');
    final r = int.parse(cell.substring(0, comma));
    final c = int.parse(cell.substring(comma + 1));
    final bit = r * gs + c;
    maskBytes[bit >> 3] |= (0x80 >> (bit & 7));
  }
  buf.writeBytes(maskBytes);

  // Orphan dots
  buf.writeUint16(level.orphanDots.length);
  for (final dot in level.orphanDots) {
    buf.writeUint8(dot.row);
    buf.writeUint8(dot.col);
    buf.writeUint8(dot.type.index);
  }

  return buf.toBytes();
}

/// Converts path (list of [row,col] pairs) to delta step directions.
List<int> _encodePathSteps(List<List<int>> path) {
  final steps = <int>[];
  for (int i = 0; i < path.length - 1; i++) {
    final dr = path[i + 1][0] - path[i][0];
    final dc = path[i + 1][1] - path[i][1];
    if (dr == -1) {
      steps.add(0); // up
    } else if (dr == 1) {
      steps.add(1); // down
    } else if (dc == -1) {
      steps.add(2); // left
    } else {
      steps.add(3); // right
    }
  }
  return steps;
}

// ─── Decoder ─────────────────────────────────────────────────────────────────

/// Decodes binary level data produced by [encodeLevels].
/// Provides O(1) random access to any level via an index table.
class LevelBinaryDecoder {
  final ByteData _data;
  final int _levelCount;
  final int _dataStart;
  final int _version;
  final List<int> _offsets;

  LevelBinaryDecoder._(
    this._data,
    this._levelCount,
    this._dataStart,
    this._version,
    this._offsets,
  );

  /// Parse the header and construct the decoder.
  /// Throws [FormatException] on magic/version mismatch or structural damage.
  factory LevelBinaryDecoder.fromBytes(Uint8List bytes) {
    if (bytes.length < _kHeaderSize) {
      throw FormatException(
        'Invalid levels.bin: truncated header (${bytes.length} bytes)',
      );
    }
    final data = ByteData.sublistView(bytes);

    for (int i = 0; i < 4; i++) {
      if (data.getUint8(i) != _kMagic[i]) {
        throw const FormatException('Invalid levels.bin: bad magic');
      }
    }

    final version = data.getUint16(4, Endian.little);
    if (version != _kVersion && version != _kLegacyVersion) {
      throw FormatException('Unsupported levels.bin version: $version');
    }

    final levelCount = data.getUint16(6, Endian.little);
    const indexTableStart = _kHeaderSize;
    final indexBytes = levelCount * 4;
    if (bytes.length < indexTableStart + indexBytes) {
      throw FormatException(
        'Invalid levels.bin: truncated index table '
        '(count=$levelCount, need ${indexTableStart + indexBytes}, have ${bytes.length})',
      );
    }

    final dataStart = indexTableStart + indexBytes;
    final dataLength = bytes.length - dataStart;
    final offsets = List<int>.filled(levelCount, 0);
    for (var i = 0; i < levelCount; i++) {
      final offset = data.getUint32(indexTableStart + i * 4, Endian.little);
      if (offset > dataLength) {
        throw FormatException(
          'Invalid levels.bin: level ${i + 1} offset $offset '
          'exceeds data length $dataLength',
        );
      }
      offsets[i] = offset;
    }

    return LevelBinaryDecoder._(
      data,
      levelCount,
      dataStart,
      version,
      offsets,
    );
  }

  int get levelCount => _levelCount;

  /// Binary format version (2 or 3).
  int get version => _version;

  /// Decode a level by its 1-based level number.
  /// Returns null if out of range. Throws [FormatException] if the record
  /// is truncated or structurally invalid.
  LevelModel? decodeLevelByNumber(int levelNumber) {
    final idx = levelNumber - 1;
    if (idx < 0 || idx >= _levelCount) return null;
    return _decodeLevelAtIndex(idx);
  }

  /// Decode all levels eagerly (only for tools, not for device use).
  List<LevelModel> decodeAll() {
    return List.generate(_levelCount, _decodeLevelAtIndex);
  }

  LevelModel _decodeLevelAtIndex(int idx) {
    final offsetInData = _offsets[idx];
    final reader =
        _ByteReader(_data, _dataStart + offsetInData, _data.lengthInBytes);
    try {
      return _decodeLevel(reader);
    } on FormatException {
      rethrow;
    } on RangeError catch (e) {
      throw FormatException(
        'Invalid levels.bin: out-of-bounds read for level index ${idx + 1}: $e',
      );
    }
  }

  LevelModel _decodeLevel(_ByteReader r) {
    final levelNumber = r.readUint16();
    final gridSize = r.readUint8();
    if (gridSize < 1 || gridSize > _kDecodeMaxGridSize) {
      throw FormatException(
        'Invalid levels.bin: gridSize $gridSize out of range 1..$_kDecodeMaxGridSize '
        '(level $levelNumber)',
      );
    }

    final shapeIndex =
        _version == _kLegacyVersion ? r.readUint8() : r.readUint16();
    if (shapeIndex < 0 || shapeIndex >= MaskShape.values.length) {
      throw FormatException(
        'Invalid levels.bin: maskShape index $shapeIndex '
        '(level $levelNumber)',
      );
    }
    final maskShape = MaskShape.values[shapeIndex];

    final difficultyIndex = r.readUint8();
    if (difficultyIndex < 0 || difficultyIndex >= Difficulty.values.length) {
      throw FormatException(
        'Invalid levels.bin: difficulty index $difficultyIndex '
        '(level $levelNumber)',
      );
    }
    final difficulty = Difficulty.values[difficultyIndex];
    final patternName = r.readString();
    final arrowCount = r.readUint16();
    final cellBudget = gridSize * gridSize;
    if (arrowCount > cellBudget) {
      throw FormatException(
        'Invalid levels.bin: arrowCount $arrowCount exceeds grid cells '
        '$cellBudget (level $levelNumber)',
      );
    }

    final arrows = <ArrowModel>[];
    for (int i = 0; i < arrowCount; i++) {
      final row = r.readUint8();
      final col = r.readUint8();
      if (row >= gridSize || col >= gridSize) {
        throw FormatException(
          'Invalid levels.bin: arrow[$i] cell ($row,$col) outside '
          '${gridSize}x$gridSize (level $levelNumber)',
        );
      }
      final packed = r.readUint8();
      final direction = ArrowDirection.values[packed & 0x3];
      final mechanic = SnakeMechanic.values[(packed >> 2) & 0x3];
      final isPartOfPattern = ((packed >> 4) & 0x1) == 1;
      final colorGroupRaw = r.readUint8();
      final colorGroup = colorGroupRaw == 0xFF ? null : colorGroupRaw;

      final stepCount = r.readUint8();
      final path = <List<int>>[
        [row, col]
      ];
      for (int s = 0; s < stepCount; s++) {
        final stepDir = r.readUint8();
        if (stepDir > 3) {
          throw FormatException(
            'Invalid levels.bin: arrow[$i] path step $stepDir '
            '(level $levelNumber)',
          );
        }
        final last = path.last;
        switch (stepDir) {
          case 0:
            path.add([last[0] - 1, last[1]]);
          case 1:
            path.add([last[0] + 1, last[1]]);
          case 2:
            path.add([last[0], last[1] - 1]);
          default:
            path.add([last[0], last[1] + 1]);
        }
      }

      arrows.add(ArrowModel(
        id: 'a_${levelNumber}_$i',
        row: row,
        col: col,
        direction: direction,
        state: ArrowState.idle,
        isPartOfPattern: isPartOfPattern,
        mechanic: mechanic,
        colorGroup: colorGroup,
        path: path,
      ));
    }

    final solCount = r.readUint16();
    if (solCount > arrowCount) {
      throw FormatException(
        'Invalid levels.bin: solutionOrder length $solCount exceeds '
        'arrowCount $arrowCount (level $levelNumber)',
      );
    }
    final solutionOrder = <String>[];
    for (int i = 0; i < solCount; i++) {
      final arrowIdx =
          _version == _kLegacyVersion ? r.readUint8() : r.readUint16();
      if (arrowIdx >= arrowCount) {
        throw FormatException(
          'Invalid levels.bin: solution index $arrowIdx out of range '
          '(level $levelNumber)',
        );
      }
      solutionOrder.add('a_${levelNumber}_$arrowIdx');
    }

    final maskBitCount = gridSize * gridSize;
    final maskByteCount = (maskBitCount + 7) ~/ 8;
    final maskBytes = r.readBytes(maskByteCount);
    final mask = <String>{};
    for (int bit = 0; bit < maskBitCount; bit++) {
      if ((maskBytes[bit >> 3] & (0x80 >> (bit & 7))) != 0) {
        final row = bit ~/ gridSize;
        final col = bit % gridSize;
        mask.add('$row,$col');
      }
    }

    final orphanCount = r.readUint16();
    if (orphanCount > cellBudget) {
      throw FormatException(
        'Invalid levels.bin: orphanDotCount $orphanCount exceeds grid cells '
        '$cellBudget (level $levelNumber)',
      );
    }
    final orphanDots = <OrphanDot>[];
    for (int i = 0; i < orphanCount; i++) {
      final row = r.readUint8();
      final col = r.readUint8();
      final typeIndex = r.readUint8();
      if (typeIndex >= OrphanDotType.values.length) {
        throw FormatException(
          'Invalid levels.bin: orphan type $typeIndex (level $levelNumber)',
        );
      }
      orphanDots.add(OrphanDot(
        row: row,
        col: col,
        type: OrphanDotType.values[typeIndex],
      ));
    }

    return LevelModel(
      levelNumber: levelNumber,
      gridSize: gridSize,
      arrows: arrows,
      patternName: patternName,
      difficulty: difficulty,
      solutionOrder: solutionOrder,
      maskShape: maskShape,
      mask: mask,
      orphanDots: orphanDots,
    );
  }
}

// ─── Internal helpers ─────────────────────────────────────────────────────────

class _ByteWriter {
  final List<int> _bytes = [];

  void writeUint8(int v) => _bytes.add(v & 0xFF);

  void writeUint16(int v) {
    _bytes.add(v & 0xFF);
    _bytes.add((v >> 8) & 0xFF);
  }

  /// Write a short UTF-8 string (length-prefixed, max 255 bytes).
  void writeString(String s) {
    final encoded = utf8.encode(s);
    writeUint8(encoded.length);
    _bytes.addAll(encoded);
  }

  void writeBytes(Uint8List bytes) => _bytes.addAll(bytes);

  Uint8List toBytes() => Uint8List.fromList(_bytes);
}

class _ByteReader {
  final ByteData _data;
  int _pos;
  final int _end;

  _ByteReader(this._data, int start, this._end) : _pos = start {
    if (start < 0 || start > _end || _end > _data.lengthInBytes) {
      throw FormatException(
        'Invalid levels.bin: reader range [$start,$_end) '
        'outside buffer (len=${_data.lengthInBytes})',
      );
    }
  }

  void _need(int count) {
    if (count < 0 || _pos + count > _end) {
      throw FormatException(
        'Invalid levels.bin: truncated record at offset $_pos '
        '(need $count bytes, end $_end)',
      );
    }
  }

  int readUint8() {
    _need(1);
    return _data.getUint8(_pos++);
  }

  int readUint16() {
    _need(2);
    final v = _data.getUint16(_pos, Endian.little);
    _pos += 2;
    return v;
  }

  /// Read a length-prefixed UTF-8 string.
  String readString() {
    final len = readUint8();
    final bytes = readBytes(len);
    try {
      return utf8.decode(bytes);
    } on FormatException catch (e) {
      throw FormatException('Invalid levels.bin: bad UTF-8 patternName ($e)');
    }
  }

  Uint8List readBytes(int count) {
    _need(count);
    final bytes = _data.buffer.asUint8List(_data.offsetInBytes + _pos, count);
    _pos += count;
    return bytes;
  }
}

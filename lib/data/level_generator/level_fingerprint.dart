import '../models/arrow.dart';
import '../models/level.dart';
import '../level_layout_profile.dart';

/// Normalized layout fingerprint for duplicate / near-duplicate detection.
class LevelFingerprint {
  LevelFingerprint._();

  static String canonicalHash(LevelModel level) {
    final variants = equivalenceHashes(level);
    return variants.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
  }

  static List<String> equivalenceHashes(LevelModel level) {
    final profile = LevelLayoutProfile.analyze(
      arrows: level.arrows,
      gridSize: level.gridSize,
      maskCells: level.mask.length,
      shapeType: level.maskShape.name,
    );
    final depSig = _dependencySignature(level, profile);
    final out = <String>[];
    for (final t in _transforms) {
      out.add(_hash(level, depSig, t));
    }
    return out;
  }

  static bool collidesWith(String hash, Set<String> seen) {
    if (seen.contains(hash)) return true;
    return false;
  }

  static String _dependencySignature(
      LevelModel level, LevelLayoutProfile profile) {
    final occupied = <int, int>{};
    for (var i = 0; i < level.arrows.length; i++) {
      for (final pt in level.arrows[i].path) {
        occupied[pt[0] * 1000 + pt[1]] = i;
      }
    }
    final edges = <String>[];
    for (var i = 0; i < level.arrows.length; i++) {
      final dir = level.arrows[i].direction.delta;
      var r = level.arrows[i].row + dir[0];
      var c = level.arrows[i].col + dir[1];
      while (r >= 0 &&
          r < level.gridSize &&
          c >= 0 &&
          c < level.gridSize) {
        final id = occupied[r * 1000 + c];
        if (id != null && id != i) {
          edges.add('$id>$i');
          break;
        }
        r += dir[0];
        c += dir[1];
      }
    }
    edges.sort();
    return edges.join(';');
  }

  static String _hash(
    LevelModel level,
    String depSig,
    _Transform t,
  ) {
    final cells = level.mask.map((k) {
      final p = k.split(',');
      return [int.parse(p[0]), int.parse(p[1])];
    }).toList();
    if (cells.isEmpty) return 'empty';

    var minR = 1 << 20, minC = 1 << 20;
    for (final c in cells) {
      if (c[0] < minR) minR = c[0];
      if (c[1] < minC) minC = c[1];
    }

    final normMask = cells.map((c) {
      final p = t.map(c[0] - minR, c[1] - minC, level.gridSize);
      return '${p[0]},${p[1]}';
    }).toList()
      ..sort();

    final arrowParts = <String>[];
    for (final a in level.arrows) {
      final rel = a.path.map((pt) {
        final p = t.map(pt[0] - minR, pt[1] - minC, level.gridSize);
        return '${p[0]},${p[1]}';
      }).join('>');
      arrowParts.add('${t.dir(a.direction)}:$rel');
    }
    arrowParts.sort();

    return '${normMask.join("|")}#${arrowParts.join("*")}#${level.maskShape.name}#$depSig';
  }

  static final _transforms = [
    _Transform.identity,
    _Transform.rotate90,
    _Transform.rotate180,
    _Transform.rotate270,
    _Transform.mirrorH,
    _Transform.mirrorV,
    _Transform.mirrorH90,
    _Transform.mirrorV90,
  ];
}

class _Transform {
  final List<int> Function(int r, int c, int size) map;
  final ArrowDirection Function(ArrowDirection d) dir;

  const _Transform(this.map, this.dir);

  static List<int> id(int r, int c, int size) => [r, c];

  static final identity = _Transform(id, (d) => d);

  static List<int> r90(int r, int c, int size) => [c, size - 1 - r];
  static final rotate90 = _Transform(r90, (d) {
    switch (d) {
      case ArrowDirection.up:
        return ArrowDirection.right;
      case ArrowDirection.right:
        return ArrowDirection.down;
      case ArrowDirection.down:
        return ArrowDirection.left;
      case ArrowDirection.left:
        return ArrowDirection.up;
    }
  });

  static List<int> r180(int r, int c, int size) =>
      [size - 1 - r, size - 1 - c];
  static final rotate180 = _Transform(r180, (d) {
    switch (d) {
      case ArrowDirection.up:
        return ArrowDirection.down;
      case ArrowDirection.down:
        return ArrowDirection.up;
      case ArrowDirection.left:
        return ArrowDirection.right;
      case ArrowDirection.right:
        return ArrowDirection.left;
    }
  });

  static List<int> r270(int r, int c, int size) => [size - 1 - c, r];
  static final rotate270 = _Transform(r270, (d) {
    switch (d) {
      case ArrowDirection.up:
        return ArrowDirection.left;
      case ArrowDirection.left:
        return ArrowDirection.down;
      case ArrowDirection.down:
        return ArrowDirection.right;
      case ArrowDirection.right:
        return ArrowDirection.up;
    }
  });

  static List<int> mh(int r, int c, int size) => [r, size - 1 - c];
  static final mirrorH = _Transform(mh, (d) {
    if (d == ArrowDirection.left) return ArrowDirection.right;
    if (d == ArrowDirection.right) return ArrowDirection.left;
    return d;
  });

  static List<int> mv(int r, int c, int size) => [size - 1 - r, c];
  static final mirrorV = _Transform(mv, (d) {
    if (d == ArrowDirection.up) return ArrowDirection.down;
    if (d == ArrowDirection.down) return ArrowDirection.up;
    return d;
  });

  static final mirrorH90 =
      _Transform((r, c, s) => r90(mh(r, c, s)[0], mh(r, c, s)[1], s), (d) {
    return mirrorH.dir(rotate90.dir(d));
  });

  static final mirrorV90 =
      _Transform((r, c, s) => r90(mv(r, c, s)[0], mv(r, c, s)[1], s), (d) {
    return mirrorV.dir(rotate90.dir(d));
  });
}

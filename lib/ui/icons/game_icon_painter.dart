import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/game_tokens.dart';
import 'game_icon_kind.dart';

/// Original dimensional icons. Drawn in a 100×100 space, then scaled.
///
/// No third-party artwork. Shadows are offset fills so a full level grid
/// can paint them without blur.
class GameIconPainter extends CustomPainter {
  GameIconPainter(this.kind);

  final GameIconKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 100;
    canvas.save();
    canvas.translate(
      (size.width - 100 * scale) / 2,
      (size.height - 100 * scale) / 2,
    );
    canvas.scale(scale);
    _draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GameIconPainter oldDelegate) =>
      oldDelegate.kind != kind;

  void _draw(Canvas canvas) {
    switch (kind) {
      case GameIconKind.coin:
        _coin(canvas, const Offset(50, 50), 34);
      case GameIconKind.coinStack:
        _coinStack(canvas, 3);
      case GameIconKind.coinStackLarge:
        _coinStack(canvas, 5);
      case GameIconKind.coinPile:
        _coinPile(canvas);
      case GameIconKind.coinBurst:
        _coin(canvas, const Offset(48, 52), 26);
        _sparkle(canvas, const Offset(82, 22), 10, GameColors.coinHi);
        _sparkle(canvas, const Offset(18, 30), 7, Colors.white);
        _sparkle(canvas, const Offset(78, 78), 6, GameColors.coin);
      case GameIconKind.coinFlying:
        canvas.save();
        canvas.translate(50, 50);
        canvas.rotate(-0.35);
        canvas.translate(-50, -50);
        _coin(canvas, const Offset(50, 50), 30);
        canvas.restore();
        _sparkle(canvas, const Offset(18, 70), 6, GameColors.coinHi);
      case GameIconKind.freeCoins:
        _coin(canvas, const Offset(46, 52), 28);
        _badge(canvas, GameColors.leaf, _plus);
      case GameIconKind.coinPurchase:
        _coinStack(canvas, 3);
        _badge(canvas, GameColors.sky, _tagGlyph);
      case GameIconKind.coinBonus:
        _coin(canvas, const Offset(44, 50), 28);
        _badge(canvas, GameColors.reward, _plus);
      case GameIconKind.dailyReward:
        _calendar(canvas);
        _coin(canvas, const Offset(70, 68), 16);
      case GameIconKind.gift:
        _gift(canvas, open: false);
      case GameIconKind.giftOpen:
        _gift(canvas, open: true);
      case GameIconKind.chest:
        _chest(canvas, open: false);
      case GameIconKind.chestOpen:
        _chest(canvas, open: true);
      case GameIconKind.undo:
        _hookArrow(canvas, pointsLeft: true);
      case GameIconKind.redo:
        _hookArrow(canvas, pointsLeft: false);
      case GameIconKind.hint:
        _hint(canvas);
      case GameIconKind.shuffle:
        _shuffle(canvas);
      case GameIconKind.freeze:
        _snow(canvas);
      case GameIconKind.remove:
        _eraser(canvas);
      case GameIconKind.reset:
        _restart(canvas, dot: true);
      case GameIconKind.refresh:
        _refresh(canvas);
      case GameIconKind.skip:
        _skip(canvas);
      case GameIconKind.continuePlay:
        _disc(canvas, const Offset(50, 50), 36, GameColors.leafHi,
            GameColors.leafDeep);
        _chevron(canvas,
            left: false, weight: 10, color: Colors.white, inset: 8);
      case GameIconKind.pause:
        _disc(canvas, const Offset(50, 50), 36, GameColors.sky,
            GameColors.skyDeep);
        _pauseBars(canvas);
      case GameIconKind.play:
        _disc(canvas, const Offset(50, 50), 36, GameColors.leafHi,
            GameColors.leafDeep);
        _playTriangle(canvas, const Offset(54, 50), 18, Colors.white);
      case GameIconKind.restart:
        _restart(canvas, dot: false);
      case GameIconKind.home:
        _house(canvas);
      case GameIconKind.settings:
        _gear(canvas);
      case GameIconKind.soundOn:
        _speaker(canvas, waves: true);
      case GameIconKind.soundOff:
        _speaker(canvas, waves: false);
        _friendlySlash(canvas);
      case GameIconKind.musicOn:
        _note(canvas);
      case GameIconKind.musicOff:
        _note(canvas);
        _friendlySlash(canvas);
      case GameIconKind.watchAd:
      case GameIconKind.rewardedAd:
        _watchAd(canvas);
      case GameIconKind.removeAds:
      case GameIconKind.noAds:
      case GameIconKind.adFree:
        _removeAds(canvas);
      case GameIconKind.freeReward:
      case GameIconKind.freeGift:
        _gift(canvas, open: kind == GameIconKind.freeGift);
        _sparkle(canvas, const Offset(80, 18), 8, GameColors.coinHi);
      case GameIconKind.doubleReward:
        _coin(canvas, const Offset(38, 56), 22);
        _coin(canvas, const Offset(62, 44), 22);
      case GameIconKind.claimReward:
        _gift(canvas, open: false);
        _badge(canvas, GameColors.leaf, _checkGlyph);
      case GameIconKind.getCoins:
      case GameIconKind.earnCoins:
        _coin(canvas, const Offset(50, 46), 26);
        _sparkle(canvas, const Offset(78, 24), 8, GameColors.coinHi);
      case GameIconKind.bonus:
        _star(canvas, const Offset(50, 50), 30, filled: true);
        _sparkle(canvas, const Offset(82, 20), 8, Colors.white);
      case GameIconKind.star:
      case GameIconKind.stars1:
        _star(canvas, const Offset(50, 50), 32, filled: true);
      case GameIconKind.starEmpty:
        _star(canvas, const Offset(50, 50), 32, filled: false);
      case GameIconKind.stars2:
        _star(canvas, const Offset(34, 52), 20, filled: true);
        _star(canvas, const Offset(66, 48), 20, filled: true);
      case GameIconKind.stars3:
        _star(canvas, const Offset(22, 56), 14, filled: true);
        _star(canvas, const Offset(50, 42), 16, filled: true);
        _star(canvas, const Offset(78, 56), 14, filled: true);
      case GameIconKind.levelComplete:
        _star(canvas, const Offset(50, 46), 28, filled: true);
        _badge(canvas, GameColors.leaf, _checkGlyph);
      case GameIconKind.levelLocked:
        _lock(canvas, open: false);
      case GameIconKind.levelUnlocked:
        _lock(canvas, open: true);
      case GameIconKind.newLevel:
        _star(canvas, const Offset(50, 54), 24, filled: true);
        _sparkle(canvas, const Offset(78, 24), 10, GameColors.coinHi);
      case GameIconKind.trophy:
        _trophy(canvas);
      case GameIconKind.crown:
        _crown(canvas);
      case GameIconKind.achievement:
        _medal(canvas);
      case GameIconKind.streak:
        _flame(canvas);
      case GameIconKind.progress:
        _progress(canvas);
      case GameIconKind.shop:
        _shop(canvas);
      case GameIconKind.coinBundle:
        _coinStack(canvas, 3);
      case GameIconKind.starterPack:
        _gift(canvas, open: false);
        _coin(canvas, const Offset(72, 72), 14);
      case GameIconKind.specialOffer:
        _tag(canvas);
        _sparkle(canvas, const Offset(78, 22), 8, GameColors.coinHi);
      case GameIconKind.bestValue:
        _coin(canvas, const Offset(50, 58), 24);
        _crownAt(canvas, const Offset(50, 28), 0.7);
      case GameIconKind.discount:
        _tag(canvas);
      case GameIconKind.limitedOffer:
        _tag(canvas);
        _badge(canvas, GameColors.sky, _clockGlyph);
      case GameIconKind.purchase:
        _bag(canvas);
      case GameIconKind.confirmPurchase:
        _bag(canvas);
        _badge(canvas, GameColors.leaf, _checkGlyph);
      case GameIconKind.heart:
        _heart(canvas, filled: true, cracked: false);
      case GameIconKind.heartEmpty:
        _heart(canvas, filled: false, cracked: false);
      case GameIconKind.heartBroken:
        _heart(canvas, filled: true, cracked: true);
      case GameIconKind.wand:
        _wand(canvas);
      case GameIconKind.ruler:
        _ruler(canvas);
      case GameIconKind.back:
        _disc(canvas, const Offset(50, 50), 36, GameColors.cream,
            const Color(0xFFE4DDD2));
        _chevron(canvas,
            left: true, weight: 10, color: GameColors.ink, inset: 6);
      case GameIconKind.eye:
        _eye(canvas);
      case GameIconKind.grid:
        _grid(canvas);
      case GameIconKind.album:
        _album(canvas);
      case GameIconKind.calendar:
        _calendar(canvas);
      case GameIconKind.wheel:
        _wheel(canvas);
      case GameIconKind.medal:
        _medal(canvas);
      case GameIconKind.haptic:
        _phone(canvas);
      case GameIconKind.theme:
        _sun(canvas);
      case GameIconKind.language:
        _globe(canvas);
      case GameIconKind.shield:
        _shield(canvas);
      case GameIconKind.chevron:
        _chevron(canvas,
            left: false, weight: 12, color: GameColors.ink, inset: 4);
      case GameIconKind.chevronDown:
        canvas.save();
        canvas.translate(50, 50);
        canvas.rotate(math.pi / 2);
        canvas.translate(-50, -50);
        _chevron(canvas,
            left: false, weight: 12, color: GameColors.ink, inset: 4);
        canvas.restore();
      case GameIconKind.palette:
        _palette(canvas);
      case GameIconKind.arrowMark:
        _disc(canvas, const Offset(50, 50), 36, GameColors.leafHi,
            GameColors.leafDeep);
        _chevronMark(canvas, const Offset(50, 52), 28, Colors.white);
      case GameIconKind.check:
        _disc(canvas, const Offset(50, 50), 36, GameColors.leafHi,
            GameColors.leafDeep);
        _checkGlyph(canvas, const Offset(50, 50), 22);
      case GameIconKind.info:
        _disc(canvas, const Offset(50, 50), 34, const Color(0xFFFFB15A),
            const Color(0xFFE07A1A));
      case GameIconKind.hourglass:
        _hourglass(canvas);
      case GameIconKind.more:
        _moreDots(canvas);
    }
  }

  Paint _vert(Rect rect, Color a, Color b) {
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [a, b],
      ).createShader(rect);
  }

  void _coin(Canvas canvas, Offset center, double r) {
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, r * 0.92),
        width: r * 1.5,
        height: r * 0.38,
      ),
      Paint()..color = const Color(0x33000000),
    );
    canvas.drawCircle(
      center.translate(0, r * 0.1),
      r,
      Paint()..color = GameColors.coinDeep,
    );
    final face = Rect.fromCircle(center: center, radius: r * 0.9);
    canvas.drawCircle(
        center, r * 0.9, _vert(face, GameColors.coinHi, GameColors.coinMid));
    canvas.drawCircle(
      center,
      r * 0.66,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.6, r * 0.08)
        ..color = const Color(0xFFFFF6D0),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-r * 0.16, -r * 0.28),
        width: r * 0.62,
        height: r * 0.3,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.62),
    );
    _chevronMark(
        canvas, center.translate(0, r * 0.06), r * 0.85, GameColors.coinInk);
  }

  void _coinStack(Canvas canvas, int count) {
    final r = count <= 3 ? 20.0 : 15.0;
    final gap = r * 0.55;
    final base = 74.0;
    for (var i = count - 1; i >= 0; i--) {
      _coin(canvas, Offset(50, base - i * gap), r);
    }
  }

  void _coinPile(Canvas canvas) {
    _coin(canvas, const Offset(30, 62), 16);
    _coin(canvas, const Offset(70, 64), 16);
    _coin(canvas, const Offset(50, 58), 16);
    _coin(canvas, const Offset(38, 46), 18);
    _coin(canvas, const Offset(62, 44), 18);
    _coin(canvas, const Offset(50, 34), 20);
  }

  void _chevronMark(Canvas canvas, Offset center, double r, Color color) {
    final path = Path()
      ..moveTo(center.dx - r * 0.36, center.dy + r * 0.08)
      ..lineTo(center.dx, center.dy - r * 0.32)
      ..lineTo(center.dx + r * 0.36, center.dy + r * 0.08);
    canvas.drawPath(
      path.shift(const Offset(0.6, 1.1)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, r * 0.16)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.35),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.2, r * 0.2)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  void _sparkle(Canvas canvas, Offset center, double s, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - s)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + s, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + s)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - s, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - s)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  Path _starPath(Offset center, double r) {
    final path = Path();
    const points = 5;
    final inner = r * 0.46;
    for (var i = 0; i < points * 2; i++) {
      final rad = i.isEven ? r : inner;
      final a = -math.pi / 2 + i * math.pi / points;
      final p =
          Offset(center.dx + math.cos(a) * rad, center.dy + math.sin(a) * rad);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  void _star(Canvas canvas, Offset center, double r, {required bool filled}) {
    final path = _starPath(center, r);
    if (!filled) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.8, r * 0.12)
          ..strokeJoin = StrokeJoin.round
          ..color = GameColors.missed,
      );
      return;
    }
    canvas.drawPath(path.shift(const Offset(0, 2.4)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(
      path,
      _vert(Rect.fromCircle(center: center, radius: r), GameColors.coinHi,
          GameColors.coinMid),
    );
  }

  void _disc(Canvas canvas, Offset center, double r, Color hi, Color lo) {
    canvas.drawCircle(
        center.translate(0, 4), r, Paint()..color = const Color(0x28000000));
    canvas.drawCircle(center.translate(0, r * 0.08), r, Paint()..color = lo);
    canvas.drawCircle(
      center,
      r * 0.92,
      _vert(Rect.fromCircle(center: center, radius: r), hi, lo),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-r * 0.12, -r * 0.34),
        width: r * 0.72,
        height: r * 0.34,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.38),
    );
  }

  void _badge(
      Canvas canvas, Color color, void Function(Canvas, Offset, double) glyph) {
    const center = Offset(78, 76);
    canvas.drawCircle(
        center.translate(0, 2), 16, Paint()..color = const Color(0x33000000));
    canvas.drawCircle(
        center,
        15,
        _vert(
            Rect.fromCircle(center: center, radius: 15), Colors.white, color));
    glyph(canvas, center, 9);
  }

  void _plus(Canvas canvas, Offset center, double s) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = math.max(2.4, s * 0.38)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        center.translate(-s * 0.55, 0), center.translate(s * 0.55, 0), paint);
    canvas.drawLine(
        center.translate(0, -s * 0.55), center.translate(0, s * 0.55), paint);
  }

  void _checkGlyph(Canvas canvas, Offset center, double s) {
    final path = Path()
      ..moveTo(center.dx - s * 0.55, center.dy)
      ..lineTo(center.dx - s * 0.12, center.dy + s * 0.42)
      ..lineTo(center.dx + s * 0.62, center.dy - s * 0.46);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.6, s * 0.28)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  void _tagGlyph(Canvas canvas, Offset center, double s) {
    final path = Path()
      ..moveTo(center.dx - s * 0.2, center.dy - s * 0.55)
      ..lineTo(center.dx + s * 0.55, center.dy - s * 0.55)
      ..lineTo(center.dx + s * 0.55, center.dy + s * 0.15)
      ..lineTo(center.dx, center.dy + s * 0.62)
      ..lineTo(center.dx - s * 0.55, center.dy + s * 0.15)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  void _clockGlyph(Canvas canvas, Offset center, double s) {
    canvas.drawCircle(
      center,
      s * 0.62,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
    canvas.drawLine(
      center,
      center.translate(0, -s * 0.36),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white,
    );
    canvas.drawLine(
      center,
      center.translate(s * 0.28, s * 0.08),
      Paint()
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white,
    );
  }

  void _playTriangle(Canvas canvas, Offset center, double r, Color color) {
    final path = Path()
      ..moveTo(center.dx + r * 0.78, center.dy)
      ..lineTo(center.dx - r * 0.5, center.dy - r * 0.62)
      ..lineTo(center.dx - r * 0.5, center.dy + r * 0.62)
      ..close();
    canvas.drawPath(path.shift(const Offset(0, 1.5)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(path, Paint()..color = color);
  }

  void _gift(Canvas canvas, {required bool open}) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(24, 48, 52, 34),
      const Radius.circular(8),
    );
    canvas.drawRRect(body.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(
        body, _vert(body.outerRect, GameColors.gift, GameColors.giftDeep));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(46, 48, 8, 34), const Radius.circular(2)),
      Paint()..color = GameColors.ribbon,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(24, 60, 52, 8), const Radius.circular(2)),
      Paint()..color = GameColors.ribbon,
    );
    if (open) {
      canvas.save();
      canvas.translate(50, 46);
      canvas.rotate(-0.45);
      canvas.translate(-50, -46);
    }
    final lid = RRect.fromRectAndRadius(
      const Rect.fromLTWH(20, 36, 60, 16),
      const Radius.circular(6),
    );
    canvas.drawRRect(
        lid, _vert(lid.outerRect, const Color(0xFFFF8A96), GameColors.gift));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(46, 36, 8, 16), const Radius.circular(2)),
      Paint()..color = GameColors.ribbon,
    );
    if (open) canvas.restore();
    _bow(canvas, Offset(50, open ? 30 : 34));
    if (open) {
      _coin(canvas, const Offset(50, 62), 10);
      _sparkle(canvas, const Offset(78, 28), 7, GameColors.coinHi);
    }
  }

  void _bow(Canvas canvas, Offset center) {
    final paint = Paint()..color = GameColors.ribbon;
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(-10, 0), width: 18, height: 12),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(10, 0), width: 18, height: 12),
      paint,
    );
    canvas.drawCircle(center, 4.5, Paint()..color = GameColors.coinDeep);
  }

  void _chest(Canvas canvas, {required bool open}) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 48, 64, 34),
      const Radius.circular(10),
    );
    canvas.drawRRect(body.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(
        body, _vert(body.outerRect, GameColors.chest, GameColors.chestDeep));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(18, 60, 64, 8), const Radius.circular(2)),
      Paint()..color = GameColors.coin,
    );
    canvas.drawCircle(
        const Offset(50, 64), 4, Paint()..color = GameColors.coinHi);
    if (open) {
      canvas.save();
      canvas.translate(22, 48);
      canvas.rotate(-0.7);
      canvas.translate(-22, -48);
    }
    final lid = RRect.fromRectAndRadius(
      Rect.fromLTWH(16, open ? 34 : 36, 68, 18),
      const Radius.circular(8),
    );
    canvas.drawRRect(
        lid, _vert(lid.outerRect, const Color(0xFFFFD08A), GameColors.chest));
    if (open) canvas.restore();
    if (open) {
      _coin(canvas, const Offset(42, 58), 9);
      _coin(canvas, const Offset(58, 60), 9);
      _sparkle(canvas, const Offset(78, 24), 7, GameColors.coinHi);
    }
  }

  void _hookArrow(Canvas canvas, {required bool pointsLeft}) {
    canvas.save();
    if (!pointsLeft) {
      canvas.translate(100, 0);
      canvas.scale(-1, 1);
    }
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = GameColors.skyDeep;
    final path = Path()
      ..moveTo(74, 34)
      ..quadraticBezierTo(76, 70, 42, 70);
    canvas.drawPath(path, paint);
    final head = Path()
      ..moveTo(22, 62)
      ..lineTo(42, 50)
      ..lineTo(42, 74)
      ..close();
    canvas.drawPath(head, Paint()..color = GameColors.skyDeep);
    canvas.restore();
  }

  void _hint(Canvas canvas) {
    _disc(canvas, const Offset(50, 44), 24, GameColors.coinHi,
        GameColors.coinMid);
    final neck = RRect.fromRectAndRadius(
      const Rect.fromLTWH(42, 62, 16, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(neck, Paint()..color = GameColors.coinDeep);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(40, 74, 20, 8), const Radius.circular(3)),
      Paint()..color = GameColors.coinInk,
    );
    for (final spot in const [Offset(18, 28), Offset(82, 26), Offset(84, 52)]) {
      canvas.drawLine(
        spot,
        spot.translate(spot.dx < 50 ? -8 : 8, spot.dy < 40 ? -6 : 0),
        Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = GameColors.coin,
      );
    }
  }

  void _shuffle(Canvas canvas) {
    _straightArrow(
        canvas, const Offset(22, 36), const Offset(78, 36), GameColors.skyDeep);
    _straightArrow(canvas, const Offset(78, 64), const Offset(22, 64),
        GameColors.leafDeep);
  }

  void _straightArrow(Canvas canvas, Offset from, Offset to, Color color) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    final tip = to;
    final a = tip + Offset(math.cos(angle + 2.5), math.sin(angle + 2.5)) * 12;
    final b = tip + Offset(math.cos(angle - 2.5), math.sin(angle - 2.5)) * 12;
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..close(),
      Paint()..color = color,
    );
  }

  void _snow(Canvas canvas) {
    _disc(canvas, const Offset(50, 50), 36, const Color(0xFFF3FBFF),
        GameColors.sky);
    final paint = Paint()
      ..color = GameColors.skyDeep
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawLine(
        const Offset(50, 50),
        Offset(50 + math.cos(a) * 20, 50 + math.sin(a) * 20),
        paint,
      );
    }
    canvas.drawCircle(const Offset(50, 50), 4, Paint()..color = Colors.white);
  }

  void _eraser(Canvas canvas) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(22, 36, 56, 32),
      const Radius.circular(10),
    );
    canvas.drawRRect(body.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(
        body,
        _vert(
            body.outerRect, const Color(0xFFFFB4AE), const Color(0xFFFF7A72)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(58, 36, 20, 32), const Radius.circular(8)),
      Paint()..color = const Color(0xFFFFF1EE),
    );
  }

  void _restart(Canvas canvas, {required bool dot}) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = GameColors.leafDeep;
    canvas.drawArc(
      const Rect.fromLTWH(24, 24, 52, 52),
      -math.pi * 0.15,
      math.pi * 1.55,
      false,
      paint,
    );
    _playTriangle(canvas, const Offset(74, 30), 10, GameColors.leafDeep);
    if (dot) {
      canvas.drawCircle(
          const Offset(50, 50), 6, Paint()..color = GameColors.leaf);
    }
  }

  void _refresh(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = GameColors.skyDeep;
    canvas.drawArc(
        const Rect.fromLTWH(26, 22, 48, 48), -0.4, 2.4, false, paint);
    canvas.drawArc(const Rect.fromLTWH(26, 30, 48, 48), 2.2, 2.4, false, paint);
    _playTriangle(canvas, const Offset(72, 28), 8, GameColors.skyDeep);
    _playTriangle(canvas, const Offset(28, 74), 8, GameColors.skyDeep);
  }

  void _skip(Canvas canvas) {
    _playTriangle(canvas, const Offset(40, 50), 16, GameColors.leafDeep);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(64, 32, 10, 36), const Radius.circular(4)),
      Paint()..color = GameColors.leafDeep,
    );
  }

  void _pauseBars(Canvas canvas) {
    final paint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(36, 32, 10, 36), const Radius.circular(4)),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(54, 32, 10, 36), const Radius.circular(4)),
      paint,
    );
  }

  void _chevron(
    Canvas canvas, {
    required bool left,
    required double weight,
    required Color color,
    required double inset,
  }) {
    canvas.save();
    if (left) {
      canvas.translate(100, 0);
      canvas.scale(-1, 1);
    }
    final path = Path()
      ..moveTo(38 + inset, 28)
      ..lineTo(64 - inset, 50)
      ..lineTo(38 + inset, 72);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = weight
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
    canvas.restore();
  }

  void _house(Canvas canvas) {
    final roof = Path()
      ..moveTo(50, 16)
      ..lineTo(86, 48)
      ..lineTo(14, 48)
      ..close();
    canvas.drawPath(roof.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(
        roof,
        _vert(const Rect.fromLTWH(14, 16, 72, 34), GameColors.gift,
            GameColors.giftDeep));
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(24, 46, 52, 38),
      const Radius.circular(6),
    );
    canvas.drawRRect(
        body, _vert(body.outerRect, GameColors.cream, const Color(0xFFE7D7C4)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(44, 60, 14, 24), const Radius.circular(3)),
      Paint()..color = GameColors.chestDeep,
    );
  }

  void _gear(Canvas canvas) {
    final path = Path();
    const teeth = 8;
    const outer = 34.0;
    const inner = 26.0;
    for (var i = 0; i < teeth * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / teeth;
      final p = Offset(50 + math.cos(a) * r, 50 + math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    path.addOval(Rect.fromCircle(center: const Offset(50, 50), radius: 12));
    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(
      path,
      _vert(const Rect.fromLTWH(16, 16, 68, 68), const Color(0xFFD5DDD0),
          GameColors.ink),
    );
  }

  void _speaker(Canvas canvas, {required bool waves}) {
    final body = Path()
      ..moveTo(22, 40)
      ..lineTo(38, 40)
      ..lineTo(58, 26)
      ..lineTo(58, 74)
      ..lineTo(38, 60)
      ..lineTo(22, 60)
      ..close();
    canvas.drawPath(body.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(
        body,
        _vert(const Rect.fromLTWH(22, 26, 36, 48), GameColors.leafHi,
            GameColors.leafDeep));
    if (!waves) return;
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = GameColors.leafDeep;
    canvas.drawArc(const Rect.fromLTWH(52, 36, 18, 28), -0.8, 1.6, false, wave);
    canvas.drawArc(const Rect.fromLTWH(58, 28, 26, 44), -0.8, 1.6, false, wave);
  }

  void _friendlySlash(Canvas canvas) {
    canvas.drawLine(
      const Offset(24, 78),
      const Offset(78, 22),
      Paint()
        ..color = GameColors.cream
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(24, 78),
      const Offset(78, 22),
      Paint()
        ..color = GameColors.coinDeep
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  void _note(Canvas canvas) {
    canvas.drawCircle(
        const Offset(36, 70), 12, Paint()..color = const Color(0x33000000));
    canvas.drawCircle(
      const Offset(36, 68),
      12,
      _vert(const Rect.fromLTWH(24, 56, 24, 24), GameColors.premiumHi,
          GameColors.premium),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(46, 24, 8, 46), const Radius.circular(3)),
      Paint()..color = GameColors.premiumDeep,
    );
    final flag = Path()
      ..moveTo(54, 24)
      ..quadraticBezierTo(78, 28, 72, 46)
      ..quadraticBezierTo(62, 40, 54, 42)
      ..close();
    canvas.drawPath(flag, Paint()..color = GameColors.premium);
  }

  void _watchAd(Canvas canvas) {
    final bezel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(14, 22, 62, 50),
      const Radius.circular(12),
    );
    canvas.drawRRect(bezel.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(
        bezel,
        _vert(
            bezel.outerRect, const Color(0xFF4E5D73), const Color(0xFF2C3848)));
    final face = RRect.fromRectAndRadius(
      const Rect.fromLTWH(20, 28, 50, 38),
      const Radius.circular(8),
    );
    canvas.drawRRect(
        face, _vert(face.outerRect, const Color(0xFFE8F6FF), GameColors.sky));
    _playTriangle(canvas, const Offset(46, 47), 12, Colors.white);
    _sparkle(canvas, const Offset(24, 16), 6, GameColors.coinHi);
    _coin(canvas, const Offset(74, 70), 16);
  }

  void _removeAds(Canvas canvas) {
    final card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 24, 64, 52),
      const Radius.circular(12),
    );
    canvas.drawRRect(card.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(
        card, _vert(card.outerRect, GameColors.cream, const Color(0xFFE4D8C8)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(26, 32, 48, 28), const Radius.circular(6)),
      Paint()..color = const Color(0xFFD5E4F2),
    );
    canvas.drawLine(
      const Offset(28, 68),
      const Offset(72, 30),
      Paint()
        ..color = GameColors.cream
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(28, 68),
      const Offset(72, 30),
      Paint()
        ..color = GameColors.premium
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    _sparkle(canvas, const Offset(82, 20), 8, GameColors.coinHi);
    _crownAt(canvas, const Offset(78, 78), 0.42);
  }

  void _lock(Canvas canvas, {required bool open}) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(26, 44, 48, 38),
      const Radius.circular(10),
    );
    canvas.drawRRect(body.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(
        body, _vert(body.outerRect, GameColors.coin, GameColors.coinDeep));
    final shackle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = open ? GameColors.leafDeep : GameColors.coinInk;
    canvas.drawArc(
      Rect.fromLTWH(open ? 40 : 32, 20, 36, 36),
      math.pi,
      math.pi,
      false,
      shackle,
    );
    canvas.drawCircle(
        const Offset(50, 62), 5, Paint()..color = GameColors.cream);
  }

  void _trophy(Canvas canvas) {
    final cup = Path()
      ..moveTo(30, 24)
      ..lineTo(70, 24)
      ..quadraticBezierTo(72, 52, 50, 62)
      ..quadraticBezierTo(28, 52, 30, 24)
      ..close();
    canvas.drawPath(cup.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(
        cup,
        _vert(const Rect.fromLTWH(28, 22, 44, 42), GameColors.coinHi,
            GameColors.coinMid));
    canvas.drawArc(
      const Rect.fromLTWH(16, 26, 18, 22),
      math.pi / 2,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = GameColors.coinDeep,
    );
    canvas.drawArc(
      const Rect.fromLTWH(66, 26, 18, 22),
      -math.pi / 2,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = GameColors.coinDeep,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(46, 60, 8, 14), const Radius.circular(2)),
      Paint()..color = GameColors.coinDeep,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(34, 72, 32, 10), const Radius.circular(4)),
      Paint()..color = GameColors.coinInk,
    );
  }

  void _crown(Canvas canvas) => _crownAt(canvas, const Offset(50, 50), 1);

  void _crownAt(Canvas canvas, Offset center, double scale) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-50, -50);
    final path = Path()
      ..moveTo(16, 68)
      ..lineTo(16, 40)
      ..lineTo(32, 54)
      ..lineTo(50, 28)
      ..lineTo(68, 54)
      ..lineTo(84, 40)
      ..lineTo(84, 68)
      ..close();
    canvas.drawPath(path.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(
        path,
        _vert(const Rect.fromLTWH(16, 28, 68, 42), GameColors.coinHi,
            GameColors.coinMid));
    canvas.drawCircle(
        const Offset(50, 26), 5, Paint()..color = GameColors.heart);
    canvas.restore();
  }

  void _medal(Canvas canvas) {
    final ribbon = Path()
      ..moveTo(34, 18)
      ..lineTo(46, 48)
      ..lineTo(34, 48)
      ..close();
    canvas.drawPath(ribbon, Paint()..color = GameColors.gift);
    canvas.drawPath(
      Path()
        ..moveTo(66, 18)
        ..lineTo(54, 48)
        ..lineTo(66, 48)
        ..close(),
      Paint()..color = GameColors.skyDeep,
    );
    _disc(canvas, const Offset(50, 62), 24, GameColors.coinHi,
        GameColors.coinMid);
    _star(canvas, const Offset(50, 62), 12, filled: true);
  }

  void _flame(Canvas canvas) {
    final path = Path()
      ..moveTo(50, 14)
      ..quadraticBezierTo(78, 40, 70, 62)
      ..quadraticBezierTo(64, 82, 50, 86)
      ..quadraticBezierTo(36, 82, 30, 62)
      ..quadraticBezierTo(22, 40, 50, 14)
      ..close();
    canvas.drawPath(path.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(
        path,
        _vert(const Rect.fromLTWH(22, 14, 56, 74), GameColors.coinHi,
            GameColors.heart));
    final inner = Path()
      ..moveTo(50, 40)
      ..quadraticBezierTo(62, 54, 56, 70)
      ..quadraticBezierTo(50, 78, 44, 70)
      ..quadraticBezierTo(38, 54, 50, 40)
      ..close();
    canvas.drawPath(inner, Paint()..color = GameColors.coinHi);
  }

  void _progress(Canvas canvas) {
    final track = RRect.fromRectAndRadius(
      const Rect.fromLTWH(14, 40, 72, 20),
      const Radius.circular(10),
    );
    canvas.drawRRect(track, Paint()..color = const Color(0xFFE4DDD2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(14, 40, 46, 20), const Radius.circular(10)),
      _vert(const Rect.fromLTWH(14, 40, 46, 20), GameColors.leafHi,
          GameColors.leafDeep),
    );
  }

  void _shop(Canvas canvas) {
    final awning = RRect.fromRectAndRadius(
      const Rect.fromLTWH(16, 22, 68, 22),
      const Radius.circular(8),
    );
    canvas.drawRRect(awning.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(
        awning, _vert(awning.outerRect, GameColors.gift, GameColors.giftDeep));
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(20 + i * 16, 22, 8, 22),
        Paint()..color = Colors.white.withValues(alpha: 0.28),
      );
    }
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(22, 42, 56, 40),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, Paint()..color = GameColors.cream);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(42, 56, 16, 26), const Radius.circular(3)),
      Paint()..color = GameColors.chestDeep,
    );
  }

  void _tag(Canvas canvas) {
    final path = Path()
      ..moveTo(22, 28)
      ..lineTo(62, 28)
      ..lineTo(82, 50)
      ..lineTo(62, 72)
      ..lineTo(22, 72)
      ..close();
    canvas.drawPath(path.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(
        path,
        _vert(const Rect.fromLTWH(22, 28, 60, 44), GameColors.rewardHi,
            GameColors.reward));
    canvas.drawCircle(
        const Offset(36, 50), 5, Paint()..color = GameColors.cream);
  }

  void _bag(Canvas canvas) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(24, 36, 52, 46),
      const Radius.circular(10),
    );
    canvas.drawRRect(body.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(
        body, _vert(body.outerRect, GameColors.premiumHi, GameColors.premium));
    final handle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = GameColors.premiumDeep;
    canvas.drawArc(
        const Rect.fromLTWH(34, 18, 32, 28), math.pi, math.pi, false, handle);
  }

  Path _heartPath(Offset center, double s) {
    return Path()
      ..moveTo(center.dx, center.dy + s * 0.72)
      ..cubicTo(
        center.dx - s * 1.15,
        center.dy + s * 0.15,
        center.dx - s * 0.72,
        center.dy - s * 0.85,
        center.dx,
        center.dy - s * 0.28,
      )
      ..cubicTo(
        center.dx + s * 0.72,
        center.dy - s * 0.85,
        center.dx + s * 1.15,
        center.dy + s * 0.15,
        center.dx,
        center.dy + s * 0.72,
      )
      ..close();
  }

  void _heart(Canvas canvas, {required bool filled, required bool cracked}) {
    final path = _heartPath(const Offset(50, 52), 32);
    if (!filled) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = GameColors.missed,
      );
      return;
    }
    canvas.drawPath(path.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(
        path,
        _vert(const Rect.fromLTWH(18, 18, 64, 68), GameColors.heartHi,
            GameColors.heartDeep));
    canvas.drawOval(
      const Rect.fromLTWH(30, 30, 14, 10),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );
    if (!cracked) return;
    canvas.drawLine(
      const Offset(50, 34),
      const Offset(44, 50),
      Paint()
        ..color = GameColors.cream
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      const Offset(44, 50),
      const Offset(56, 58),
      Paint()
        ..color = GameColors.cream
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _wand(Canvas canvas) {
    canvas.drawLine(
      const Offset(24, 78),
      const Offset(68, 30),
      Paint()
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = GameColors.chestDeep,
    );
    _star(canvas, const Offset(74, 24), 16, filled: true);
  }

  void _ruler(Canvas canvas) {
    canvas.save();
    canvas.translate(50, 50);
    canvas.rotate(-0.4);
    canvas.translate(-50, -50);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(16, 40, 68, 20),
      const Radius.circular(6),
    );
    canvas.drawRRect(body.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(
        body, _vert(body.outerRect, GameColors.cream, GameColors.sky));
    for (var i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(26 + i * 12, 40),
        Offset(26 + i * 12, i.isEven ? 50 : 46),
        Paint()
          ..strokeWidth = 2
          ..color = GameColors.skyDeep,
      );
    }
    canvas.restore();
  }

  void _eye(Canvas canvas) {
    final eye = Path()
      ..moveTo(12, 50)
      ..quadraticBezierTo(50, 22, 88, 50)
      ..quadraticBezierTo(50, 78, 12, 50)
      ..close();
    canvas.drawPath(eye.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(eye, Paint()..color = GameColors.cream);
    canvas.drawPath(
      eye,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = GameColors.ink,
    );
    canvas.drawCircle(
        const Offset(50, 50), 10, Paint()..color = GameColors.leafDeep);
    canvas.drawCircle(const Offset(54, 46), 3.5, Paint()..color = Colors.white);
  }

  void _grid(Canvas canvas) {
    for (var y = 0; y < 2; y++) {
      for (var x = 0; x < 2; x++) {
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(18 + x * 34, 18 + y * 34, 28, 28),
          const Radius.circular(8),
        );
        canvas.drawRRect(
          rect,
          _vert(rect.outerRect, GameColors.leafHi, GameColors.leafDeep),
        );
      }
    }
  }

  void _album(Canvas canvas) {
    final frame = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 22, 64, 56),
      const Radius.circular(8),
    );
    canvas.drawRRect(frame.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(frame, Paint()..color = GameColors.cream);
    canvas.drawCircle(
        const Offset(38, 42), 8, Paint()..color = GameColors.coin);
    final hill = Path()
      ..moveTo(22, 70)
      ..quadraticBezierTo(40, 48, 58, 66)
      ..lineTo(78, 70)
      ..close();
    canvas.drawPath(hill, Paint()..color = GameColors.leaf);
  }

  void _calendar(Canvas canvas) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(20, 24, 60, 58),
      const Radius.circular(10),
    );
    canvas.drawRRect(body.shift(const Offset(0, 3)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(body, Paint()..color = GameColors.cream);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(20, 24, 60, 16), const Radius.circular(8)),
      Paint()..color = GameColors.gift,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(32, 16, 6, 16), const Radius.circular(3)),
      Paint()..color = GameColors.coinInk,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(62, 16, 6, 16), const Radius.circular(3)),
      Paint()..color = GameColors.coinInk,
    );
  }

  void _wheel(Canvas canvas) {
    _disc(canvas, const Offset(50, 50), 34, GameColors.rewardHi,
        GameColors.rewardDeep);
    final paint = Paint()
      ..color = GameColors.cream
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawLine(
        const Offset(50, 50),
        Offset(50 + math.cos(a) * 22, 50 + math.sin(a) * 22),
        paint,
      );
    }
    canvas.drawCircle(
        const Offset(50, 50), 6, Paint()..color = GameColors.cream);
  }

  void _phone(Canvas canvas) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(32, 16, 36, 68),
      const Radius.circular(8),
    );
    canvas.drawRRect(body.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x33000000));
    canvas.drawRRect(
        body,
        _vert(
            body.outerRect, const Color(0xFF4E5D73), const Color(0xFF2C3848)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(36, 24, 28, 46), const Radius.circular(4)),
      Paint()..color = GameColors.sky,
    );
    final wave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = GameColors.coin;
    canvas.drawArc(
        const Rect.fromLTWH(18, 36, 16, 20), math.pi / 2, math.pi, false, wave);
  }

  void _sun(Canvas canvas) {
    final ray = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = GameColors.coin;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      canvas.drawLine(
        Offset(50 + math.cos(a) * 24, 50 + math.sin(a) * 24),
        Offset(50 + math.cos(a) * 34, 50 + math.sin(a) * 34),
        ray,
      );
    }
    _disc(canvas, const Offset(50, 50), 18, GameColors.coinHi,
        GameColors.coinMid);
  }

  void _globe(Canvas canvas) {
    _disc(canvas, const Offset(50, 50), 32, const Color(0xFFD7F1FF),
        GameColors.skyDeep);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawLine(const Offset(22, 50), const Offset(78, 50), line);
    canvas.drawOval(const Rect.fromLTWH(38, 20, 24, 60), line);
    canvas.drawOval(const Rect.fromLTWH(26, 32, 48, 36), line);
  }

  void _shield(Canvas canvas) {
    final path = Path()
      ..moveTo(50, 14)
      ..lineTo(80, 28)
      ..lineTo(74, 58)
      ..quadraticBezierTo(68, 80, 50, 88)
      ..quadraticBezierTo(32, 80, 26, 58)
      ..lineTo(20, 28)
      ..close();
    canvas.drawPath(path.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(
        path,
        _vert(const Rect.fromLTWH(20, 14, 60, 74), GameColors.premiumHi,
            GameColors.premiumDeep));
    _checkGlyph(canvas, const Offset(50, 52), 18);
  }

  void _moreDots(Canvas canvas) {
    final paint = Paint()..color = GameColors.ink;
    for (final x in const [32.0, 50.0, 68.0]) {
      canvas.drawCircle(Offset(x, 50), 5.5, paint);
    }
  }

  void _hourglass(Canvas canvas) {
    final cap = RRect.fromRectAndRadius(
      const Rect.fromLTWH(26, 16, 48, 8),
      const Radius.circular(3),
    );
    canvas.drawRRect(cap, Paint()..color = GameColors.coinDeep);
    canvas.drawRRect(
        cap.shift(const Offset(0, 60)), Paint()..color = GameColors.coinDeep);
    final top = Path()
      ..moveTo(30, 26)
      ..lineTo(70, 26)
      ..lineTo(54, 48)
      ..lineTo(46, 48)
      ..close();
    final bottom = Path()
      ..moveTo(46, 52)
      ..lineTo(54, 52)
      ..lineTo(70, 76)
      ..lineTo(30, 76)
      ..close();
    canvas.drawPath(
        top,
        _vert(const Rect.fromLTWH(30, 26, 40, 24), GameColors.coinHi,
            GameColors.coin));
    canvas.drawPath(
        bottom,
        _vert(const Rect.fromLTWH(30, 52, 40, 24), GameColors.coin,
            GameColors.coinDeep));
  }

  void _palette(Canvas canvas) {
    final path = Path()
      ..moveTo(28, 58)
      ..cubicTo(18, 30, 40, 16, 62, 22)
      ..cubicTo(86, 28, 88, 58, 70, 70)
      ..cubicTo(60, 76, 58, 64, 52, 64)
      ..cubicTo(40, 64, 38, 78, 28, 58)
      ..close();
    canvas.drawPath(path.shift(const Offset(0, 2)),
        Paint()..color = const Color(0x33000000));
    canvas.drawPath(path, Paint()..color = GameColors.cream);
    canvas.drawCircle(
        const Offset(40, 36), 5, Paint()..color = GameColors.gift);
    canvas.drawCircle(
        const Offset(54, 30), 5, Paint()..color = GameColors.coin);
    canvas.drawCircle(
        const Offset(68, 40), 5, Paint()..color = GameColors.skyDeep);
    canvas.drawCircle(
        const Offset(62, 56), 5, Paint()..color = GameColors.leaf);
  }
}

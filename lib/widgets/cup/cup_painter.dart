import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

import 'drink_art.dart';
import 'drink_colors.dart';

/// Paints a drink in a tapered glass on a 200 x 262 design canvas.
///
/// Every part is a parameter: the layers, the latte art, steam, ice, the
/// straw, and the surface's [tilt] when the drink sloshes. [time] (seconds)
/// drives the ambient motion: steam curling up, ice bobbing, milk clouds
/// drifting through the coffee.
class CupPainter extends CustomPainter {
  CupPainter({
    required this.drink,
    required this.time,
    required this.tilt,
    required this.shadow,
    required this.steam,
    super.repaint,
  });

  final DrinkArt Function() drink;
  final double Function() time;
  final double Function() tilt;
  final Color shadow;

  /// Steam reads white on dark pages and as a warm grey on light ones.
  final Color steam;

  static const width = 200.0;
  static const height = 262.0;

  // The glass, in design units.
  static const _rimY = 60.0;
  static const _innerTop = 62.0;
  static const _innerBottom = 240.0;
  static const _outerBottom = 254.0;
  static const _topHalf = 70.0;
  static const _bottomHalf = 54.0;
  static const _wall = 5.0;

  static double innerHalfAt(double y) {
    final t = ((y - _innerTop) / (_innerBottom - _innerTop)).clamp(0.0, 1.0);
    return (_topHalf - _wall) + ((_bottomHalf - _wall) - (_topHalf - _wall)) * t;
  }

  static Path innerPath() {
    const r = 16.0;
    final bl = 100 - innerHalfAt(_innerBottom), br = 100 + innerHalfAt(_innerBottom);
    return Path()
      ..moveTo(100 - innerHalfAt(_innerTop - 40), _innerTop - 40)
      ..lineTo(bl, _innerBottom - r)
      ..quadraticBezierTo(bl, _innerBottom, bl + r, _innerBottom)
      ..lineTo(br - r, _innerBottom)
      ..quadraticBezierTo(br, _innerBottom, br, _innerBottom - r)
      ..lineTo(100 + innerHalfAt(_innerTop - 40), _innerTop - 40)
      ..close();
  }

  static Path outerPath() {
    const r = 20.0;
    const bl = 100 - _bottomHalf, br = 100 + _bottomHalf;
    return Path()
      ..moveTo(100 - _topHalf, _rimY)
      ..lineTo(bl, _outerBottom - r)
      ..quadraticBezierTo(bl, _outerBottom, bl + r, _outerBottom)
      ..lineTo(br - r, _outerBottom)
      ..quadraticBezierTo(br, _outerBottom, br, _outerBottom - r)
      ..lineTo(100 + _topHalf, _rimY)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = math.min(size.width / width, size.height / height);
    canvas.save();
    canvas.translate((size.width - width * k) / 2, (size.height - height * k) / 2);
    canvas.scale(k);

    final d = drink();
    final t = time();
    final tl = tilt();

    _shadow(canvas);
    if (d.iced > 0.01) _straw(canvas, d, behind: true);
    _liquid(canvas, d, t, tl);
    _glass(canvas, d);
    if (d.iced > 0.01) _beads(canvas, d);
    if (d.hot > 0.01) _steam(canvas, d, t);
    canvas.restore();
  }

  // ------------------------------------------------------------------ parts

  void _shadow(Canvas canvas) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, _outerBottom + 3), width: 150, height: 14),
      Paint()
        ..color = shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
  }

  /// Where the surface sits, and where each layer starts, bottom up.
  ({double surface, double milkTop, double baseTop}) _levels(DrinkArt d) {
    const full = _innerBottom - _innerTop;
    final sum = math.max(d.base + d.milk + d.foam, 0.0001);
    final h = full * d.level.clamp(0.0, 1.0);
    final baseH = h * d.base / sum;
    final milkH = h * d.milk / sum;
    return (
      surface: _innerBottom - h,
      baseTop: _innerBottom - baseH,
      milkTop: _innerBottom - baseH - milkH,
    );
  }

  void _liquid(Canvas canvas, DrinkArt d, double t, double tilt) {
    final lv = _levels(d);
    if (d.level <= 0.005) return;
    canvas.save();
    canvas.clipPath(innerPath());

    // The surface tips with the slosh: the body is clipped to a tilted top.
    final half = innerHalfAt(lv.surface);
    final body = Path()
      ..moveTo(100 - half - 4, lv.surface + tilt * half * 0.12)
      ..lineTo(100 + half + 4, lv.surface - tilt * half * 0.12)
      ..lineTo(100 + 80, _innerBottom + 2)
      ..lineTo(100 - 80, _innerBottom + 2)
      ..close();
    canvas.save();
    canvas.clipPath(body);

    final foamC = d.foam > 0.01 ? DrinkColors.foam : d.milkColor;
    final soft = 9.0;
    final span = _innerBottom - lv.surface;
    double stop(double y) => ((y - lv.surface) / span).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTRB(0, lv.surface - 12, 200, _innerBottom + 2),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, lv.surface),
          const Offset(0, _innerBottom),
          [foamC, foamC, d.milkColor, d.milkColor, d.baseColor, d.baseColor],
          [
            0,
            stop(lv.milkTop - soft / 2),
            stop(lv.milkTop + soft / 2),
            stop(lv.baseTop - soft),
            stop(lv.baseTop + soft),
            1,
          ],
        ),
    );

    // Milk drifting down into the coffee, the look of a fresh iced latte.
    if (d.milk > 0.02 && d.base > 0.02) {
      final cloud = Paint()
        ..color = d.milkColor.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      for (var i = 0; i < 4; i++) {
        final ph = t * 0.35 + i * 1.7;
        final x = 100 + math.sin(ph) * 30 + (i - 1.5) * 16;
        final y = lv.baseTop + 4 + math.sin(ph * 0.7 + i) * 7;
        canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 40 + i * 6.0, height: 12), cloud);
      }
    }

    // A darker band hugging the walls gives the liquid its roundness.
    canvas.drawRect(
      Rect.fromLTRB(0, lv.surface - 12, 200, _innerBottom + 2),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(100 - _topHalf, 0),
          const Offset(100 + _topHalf, 0),
          [const Color(0x33000000), const Color(0x00000000), const Color(0x00000000), const Color(0x40000000)],
          [0, 0.22, 0.7, 1],
        ),
    );
    canvas.restore();

    _surface(canvas, d, lv.surface, half, t, tilt);
    if (d.iced > 0.01) _ice(canvas, d, lv.surface, t);
    canvas.restore();
  }

  void _surface(Canvas canvas, DrinkArt d, double y, double half, double t, double tilt) {
    final ry = half * 0.24;
    canvas.save();
    canvas.translate(100, y);
    canvas.rotate(-tilt * 0.12);
    final rect = Rect.fromCenter(center: Offset.zero, width: half * 2, height: ry * 2);

    final hasArt = d.art != LatteArt.none && d.artAmount > 0.01 && d.foam > 0.01;
    final topC = d.foam > 0.01 ? DrinkColors.foam : d.milk > 0.01 ? d.milkColor : d.baseColor;
    final ground = hasArt
        ? Color.lerp(topC, Color.lerp(d.baseColor, DrinkColors.crema, 0.55)!, d.artAmount)!
        : topC;
    canvas.drawOval(rect, Paint()..color = ground);

    if (d.crema > 0.01) {
      canvas.drawOval(
        rect.deflate(2),
        Paint()
          ..shader = ui.Gradient.radial(Offset.zero, half, [
            DrinkColors.crema.withValues(alpha: d.crema),
            Color.lerp(DrinkColors.crema, d.baseColor, 0.6)!.withValues(alpha: d.crema),
          ]),
      );
    }

    if (hasArt) {
      canvas.save();
      canvas.clipPath(Path()..addOval(rect));
      canvas.scale(1, ry / half);
      _art(canvas, d.art, half, DrinkColors.foam.withValues(alpha: d.artAmount));
      canvas.restore();
    }

    // A highlight along the far edge, moving a little with the slosh.
    canvas.drawArc(
      rect.deflate(3),
      math.pi * (1.15 + tilt * 0.05),
      math.pi * 0.55,
      false,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  /// Latte art on a circle of radius [r] centred at the origin.
  void _art(Canvas canvas, LatteArt art, double r, Color c) {
    final paint = Paint()..color = c;
    switch (art) {
      case LatteArt.heart:
        final s = r * 0.78;
        final heart = Path()
          ..moveTo(0, s * 0.75)
          ..cubicTo(-s * 1.25, -s * 0.05, -s * 0.55, -s * 0.95, 0, -s * 0.35)
          ..cubicTo(s * 0.55, -s * 0.95, s * 1.25, -s * 0.05, 0, s * 0.75)
          ..close();
        canvas.drawPath(heart, paint);
        canvas.drawLine(Offset(0, -s * 0.9), Offset(0, s * 0.75),
            Paint()
              ..color = c.withValues(alpha: c.a * 0.7)
              ..strokeWidth = 1.6);
      case LatteArt.rosetta:
        for (var i = 0; i < 6; i++) {
          final y = -r * 0.66 + i * r * 0.22;
          final w = r * (0.32 + i * 0.09);
          canvas.drawPath(
            Path()
              ..moveTo(-w, y)
              ..quadraticBezierTo(0, y + r * 0.26, w, y)
              ..quadraticBezierTo(0, y + r * 0.12, -w, y)
              ..close(),
            paint,
          );
        }
        canvas.drawLine(Offset(0, -r * 0.7), Offset(0, r * 0.6),
            Paint()
              ..color = c
              ..strokeWidth = 1.8);
      case LatteArt.tulip:
        for (var i = 0; i < 3; i++) {
          final cy = -r * 0.35 + i * r * 0.32;
          final rr = r * (0.24 + i * 0.09);
          canvas.drawOval(Rect.fromCenter(center: Offset(0, cy), width: rr * 2.4, height: rr * 1.5), paint);
        }
      case LatteArt.none:
        break;
    }
  }

  void _ice(Canvas canvas, DrinkArt d, double surface, double t) {
    final a = d.iced.clamp(0.0, 1.0);
    final cubes = [(-26.0, 0.0, 0.2), (8.0, 1.4, -0.25), (32.0, 2.6, 0.5)];
    for (final (dx, ph, rot) in cubes) {
      final bob = math.sin(t * 1.3 + ph) * 2.5;
      canvas.save();
      canvas.translate(100 + dx, surface + 4 + bob);
      canvas.rotate(rot + math.sin(t * 0.8 + ph) * 0.06);
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 28, height: 24), const Radius.circular(6));
      canvas.drawRRect(r, Paint()..color = DrinkColors.ice.withValues(alpha: 0.55 * a));
      canvas.drawRRect(
        r,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85 * a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      canvas.drawLine(const Offset(-8, -7), const Offset(4, -7),
          Paint()
            ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * a)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round);
      canvas.restore();
    }
  }

  void _straw(Canvas canvas, DrinkArt d, {required bool behind}) {
    final a = d.iced.clamp(0.0, 1.0);
    canvas.save();
    canvas.translate(124, 150);
    canvas.rotate(0.28);
    final straw = RRect.fromRectAndRadius(Rect.fromLTWH(-6, -140 + (1 - a) * 40, 12, 200), const Radius.circular(5));
    canvas.clipRRect(straw);
    canvas.drawRRect(straw, Paint()..color = DrinkColors.straw.withValues(alpha: a));
    final stripe = Paint()..color = DrinkColors.strawStripe.withValues(alpha: 0.8 * a);
    for (var y = -150.0; y < 70; y += 18) {
      canvas.drawPath(
        Path()
          ..moveTo(-8, y)
          ..lineTo(8, y - 7)
          ..lineTo(8, y - 1)
          ..lineTo(-8, y + 6)
          ..close(),
        stripe,
      );
    }
    canvas.restore();
  }

  void _glass(Canvas canvas, DrinkArt d) {
    final outer = outerPath();
    // A faint tint so the empty part still reads as glass.
    canvas.drawPath(outer, Paint()..color = DrinkColors.glass.withValues(alpha: 0.1));

    // The thick base, catching some of the drink's colour.
    canvas.save();
    canvas.clipPath(outer);
    canvas.drawRect(
      const Rect.fromLTRB(0, _innerBottom, 200, _outerBottom + 2),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, _innerBottom),
          const Offset(0, _outerBottom),
          [d.baseColor.withValues(alpha: 0.28 * (d.level > 0 ? 1 : 0)), DrinkColors.glass.withValues(alpha: 0.35)],
        ),
    );
    // Long highlight on the left wall, a thin one on the right.
    canvas.drawPath(
      Path()
        ..moveTo(100 - _topHalf + 12, _rimY + 14)
        ..lineTo(100 - _bottomHalf + 11, _outerBottom - 26),
      Paint()
        ..color = const Color(0xA6FFFFFF)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawPath(
      Path()
        ..moveTo(100 + _topHalf - 10, _rimY + 30)
        ..lineTo(100 + _bottomHalf - 9, _outerBottom - 50),
      Paint()
        ..color = const Color(0x59FFFFFF)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    final edge = Paint()
      ..color = DrinkColors.glassEdge.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawPath(outer, edge);
    // The rim: the back of it faint, the front bright.
    final rim = Rect.fromCenter(center: const Offset(100, _rimY), width: _topHalf * 2, height: 18);
    canvas.drawArc(rim, math.pi, math.pi, false, edge);
    canvas.drawArc(
      rim,
      0,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  void _beads(Canvas canvas, DrinkArt d) {
    final rng = math.Random(4);
    final p = Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55 * d.iced);
    for (var i = 0; i < 26; i++) {
      final y = _rimY + 40 + rng.nextDouble() * 140;
      final half = _topHalf + (_bottomHalf - _topHalf) * ((y - _rimY) / (_outerBottom - _rimY));
      final x = 100 + (rng.nextDouble() * 2 - 1) * (half - 10);
      canvas.drawCircle(Offset(x, y), 0.8 + rng.nextDouble() * 1.6, p);
    }
  }

  void _steam(Canvas canvas, DrinkArt d, double t) {
    for (var i = 0; i < 3; i++) {
      final phase = (t * 0.32 + i / 3) % 1;
      final x0 = 100 + (i - 1) * 26.0;
      final rise = phase * 46;
      final alpha = math.sin(phase * math.pi) * 0.55 * d.hot;
      final path = Path()..moveTo(x0, _rimY - 4 - rise);
      for (var s = 1; s <= 4; s++) {
        final y = _rimY - 4 - rise - s * 9;
        path.quadraticBezierTo(
          x0 + math.sin(t * 1.6 + i + s) * 9,
          y + 4,
          x0 + math.sin(t * 1.1 + i * 2 + s) * 5,
          y,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = steam.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
      );
    }
  }

  @override
  bool shouldRepaint(CupPainter old) => old.shadow != shadow || old.steam != steam;
}

// Draws the app icon to assets/brand/icon_1024.png from the same cup the app
// pours. Then: python3 tool/make_icons.py
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crema/config/palette.dart';
import 'package:crema/widgets/cup/cup_painter.dart';
import 'package:crema/widgets/cup/drink_art.dart';
import 'package:crema/widgets/cup/drink_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('icon', () async {
    const s = 1024.0;
    const p = Palette.light;
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(const Rect.fromLTWH(0, 0, s, s),
        Paint()..shader = ui.Gradient.linear(Offset.zero, const Offset(s, s), [p.accent, p.accentDeep]));
    c.drawCircle(const Offset(s * 0.5, s * 0.42), s * 0.5,
        Paint()..shader = ui.Gradient.radial(const Offset(s * 0.5, s * 0.42), s * 0.5, [p.accentGlow.withValues(alpha: 0.55), p.accentGlow.withValues(alpha: 0)]));
    c.save();
    c.translate(s * 0.2, s * 0.08);
    CupPainter(
      drink: () => const DrinkArt(baseColor: DrinkColors.espresso, base: 0.3, milk: 0.52, foam: 0.12, art: LatteArt.heart),
      time: () => 1.2,
      tilt: () => 0,
      shadow: const Color(0x55000000),
      steam: Colors.white,
    ).paint(c, const Size(s * 0.6, s * 0.8));
    c.restore();
    final img = await rec.endRecording().toImage(s.toInt(), s.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File('assets/brand/icon_1024.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

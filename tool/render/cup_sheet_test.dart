// Renders the cup in its main looks to build/cup_<mode>.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crema/config/palette.dart';
import 'package:crema/widgets/cup/cup_painter.dart';
import 'package:crema/widgets/cup/drink_art.dart';
import 'package:crema/widgets/cup/drink_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cup sheet', () async {
    for (final mode in ['light', 'dark']) {
      final pal = mode == 'light' ? Palette.light : Palette.dark;
      final drinks = <(DrinkArt, double)>[
        (const DrinkArt(baseColor: DrinkColors.espresso, base: 0.3, milk: 0.5, foam: 0.12, art: LatteArt.heart), 0),
        (const DrinkArt(baseColor: DrinkColors.espresso, base: 0.35, milk: 0.55, foam: 0.02, hot: 0, iced: 1, art: LatteArt.none, level: 0.8), 0),
        (const DrinkArt(baseColor: DrinkColors.matcha, base: 0.3, milkColor: DrinkColors.oatMilk, milk: 0.5, foam: 0.1, art: LatteArt.rosetta), 0),
        (const DrinkArt(baseColor: DrinkColors.espresso, base: 1, milk: 0, foam: 0, level: 0.32, art: LatteArt.none, crema: 1), 0),
        (const DrinkArt(baseColor: DrinkColors.coldBrew, base: 1, milk: 0, foam: 0, hot: 0, iced: 1, art: LatteArt.none, level: 0.85), 0.8),
        (const DrinkArt(baseColor: DrinkColors.espresso, base: 0.25, milk: 0.35, foam: 0.35, art: LatteArt.tulip), 0.6),
      ];
      const cw = 240.0, ch = 320.0;
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.drawRect(Rect.fromLTWH(0, 0, cw * drinks.length, ch), Paint()..color = pal.paper);
      for (var i = 0; i < drinks.length; i++) {
        c.save();
        c.translate(i * cw, 0);
        CupPainter(drink: () => drinks[i].$1, time: () => 1.3, tilt: () => drinks[i].$2, shadow: pal.shadow, steam: mode == 'dark' ? Colors.white : pal.muted)
            .paint(c, const Size(cw, ch));
        c.restore();
      }
      final img = await rec.endRecording().toImage((cw * drinks.length).toInt(), ch.toInt());
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      File('build/cup_$mode.png')..createSync(recursive: true)..writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  });
}

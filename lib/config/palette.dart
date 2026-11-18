import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Every UI colour in Crema is defined in this file.
//
// To re-skin the app, edit [Palette.light] and [Palette.dark] below. Every
// screen, the carousel, the bag, the stamp card and the buttons read their
// colours from here through `context.palette`.
//
// Deliberately not here: the coffee itself (espresso, milk, foam, ice), drawn
// in lib/widgets/cup/drink_colors.dart. It is the product, so it looks the
// same in light and dark.
//
// The system: oat paper, espresso ink and exactly one accent (cafe green).
// Ink is never pure black and paper is never pure white.
// ---------------------------------------------------------------------------

@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.paper,
    required this.card,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.line,
    required this.field,
    required this.accent,
    required this.accentDeep,
    required this.accentGlow,
    required this.onAccent,
    required this.accentWash,
    required this.error,
    required this.eye,
    required this.face,
    required this.shadow,
    required this.scrim,
  });

  /// The page ground.
  final Color paper;

  /// Raised surfaces: the form card, sheets, the keypad keys.
  final Color card;

  /// Headlines and primary type.
  final Color ink;

  /// Body copy.
  final Color inkSoft;

  /// Hints, captions, inactive icons.
  final Color muted;

  /// Hairlines and resting field borders.
  final Color line;

  /// The fill of a field at rest.
  final Color field;

  /// The one accent: the primary button, selected chips, the bag badge.
  final Color accent;

  /// Pressed and emphasised accent.
  final Color accentDeep;

  /// A lighter accent for glows and gradients.
  final Color accentGlow;

  /// Type and icons on top of [accent].
  final Color onAccent;

  /// A pale tint of the accent for selected states and notices.
  final Color accentWash;

  /// Errors stay in the family: a deeper, redder neighbour of the accent.
  final Color error;

  /// Highlights on glossy art (the rim of a cup).
  final Color eye;

  /// The darkest ink, the same in both modes (type on the coffee art).
  final Color face;

  /// Shadows under raised surfaces.
  final Color shadow;

  /// Behind sheets.
  final Color scrim;

  static const light = Palette(
    paper: Color(0xFFF6F0E6),
    card: Color(0xFFFFFBF4),
    ink: Color(0xFF241911),
    inkSoft: Color(0xFF54473B),
    muted: Color(0xFF93877A),
    line: Color(0xFFE6DCCD),
    field: Color(0xFFEFE6D8),
    accent: Color(0xFF2F6B52),
    accentDeep: Color(0xFF1E4A38),
    accentGlow: Color(0xFF6FA88B),
    onAccent: Color(0xFFF8F2E8),
    accentWash: Color(0xFFE1EBE2),
    error: Color(0xFFB4492F),
    eye: Color(0xFFFFFCF6),
    face: Color(0xFF1C130C),
    shadow: Color(0x2E3B2614),
    scrim: Color(0x66241911),
  );

  static const dark = Palette(
    paper: Color(0xFF14110E),
    card: Color(0xFF1F1A15),
    ink: Color(0xFFF4ECE0),
    inkSoft: Color(0xFFCFC3B3),
    muted: Color(0xFF8E8273),
    line: Color(0xFF2F2821),
    field: Color(0xFF262019),
    accent: Color(0xFF7DBE9D),
    accentDeep: Color(0xFF58987A),
    accentGlow: Color(0xFFA9D8BF),
    onAccent: Color(0xFF0F2219),
    accentWash: Color(0xFF1E2C24),
    error: Color(0xFFEA866A),
    eye: Color(0xFFFFF6EA),
    face: Color(0xFF1C130C),
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
  );
  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      paper: c(paper, other.paper),
      card: c(card, other.card),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      muted: c(muted, other.muted),
      line: c(line, other.line),
      field: c(field, other.field),
      accent: c(accent, other.accent),
      accentDeep: c(accentDeep, other.accentDeep),
      accentGlow: c(accentGlow, other.accentGlow),
      onAccent: c(onAccent, other.onAccent),
      accentWash: c(accentWash, other.accentWash),
      error: c(error, other.error),
      eye: c(eye, other.eye),
      face: c(face, other.face),
      shadow: c(shadow, other.shadow),
      scrim: c(scrim, other.scrim),
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}

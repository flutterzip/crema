import 'dart:ui';

/// The pattern poured into the foam.
enum LatteArt { none, heart, rosetta, tulip }

/// Everything the cup needs to draw one drink, as numbers that can be
/// blended, so a change of size, milk or shots re-pours smoothly.
///
/// Amounts are fractions of the glass's height, bottom up: [base] (espresso,
/// matcha, chocolate...), then [milk], then [foam]. [level] is how full the
/// glass is overall, so the three are scaled to fit under it.
class DrinkArt {
  const DrinkArt({
    required this.baseColor,
    this.base = 0.3,
    this.milkColor = const Color(0xFFF3E7D6),
    this.milk = 0.5,
    this.foam = 0.12,
    this.level = 0.86,
    this.hot = 1,
    this.iced = 0,
    this.art = LatteArt.heart,
    this.artAmount = 1,
    this.crema = 0,
  });

  final Color baseColor;
  final double base;
  final Color milkColor;
  final double milk;
  final double foam;
  final double level;

  /// 0..1: how much steam rises.
  final double hot;

  /// 0..1: ice cubes, the straw and the beads on the glass.
  final double iced;

  final LatteArt art;
  final double artAmount;

  /// 0..1: a golden crema band on top of a straight espresso.
  final double crema;

  DrinkArt copyWith({
    Color? baseColor,
    double? base,
    Color? milkColor,
    double? milk,
    double? foam,
    double? level,
    double? hot,
    double? iced,
    LatteArt? art,
    double? artAmount,
    double? crema,
  }) =>
      DrinkArt(
        baseColor: baseColor ?? this.baseColor,
        base: base ?? this.base,
        milkColor: milkColor ?? this.milkColor,
        milk: milk ?? this.milk,
        foam: foam ?? this.foam,
        level: level ?? this.level,
        hot: hot ?? this.hot,
        iced: iced ?? this.iced,
        art: art ?? this.art,
        artAmount: artAmount ?? this.artAmount,
        crema: crema ?? this.crema,
      );

  /// Blends two drinks. The latte art fades out and the new one fades in.
  static DrinkArt lerp(DrinkArt a, DrinkArt b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    double l(double x, double y) => x + (y - x) * t;
    final art = t < 0.5 ? a.art : b.art;
    final artAmount = a.art == b.art
        ? l(a.artAmount, b.artAmount)
        : (t < 0.5 ? a.artAmount * (1 - t * 2) : b.artAmount * (t * 2 - 1));
    return DrinkArt(
      baseColor: Color.lerp(a.baseColor, b.baseColor, t)!,
      base: l(a.base, b.base),
      milkColor: Color.lerp(a.milkColor, b.milkColor, t)!,
      milk: l(a.milk, b.milk),
      foam: l(a.foam, b.foam),
      level: l(a.level, b.level),
      hot: l(a.hot, b.hot),
      iced: l(a.iced, b.iced),
      art: art,
      artAmount: artAmount,
      crema: l(a.crema, b.crema),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DrinkArt &&
      other.baseColor == baseColor &&
      other.base == base &&
      other.milkColor == milkColor &&
      other.milk == milk &&
      other.foam == foam &&
      other.level == level &&
      other.hot == hot &&
      other.iced == iced &&
      other.art == art &&
      other.artAmount == artAmount &&
      other.crema == crema;

  @override
  int get hashCode => Object.hash(baseColor, base, milkColor, milk, foam, level, hot, iced, art, artAmount, crema);
}

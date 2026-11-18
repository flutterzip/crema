import 'dart:ui';

/// The coffee itself. It is the product, so it is drawn the same in light
/// and dark mode, and lives here rather than in the UI palette.
abstract final class DrinkColors {
  static const espresso = Color(0xFF3B2215);
  static const espressoLight = Color(0xFF6A3E22);
  static const coldBrew = Color(0xFF2A170D);
  static const matcha = Color(0xFF7FA14A);
  static const chocolate = Color(0xFF5A2E1E);
  static const chai = Color(0xFFB07A4A);

  static const wholeMilk = Color(0xFFF3E7D6);
  static const oatMilk = Color(0xFFEBD8B9);
  static const almondMilk = Color(0xFFF0E0CC);

  static const foam = Color(0xFFFBF3E6);
  static const foamShadow = Color(0xFFE2CDAE);
  static const crema = Color(0xFFC88B4E);

  static const ice = Color(0xFFEAF4F6);
  static const glass = Color(0xFFFFFFFF);
  static const glassEdge = Color(0xFF9FB0B5);
  static const straw = Color(0xFFF3E9DA);
  static const strawStripe = Color(0xFF3B2215);
  static const steam = Color(0xFFFFFFFF);
}

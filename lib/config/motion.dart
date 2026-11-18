import 'package:flutter/widgets.dart';

/// How things move. How long the app *waits* is a different question and
/// lives in `AppTiming`.
abstract final class Motion {
  static const quick = Duration(milliseconds: 160);
  static const short = Duration(milliseconds: 240);
  static const medium = Duration(milliseconds: 380);
  static const long = Duration(milliseconds: 600);

  /// A screen's sections rising in, from one controller sliced by intervals.
  static const entrance = Duration(milliseconds: 1000);

  /// One screen handing over to the next (the cup flies between them).
  static const route = Duration(milliseconds: 620);

  /// A cup lifting off its card and landing in the bag.
  static const flyToBag = Duration(milliseconds: 820);

  /// The coffee rising or falling to a new level.
  static const pour = Duration(milliseconds: 900);

  /// A stamp pressed into the card.
  static const stamp = Duration(milliseconds: 520);

  static const shake = Duration(milliseconds: 520);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const settle = Curves.easeOutQuart;
  static const spring = Curves.easeOutBack;

  /// Ambient loops (steam, the liquid's surface, ice bobbing) run only when
  /// this is true. Tests switch it off so `pumpAndSettle` can settle.
  static bool ambient = true;

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static bool loops(BuildContext context) => ambient && !reduced(context);
}

import 'package:crema/config/motion.dart';
import 'package:crema/config/theme.dart';
import 'package:crema/config/timing.dart';
import 'package:crema/data/models.dart';
import 'package:crema/state/store.dart';
import 'package:crema/widgets/backdrop.dart';
import 'package:crema/widgets/cup/cup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final testNow = DateTime(2026, 11, 18, 9, 41);

Drink drink(String id, String name, {Category category = Category.hot, List<Temp> temps = const [Temp.hot], Milk milk = Milk.whole, int price = 450}) => Drink(
      id: id,
      name: name,
      category: category,
      tagline: '$name tagline',
      description: '$name description',
      price: price,
      rating: 4.8,
      kcal: 120,
      minutes: 4,
      base: 'espresso',
      baseAmount: 0.3,
      milk: milk,
      milkAmount: 0.5,
      foam: 0.1,
      level: 0.86,
      art: LatteArt.heart,
      temps: temps,
    );

final testSeed = Seed(
  drinks: [
    drink('flat-white', 'Flat White', price: 420),
    drink('oat-latte', 'Oat Latte', milk: Milk.oat, temps: const [Temp.hot, Temp.iced], price: 460),
    drink('iced-latte', 'Iced Latte', category: Category.iced, temps: const [Temp.iced, Temp.hot], price: 480),
    drink('matcha-latte', 'Matcha Latte', category: Category.tea, milk: Milk.oat, price: 520),
    drink('espresso', 'Espresso', milk: Milk.none, price: 280),
  ],
  profile: const Profile(name: 'Olympicson', email: 'hello@flutterzip.com', store: 'Crema, 21 Market Lane', stamps: 6),
);

class TestClock {
  DateTime now = testNow;
}

/// Pumps [screen] (or the whole shell) with no waits, no ambient loops, on
/// a phone-sized screen, with a movable clock.
Future<(ProviderContainer, TestClock)> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Map<String, Object> prefs = const {},
  Seed? seed,
}) async {
  Motion.ambient = false;
  AppTiming.scale = 0;
  tester.view.physicalSize = const Size(1320, 2868);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final clock = TestClock();
  final container = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(sp),
    seedProvider.overrideWithValue(seed ?? testSeed),
    clockProvider.overrideWithValue(() => clock.now),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light(),
      builder: (context, child) => CafeBackdrop(child: child!),
      home: Material(type: MaterialType.transparency, child: screen),
    ),
  ));
  await tester.pumpAndSettle();
  return (container, clock);
}

/// Moves the clock and lets the providers that read it rebuild.
Future<void> advance(WidgetTester tester, ProviderContainer c, TestClock clock, Duration by) async {
  clock.now = clock.now.add(by);
  c.invalidate(nowProvider);
  await tester.pump();
  await tester.pumpAndSettle();
}

/// A cup the tests can look for.
final anyCup = find.byType(Cup);

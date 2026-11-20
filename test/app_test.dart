import 'package:crema/app.dart';
import 'package:crema/screens/drink/drink_screen.dart';
import 'package:crema/screens/menu/menu_screen.dart';
import 'package:crema/screens/shell/shell.dart';
import 'package:crema/screens/splash/splash.dart';
import 'package:crema/state/store.dart';
import 'package:crema/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

Future<ProviderContainer> pumpApp(WidgetTester tester, {bool splash = true, Map<String, Object> prefs = const {}}) async {
  Motion.ambient = false;
  AppTiming.scale = splash ? 1 : 0;
  addTearDown(() => AppTiming.scale = 0);
  tester.view.physicalSize = const Size(1320, 2868);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(sp),
    seedProvider.overrideWithValue(testSeed),
    clockProvider.overrideWithValue(() => testNow),
  ]);
  addTearDown(c.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: c, child: CremaApp(splash: splash)));
  return c;
}

void main() {
  testWidgets('the splash pours, then leaves the menu without rebuilding it', (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Splash), findsOneWidget);
    final before = tester.state(find.byType(MenuScreen));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(Splash), findsNothing);
    expect(identical(tester.state(find.byType(MenuScreen)), before), isTrue);
  });

  testWidgets('the splash text has a real style (no debug underline)', (tester) async {
    await pumpApp(tester);
    await tester.pump(const Duration(milliseconds: 2000));
    final style = DefaultTextStyle.of(tester.element(find.text('Coffee, made yours.'))).style;
    expect(style.decoration, anyOf(isNull, TextDecoration.none));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('tabs switch, and the bag badge counts cups', (tester) async {
    final c = await pumpApp(tester, splash: false);
    await tester.pumpAndSettle();
    c.read(bagProvider.notifier).add('espresso', testSeed.drink('espresso').defaults);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Bag, 1'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Bag, 1'));
    await tester.pumpAndSettle();
    expect(c.read(tabProvider), 1);
    expect(find.text('Your bag'), findsOneWidget);
  });

  testWidgets('a drink hides the tab bar, adds to the bag and leads to it', (tester) async {
    final c = await pumpApp(tester, splash: false);
    await tester.pumpAndSettle();
    bool barHidden() => tester.widget<AnimatedSlide>(find.ancestor(of: find.byType(GlassTabBar), matching: find.byType(AnimatedSlide))).offset.dy > 0;
    expect(barHidden(), isFalse);
    menuNavigator.currentState!.push(CremaRoute(DrinkScreen(drink: testSeed.drink('flat-white'))));
    await tester.pumpAndSettle();
    expect(barHidden(), isTrue);
    await tester.tap(find.text('Add to bag'));
    await tester.pumpAndSettle();
    expect(c.read(bagCountProvider), 1);
    expect(find.text('In your bag'), findsOneWidget);
    await tester.tap(find.text('View bag'));
    await tester.pumpAndSettle();
    expect(c.read(tabProvider), 1);
    expect(find.byType(DrinkScreen), findsNothing);
    expect(barHidden(), isFalse);
  });

  testWidgets('Demo settings switches to dark and resets the demo', (tester) async {
    final c = await pumpApp(tester, splash: false);
    await tester.pumpAndSettle();
    c.read(bagProvider.notifier).add('espresso', testSeed.drink('espresso').defaults);
    await tester.tap(find.bySemanticsLabel('Demo settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(find.byType(MenuScreen))).brightness, Brightness.dark);
    await tester.tap(find.text('Reset demo data'));
    await tester.pumpAndSettle();
    expect(c.read(bagProvider), isEmpty);
  });
}

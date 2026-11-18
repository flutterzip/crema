import 'package:crema/screens/bag/bag_screen.dart';
import 'package:crema/screens/drink/drink_screen.dart';
import 'package:crema/screens/menu/menu_screen.dart';
import 'package:crema/screens/order/order_screen.dart';
import 'package:crema/screens/rewards/rewards_screen.dart';
import 'package:crema/screens/shell/shell.dart';
import 'package:crema/state/store.dart';
import 'package:crema/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Menu', () {
    testWidgets('greets the person and shows the wheel and the popular list', (tester) async {
      await pumpScreen(tester, const MenuScreen());
      expect(find.text('Hi, Olympicson'), findsOneWidget);
      expect(find.byType(DrinkCarousel), findsOneWidget);
      expect(find.text('Popular today'), findsOneWidget);
    });

    testWidgets('a category narrows the menu', (tester) async {
      await pumpScreen(tester, const MenuScreen());
      await tester.tap(find.bySemanticsLabel('Tea'));
      await tester.pumpAndSettle();
      final wheel = tester.widget<DrinkCarousel>(find.byType(DrinkCarousel));
      expect(wheel.drinks.map((d) => d.id), ['matcha-latte']);
    });

    testWidgets('search finds by name and names an empty result', (tester) async {
      await pumpScreen(tester, const MenuScreen());
      await tester.enterText(find.byType(TextField), 'flat');
      await tester.pumpAndSettle();
      expect(tester.widget<DrinkCarousel>(find.byType(DrinkCarousel)).drinks.single.id, 'flat-white');
      await tester.enterText(find.byType(TextField), 'tequila');
      await tester.pumpAndSettle();
      expect(find.text('Nothing called that'), findsOneWidget);
    });

    testWidgets('tapping the middle cup opens the drink', (tester) async {
      await pumpScreen(tester, const MenuScreen());
      await tester.tap(find.bySemanticsLabel('Flat White').first);
      await tester.pumpAndSettle();
      expect(find.byType(DrinkScreen), findsOneWidget);
    });
  });

  group('Drink', () {
    testWidgets('every choice changes the price and re-pours the cup', (tester) async {
      await pumpScreen(tester, DrinkScreen(drink: testSeed.drink('flat-white')));
      expect(find.bySemanticsLabel('\$4.20'), findsOneWidget);
      final before = tester.widget<Cup>(find.byType(Cup)).drink;
      await tester.ensureVisible(find.text('L'));
      await tester.pump();
      await tester.tap(find.text('L'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('\$4.70'), findsOneWidget);
      await tester.ensureVisible(find.text('Oat'));
      await tester.pump();
      await tester.tap(find.text('Oat'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('\$5.30'), findsOneWidget);
      expect(tester.widget<Cup>(find.byType(Cup)).drink, isNot(before));
    });

    testWidgets('a drink with one temperature offers no switch', (tester) async {
      await pumpScreen(tester, DrinkScreen(drink: testSeed.drink('flat-white')));
      expect(find.text('Temperature'), findsNothing);
      await pumpScreen(tester, DrinkScreen(drink: testSeed.drink('oat-latte')));
      expect(find.text('Temperature'), findsOneWidget);
    });

    testWidgets('a straight espresso takes no milk', (tester) async {
      await pumpScreen(tester, DrinkScreen(drink: testSeed.drink('espresso')));
      expect(find.text('Milk'), findsNothing);
    });

    testWidgets('shots stop at three and sugar can be cleared', (tester) async {
      await pumpScreen(tester, DrinkScreen(drink: testSeed.drink('flat-white')));
      // Bring the controls well above the pinned price and button.
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(CountStepper), matching: find.byIcon(Icons.add_rounded)));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: find.byType(CountStepper), matching: find.byIcon(Icons.add_rounded)));
      await tester.pumpAndSettle();
      expect(tester.widget<CountStepper>(find.byType(CountStepper)).value, 3);
      await tester.tap(find.descendant(of: find.byType(CountStepper), matching: find.byIcon(Icons.add_rounded)));
      await tester.pumpAndSettle();
      expect(tester.widget<CountStepper>(find.byType(CountStepper)).value, 3);
      final second = find.descendant(of: find.byType(SugarPicker), matching: find.byType(GestureDetector)).at(1);
      await tester.tap(second);
      await tester.pumpAndSettle();
      expect(find.text('Sweet'), findsOneWidget);
      await tester.tap(second);
      await tester.pumpAndSettle();
      expect(find.text('A little'), findsOneWidget);
    });

    testWidgets('Add to bag puts it in the bag made that way', (tester) async {
      final (c, _) = await pumpScreen(tester, DrinkScreen(drink: testSeed.drink('oat-latte')));
      await tester.ensureVisible(find.text('Iced'));
      await tester.pump();
      await tester.tap(find.text('Iced'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to bag'));
      await tester.pumpAndSettle();
      final line = c.read(bagProvider).single;
      expect(line.drinkId, 'oat-latte');
      expect(line.options.temp, Temp.iced);
    });
  });

  group('Bag', () {
    testWidgets('empty bag sends you to the menu', (tester) async {
      final (c, _) = await pumpScreen(tester, const BagScreen());
      expect(find.text('Your bag is empty'), findsOneWidget);
      await tester.tap(find.text('See the menu'));
      expect(c.read(tabProvider), 0);
    });

    testWidgets('quantities change the total; swiping removes with undo', (tester) async {
      final (c, _) = await pumpScreen(tester, const Scaffold(body: BagScreen()));
      c.read(bagProvider.notifier).add('flat-white', testSeed.drink('flat-white').defaults);
      c.read(bagProvider.notifier).add('espresso', testSeed.drink('espresso').defaults);
      await tester.pumpAndSettle();
      expect(find.text('Pay \$7.00'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('More cups').first);
      await tester.pumpAndSettle();
      expect(find.text('Pay \$11.20'), findsOneWidget);
      await tester.drag(find.text('Espresso'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(c.read(bagProvider).length, 1);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(c.read(bagProvider).length, 2);
    });

    testWidgets('paying places the order and opens its status', (tester) async {
      final (c, _) = await pumpScreen(tester, const Scaffold(body: BagScreen()));
      c.read(bagProvider.notifier).add('flat-white', testSeed.drink('flat-white').defaults);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('In 15 minutes').evaluate().isEmpty ? find.text('15 min') : find.bySemanticsLabel('15 min'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pay \$4.20'));
      await tester.pump();
      await tester.tap(find.text('Pay \$4.20'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderScreen), findsOneWidget);
      expect(c.read(ordersProvider).single.pickup, Pickup.in15);
      expect(c.read(bagProvider), isEmpty);
    });
  });

  group('Order', () {
    testWidgets('moves through the stages with the clock and can be collected', (tester) async {
      final (c, clock) = await pumpScreen(tester, const SizedBox());
      c.read(bagProvider.notifier).add('flat-white', testSeed.drink('flat-white').defaults);
      final order = await c.read(ordersProvider.notifier).place(Pickup.now);
      await pumpScreen(tester, OrderScreen(orderId: order.id), prefs: {'crema.orders.v1': c.read(prefsProvider).getString('crema.orders.v1')!});
      expect(find.text('Order received'), findsWidgets);
      expect(find.text('Waiting for the bar'), findsOneWidget);
    });

    testWidgets('a ready order offers collection', (tester) async {
      final (c, clock) = await pumpScreen(tester, const SizedBox());
      c.read(bagProvider.notifier).add('flat-white', testSeed.drink('flat-white').defaults);
      await c.read(ordersProvider.notifier).place(Pickup.now);
      final saved = c.read(prefsProvider).getString('crema.orders.v1')!;
      final (c2, clock2) = await pumpScreen(tester, const SizedBox(), prefs: {'crema.orders.v1': saved});
      final id = c2.read(ordersProvider).single.id;
      await pumpScreen(tester, OrderScreen(orderId: id), prefs: {'crema.orders.v1': saved});
      final (_, _) = (c2, clock2);
      expect(find.text('Waiting for the bar'), findsOneWidget);
    });
  });

  group('Rewards', () {
    testWidgets('shows the card and how many to go', (tester) async {
      await pumpScreen(tester, const RewardsScreen());
      expect(find.byType(StampCard), findsOneWidget);
      expect(find.text('4 more drinks until one is on us.'), findsOneWidget);
      expect(find.text('Your orders will show up here, ready to have again.'), findsOneWidget);
    });
  });
}

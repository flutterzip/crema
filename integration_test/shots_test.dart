// Screenshots of every screen on the simulator, light and dark:
//   tool/shots.sh
import 'package:crema/app.dart';
import 'package:crema/demo/demo_control.dart';
import 'package:crema/screens/drink/drink_screen.dart';
import 'package:crema/screens/order/order_screen.dart';
import 'package:crema/screens/shell/shell.dart';
import 'package:crema/state/store.dart';
import 'package:crema/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const mode = String.fromEnvironment('mode', defaultValue: 'light');

Future<void> settle(WidgetTester t, [int ms = 1600]) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('shots $mode', (t) async {
    DemoControl.enabled = false;
    SharedPreferences.setMockInitialValues({'crema.theme.v1': mode});
    final prefs = await SharedPreferences.getInstance();
    final seed = await Seed.load();
    final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs), seedProvider.overrideWithValue(seed)]);
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const CremaApp(splash: false)));
    await settle(t, 2500);
    Future<void> shot(String name) async {
      await settle(t);
      await binding.takeScreenshot('${name}_$mode');
    }

    await shot('menu');
    menuNavigator.currentState!.push(CremaRoute(DrinkScreen(drink: seed.drink('oat-latte'))));
    await shot('drink');
    menuNavigator.currentState!.pop();
    await settle(t, 800);
    menuNavigator.currentState!.push(CremaRoute(DrinkScreen(drink: seed.drink('iced-latte'))));
    await shot('drink_iced');
    menuNavigator.currentState!.pop();
    await settle(t, 800);

    final bag = c.read(bagProvider.notifier);
    bag.add('oat-latte', seed.drink('oat-latte').defaults);
    bag.add('iced-latte', seed.drink('iced-latte').defaults.copyWith(size: CupSize.large));
    bag.add('matcha-latte', seed.drink('matcha-latte').defaults);
    c.read(tabProvider.notifier).state = 1;
    await shot('bag');

    final order = await c.read(ordersProvider.notifier).place(Pickup.now);
    navigatorKey.currentState!.push(CremaRoute(OrderScreen(orderId: order.id)));
    await settle(t, 16000);
    await shot('order_brewing');
    await settle(t, 11000);
    await shot('order_ready');
    navigatorKey.currentState!.pop();
    c.read(tabProvider.notifier).state = 2;
    await settle(t, 3000);
    await shot('rewards');
  });
}

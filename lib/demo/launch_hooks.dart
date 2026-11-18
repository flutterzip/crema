import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app.dart';
import '../data/models.dart';
import '../screens/drink/drink_screen.dart';
import '../screens/order/order_screen.dart';
import '../screens/shell/shell.dart';
import '../state/store.dart';
import '../widgets/routes.dart';

/// Opens a screen straight after the splash, for screenshots and
/// recordings: `--dart-define=startRoute=drink`. Off by default, so a
/// release build is unaffected.
///
/// menu, drink (the Oat Latte), bag, order (places a demo order), rewards.
const startRoute = String.fromEnvironment('startRoute');

void runLaunchHooks(WidgetRef ref) {
  if (startRoute.isEmpty) return;
  final seed = ref.read(seedProvider);
  switch (startRoute) {
    case 'drink':
      menuNavigator.currentState?.push(CremaRoute(DrinkScreen(drink: seed.drink('oat-latte'))));
    case 'bag':
      final bag = ref.read(bagProvider.notifier);
      if (ref.read(bagProvider).isEmpty) {
        bag.add('oat-latte', seed.drink('oat-latte').defaults);
        bag.add('iced-latte', seed.drink('iced-latte').defaults.copyWith(size: CupSize.large));
      }
      ref.read(tabProvider.notifier).state = 1;
    case 'order':
      if (ref.read(bagProvider).isEmpty) ref.read(bagProvider.notifier).add('flat-white', seed.drink('flat-white').defaults);
      ref.read(ordersProvider.notifier).place(Pickup.now).then((o) {
        navigatorKey.currentState?.push(CremaRoute(OrderScreen(orderId: o.id)));
      });
    case 'rewards':
      ref.read(tabProvider.notifier).state = 2;
  }
}

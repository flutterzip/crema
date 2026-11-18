import 'package:crema/data/models.dart';
import 'package:crema/state/store.dart';
import 'package:crema/widgets/cup/cup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crema/config/timing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

Future<(ProviderContainer, TestClock)> container([Map<String, Object> prefs = const {}]) async {
  AppTiming.scale = 0;
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  final clock = TestClock();
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(sp),
    seedProvider.overrideWithValue(testSeed),
    clockProvider.overrideWithValue(() => clock.now),
  ]);
  addTearDown(c.dispose);
  return (c, clock);
}

void main() {
  group('money and prices', () {
    test('formats cents', () {
      expect(money(-40), '-\$0.40');
      expect(moneyDelta(50), '+\$0.50');
      expect(money(460), '\$4.60');
      expect(money(1005), '\$10.05');
    });

    test('options add up', () {
      final d = testSeed.drink('flat-white');
      expect(d.priceWith(d.defaults), 420);
      expect(d.priceWith(d.defaults.copyWith(size: CupSize.large)), 470);
      expect(d.priceWith(d.defaults.copyWith(size: CupSize.small)), 380);
      expect(d.priceWith(d.defaults.copyWith(milk: Milk.oat, shots: 3)), 420 + 60 + 160);
    });

    test('a drink that comes with oat does not charge for oat', () {
      final d = testSeed.drink('oat-latte');
      expect(d.priceWith(d.defaults), 460);
    });
  });

  group('pouring', () {
    test('iced drinks lose the foam and the art, and gain ice', () {
      final d = testSeed.drink('oat-latte');
      final art = d.pour(d.defaults.copyWith(temp: Temp.iced));
      expect(art.iced, 1);
      expect(art.hot, 0);
      expect(art.foam, 0);
      expect(art.art, LatteArt.none);
    });

    test('more shots means more coffee in the glass', () {
      final d = testSeed.drink('flat-white');
      expect(d.pour(d.defaults.copyWith(shots: 3)).base, greaterThan(d.pour(d.defaults).base));
    });

    test('blending two drinks lands exactly on each end', () {
      const a = DrinkArt(baseColor: DrinkColors.espresso, level: 0.2);
      const b = DrinkArt(baseColor: DrinkColors.matcha, level: 0.9, art: LatteArt.rosetta);
      expect(DrinkArt.lerp(a, b, 0), a);
      expect(DrinkArt.lerp(a, b, 1), b);
    });
  });

  group('bag', () {
    test('the same drink made the same way joins its line', () async {
      final (c, _) = await container();
      final o = testSeed.drink('flat-white').defaults;
      c.read(bagProvider.notifier).add('flat-white', o);
      c.read(bagProvider.notifier).add('flat-white', o);
      c.read(bagProvider.notifier).add('flat-white', o.copyWith(size: CupSize.large));
      expect(c.read(bagProvider).length, 2);
      expect(c.read(bagCountProvider), 3);
      expect(c.read(bagTotalProvider), 420 * 2 + 470);
    });

    test('removing can be undone in place', () async {
      final (c, _) = await container();
      final bag = c.read(bagProvider.notifier);
      bag.add('flat-white', testSeed.drink('flat-white').defaults);
      bag.add('espresso', testSeed.drink('espresso').defaults);
      final first = c.read(bagProvider).first;
      final undo = bag.remove(first.id)!;
      expect(c.read(bagProvider).length, 1);
      bag.restore(undo.$1, undo.$2);
      expect(c.read(bagProvider).first.id, first.id);
    });

    test('survives a restart', () async {
      final (c, _) = await container();
      c.read(bagProvider.notifier).add('espresso', testSeed.drink('espresso').defaults);
      final saved = c.read(prefsProvider).getString('crema.bag.v1')!;
      final (c2, _) = await container({'crema.bag.v1': saved});
      expect(c2.read(bagProvider).single.drinkId, 'espresso');
    });
  });

  group('orders', () {
    test('placing empties the bag and moves through the bar with the clock', () async {
      final (c, clock) = await container();
      c.read(bagProvider.notifier).add('flat-white', testSeed.drink('flat-white').defaults);
      final order = await c.read(ordersProvider.notifier).place(Pickup.now);
      expect(c.read(bagProvider), isEmpty);
      expect(order.total, 420);
      expect(stageOf(order, clock.now), Stage.received);
      expect(stageOf(order, clock.now.add(const Duration(seconds: 7))), Stage.grinding);
      expect(stageOf(order, clock.now.add(const Duration(seconds: 15))), Stage.brewing);
      expect(stageOf(order, clock.now.add(const Duration(seconds: 30))), Stage.ready);
      expect(progressOf(order, clock.now.add(const Duration(minutes: 5))), 1);
    });

    test('a later pickup waits before it starts', () async {
      final (c, clock) = await container();
      c.read(bagProvider.notifier).add('espresso', testSeed.drink('espresso').defaults);
      final order = await c.read(ordersProvider.notifier).place(Pickup.in15);
      expect(stageOf(order, clock.now.add(const Duration(minutes: 10))), Stage.received);
      expect(stageOf(order, clock.now.add(const Duration(minutes: 16))), Stage.ready);
    });

    test('collected orders leave the active slot, and can be had again', () async {
      final (c, _) = await container();
      c.read(bagProvider.notifier).add('espresso', testSeed.drink('espresso').defaults);
      final order = await c.read(ordersProvider.notifier).place(Pickup.now);
      expect(c.read(activeOrderProvider)?.id, order.id);
      c.read(ordersProvider.notifier).collect(order.id);
      expect(c.read(activeOrderProvider), isNull);
      c.read(ordersProvider.notifier).reorder(order);
      expect(c.read(bagCountProvider), 1);
    });
  });

  group('stamp card', () {
    test('starts at the seeded stamps and earns one per cup', () async {
      final (c, _) = await container();
      expect(c.read(cardProvider), (stamps: 6, rewards: 0));
      final bag = c.read(bagProvider.notifier);
      bag.add('espresso', testSeed.drink('espresso').defaults);
      bag.setQty(c.read(bagProvider).single.id, 4);
      await c.read(ordersProvider.notifier).place(Pickup.now);
      expect(c.read(cardProvider), (stamps: 10, rewards: 1));
      await c.read(redeemedProvider.notifier).redeem();
      expect(c.read(cardProvider), (stamps: 0, rewards: 0));
    });
  });
}

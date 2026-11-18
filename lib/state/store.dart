import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/motion.dart';
import '../config/timing.dart';
import '../data/models.dart';

/// The bundled seed: the menu and the demo person.
class Seed {
  const Seed({required this.drinks, required this.profile});

  final List<Drink> drinks;
  final Profile profile;

  Drink drink(String id) => drinks.firstWhere((d) => d.id == id);

  static Future<Seed> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final drinks = jsonDecode(await b.loadString('assets/data/drinks.json')) as List;
    final profile = jsonDecode(await b.loadString('assets/data/profile.json')) as Map<String, Object?>;
    return Seed(
      drinks: [for (final d in drinks) Drink.fromJson(d as Map<String, Object?>)],
      profile: Profile.fromJson(profile),
    );
  }
}

/// Overridden in `main.dart` once the seed and preferences have loaded.
final seedProvider = Provider<Seed>((_) => throw UnimplementedError());
final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());

/// The clock, so tests can move time.
final clockProvider = Provider<DateTime Function()>((_) => DateTime.now);

/// Ticks once a second while ambient motion is on, so live order status
/// moves on its own.
final tickProvider = StreamProvider<int>((ref) {
  if (!Motion.ambient) return const Stream.empty();
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});

final nowProvider = Provider<DateTime>((ref) {
  ref.watch(tickProvider);
  return ref.watch(clockProvider)();
});

int _ids = 0;
String newId(DateTime now) => '${now.microsecondsSinceEpoch}-${_ids++}';

// ---------------------------------------------------------------- the bag

final bagProvider = NotifierProvider<BagNotifier, List<BagLine>>(BagNotifier.new);

class BagNotifier extends Notifier<List<BagLine>> {
  static const _key = 'crema.bag.v1';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  List<BagLine> build() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      return [for (final l in jsonDecode(raw) as List) BagLine.fromJson(l as Map<String, Object?>)];
    } catch (_) {
      return const [];
    }
  }

  void _save(List<BagLine> lines) {
    state = lines;
    _prefs.setString(_key, jsonEncode([for (final l in lines) l.toJson()]));
  }

  /// Adds a drink. The same drink made the same way joins its line.
  void add(String drinkId, Options options) {
    final i = state.indexWhere((l) => l.drinkId == drinkId && l.options == options);
    if (i >= 0) {
      _save([...state]..[i] = state[i].copyWith(qty: state[i].qty + 1));
    } else {
      _save([...state, BagLine(id: newId(ref.read(clockProvider)()), drinkId: drinkId, options: options)]);
    }
  }

  void setQty(String id, int qty) {
    if (qty <= 0) {
      remove(id);
      return;
    }
    _save([for (final l in state) l.id == id ? l.copyWith(qty: qty.clamp(1, 9)) : l]);
  }

  /// Removes a line and hands back what is needed to put it back.
  (BagLine, int)? remove(String id) {
    final i = state.indexWhere((l) => l.id == id);
    if (i < 0) return null;
    final line = state[i];
    _save([...state]..removeAt(i));
    return (line, i);
  }

  void restore(BagLine line, int index) => _save([...state]..insert(index.clamp(0, state.length), line));

  void clear() => _save(const []);
}

/// What the bag costs, derived from the lines and the menu.
final bagTotalProvider = Provider<int>((ref) {
  final seed = ref.watch(seedProvider);
  return ref.watch(bagProvider).fold(0, (sum, l) => sum + seed.drink(l.drinkId).priceWith(l.options) * l.qty);
});

final bagCountProvider = Provider<int>((ref) => ref.watch(bagProvider).fold(0, (n, l) => n + l.qty));

// ---------------------------------------------------------------- orders

final ordersProvider = NotifierProvider<OrdersNotifier, List<Order>>(OrdersNotifier.new);

class OrdersNotifier extends Notifier<List<Order>> {
  static const _key = 'crema.orders.v1';

  SharedPreferences get _prefs => ref.read(prefsProvider);

  @override
  List<Order> build() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    try {
      return [for (final o in jsonDecode(raw) as List) Order.fromJson(o as Map<String, Object?>)];
    } catch (_) {
      return const [];
    }
  }

  void _save(List<Order> orders) {
    state = orders;
    _prefs.setString(_key, jsonEncode([for (final o in orders) o.toJson()]));
  }

  /// Pays for the bag and places the order (newest first).
  Future<Order> place(Pickup pickup) async {
    final lines = ref.read(bagProvider);
    final total = ref.read(bagTotalProvider);
    await AppTiming.wait(AppTiming.pay);
    final now = ref.read(clockProvider)();
    final order = Order(
      id: newId(now),
      number: 41 + state.length,
      placedAt: now,
      lines: lines,
      total: total,
      pickup: pickup,
    );
    _save([order, ...state]);
    ref.read(bagProvider.notifier).clear();
    return order;
  }

  void collect(String id) => _save([for (final o in state) o.id == id ? o.copyWith(collected: true) : o]);

  /// Puts every drink of a past order back in the bag.
  void reorder(Order order) {
    for (final l in order.lines) {
      for (var i = 0; i < l.qty; i++) {
        ref.read(bagProvider.notifier).add(l.drinkId, l.options);
      }
    }
  }
}

/// Where an order is at [now]. A collected order stays ready.
Stage stageOf(Order order, DateTime now) {
  final elapsed = now.difference(order.placedAt.add(Duration(minutes: order.pickup.minutes)));
  var stage = Stage.received;
  for (var i = 0; i < AppTiming.orderStages.length; i++) {
    if (elapsed >= AppTiming.orderStages[i]) stage = Stage.values[i];
  }
  return order.collected ? Stage.ready : stage;
}

/// 0..1 through the whole order, for the cup filling on the status page.
double progressOf(Order order, DateTime now) {
  final start = order.placedAt.add(Duration(minutes: order.pickup.minutes));
  final total = AppTiming.orderStages.last.inMilliseconds;
  return (now.difference(start).inMilliseconds / total).clamp(0.0, 1.0);
}

/// The newest order not yet collected, if any.
final activeOrderProvider = Provider<Order?>((ref) {
  for (final o in ref.watch(ordersProvider)) {
    if (!o.collected) return o;
  }
  return null;
});

// ---------------------------------------------------------------- rewards

const stampsPerReward = 10;

final redeemedProvider = NotifierProvider<RedeemedNotifier, int>(RedeemedNotifier.new);

class RedeemedNotifier extends Notifier<int> {
  static const _key = 'crema.redeemed.v1';

  @override
  int build() => ref.read(prefsProvider).getInt(_key) ?? 0;

  Future<void> redeem() async {
    await AppTiming.wait(AppTiming.redeem);
    state = state + 1;
    await ref.read(prefsProvider).setInt(_key, state);
  }
}

/// Stamps earned in all (seed plus every cup ordered).
final stampsEarnedProvider = Provider<int>((ref) {
  final seed = ref.watch(seedProvider).profile.stamps;
  return seed + ref.watch(ordersProvider).fold(0, (n, o) => n + o.cups);
});

/// Stamps on the current card, 0..10, and free drinks waiting.
final cardProvider = Provider<({int stamps, int rewards})>((ref) {
  final earned = ref.watch(stampsEarnedProvider);
  final redeemed = ref.watch(redeemedProvider);
  final full = earned ~/ stampsPerReward;
  final waiting = (full - redeemed).clamp(0, 99);
  final onCard = waiting > 0 ? stampsPerReward : earned % stampsPerReward;
  return (stamps: onCard, rewards: waiting);
});

// ---------------------------------------------------------------- settings

class DemoSettings {
  const DemoSettings({this.theme = ThemeMode.system});

  final ThemeMode theme;
}

final demoSettingsProvider = NotifierProvider<DemoSettingsNotifier, DemoSettings>(DemoSettingsNotifier.new);

class DemoSettingsNotifier extends Notifier<DemoSettings> {
  static const _theme = 'crema.theme.v1';

  @override
  DemoSettings build() => DemoSettings(
        theme: ThemeMode.values.asNameMap()[ref.read(prefsProvider).getString(_theme)] ?? ThemeMode.system,
      );

  Future<void> setTheme(ThemeMode mode) async {
    state = DemoSettings(theme: mode);
    await ref.read(prefsProvider).setString(_theme, mode.name);
  }
}

/// Back to first launch: empty bag, no orders, the seeded card.
Future<void> resetDemo(WidgetRef ref) async {
  await ref.read(prefsProvider).clear();
  ref.invalidate(bagProvider);
  ref.invalidate(ordersProvider);
  ref.invalidate(redeemedProvider);
  ref.invalidate(demoSettingsProvider);
}

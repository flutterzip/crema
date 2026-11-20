import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../bag/bag_screen.dart';
import '../menu/menu_screen.dart';
import '../rewards/rewards_screen.dart';

/// Which tab is showing. Screens switch tabs through it (the bag's empty
/// state sends you to the menu).
final tabProvider = StateProvider<int>((_) => 0);

/// The menu tab's own navigator: a drink opens inside the tab, and the bar
/// slides away while it is open so the drink's price and Add to bag can sit
/// at the bottom edge. The drink page carries its own bag for the cup to
/// fly into.
final menuNavigator = GlobalKey<NavigatorState>(debugLabel: 'menu');

/// Whether the menu tab has a page open over its home.
class _Depth extends NavigatorObserver {
  final deep = ValueNotifier(false);
  var _n = 0;

  void _set(int n) {
    _n = n;
    deep.value = _n > 1;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(_n + 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(_n - 1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(_n - 1);
}

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  final _heroes = HeroController();
  final _depth = _Depth();
  final _built = <int>{0};

  @override
  void dispose() {
    _depth.deep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(tabProvider);
    _built.add(tab);
    final count = ref.watch(bagCountProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(
        index: tab,
        children: [
          HeroMode(
            enabled: tab == 0,
            child: NavigatorPopHandler(
              onPopWithResult: (_) => menuNavigator.currentState?.maybePop(),
              child: Navigator(
                key: menuNavigator,
                observers: [_heroes, _depth],
                onGenerateRoute: (_) => CremaRoute<void>(const MenuScreen()),
              ),
            ),
          ),
          _built.contains(1) ? const StatusFrost(child: BagScreen()) : const SizedBox(),
          _built.contains(2) ? const StatusFrost(child: RewardsScreen()) : const SizedBox(),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder(
        valueListenable: _depth.deep,
        builder: (context, deep, bar) {
          final hide = deep && tab == 0;
          return IgnorePointer(
            ignoring: hide,
            child: AnimatedSlide(offset: Offset(0, hide ? 1.2 : 0), duration: Motion.medium, curve: Motion.spring, child: bar),
          );
        },
        child: GlassTabBar(
          index: tab,
          onTap: (i) {
            if (i == tab && i == 0) menuNavigator.currentState?.popUntil((r) => r.isFirst);
            ref.read(tabProvider.notifier).state = i;
          },
          items: [
            const TabItem('Menu', Icons.local_cafe_outlined, Icons.local_cafe_rounded),
            TabItem('Bag', Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, badge: count, isBag: true),
            const TabItem('Rewards', Icons.loyalty_outlined, Icons.loyalty_rounded),
          ],
        ),
      ),
    );
  }
}

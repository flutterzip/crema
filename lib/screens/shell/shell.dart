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

/// The menu tab's own navigator: a drink opens inside the tab, so the bar
/// (and the bag the cup flies into) stays on screen.
final menuNavigator = GlobalKey<NavigatorState>(debugLabel: 'menu');

class Shell extends ConsumerStatefulWidget {
  const Shell({super.key});

  @override
  ConsumerState<Shell> createState() => _ShellState();
}

class _ShellState extends ConsumerState<Shell> {
  final _heroes = HeroController();
  final _built = <int>{0};

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
                observers: [_heroes],
                onGenerateRoute: (_) => CremaRoute<void>(const MenuScreen()),
              ),
            ),
          ),
          _built.contains(1) ? const BagScreen() : const SizedBox(),
          _built.contains(2) ? const RewardsScreen() : const SizedBox(),
        ],
      ),
      bottomNavigationBar: GlassTabBar(
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
    );
  }
}

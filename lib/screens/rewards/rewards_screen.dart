import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../order/order_screen.dart';
import '../shell/shell.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  /// Stamps already seen, so only new ones are pressed in.
  late int seen = (ref.read(seedProvider).profile.stamps - 3).clamp(0, 10);
  bool redeeming = false, redeemed = false;

  Future<void> redeem() async {
    setState(() => redeeming = true);
    await ref.read(redeemedProvider.notifier).redeem();
    setState(() {
      redeeming = false;
      redeemed = true;
      seen = 0;
    });
  }

  void reorder(Order order) {
    ref.read(ordersProvider.notifier).reorder(order);
    bagLanded.value++;
    ref.read(tabProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final card = ref.watch(cardProvider);
    final orders = ref.watch(ordersProvider);
    final seed = ref.watch(seedProvider);
    final now = ref.watch(nowProvider);
    final text = Theme.of(context).textTheme;
    final left = stampsPerReward - card.stamps;

    return ListView(
      padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 12, Tokens.gutter, 130),
      children: [
        Entrance(
          spacing: 20,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rewards', style: text.headlineSmall),
                Text(
                  card.rewards > 0 ? 'A free drink is waiting for you.' : '$left more ${left == 1 ? 'drink' : 'drinks'} until one is on us.',
                  style: text.bodyMedium,
                ),
              ],
            ),
            StampCard(stamps: card.stamps, seen: seen),
            if (redeemed)
              const FreeDrinkTicket(code: 'CREMA 4821')
            else if (card.rewards > 0)
              CremaButton(label: 'Redeem a free drink', icon: Icons.redeem_rounded, busy: redeeming, onPressed: redeem),
            const SectionTitle('Your orders'),
            if (orders.isEmpty)
              Text('Your orders will show up here, ready to have again.', style: text.bodyMedium)
            else
              for (final o in orders)
                DrinkRow(
                  drink: seed.drink(o.lines.first.drinkId),
                  options: o.lines.first.options,
                  onTap: () => Navigator.of(context, rootNavigator: true).push(CremaRoute(OrderScreen(orderId: o.id))),
                  trailing: o.collected || stageOf(o, now) == Stage.ready
                      ? RoundButton(icon: Icons.replay_rounded, label: 'Order again', size: 42, onTap: () => reorder(o))
                      : Text(stageOf(o, now).title, style: text.labelMedium),
                ),
          ],
        ),
      ],
    );
  }
}

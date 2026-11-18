import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../order/order_screen.dart';
import '../shell/shell.dart';

class BagScreen extends ConsumerStatefulWidget {
  const BagScreen({super.key});

  @override
  ConsumerState<BagScreen> createState() => _BagScreenState();
}

class _BagScreenState extends ConsumerState<BagScreen> {
  Pickup pickup = Pickup.now;
  bool paying = false, paid = false;

  void remove(BagLine line) {
    final undo = ref.read(bagProvider.notifier).remove(line.id);
    if (undo == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('${ref.read(seedProvider).drink(line.drinkId).name} removed'),
        action: SnackBarAction(label: 'Undo', onPressed: () => ref.read(bagProvider.notifier).restore(undo.$1, undo.$2)),
      ));
  }

  Future<void> pay() async {
    setState(() => paying = true);
    final order = await ref.read(ordersProvider.notifier).place(pickup);
    setState(() {
      paying = false;
      paid = true;
    });
    await AppTiming.wait(AppTiming.successBeat);
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(CremaRoute(OrderScreen(orderId: order.id)));
    if (mounted) setState(() => paid = false);
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(bagProvider);
    final seed = ref.watch(seedProvider);
    final total = ref.watch(bagTotalProvider);
    final text = Theme.of(context).textTheme;

    if (lines.isEmpty && !paid) {
      return Center(
        child: EmptyState(
          art: Cup(drink: const DrinkArt(baseColor: DrinkColors.espresso, level: 0, hot: 0), width: 120),
          title: 'Your bag is empty',
          message: 'Pick something warm, or something with ice. We will have it ready when you arrive.',
          action: CremaButton(label: 'See the menu', onPressed: () => ref.read(tabProvider.notifier).state = 0),
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 12, Tokens.gutter, 130),
      children: [
        Text('Your bag', style: text.headlineSmall),
        Text('Swipe a drink away to remove it.', style: text.bodyMedium),
        const SizedBox(height: 20),
        for (final line in lines) ...[
          Dismissible(
            key: ValueKey(line.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => remove(line),
            background: const SwipeToRemove(),
            child: DrinkRow(
              drink: seed.drink(line.drinkId),
              options: line.options,
              trailing: CountStepper(
                value: line.qty,
                min: 0,
                max: 9,
                label: 'cups',
                onChanged: (n) => n == 0 ? remove(line) : ref.read(bagProvider.notifier).setQty(line.id, n),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 14),
        OptionSection(
          title: 'Pick up',
          value: pickup.label,
          child: Segments<Pickup>(
            values: Pickup.values,
            value: pickup,
            label: (p) => p.short,
            onChanged: (p) => setState(() => pickup = p),
          ),
        ),
        const SizedBox(height: 24),
        TotalRow(label: 'Subtotal', cents: total),
        const TotalRow(label: 'Service', cents: 0),
        TotalRow(label: 'Total', cents: total, strong: true),
        const SizedBox(height: 20),
        CremaButton(
          label: 'Pay ${money(total)}',
          icon: Icons.lock_rounded,
          busy: paying,
          done: paid,
          onPressed: lines.isEmpty ? null : pay,
        ),
      ],
    );
  }
}

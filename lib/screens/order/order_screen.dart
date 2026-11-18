import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';

/// Live status of one order, worked out from the clock: watch it grind,
/// pour and fill, then collect it.
class OrderScreen extends ConsumerStatefulWidget {
  const OrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends ConsumerState<OrderScreen> {
  bool collecting = false;

  Future<void> collect(Order order) async {
    setState(() => collecting = true);
    ref.read(ordersProvider.notifier).collect(order.id);
    await AppTiming.wait(AppTiming.successBeat);
    if (mounted) Navigator.of(context).pop();
  }

  String wait(Order order, DateTime now) {
    final ready = order.placedAt.add(Duration(minutes: order.pickup.minutes)).add(AppTiming.orderStages.last);
    final left = ready.difference(now);
    if (left.inSeconds <= 0) return 'Ready now';
    if (left.inMinutes >= 1) return 'Ready in about ${left.inMinutes + 1} min';
    return 'Ready in ${left.inSeconds} s';
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(ordersProvider).firstWhere((o) => o.id == widget.orderId);
    final now = ref.watch(nowProvider);
    final seed = ref.watch(seedProvider);
    final stage = stageOf(order, now);
    final first = order.lines.first;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 8, Tokens.gutter, 40),
        children: [
          Row(
            children: [
              RoundButton(icon: Icons.close_rounded, label: 'Close', onTap: () => Navigator.of(context).pop()),
              const Spacer(),
              Text('Order ${order.number}', style: text.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: BrewScene(
              drink: seed.drink(first.drinkId).pour(first.options),
              stage: stage,
              progress: progressOf(order, now),
            ),
          ),
          const SizedBox(height: 20),
          Entrance(
            spacing: 22,
            children: [
              Column(
                children: [
                  AnimatedSwitcher(
                    duration: Motion.medium,
                    child: Text(stage.title, key: ValueKey(stage), style: text.displaySmall),
                  ),
                  const SizedBox(height: 6),
                  Text('${wait(order, now)} · ${seed.profile.store}', style: text.bodyMedium, textAlign: TextAlign.center),
                ],
              ),
              StageTrack(stage: stage),
              Column(
                children: [
                  for (final l in order.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: DrinkRow(drink: seed.drink(l.drinkId), options: l.options, trailing: Text('× ${l.qty}', style: text.titleMedium)),
                    ),
                  TotalRow(label: 'Paid', cents: order.total, strong: true),
                ],
              ),
              CremaButton(
                label: stage == Stage.ready ? 'I have it, thanks' : 'Waiting for the bar',
                done: collecting,
                onPressed: stage == Stage.ready && !order.collected ? () => collect(order) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../shell/shell.dart';

/// One drink, made your way. Every choice re-pours the cup.
class DrinkScreen extends ConsumerStatefulWidget {
  const DrinkScreen({super.key, required this.drink});

  final Drink drink;

  @override
  ConsumerState<DrinkScreen> createState() => _DrinkScreenState();
}

class _DrinkScreenState extends ConsumerState<DrinkScreen> {
  late Options options = widget.drink.defaults;
  final cupKey = GlobalKey();
  final bagKey = GlobalKey(debugLabel: 'drink bag');
  final scroll = ScrollController();
  bool adding = false;

  /// This cup, made this way, is in the bag. Any new choice makes it a
  /// different cup, so the dock offers Add to bag again.
  bool added = false;

  Drink get drink => widget.drink;

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void choose(Options next) => setState(() {
    options = next;
    added = false;
  });

  Future<void> addToBag() async {
    setState(() => adding = true);
    await flyToBag(
      context,
      from: cupKey,
      to: bagKey,
      child: Cup(drink: drink.pour(options), width: 230),
      onLand: () => ref.read(bagProvider.notifier).add(drink.id, options),
    );
    if (mounted) {
      setState(() {
        adding = false;
        added = true;
      });
    }
  }

  void openBag() {
    menuNavigator.currentState?.popUntil((r) => r.isFirst);
    ref.read(tabProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final count = ref.watch(bagCountProvider);
    // The device's own inset: the tab bar slides away on this page, so the
    // padding the shell reserves for it does not apply.
    final safe = ActionDock.safeBottom(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ListView(
            controller: scroll,
            padding: EdgeInsets.fromLTRB(Tokens.gutter, TopChrome.extent(context), Tokens.gutter, safe + 120),
            children: [
              Center(
                child: AnimatedScale(
                  scale: options.size.scale,
                  duration: Motion.long,
                  curve: Motion.spring,
                  child: Hero(
                    tag: 'cup-${drink.id}',
                    child: KeyedSubtree(key: cupKey, child: Cup(drink: drink.pour(options), width: 230)),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Entrance(
                delay: Motion.short,
                spacing: 26,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(drink.name, style: text.displaySmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, size: 18, color: p.accent),
                          Text(' ${drink.rating}  ·  ${drink.kcal} kcal  ·  ${drink.minutes} min', style: text.bodySmall),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(drink.description, style: text.bodyLarge),
                    ],
                  ),
                  OptionSection(
                    title: 'Size',
                    value: options.size.extra == 0 ? options.size.label : '${options.size.label} ${moneyDelta(options.size.extra)}',
                    child: Segments<CupSize>(
                      values: CupSize.values,
                      value: options.size,
                      label: (s) => s.short,
                      icon: (s, on) => GlassIcon(height: 14 + s.index * 5.0, selected: on),
                      onChanged: (s) => choose(options.copyWith(size: s)),
                    ),
                  ),
                  if (drink.temps.length > 1)
                    OptionSection(
                      title: 'Temperature',
                      child: Segments<Temp>(
                        values: drink.temps,
                        value: options.temp,
                        label: (t) => t == Temp.hot ? 'Hot' : 'Iced',
                        icon: (t, on) => Icon(
                          t == Temp.hot ? Icons.local_fire_department_rounded : Icons.ac_unit_rounded,
                          size: 18,
                          color: on ? p.accentDeep : p.muted,
                        ),
                        onChanged: (t) => choose(options.copyWith(temp: t)),
                      ),
                    ),
                  if (drink.takesMilk)
                    OptionSection(
                      title: 'Milk',
                      value: options.milk == drink.milk || options.milk.extra == 0 ? null : '+${money(options.milk.extra)}',
                      child: Choices<Milk>(
                        values: Milk.values,
                        value: options.milk,
                        label: (m) => m.label,
                        onChanged: (m) => choose(options.copyWith(milk: m)),
                      ),
                    ),
                  OptionSection(
                    title: 'Espresso shots',
                    value: '+${money(80)} each extra',
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CountStepper(value: options.shots, onChanged: (n) => choose(options.copyWith(shots: n))),
                    ),
                  ),
                  OptionSection(
                    title: 'Sweetness',
                    value: Options.sweetWords[options.sweetness],
                    child: SugarPicker(value: options.sweetness, onChanged: (n) => choose(options.copyWith(sweetness: n))),
                  ),
                ],
              ),
            ],
          ),
          // The page fades into the paper under the dock.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: safe + 110,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [p.paper.withValues(alpha: 0), p.paper.withValues(alpha: 0.9), p.paper],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: Tokens.gutter - 6,
            right: Tokens.gutter - 6,
            bottom: safe + 12,
            child: ActionDock(
              // Once the cup lands, the price and button break apart and fly
              // together as the way to the bag.
              child: ParticleMorph(
                child: added
                    ? Row(
                        key: const ValueKey('added'),
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('In your bag', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelSmall!.copyWith(color: p.accentDeep)),
                                const SizedBox(height: 2),
                                Text(
                                  '$count ${count == 1 ? 'drink' : 'drinks'} · ${money(ref.watch(bagTotalProvider))}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleSmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 150,
                            child: CremaButton(label: 'View bag', icon: Icons.shopping_bag_rounded, onPressed: openBag),
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('add'),
                        children: [
                          Price(cents: drink.priceWith(options), style: text.headlineSmall),
                          const SizedBox(width: 18),
                          Expanded(
                            child: CremaButton(label: 'Add to bag', icon: Icons.add_rounded, busy: adding, onPressed: addToBag),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: TopChrome(
              controller: scroll,
              title: drink.name,
              titleAfter: 310,
              leading: RoundButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop()),
              trailing: BagButton(target: bagKey, count: count, onTap: openBag),
            ),
          ),
        ],
      ),
    );
  }
}

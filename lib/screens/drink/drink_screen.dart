import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';

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
  bool adding = false;

  Drink get drink => widget.drink;

  void choose(Options next) => setState(() => options = next);

  Future<void> addToBag() async {
    setState(() => adding = true);
    await flyToBag(
      context,
      from: cupKey,
      child: Cup(drink: drink.pour(options), width: 230),
      onLand: () => ref.read(bagProvider.notifier).add(drink.id, options),
    );
    if (mounted) setState(() => adding = false);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(Tokens.gutter, MediaQuery.paddingOf(context).top + 8, Tokens.gutter, 210),
            children: [
              Row(children: [RoundButton(icon: Icons.arrow_back_rounded, label: 'Back', onTap: () => Navigator.of(context).pop())]),
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
          Positioned(
            left: Tokens.gutter - 6,
            right: Tokens.gutter - 6,
            bottom: MediaQuery.paddingOf(context).bottom + 88,
            child: ActionDock(
              child: Row(
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
        ],
      ),
    );
  }
}

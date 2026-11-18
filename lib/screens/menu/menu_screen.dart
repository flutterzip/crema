import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/store.dart';
import '../../widgets/widgets.dart';
import '../drink/drink_screen.dart';
import '../order/order_screen.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final search = TextEditingController();
  Category? category;
  String query = '';

  void open(Drink drink) => context.open(DrinkScreen(drink: drink));

  @override
  Widget build(BuildContext context) {
    final seed = ref.watch(seedProvider);
    final active = ref.watch(activeOrderProvider);
    final now = ref.watch(nowProvider);
    final text = Theme.of(context).textTheme;
    final drinks = seed.drinks
        .where((d) => category == null || d.category == category)
        .where((d) => d.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    final popular = [...drinks]..sort((a, b) => b.rating.compareTo(a.rating));

    return ListView(
      padding: EdgeInsets.fromLTRB(0, MediaQuery.paddingOf(context).top + 12, 0, 130),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
          child: Entrance(
            spacing: 18,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hi, ${seed.profile.firstName}', style: text.headlineSmall),
                        Text('What are we brewing today?', style: text.bodyMedium),
                      ],
                    ),
                  ),
                  Avatar(name: seed.profile.name, image: seed.profile.avatar),
                ],
              ),
              if (active != null)
                OrderBanner(
                  order: active,
                  stage: stageOf(active, now),
                  progress: progressOf(active, now),
                  onTap: () => Navigator.of(context, rootNavigator: true).push(CremaRoute(OrderScreen(orderId: active.id))),
                ),
              SearchBox(controller: search, onChanged: (v) => setState(() => query = v)),
              Segments<Category?>(
                values: const [null, Category.hot, Category.iced, Category.tea],
                value: category,
                onChanged: (c) => setState(() => category = c),
                label: (c) => switch (c) {
                  null => 'All',
                  Category.hot => 'Hot',
                  Category.iced => 'Iced',
                  Category.tea => 'Tea',
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (drinks.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: EmptyState(
              art: Cup(drink: const DrinkArt(baseColor: DrinkColors.espresso, level: 0, hot: 0), width: 110),
              title: 'Nothing called that',
              message: 'Try another name, or look through everything we pour.',
            ),
          )
        else ...[
          DrinkCarousel(drinks: drinks, onOpen: open),
          Padding(
            padding: const EdgeInsets.fromLTRB(Tokens.gutter, 28, Tokens.gutter, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle('Popular today'),
                const SizedBox(height: 10),
                for (final d in popular.take(4)) ...[
                  DrinkRow(drink: d, onTap: () => open(d)),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}

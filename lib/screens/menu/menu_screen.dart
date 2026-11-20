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
  final scroll = ScrollController();
  Category? category;

  /// Search and the categories, under the greeting: 52 + 10 + 52, then a gap.
  static const filtersHeight = 128.0;
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

    return Stack(
      children: [
        ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(0, TopChrome.extent(context, bottomHeight: filtersHeight), 0, 130),
          children: [
            if (active != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(Tokens.gutter, 0, Tokens.gutter, 10),
                child: Entrance(
                  children: [
                    OrderBanner(
                      order: active,
                      stage: stageOf(active, now),
                      progress: progressOf(active, now),
                      onTap: () => Navigator.of(context, rootNavigator: true).push(CremaRoute(OrderScreen(orderId: active.id))),
                    ),
                  ],
                ),
              ),
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
        ),
        // The greeting stays; search and the categories step aside while you
        // read down the menu and come back the moment you scroll up.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: TopChrome(
            controller: scroll,
            bottomHeight: filtersHeight,
            row: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Hi, ${seed.profile.firstName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.headlineSmall),
                      Text('What are we brewing today?', maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
                    ],
                  ),
                ),
                Avatar(name: seed.profile.name, image: seed.profile.avatar),
              ],
            ),
            bottom: Padding(
              padding: const EdgeInsets.fromLTRB(Tokens.gutter, 4, Tokens.gutter, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SearchBox(controller: search, onChanged: (v) => setState(() => query = v)),
                  const SizedBox(height: 10),
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
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    search.dispose();
    scroll.dispose();
    super.dispose();
  }
}

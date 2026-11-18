import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../data/models.dart';
import 'cup/cup.dart';
import 'price.dart';

/// The menu's centrepiece: drinks on a wheel. The cup in the middle stands
/// tall; the ones beside it shrink, sink and lean away. Everything (size,
/// lean, the name and price below) follows the finger, not the page change,
/// so a slow drag is as smooth as a flick.
class DrinkCarousel extends StatefulWidget {
  const DrinkCarousel({super.key, required this.drinks, required this.onOpen, this.height = 330});

  final List<Drink> drinks;
  final ValueChanged<Drink> onOpen;
  final double height;

  @override
  State<DrinkCarousel> createState() => _DrinkCarouselState();
}

class _DrinkCarouselState extends State<DrinkCarousel> {
  final _pages = PageController(viewportFraction: 0.56);
  int _settled = 0;

  @override
  void didUpdateWidget(DrinkCarousel old) {
    super.didUpdateWidget(old);
    if (old.drinks.map((d) => d.id).join() != widget.drinks.map((d) => d.id).join() && _pages.hasClients) {
      _pages.jumpToPage(0);
      _settled = 0;
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  double get _page => _pages.hasClients && _pages.position.haveDimensions ? (_pages.page ?? 0) : _settled.toDouble();

  @override
  Widget build(BuildContext context) {
    final drinks = widget.drinks;
    if (drinks.isEmpty) return SizedBox(height: widget.height);
    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pages,
            itemCount: drinks.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _settled = i);
            },
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _pages,
              builder: (context, child) {
                final d = (_page - i).clamp(-2.0, 2.0);
                final a = d.abs();
                final scale = 1 - math.min(a, 1) * 0.3;
                return Opacity(
                  opacity: (1 - a * 0.45).clamp(0.0, 1.0),
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.identity()
                      ..translateByDouble(0, math.min(a, 1.4) * 34, 0, 1)
                      ..rotateZ(d * 0.14)
                      ..scaleByDouble(scale, scale, 1, 1),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () {
                  if (i == _settled) {
                    widget.onOpen(drinks[i]);
                  } else {
                    _pages.animateToPage(i, duration: Motion.medium, curve: Motion.settle);
                  }
                },
                child: Semantics(
                  button: true,
                  label: drinks[i].name,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Hero(
                      tag: 'cup-${drinks[i].id}',
                      child: Cup(drink: drinks[i].pour(drinks[i].defaults), width: 200),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: _pages,
          builder: (context, _) => _Caption(drinks: drinks, page: _page),
        ),
      ],
    );
  }
}

/// The name, tagline and price under the wheel, sliding with it.
class _Caption extends StatelessWidget {
  const _Caption({required this.drinks, required this.page});

  final List<Drink> drinks;
  final double page;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final i = page.round().clamp(0, drinks.length - 1);
    final off = page - i; // -0.5..0.5
    final drink = drinks[i];
    return Column(
      children: [
        ClipRect(
          child: Opacity(
            opacity: (1 - off.abs() * 1.8).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(-off * 120, 0),
              child: Column(
                children: [
                  Text(drink.name, style: text.headlineSmall, maxLines: 1),
                  const SizedBox(height: 4),
                  Text(drink.tagline, style: text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Price(cents: drink.price, style: text.titleLarge!.copyWith(color: p.accentDeep)),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var k = 0; k < drinks.length; k++)
              Builder(builder: (context) {
                final near = (1 - (page - k).abs()).clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6 + near * 16,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color.lerp(p.line, p.accent, near),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
          ],
        ),
      ],
    );
  }
}

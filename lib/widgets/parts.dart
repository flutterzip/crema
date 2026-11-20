import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';
import '../data/models.dart';
import 'cup/cup.dart';
import 'price.dart';

/// Squeezes its child while pressed.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, required this.onTap, this.label});

  final Widget child;
  final VoidCallback? onTap;
  final String? label;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) {
                setState(() => _down = false);
                HapticFeedback.lightImpact();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _down ? 0.965 : 1,
          duration: Duration(milliseconds: _down ? 90 : 300),
          curve: _down ? Curves.easeOut : Motion.spring,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A heading with an optional action at the right.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: p.accentDeep),
            child: Text(action!, style: Theme.of(context).textTheme.labelMedium!.copyWith(color: p.accentDeep, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

/// A drink in a list: a small cup, the name, how it is made and the price.
class DrinkRow extends StatelessWidget {
  const DrinkRow({super.key, required this.drink, this.options, this.onTap, this.trailing, this.heroTag});

  final Drink drink;
  final Options? options;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final o = options ?? drink.defaults;
    Widget cup = Cup(drink: drink.pour(o), width: 56);
    if (heroTag != null) cup = Hero(tag: heroTag!, child: cup);
    return Pressable(
      onTap: onTap,
      label: drink.name,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
        decoration: BoxDecoration(
          color: p.card.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 80,
              decoration: BoxDecoration(color: p.field, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 2),
              child: cup,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(drink.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    options == null ? drink.tagline : o.summary,
                    style: text.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Scales down rather than overflow next to a wide trailing
                  // control (the bag's quantity stepper).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, size: 15, color: p.accent),
                        const SizedBox(width: 3),
                        Text('${drink.rating}', style: text.labelSmall),
                        const SizedBox(width: 10),
                        Icon(Icons.schedule_rounded, size: 14, color: p.muted),
                        const SizedBox(width: 3),
                        Text('${drink.minutes} min', style: text.labelSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ?? Price(cents: drink.priceWith(o), style: text.titleMedium!.copyWith(color: p.accentDeep)),
          ],
        ),
      ),
    );
  }
}

/// The person's photo, or their initial.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.image, this.size = 44});

  final String name;
  final String? image;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initial = Container(
      color: p.accent,
      alignment: Alignment.center,
      child: Text(name.isEmpty ? '?' : name[0], style: Theme.of(context).textTheme.titleMedium!.copyWith(color: p.onAccent)),
    );
    return Semantics(
      label: 'Profile photo',
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.accent, width: 2)),
        child: ClipOval(
          child: image != null && image!.startsWith('asset:')
              ? Image.asset('assets/images/${image!.substring(6)}', fit: BoxFit.cover, errorBuilder: (_, _, _) => initial)
              : initial,
        ),
      ),
    );
  }
}

/// A frosted round icon button.
class RoundButton extends StatelessWidget {
  const RoundButton({super.key, required this.icon, required this.label, required this.onTap, this.size = 46});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      label: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: p.card.withValues(alpha: 0.8), border: Border.all(color: p.line)),
        child: Icon(icon, size: 21, color: p.ink),
      ),
    );
  }
}

/// A short empty state: a picture, a line and an action.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.art, required this.title, required this.message, this.action});

  final Widget art;
  final String title, message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter * 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          art,
          const SizedBox(height: 18),
          Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    );
  }
}

/// The red-free background revealed behind a row being swiped away.
class SwipeToRemove extends StatelessWidget {
  const SwipeToRemove({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(color: p.accentWash, borderRadius: BorderRadius.circular(22)),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Remove', style: Theme.of(context).textTheme.labelMedium!.copyWith(color: p.accentDeep)),
          const SizedBox(width: 8),
          Icon(Icons.delete_outline_rounded, color: p.accentDeep),
        ],
      ),
    );
  }
}

/// One line of a bill.
class TotalRow extends StatelessWidget {
  const TotalRow({super.key, required this.label, required this.cents, this.strong = false});

  final String label;
  final int cents;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = strong ? text.titleLarge! : text.bodyLarge!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          cents == 0 && !strong ? Text('Free', style: style) : Price(cents: cents, style: style),
        ],
      ),
    );
  }
}

/// A frosted dock for actions pinned over scrolling content (price and
/// Add to bag), so what scrolls underneath never collides with them.
class ActionDock extends StatelessWidget {
  const ActionDock({super.key, required this.child});

  final Widget child;

  /// The device's own bottom inset (the home indicator). Read from the view:
  /// inside the shell, the Scaffold has already swapped both padding and
  /// viewPadding for the tab bar's height, and a pushed page hides that bar.
  static double safeBottom(BuildContext context) => MediaQueryData.fromView(View.of(context)).viewPadding.bottom;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 10, 10),
          decoration: BoxDecoration(
            color: p.card.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: p.line),
          ),
          child: child,
        ),
      ),
    );
  }
}

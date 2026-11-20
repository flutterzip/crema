import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import 'parts.dart';
import 'tab_bar.dart';

/// The bag icon in the tab bar wears this key, so a cup knows where to fly.
final bagTarget = GlobalKey(debugLabel: 'bag');

/// Ticks every time something lands in the bag; the icon squashes on it.
final bagLanded = ValueNotifier<int>(0);

/// Lifts a copy of [child] off [from] and flies it in an arc into the bag
/// icon, shrinking and tilting, with two fading ghosts behind it. [onLand]
/// runs when it arrives, so the badge ticks on arrival, not on tap.
///
/// It aims at the tab bar's bag unless [to] names another (the drink page
/// hides the tab bar and wears its own bag at the top).
///
/// ```dart
/// flyToBag(context, from: cupKey, child: Cup(drink: art), onLand: add);
/// ```
Future<void> flyToBag(
  BuildContext context, {
  required GlobalKey from,
  required Widget child,
  required VoidCallback onLand,
  GlobalKey? to,
}) async {
  final overlay = Overlay.of(context, rootOverlay: true);
  final fromBox = from.currentContext?.findRenderObject() as RenderBox?;
  final toBox = (to ?? bagTarget).currentContext?.findRenderObject() as RenderBox?;
  final top = MediaQuery.paddingOf(context).top;
  if (fromBox == null || toBox == null || Motion.reduced(context)) {
    onLand();
    bagLanded.value++;
    return;
  }
  final start = fromBox.localToGlobal(Offset.zero) & fromBox.size;
  final end = toBox.localToGlobal(toBox.size.center(Offset.zero));
  final controller = AnimationController(vsync: overlay, duration: Motion.flyToBag);
  final entry = OverlayEntry(
    builder: (_) => AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        Widget at(double t, double alpha) {
          final e = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
          final a = start.center;
          // The control point sits above both ends, so the cup arcs up first,
          // but never above the screen when the bag is at the top.
          final c = Offset((a.dx + end.dx) / 2, math.max(math.min(a.dy, end.dy) - 140, top));
          final u = 1 - e;
          final pos = a * (u * u) + c * (2 * u * e) + end * (e * e);
          final s = ui.lerpDouble(1, 0.16, Curves.easeIn.transform(e))!;
          return Positioned(
            left: pos.dx - start.width / 2,
            top: pos.dy - start.height / 2,
            width: start.width,
            height: start.height,
            child: IgnorePointer(
              child: Opacity(
                opacity: alpha,
                child: Transform.rotate(angle: e * 0.5, child: Transform.scale(scale: s, child: child)),
              ),
            ),
          );
        }

        final t = controller.value;
        return Stack(
          children: [
            at(t - 0.12, 0.18 * (1 - t)),
            at(t - 0.06, 0.32 * (1 - t)),
            at(t, 1 - Curves.easeIn.transform(((t - 0.9) / 0.1).clamp(0.0, 1.0))),
          ],
        );
      },
    ),
  );
  overlay.insert(entry);
  await controller.forward();
  entry.remove();
  controller.dispose();
  HapticFeedback.mediumImpact();
  onLand();
  bagLanded.value++;
}

/// Squashes and stretches its child each time something lands in the bag.
class BagBump extends StatefulWidget {
  const BagBump({super.key, required this.child});

  final Widget child;

  @override
  State<BagBump> createState() => _BagBumpState();
}

class _BagBumpState extends State<BagBump> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void initState() {
    super.initState();
    bagLanded.addListener(_bump);
  }

  void _bump() {
    if (mounted) _c.forward(from: 0);
  }

  @override
  void dispose() {
    bagLanded.removeListener(_bump);
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = _c.value;
        final wobble = math.sin(t * math.pi * 3) * (1 - t);
        return Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.diagonal3Values(1 + wobble * 0.22, 1 - wobble * 0.22, 1),
          child: child,
        );
      },
    );
  }
}

/// A frosted round bag button with the bag's count, for a page that hides
/// the tab bar. Its icon wears [target], so a cup can fly into it.
class BagButton extends StatelessWidget {
  const BagButton({super.key, required this.target, required this.count, required this.onTap});

  final GlobalKey target;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      label: count > 0 ? 'Bag, $count' : 'Bag',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(shape: BoxShape.circle, color: p.card.withValues(alpha: 0.8), border: Border.all(color: p.line)),
            child: BagBump(child: KeyedSubtree(key: target, child: Icon(Icons.shopping_bag_outlined, size: 21, color: p.ink))),
          ),
          if (count > 0) Positioned(right: -4, top: -3, child: CountBadge(count: count)),
        ],
      ),
    );
  }
}

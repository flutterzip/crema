import 'package:flutter/material.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../data/models.dart';
import 'parts.dart';

/// A strip for an order on its way: the stage, a filling bar, and a tap
/// through to the live status.
class OrderBanner extends StatelessWidget {
  const OrderBanner({super.key, required this.order, required this.stage, required this.progress, required this.onTap});

  final Order order;
  final Stage stage;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final ready = stage == Stage.ready;
    return Pressable(
      onTap: onTap,
      label: 'Order ${order.number}, ${stage.title}',
      child: AnimatedContainer(
        duration: Motion.medium,
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        decoration: BoxDecoration(
          color: ready ? p.accent : p.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: ready ? p.accent : p.line),
        ),
        child: Row(
          children: [
            Icon(ready ? Icons.check_circle_rounded : Icons.coffee_maker_rounded, color: ready ? p.onAccent : p.accentDeep),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ready ? 'Order ${order.number} is ready' : 'Order ${order.number} · ${stage.title}',
                    style: text.titleMedium!.copyWith(color: ready ? p.onAccent : p.ink),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: progress),
                      duration: const Duration(milliseconds: 950),
                      builder: (_, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 5,
                        color: ready ? p.onAccent : p.accent,
                        backgroundColor: (ready ? p.onAccent : p.line).withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: ready ? p.onAccent : p.muted),
          ],
        ),
      ),
    );
  }
}

/// A rounded search box.
class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.controller, required this.onChanged, this.hint = 'Search the menu'});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: p.card.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line)),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: p.muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: p.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(color: p.muted),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: controller,
            builder: (_, _) => controller.text.isEmpty
                ? const SizedBox.shrink()
                : GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: Semantics(label: 'Clear search', button: true, child: Icon(Icons.close_rounded, color: p.muted, size: 20)),
                  ),
          ),
        ],
      ),
    );
  }
}

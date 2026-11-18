import 'package:flutter/material.dart';

import '../config/motion.dart';
import '../data/models.dart';

/// A price whose digits roll to the new value, each digit on its own wheel,
/// the way a pump counter turns.
class Price extends StatelessWidget {
  const Price({super.key, required this.cents, this.style});

  final int cents;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = style ?? Theme.of(context).textTheme.titleLarge!;
    final text = money(cents);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < text.length; i++)
            int.tryParse(text[i]) == null
                ? Text(text[i], style: s)
                // Keyed from the right so the units stay put when the
                // number grows a digit.
                : _Wheel(key: ValueKey(text.length - i), digit: int.parse(text[i]), style: s),
        ],
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({super.key, required this.digit, required this.style});

  final int digit;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final h = (style.fontSize ?? 20) * (style.height ?? 1.3);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: digit.toDouble()),
      duration: Motion.long,
      curve: Motion.settle,
      builder: (context, v, _) => ClipRect(
        child: SizedBox(
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Opacity(opacity: 0, child: Text('0', style: style)),
              for (var n = 0; n <= 9; n++)
                if ((n - v).abs() < 1.2)
                  Positioned(
                    top: (n - v) * h,
                    left: 0,
                    right: 0,
                    child: Text('$n', style: style, textAlign: TextAlign.center),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

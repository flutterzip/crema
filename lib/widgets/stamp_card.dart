import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';

/// Ten circles on a card. Stamps already there are shown at once; new ones
/// ([stamps] beyond [seen]) are pressed in one after another, each landing
/// slightly askew with a ring of ink spreading out.
class StampCard extends StatefulWidget {
  const StampCard({super.key, required this.stamps, this.seen = 0, this.slots = 10, this.title = 'Crema card'});

  final int stamps;

  /// Stamps the person has already seen; the rest are animated in.
  final int seen;
  final int slots;
  final String title;

  @override
  State<StampCard> createState() => _StampCardState();
}

class _StampCardState extends State<StampCard> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this);

  int get _fresh => (widget.stamps - widget.seen).clamp(0, widget.slots);

  @override
  void initState() {
    super.initState();
    _c.addListener(_feel);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _play();
    });
  }

  @override
  void didUpdateWidget(StampCard old) {
    super.didUpdateWidget(old);
    if (old.stamps != widget.stamps || old.seen != widget.seen) _play();
  }

  void _play() {
    if (_fresh == 0) {
      _c.value = 1;
      return;
    }
    _c.duration = Duration(milliseconds: 300 + _fresh * 380);
    _landed = widget.seen;
    _c.forward(from: 0);
  }

  int _landed = 0;

  /// A tap of the haptic engine as each stamp hits the card.
  void _feel() {
    var n = widget.seen;
    for (var i = widget.seen; i < widget.stamps; i++) {
      if (_landing(i) > 0.6) n = i + 1;
    }
    if (n > _landed) {
      _landed = n;
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 0..1 progress of slot [i]'s stamp landing.
  double _landing(int i) {
    if (i >= widget.stamps) return 0;
    if (i < widget.seen || Motion.reduced(context)) return 1;
    final ms = (_c.duration?.inMilliseconds ?? 1) * _c.value;
    final start = 300 + (i - widget.seen) * 380.0;
    return ((ms - start) / 380).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: '${widget.stamps} of ${widget.slots} stamps',
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Tokens.cardRadius),
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.accentDeep, p.accent]),
          boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.title, style: text.titleLarge!.copyWith(color: p.onAccent))),
                Text('${widget.stamps}/${widget.slots}', style: text.titleMedium!.copyWith(color: p.onAccent)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Every drink earns a stamp. The tenth is on us.', style: text.bodySmall!.copyWith(color: p.onAccent.withValues(alpha: 0.75))),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => GridView.count(
                crossAxisCount: 5,
                shrinkWrap: true,
                // A grid otherwise pads itself with the screen's safe area.
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [for (var i = 0; i < widget.slots; i++) _Slot(t: _landing(i), last: i == widget.slots - 1, tilt: math.sin(i * 1.9) * 0.3)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.t, required this.last, required this.tilt});

  final double t;
  final bool last;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Comes down from big and see-through, overshoots a little, settles.
    final scale = t <= 0 ? 0.0 : (t < 0.7 ? 1.7 - t / 0.7 * 0.8 : 0.9 + (t - 0.7) / 0.3 * 0.1);
    final ring = t > 0.6 ? ((t - 0.6) / 0.4) : 0.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.onAccent.withValues(alpha: 0.35), width: 1.5),
          ),
          child: last ? Center(child: Icon(Icons.redeem_rounded, size: 18, color: p.onAccent.withValues(alpha: 0.5))) : null,
        ),
        if (ring > 0 && ring < 1)
          Transform.scale(
            scale: 1 + ring * 0.6,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: p.onAccent.withValues(alpha: 0.5 * (1 - ring)), width: 2),
              ),
            ),
          ),
        if (t > 0)
          Opacity(
            opacity: (t * 2).clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: tilt * t,
              child: Transform.scale(
                scale: scale,
                child: SizedBox.expand(
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: p.onAccent),
                    child: Icon(Icons.coffee_rounded, size: 22, color: p.accentDeep),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// What to show at the bar once a free drink is redeemed.
class FreeDrinkTicket extends StatelessWidget {
  const FreeDrinkTicket({super.key, required this.code, this.rise = true});

  final String code;

  /// Springs in on its own. Off when something else brings it in (the
  /// particles need it whole from the first frame).
  final bool rise;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: rise ? 0 : 1, end: 1),
      duration: Motion.long,
      curve: Motion.spring,
      builder: (_, t, child) => Transform.scale(scale: 0.8 + t * 0.2, child: Opacity(opacity: t.clamp(0.0, 1.0), child: child)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(Tokens.cardRadius),
          border: Border.all(color: p.accent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.redeem_rounded, color: p.accentDeep, size: 34),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your free drink', style: text.titleMedium),
                  Text('Show this code at the bar', style: text.bodySmall),
                ],
              ),
            ),
            Text(code, style: text.titleLarge!.copyWith(color: p.accentDeep, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

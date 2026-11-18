import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../data/models.dart';
import 'cup/cup.dart';

/// The bar, making your drink: beans tumble in while it grinds, a stream
/// pours from the spout while it brews, and the glass fills with the
/// order's [progress]. When it is ready the art appears and it steams.
class BrewScene extends StatefulWidget {
  const BrewScene({super.key, required this.drink, required this.stage, required this.progress, this.width = 210});

  /// The drink as it will be when finished.
  final DrinkArt drink;
  final Stage stage;

  /// 0..1 through the whole order.
  final double progress;
  final double width;

  @override
  State<BrewScene> createState() => _BrewSceneState();
}

class _BrewSceneState extends State<BrewScene> with SingleTickerProviderStateMixin {
  late final _loop = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.loops(context)) {
      _loop.repeat();
    } else {
      _loop.value = 0.4;
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  DrinkArt get _now {
    final d = widget.drink;
    switch (widget.stage) {
      case Stage.received:
      case Stage.grinding:
        return d.copyWith(level: 0, hot: 0, artAmount: 0);
      case Stage.brewing:
        // Filling during brewing: from empty to just under full.
        final t = ((widget.progress - 14 / 26) / (12 / 26)).clamp(0.0, 1.0);
        return d.copyWith(level: d.level * (0.15 + t * 0.8), hot: 0, artAmount: 0, foam: d.foam * t);
      case Stage.ready:
        return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final w = widget.width;
    return SizedBox(
      width: w,
      height: w * 1.45,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loop,
              builder: (context, _) => CustomPaint(
                painter: _BarPainter(
                  t: _loop.value,
                  stage: widget.stage,
                  stream: widget.drink.baseColor,
                  metal: p.ink,
                  bean: const Color(0xFF4A2A18),
                  cupWidth: w,
                ),
              ),
            ),
          ),
          Cup(drink: _now, width: w),
        ],
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.t,
    required this.stage,
    required this.stream,
    required this.metal,
    required this.bean,
    required this.cupWidth,
  });

  final double t;
  final Stage stage;
  final Color stream, metal, bean;
  final double cupWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final k = cupWidth / 200;
    final cupTop = size.height - cupWidth * 262 / 200 + 60 * k;

    // The machine is product art, like the coffee: brushed steel and a
    // black handle, the same in light and dark.
    const steelTop = Color(0xFFE2DDD5), steelBottom = Color(0xFF8C857C), basket = Color(0xFF5E5850), handle = Color(0xFF26211D);
    final head = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, 14 * k), width: 132 * k, height: 30 * k), Radius.circular(12 * k));
    canvas.drawRRect(
      head,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: const [steelTop, steelBottom]).createShader(head.outerRect),
    );
    canvas.drawLine(Offset(cx - 56 * k, 5 * k), Offset(cx + 56 * k, 5 * k), Paint()..color = const Color(0xAAFFFFFF)..strokeWidth = 1.5 * k);
    // The portafilter: basket, then the handle reaching out to the right.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(cx + 30 * k, 33 * k, 78 * k, 10 * k), Radius.circular(5 * k)),
      Paint()..color = handle,
    );
    final basketPath = Path()
      ..moveTo(cx - 38 * k, 29 * k)
      ..lineTo(cx + 38 * k, 29 * k)
      ..lineTo(cx + 30 * k, 48 * k)
      ..quadraticBezierTo(cx, 52 * k, cx - 30 * k, 48 * k)
      ..close();
    canvas.drawPath(basketPath, Paint()..color = basket);
    // Twin spouts.
    for (final dx in [-9.0, 9.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx + dx * k, 54 * k), width: 7 * k, height: 10 * k), Radius.circular(2 * k)),
        Paint()..color = basket,
      );
    }

    switch (stage) {
      case Stage.brewing:
        // Two thin streams from the spouts, meeting as they reach the glass.
        final top = 58 * k, bottom = cupTop + 40 * k;
        for (final dx in [-9.0, 9.0]) {
          final wob = math.sin(t * math.pi * 8 + dx) * 1.1 * k;
          final path = Path()
            ..moveTo(cx + dx * k, top)
            ..quadraticBezierTo(cx + dx * 0.8 * k + wob, (top + bottom) / 2, cx + dx * 0.15 * k, bottom);
          canvas.drawPath(
            path,
            Paint()
              ..color = stream
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.2 * k
              ..strokeCap = StrokeCap.round,
          );
        }
      case Stage.grinding:
        // Beans falling in a loop into the group head.
        for (var i = 0; i < 6; i++) {
          final local = (t * 1.5 + i / 6) % 1;
          final x = cx + math.sin(i * 2.3) * 40 * k;
          final y = -30 * k + local * 40 * k;
          canvas.save();
          canvas.translate(x, y);
          canvas.rotate(local * 6 + i);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 9 * k, height: 12 * k), Paint()..color = bean.withValues(alpha: 1 - local));
          canvas.restore();
        }
      case Stage.received:
      case Stage.ready:
        break;
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.t != t || old.stage != stage || old.stream != stream;
}

/// The four stages, a line filling between them, the current one pulsing.
/// Rows have a fixed height so it lays out inside any scroll view.
class StageTrack extends StatelessWidget {
  const StageTrack({super.key, required this.stage});

  final Stage stage;

  static const _row = 66.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final s in Stage.values)
          SizedBox(
            height: s == Stage.values.last ? 46 : _row,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 34,
                  child: Column(
                    children: [
                      _Dot(done: s.index < stage.index, current: s == stage),
                      if (s != Stage.values.last)
                        Expanded(
                          child: Container(
                            width: 3,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2)),
                            alignment: Alignment.topCenter,
                            child: LayoutBuilder(
                              builder: (context, box) => AnimatedContainer(
                                duration: Motion.long,
                                curve: Motion.settle,
                                width: 3,
                                height: s.index < stage.index ? box.maxHeight : 0,
                                color: p.accent,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: Motion.short,
                        style: text.titleMedium!.copyWith(color: s.index <= stage.index ? p.ink : p.muted),
                        child: Text(s.title, maxLines: 1),
                      ),
                      const SizedBox(height: 2),
                      Text(s.detail, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.done, required this.current});

  final bool done, current;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Dot old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.current && Motion.loops(context)) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = widget.done || widget.current;
    return SizedBox.square(
      dimension: 26,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            if (widget.current)
              Container(
                width: 26 * (0.8 + _pulse.value * 0.6),
                height: 26 * (0.8 + _pulse.value * 0.6),
                decoration: BoxDecoration(shape: BoxShape.circle, color: p.accent.withValues(alpha: 0.35 * (1 - _pulse.value))),
              ),
            AnimatedContainer(
              duration: Motion.medium,
              curve: Motion.spring,
              width: on ? 22 : 16,
              height: on ? 22 : 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? p.accent : p.card,
                border: Border.all(color: on ? p.accent : p.line, width: 2),
              ),
              child: widget.done ? Icon(Icons.check_rounded, size: 14, color: p.onAccent) : null,
            ),
          ],
        ),
      ),
    );
  }
}

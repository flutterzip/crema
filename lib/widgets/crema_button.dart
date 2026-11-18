import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/motion.dart';
import '../config/palette.dart';
import '../config/theme.dart';

enum ButtonStyleKind { primary, ghost }

/// The primary action. Pressing it squeezes it; while [busy] its label
/// becomes three coffee beans hopping in turn (the button keeps its
/// colour, so it reads as working, not refused); when [done] it shrinks to
/// a circle and draws a tick.
class CremaButton extends StatefulWidget {
  const CremaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.done = false,
    this.icon,
  }) : kind = ButtonStyleKind.primary;

  const CremaButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  })  : kind = ButtonStyleKind.ghost,
        busy = false,
        done = false;

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool done;
  final IconData? icon;
  final ButtonStyleKind kind;

  @override
  State<CremaButton> createState() => _CremaButtonState();
}

class _CremaButtonState extends State<CremaButton>
    with TickerProviderStateMixin {
  late final _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
    reverseDuration: const Duration(milliseconds: 380),
  );
  late final _morph = AnimationController(vsync: this, duration: Motion.medium);
  late final _tick = AnimationController(vsync: this, duration: Motion.medium);

  @override
  void didUpdateWidget(CremaButton old) {
    super.didUpdateWidget(old);
    if (widget.done && !old.done) {
      HapticFeedback.mediumImpact();
      _morph.forward().then((_) {
        if (mounted) _tick.forward();
      });
    } else if (!widget.done && old.done) {
      _tick.value = 0;
      _morph.reverse();
    }
  }

  @override
  void dispose() {
    _press.dispose();
    _morph.dispose();
    _tick.dispose();
    super.dispose();
  }

  bool get _enabled =>
      widget.onPressed != null && !widget.busy && !widget.done;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primary = widget.kind == ButtonStyleKind.primary;
    final disabled = widget.onPressed == null;
    return Semantics(
      button: true,
      enabled: !disabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => _press.forward() : null,
        onTapCancel: () => _press.reverse(),
        onTapUp: _enabled
            ? (_) {
                _press.reverse();
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: LayoutBuilder(builder: (context, box) {
          final full = box.maxWidth;
          return AnimatedBuilder(
            animation: Listenable.merge([_press, _morph]),
            builder: (context, _) {
              final m = Motion.settle.transform(_morph.value);
              final width = full - (full - Tokens.buttonHeight) * m;
              final pressScale = 1 - _press.value * 0.035;
              return Center(
                child: Transform.scale(
                  scale: pressScale,
                  child: Container(
                    width: width,
                    height: Tokens.buttonHeight,
                    decoration: BoxDecoration(
                      color: primary ? null : p.card.withValues(alpha: 0.6),
                      gradient: primary
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: disabled
                                  ? [p.line, p.line]
                                  : [p.accentGlow, p.accent],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(
                          Tokens.buttonRadius + (Tokens.buttonHeight / 2 - Tokens.buttonRadius) * m),
                      border: primary
                          ? Border.all(
                              color: p.accentDeep.withValues(alpha: disabled ? 0 : 0.35))
                          : Border.all(color: p.line, width: 1.2),
                      boxShadow: primary && !disabled
                          ? [
                              BoxShadow(
                                color: p.accent.withValues(alpha: 0.38 - _press.value * 0.2),
                                blurRadius: 24 - _press.value * 10,
                                spreadRadius: -4,
                                offset: Offset(0, 12 - _press.value * 6),
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Tokens.buttonHeight / 2),
                      child: _content(context, p, primary, m),
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _content(BuildContext context, Palette p, bool primary, double m) {
    final ink = primary ? p.onAccent : p.ink;
    if (m > 0.02) {
      return Center(
        child: AnimatedBuilder(
          animation: _tick,
          builder: (_, _) => CustomPaint(
            size: const Size(26, 26),
            painter: _TickPainter(_tick.value, ink),
          ),
        ),
      );
    }
    return AnimatedSwitcher(
      duration: Motion.short,
      switchInCurve: Motion.enter,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.35), end: Offset.zero)
              .animate(a),
          child: child,
        ),
      ),
      child: widget.busy
          ? _BeansLoader(key: const ValueKey('busy'), color: ink)
          : Row(
              key: const ValueKey('label'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: ink),
                  const SizedBox(width: 10),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge!
                        .copyWith(color: widget.onPressed == null ? p.muted : ink),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.54)
      ..lineTo(size.width * 0.42, size.height * 0.76)
      ..lineTo(size.width * 0.84, size.height * 0.28);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * Motion.settle.transform(t)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.t != t || old.color != color;
}

/// Three coffee beans hopping in turn: Crema's loader.
class _BeansLoader extends StatefulWidget {
  const _BeansLoader({super.key, required this.color});

  final Color color;

  @override
  State<_BeansLoader> createState() => _BeansLoaderState();
}

class _BeansLoaderState extends State<_BeansLoader> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.loops(context)) {
      _c.repeat();
    } else {
      _c.value = 0.3;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Working',
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(size: const Size(54, 26), painter: _BeansPainter(_c.value, widget.color)),
      ),
    );
  }
}

class _BeansPainter extends CustomPainter {
  _BeansPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final local = ((t - i * 0.18) % 1 + 1) % 1;
      final hop = local < 0.4 ? math.sin(local / 0.4 * math.pi) : 0.0;
      final c = Offset(size.width * (0.2 + i * 0.3), size.height * 0.62 - hop * 9);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(-0.5 + hop * 0.6);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 10, height: 13), Paint()..color = color);
      canvas.drawPath(
        Path()
          ..moveTo(0, -5.5)
          ..quadraticBezierTo(-2.5, 0, 0, 5.5),
        Paint()
          ..color = color.computeLuminance() > 0.5 ? const Color(0x99000000) : const Color(0x99FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BeansPainter old) => old.t != t;
}

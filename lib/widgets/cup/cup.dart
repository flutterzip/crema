import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../config/motion.dart';
import '../../config/palette.dart';
import 'cup_painter.dart';
import 'drink_art.dart';

export 'drink_art.dart';
export 'drink_colors.dart';

/// A drink in a glass. Hand it a new [drink] and it re-pours: the layers
/// rise or fall to their new levels, the latte art fades across, and the
/// surface sloshes and settles. Steam, ice and milk clouds move on their own
/// while ambient motion is on.
class Cup extends StatefulWidget {
  const Cup({super.key, required this.drink, this.width = 160});

  final DrinkArt drink;
  final double width;

  @override
  State<Cup> createState() => _CupState();
}

class _CupState extends State<Cup> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _frame = _Repaint();

  late DrinkArt _from = widget.drink;
  late DrinkArt _to = widget.drink;
  double _pour = 1; // 0..1 through the current re-pour
  double _time = 0;
  double _tilt = 0, _tiltVel = 0;
  Duration _last = Duration.zero;
  bool _loops = true, _reduced = false;

  DrinkArt get _now => _pour >= 1 ? _to : DrinkArt.lerp(_from, _to, Motion.settle.transform(_pour));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loops = Motion.loops(context);
    _reduced = Motion.reduced(context);
    _wake();
  }

  @override
  void didUpdateWidget(Cup old) {
    super.didUpdateWidget(old);
    if (widget.drink != _to) {
      _from = _now;
      _to = widget.drink;
      if (_reduced) {
        _pour = 1;
      } else {
        _pour = 0;
        // A change sloshes the drink, harder when the level jumps.
        _tiltVel += 3 + (widget.drink.level - _from.level).abs() * 14;
      }
      _wake();
    }
  }

  void _wake() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero ? 1 / 60 : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    _time += dt;
    var moving = false;
    if (_pour < 1) {
      _pour = math.min(1, _pour + dt / (Motion.pour.inMicroseconds / 1e6));
      moving = true;
    }
    // Underdamped spring: the surface rocks a few times and settles.
    _tiltVel += (-_tilt * 60 - _tiltVel * 4.2) * dt;
    _tilt += _tiltVel * dt;
    if (_tilt.abs() > 0.002 || _tiltVel.abs() > 0.002) {
      moving = true;
    } else {
      _tilt = 0;
      _tiltVel = 0;
    }
    _frame.ping();
    if (!moving && !_loops) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dark = p.paper.computeLuminance() < 0.2;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.width,
        height: widget.width * CupPainter.height / CupPainter.width,
        child: CustomPaint(
          painter: CupPainter(
            drink: () => _now,
            time: () => _time,
            tilt: () => _tilt.clamp(-1.5, 1.5),
            shadow: p.shadow,
            steam: dark ? const Color(0xFFFFFFFF) : p.muted,
            repaint: _frame,
          ),
        ),
      ),
    );
  }
}

class _Repaint extends ChangeNotifier {
  void ping() => notifyListeners();
}

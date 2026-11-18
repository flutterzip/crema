import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/brand.dart';
import '../../config/motion.dart';
import '../../config/palette.dart';
import '../../config/timing.dart';
import '../../widgets/cup/cup.dart';

/// The first thing anyone sees: an empty glass, the coffee pours in with a
/// heart on top and steam rising, the name rises letter by letter, then it
/// all dissolves into the menu.
///
/// One controller, one timeline. [showing] goes false as it starts to
/// leave, so overlays and launch hooks can wait for it.
class Splash extends StatefulWidget {
  const Splash({super.key, required this.ready, required this.onGone});

  final Future<void> ready;
  final VoidCallback onGone;

  static final showing = ValueNotifier<bool>(true);

  /// The drink the splash pours.
  static const pour = DrinkArt(baseColor: DrinkColors.espresso, base: 0.3, milk: 0.52, foam: 0.12, art: LatteArt.heart);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late final _in = AnimationController(vsync: this, duration: AppTiming.splashIn);
  late final _out = AnimationController(vsync: this, duration: AppTiming.splashOut);
  bool _poured = false;

  @override
  void initState() {
    super.initState();
    Splash.showing.value = true;
    _in.addListener(() {
      if (!_poured && _in.value > 0.18) {
        setState(() => _poured = true);
        HapticFeedback.lightImpact();
      }
    });
    _run();
  }

  Future<void> _run() async {
    if (AppTiming.scale == 0) {
      await widget.ready;
      return _gone();
    }
    await Future.wait([_in.forward().orCancel.catchError((_) {}), widget.ready]);
    await AppTiming.wait(AppTiming.splashHold);
    if (!mounted) return;
    Splash.showing.value = false;
    await _out.forward().orCancel.catchError((_) {});
    _gone();
  }

  void _gone() {
    Splash.showing.value = false;
    if (mounted) widget.onGone();
  }

  @override
  void dispose() {
    _in.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final reduced = Motion.reduced(context);
    return AnimatedBuilder(
      animation: Listenable.merge([_in, _out]),
      builder: (context, _) {
        final t = reduced ? 1.0 : _in.value;
        final out = Motion.exit.transform(_out.value);
        double phase(double a, double b) => Motion.enter.transform(((t - a) / (b - a)).clamp(0.0, 1.0));
        final name = AppBrand.name;
        return IgnorePointer(
          ignoring: _out.value > 0,
          child: Opacity(
            opacity: 1 - out,
            child: Material(
              color: p.paper,
              child: Center(
                child: Transform.scale(
                  scale: 1 + out * 0.08,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: phase(0, 0.15),
                        child: Transform.translate(
                          offset: Offset(0, (1 - phase(0, 0.2)) * 30),
                          child: Cup(
                            drink: _poured || reduced ? Splash.pour : Splash.pour.copyWith(level: 0, hot: 0, artAmount: 0),
                            width: 150,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      ClipRect(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < name.length; i++)
                              Builder(builder: (context) {
                                final local = ((phase(0.5, 0.85) * (name.length + 2) - i) / 3).clamp(0.0, 1.0);
                                return Opacity(
                                  opacity: local,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - Motion.spring.transform(local)) * 46),
                                    child: Text(name[i], style: text.displaySmall!.copyWith(fontSize: 46)),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(opacity: phase(0.78, 1), child: Text(AppBrand.tagline, style: text.bodyLarge)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

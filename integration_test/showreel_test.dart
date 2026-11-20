// Drives the real app on the simulator at human speed, for recording and
// for judging motion frame by frame:   tool/rec.sh order
import 'package:crema/app.dart';
import 'package:crema/state/store.dart';
import 'package:crema/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const reel = String.fromEnvironment('reel', defaultValue: 'order');

Future<void> pause(WidgetTester t, int ms) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 16));
  }
}

Future<void> tapText(WidgetTester t, String text, {int after = 900}) async {
  await t.tap(find.text(text).last);
  await pause(t, after);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('showreel $reel', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final seed = await Seed.load();
    await t.pumpWidget(ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs), seedProvider.overrideWithValue(seed)],
      child: const CremaApp(),
    ));
    await pause(t, 4200);

    // Spin the wheel slowly, then back.
    final wheel = find.byType(PageView);
    for (var i = 0; i < 3; i++) {
      await t.timedDrag(wheel, const Offset(-240, 0), const Duration(milliseconds: 700));
      await pause(t, 900);
    }
    await t.timedDrag(wheel, const Offset(720, 0), const Duration(milliseconds: 1100));
    await pause(t, 1200);

    // Open the Oat Latte (second) and make it.
    await t.timedDrag(wheel, const Offset(-240, 0), const Duration(milliseconds: 600));
    await pause(t, 900);
    await t.tap(find.bySemanticsLabel('Oat Latte').first);
    await pause(t, 1600);
    await tapText(t, 'L', after: 1400);
    await tapText(t, 'S', after: 1400);
    await tapText(t, 'M', after: 1000);
    await t.drag(find.byType(ListView).last, const Offset(0, -260));
    await pause(t, 700);
    await tapText(t, 'Iced', after: 1600);
    await tapText(t, 'Hot', after: 1600);
    await tapText(t, 'Almond', after: 1300);
    await tapText(t, 'Oat', after: 1000);
    await t.drag(find.byType(ListView).last, const Offset(0, -320));
    await pause(t, 600);
    final plus = find.descendant(of: find.byType(CountStepper), matching: find.byIcon(Icons.add_rounded));
    await t.tap(plus);
    await pause(t, 900);
    final sugar = find.descendant(of: find.byType(SugarPicker), matching: find.byType(GestureDetector));
    await t.tap(sugar.at(1));
    await pause(t, 1000);
    await tapText(t, 'Add to bag', after: 2600);

    if (reel == 'order') {
      await tapText(t, 'View bag', after: 1500);
      await tapText(t, '15 min', after: 600);
      await tapText(t, 'ASAP', after: 800);
      await t.tap(find.textContaining('Pay ').last);
      await pause(t, 30000);
      await t.tap(find.text('I have it, thanks'));
      await pause(t, 1500);
      await t.tap(find.bySemanticsLabel(RegExp('^Rewards')));
      await pause(t, 5000);
    }
  });
}

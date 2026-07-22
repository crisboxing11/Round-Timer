import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:round_timer/models/models.dart';
import 'package:round_timer/screens/timer_screen.dart';

const _config = TimerConfig(
  id: 'test',
  name: 'Test',
  rounds: 2,
  work: Duration(minutes: 3),
  rest: Duration(minutes: 1),
);

Future<void> _pumpAt(WidgetTester tester, Size logical) async {
  tester.view.physicalSize = logical * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    const MaterialApp(home: TimerScreen(config: _config)),
  );
  await tester.pump(const Duration(milliseconds: 150));
}

Future<void> _teardown(WidgetTester tester) async {
  // Replace the screen so the ticker is cancelled before the test ends.
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  testWidgets('portrait renders prep state without overflow', (tester) async {
    await _pumpAt(tester, const Size(402, 874)); // iPhone 17 Pro portrait
    expect(find.text('GET READY'), findsWidgets);
    expect(find.text('END'), findsOneWidget);
    expect(find.text('SKIP'), findsOneWidget);
    await _teardown(tester);
  });

  testWidgets('landscape wall-timer renders without overflow',
      (tester) async {
    await _pumpAt(tester, const Size(874, 402)); // iPhone 17 Pro landscape
    expect(find.text('GET READY'), findsWidgets);
    expect(find.text('END'), findsOneWidget);
    // The portrait-only pause hint is dropped in wall-timer mode.
    expect(find.textContaining('TAP ANYWHERE'), findsNothing);
    await _teardown(tester);
  });

  testWidgets('small-phone landscape still fits', (tester) async {
    await _pumpAt(tester, const Size(667, 375)); // iPhone SE class
    expect(find.text('GET READY'), findsWidgets);
    await _teardown(tester);
  });
}

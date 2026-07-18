import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:round_timer/models/models.dart';
import 'package:round_timer/screens/custom_config_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpConfig(WidgetTester tester, {TimerConfig? initial}) =>
    tester.pumpWidget(
      MaterialApp(home: CustomConfigScreen(initial: initial)),
    );

Finder stepperButton(String label, IconData icon) => find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(Container).first,
      ),
      matching: find.byIcon(icon),
    );

void main() {
  group('CustomConfigScreen', () {
    testWidgets('shows defaults: 5 rounds, 3:00 work, 1:00 rest',
        (tester) async {
      await pumpConfig(tester);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3:00'), findsOneWidget);
      expect(find.text('1:00'), findsOneWidget);
    });

    testWidgets('prefills from an initial custom config', (tester) async {
      await pumpConfig(
        tester,
        initial: const TimerConfig(
          id: 'custom',
          name: 'Custom',
          rounds: 8,
          work: Duration(minutes: 2),
          rest: Duration(seconds: 30),
        ),
      );
      expect(find.text('8'), findsOneWidget);
      expect(find.text('2:00'), findsOneWidget);
      expect(find.text('0:30'), findsOneWidget);
    });

    testWidgets('round stepper increments and decrements', (tester) async {
      await pumpConfig(tester);
      final plus = find.byIcon(Icons.add).first;
      final minus = find.byIcon(Icons.remove).first;
      await tester.tap(plus);
      await tester.pump();
      expect(find.text('6'), findsOneWidget);
      await tester.tap(minus);
      await tester.tap(minus);
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('rounds clamp at 1', (tester) async {
      await pumpConfig(
        tester,
        initial: const TimerConfig(
          id: 'custom',
          name: 'Custom',
          rounds: 1,
          work: Duration(minutes: 3),
          rest: Duration(minutes: 1),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });

    testWidgets('rest steps down to OFF and back in 5s steps', (tester) async {
      await pumpConfig(
        tester,
        initial: const TimerConfig(
          id: 'custom',
          name: 'Custom',
          rounds: 3,
          work: Duration(minutes: 3),
          rest: Duration(seconds: 10),
        ),
      );
      await tester.tap(find.byIcon(Icons.remove).last);
      await tester.pump();
      expect(find.text('0:05'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.remove).last);
      await tester.pump();
      expect(find.text('OFF'), findsOneWidget);
      // At OFF the minus button disables; plus brings rest back.
      await tester.tap(find.byIcon(Icons.remove).last);
      await tester.pump();
      expect(find.text('OFF'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add).last);
      await tester.pump();
      expect(find.text('0:05'), findsOneWidget);
    });

    testWidgets('steps switch to 15s above one minute', (tester) async {
      await pumpConfig(
        tester,
        initial: const TimerConfig(
          id: 'custom',
          name: 'Custom',
          rounds: 3,
          work: Duration(minutes: 1),
          rest: Duration(minutes: 1),
        ),
      );
      // Work up from 1:00 → coarse step to 1:15.
      await tester.tap(find.byIcon(Icons.add).at(1));
      await tester.pump();
      expect(find.text('1:15'), findsOneWidget);
      // Rest down from 1:00 → fine step to 0:55.
      await tester.tap(find.byIcon(Icons.remove).last);
      await tester.pump();
      expect(find.text('0:55'), findsOneWidget);
    });

    testWidgets('total updates with the schedule (prep included)',
        (tester) async {
      await pumpConfig(
        tester,
        initial: const TimerConfig(
          id: 'custom',
          name: 'Custom',
          rounds: 2,
          work: Duration(minutes: 3),
          rest: Duration(minutes: 1),
        ),
      );
      // 0:10 prep + 3:00 + 1:00 + 3:00 (no rest after final round) = 7:10
      expect(find.textContaining('TOTAL 7:10'), findsOneWidget);
    });
  });

  group('LastConfigStore', () {
    test('round-trips a custom config as JSON', () async {
      SharedPreferences.setMockInitialValues({});
      const custom = TimerConfig(
        id: 'custom',
        name: 'Custom',
        rounds: 7,
        work: Duration(seconds: 135),
        rest: Duration(seconds: 45),
      );
      await LastConfigStore.save(custom);
      final loaded = await LastConfigStore.load();
      expect(loaded.id, 'custom');
      expect(loaded.rounds, 7);
      expect(loaded.work, const Duration(seconds: 135));
      expect(loaded.rest, const Duration(seconds: 45));
    });

    test('falls back to legacy preset id then first preset', () async {
      SharedPreferences.setMockInitialValues({'last_config_id': 'mma'});
      final legacy = await LastConfigStore.load();
      expect(legacy.id, 'mma');

      SharedPreferences.setMockInitialValues({});
      final fresh = await LastConfigStore.load();
      expect(fresh.id, presets.first.id);
    });

    test('survives a corrupt stored value', () async {
      SharedPreferences.setMockInitialValues({'last_config': 'not json'});
      final loaded = await LastConfigStore.load();
      expect(loaded.id, presets.first.id);
    });
  });
}

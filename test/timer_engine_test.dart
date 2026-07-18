import 'package:flutter_test/flutter_test.dart';
import 'package:round_timer/engine/timer_engine.dart';
import 'package:round_timer/models/models.dart';

void main() {
  const boxing = TimerConfig(
    id: 'boxing',
    name: 'Boxing',
    rounds: 12,
    work: Duration(minutes: 3),
    rest: Duration(minutes: 1),
  );

  const judo = TimerConfig(
    id: 'judo',
    name: 'Judo',
    rounds: 1,
    work: Duration(minutes: 4),
    rest: Duration.zero,
  );

  group('buildSchedule', () {
    test('boxing: prep + 12 work + 11 rest, no rest after final round', () {
      final s = buildSchedule(boxing);
      expect(s.length, 1 + 12 + 11);
      expect(s.first.type, PhaseType.prep);
      expect(s.last.type, PhaseType.work);
      expect(s.last.round, 12);
      expect(s.where((p) => p.type == PhaseType.rest).length, 11);
    });

    test('judo: prep + single round, zero rest phases', () {
      final s = buildSchedule(judo);
      expect(s.length, 2);
      expect(s.last.duration, const Duration(minutes: 4));
    });

    test('total session length is correct', () {
      final engine = TimerEngine(boxing);
      expect(
        engine.total,
        const Duration(seconds: 10) +
            const Duration(minutes: 36) + // 12 × 3:00
            const Duration(minutes: 11), // 11 × 1:00
      );
    });

    test('tabata preset: 8 × 20s work / 10s rest, classic 4:00 + prep', () {
      final tabata = presets.firstWhere((p) => p.id == 'tabata');
      final s = buildSchedule(tabata);
      expect(s.where((p) => p.type == PhaseType.work).length, 8);
      expect(s.where((p) => p.type == PhaseType.rest).length, 7);
      final engine = TimerEngine(tabata);
      // 8×20s + 7×10s = 3:50 (no rest after the final round) + 10s prep.
      expect(engine.total, const Duration(minutes: 4));
    });

    test('emom preset: minute rounds, no rest phases', () {
      final emom = presets.firstWhere((p) => p.id == 'emom');
      final s = buildSchedule(emom);
      expect(s.where((p) => p.type == PhaseType.rest), isEmpty);
      expect(s.length, 11); // prep + 10 work
    });
  });

  group('position', () {
    test('starts in prep with full prep remaining', () {
      final engine = TimerEngine(boxing);
      final pos = engine.position!;
      expect(pos.phase.type, PhaseType.prep);
      expect(pos.remaining, const Duration(seconds: 10));
    });

    test('skipPhase advances to next phase boundary', () {
      final engine = TimerEngine(boxing);
      engine.skipPhase(); // prep -> round 1
      expect(engine.position!.phase.type, PhaseType.work);
      expect(engine.position!.phase.round, 1);
      engine.skipPhase(); // round 1 -> rest 1
      expect(engine.position!.phase.type, PhaseType.rest);
    });

    test('skipping through all phases finishes the session', () {
      final engine = TimerEngine(judo);
      var finished = false;
      engine.onEvent = (e, _) {
        if (e == TimerEvent.finished) finished = true;
      };
      engine.skipPhase(); // prep -> work
      engine.skipPhase(); // work -> end
      engine.tick(); // no-op when not running; call side effects directly
      engine.start();
      engine.tick();
      expect(engine.position, isNull);
      expect(finished, isTrue);
    });
  });

  group('events', () {
    test('phaseStarted fires with correct phase on skip', () {
      final engine = TimerEngine(boxing);
      final events = <(TimerEvent, PhaseType?)>[];
      engine.onEvent = (e, p) => events.add((e, p?.type));
      engine.skipPhase();
      expect(events.last, (TimerEvent.phaseStarted, PhaseType.work));
    });

    test('warning fires once per work phase', () {
      // Config with a 5-second round: warning region covers whole round.
      const quick = TimerConfig(
        id: 'q',
        name: 'Q',
        rounds: 1,
        work: Duration(seconds: 5),
        rest: Duration.zero,
        prep: Duration(seconds: 1),
      );
      final engine = TimerEngine(quick);
      var warnings = 0;
      engine.onEvent = (e, _) {
        if (e == TimerEvent.tenSecondWarning) warnings++;
      };
      engine.skipPhase(); // into work
      engine.start();
      engine.tick();
      engine.tick();
      engine.tick();
      expect(warnings, 1);
    });
  });
}

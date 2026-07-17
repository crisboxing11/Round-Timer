import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// Events the UI/audio layer reacts to.
enum TimerEvent { phaseStarted, tenSecondWarning, finished }

/// Drift-free round timer engine.
///
/// Elapsed time is derived from a monotonic [Stopwatch] plus an accumulated
/// pause offset — never from counting ticks. The tick loop only *samples*
/// time; all boundaries are computed against the schedule.
class TimerEngine extends ChangeNotifier {
  TimerEngine(TimerConfig config) : _config = config {
    _schedule = buildSchedule(config);
  }

  TimerConfig _config;
  late List<Phase> _schedule;
  final Stopwatch _clock = Stopwatch();
  Duration _accumulated = Duration.zero;

  int _lastPhaseIndex = -1;
  bool _warnedThisPhase = false;
  bool _finished = false;

  void Function(TimerEvent event, Phase? phase)? onEvent;

  TimerConfig get config => _config;
  List<Phase> get schedule => List.unmodifiable(_schedule);
  bool get isRunning => _clock.isRunning;
  bool get isFinished => _finished;

  Duration get elapsed => _accumulated + _clock.elapsed;

  /// Total duration of the whole session.
  Duration get total =>
      _schedule.fold(Duration.zero, (a, p) => a + p.duration);

  /// The phase containing [elapsed], or null when finished.
  PhasePosition? get position {
    var acc = Duration.zero;
    for (var i = 0; i < _schedule.length; i++) {
      final p = _schedule[i];
      final end = acc + p.duration;
      if (elapsed < end) {
        return PhasePosition(
          index: i,
          phase: p,
          remaining: end - elapsed,
          elapsedInPhase: elapsed - acc,
        );
      }
      acc = end;
    }
    return null;
  }

  void start() {
    if (_finished) return;
    _clock.start();
    _tickSideEffects();
    notifyListeners();
  }

  void pause() {
    _clock.stop();
    notifyListeners();
  }

  void toggle() => isRunning ? pause() : start();

  /// Jump to the start of the next phase.
  void skipPhase() {
    final pos = position;
    if (pos == null) return;
    var acc = Duration.zero;
    for (var i = 0; i <= pos.index; i++) {
      acc += _schedule[i].duration;
    }
    _accumulated = acc;
    _clock.reset();
    _tickSideEffects();
    notifyListeners();
  }

  void reset([TimerConfig? newConfig]) {
    _clock
      ..stop()
      ..reset();
    _accumulated = Duration.zero;
    _lastPhaseIndex = -1;
    _warnedThisPhase = false;
    _finished = false;
    if (newConfig != null) {
      _config = newConfig;
      _schedule = buildSchedule(newConfig);
    }
    notifyListeners();
  }

  /// Call from the UI tick loop (a ~100ms periodic timer or ticker) while
  /// running. Cheap: samples the clock and fires boundary events.
  void tick() {
    if (!isRunning) return;
    _tickSideEffects();
    notifyListeners();
  }

  void _tickSideEffects() {
    final pos = position;
    if (pos == null) {
      if (!_finished) {
        _finished = true;
        _clock.stop();
        onEvent?.call(TimerEvent.finished, null);
      }
      return;
    }
    if (pos.index != _lastPhaseIndex) {
      _lastPhaseIndex = pos.index;
      _warnedThisPhase = false;
      onEvent?.call(TimerEvent.phaseStarted, pos.phase);
    }
    if (pos.phase.type == PhaseType.work &&
        !_warnedThisPhase &&
        pos.remaining <= const Duration(seconds: 10)) {
      _warnedThisPhase = true;
      onEvent?.call(TimerEvent.tenSecondWarning, pos.phase);
    }
  }
}

/// Builds the flat phase list for a config: prep, then work/rest per round.
List<Phase> buildSchedule(TimerConfig c) {
  final phases = <Phase>[
    Phase(type: PhaseType.prep, round: 0, duration: c.prep),
  ];
  for (var r = 1; r <= c.rounds; r++) {
    phases.add(Phase(type: PhaseType.work, round: r, duration: c.work));
    final isLast = r == c.rounds;
    if (!isLast && c.rest > Duration.zero) {
      phases.add(Phase(type: PhaseType.rest, round: r, duration: c.rest));
    }
  }
  return phases;
}

class PhasePosition {
  const PhasePosition({
    required this.index,
    required this.phase,
    required this.remaining,
    required this.elapsedInPhase,
  });
  final int index;
  final Phase phase;
  final Duration remaining;
  final Duration elapsedInPhase;

  bool get isWarning =>
      phase.type == PhaseType.work &&
      remaining <= const Duration(seconds: 10);
}

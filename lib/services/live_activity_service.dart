import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../engine/timer_engine.dart';
import '../models/models.dart';

/// Drives the iOS Live Activity (lock screen + Dynamic Island).
///
/// The native side renders the countdown itself from the phase's end time,
/// so this service only talks to the platform on state changes: phase
/// boundaries, pause/resume, and session end. No-op everywhere but iOS.
class LiveActivityService {
  static const _channel = MethodChannel('round_timer/live_activity');
  static bool get _supported => !kIsWeb && Platform.isIOS;

  bool _started = false;
  String _lastKey = '';

  Future<void> sync(TimerEngine engine, TimerConfig config) async {
    if (!_supported) return;
    final args = _payload(engine, config);
    final key =
        '${args['phase']}|${args['round']}|${args['paused']}';
    if (key == _lastKey) return;
    _lastKey = key;
    try {
      if (!_started) {
        _started = true;
        await _channel.invokeMethod('start', args);
      } else {
        await _channel.invokeMethod('update', args);
      }
    } catch (e) {
      debugPrint('LiveActivityService: $e');
    }
  }

  Future<void> end() async {
    if (!_supported || !_started) return;
    _started = false;
    _lastKey = '';
    try {
      await _channel.invokeMethod('end');
    } catch (e) {
      debugPrint('LiveActivityService: $e');
    }
  }

  Map<String, Object> _payload(TimerEngine engine, TimerConfig config) {
    final pos = engine.position;
    final paused = !engine.isRunning && !engine.isFinished;
    final remaining = pos?.remaining ?? Duration.zero;
    final phase = engine.isFinished || pos == null
        ? 'done'
        : switch (pos.phase.type) {
            PhaseType.prep => 'prep',
            PhaseType.work => 'work',
            PhaseType.rest => 'rest',
          };
    return {
      'phase': phase,
      'round': pos?.phase.round ?? config.rounds,
      'totalRounds': config.rounds,
      'sportName': config.name,
      'endsAtMs':
          DateTime.now().add(remaining).millisecondsSinceEpoch.toDouble(),
      'paused': paused,
      'pausedRemaining': remaining.inSeconds,
    };
  }
}

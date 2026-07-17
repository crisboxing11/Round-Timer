import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../audio/sound_service.dart';
import '../engine/timer_engine.dart';
import '../models/models.dart';
import '../theme/led_theme.dart';
import 'seven_segment.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key, required this.config});
  final TimerConfig config;

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late final TimerEngine _engine;
  final _sounds = SoundService();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _engine = TimerEngine(widget.config)
      ..onEvent = _handleEvent
      ..addListener(_onEngine);
    _sounds.init();
    WakelockPlus.enable();
    _engine.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => _engine.tick());
  }

  void _onEngine() => setState(() {});

  void _handleEvent(TimerEvent e, Phase? phase) {
    switch (e) {
      case TimerEvent.phaseStarted:
        if (phase!.type != PhaseType.prep) _sounds.bell();
      case TimerEvent.tenSecondWarning:
        _sounds.clapper();
      case TimerEvent.finished:
        _sounds.bell();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _engine.removeListener(_onEngine);
    WakelockPlus.disable();
    _sounds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pos = _engine.position;
    final finished = _engine.isFinished || pos == null;
    final warning = pos?.isWarning ?? false;
    final color = finished
        ? LedColors.green
        : LedColors.forPhase(pos.phase.type, warning: warning);

    final roundLabel = finished
        ? 'TIME'
        : pos.phase.type == PhaseType.prep
            ? 'GET READY'
            : 'ROUND ${pos.phase.round} OF ${widget.config.rounds}';

    final stateLabel = finished
        ? 'DONE'
        : !_engine.isRunning
            ? 'PAUSED'
            : switch (pos.phase.type) {
                PhaseType.prep => 'GET READY',
                PhaseType.work => 'FIGHT',
                PhaseType.rest => 'REST',
              };

    // Flash digits during final 10s of a work round.
    final flashOff = warning &&
        _engine.isRunning &&
        (_engine.elapsed.inMilliseconds ~/ 250).isEven;
    final blink = !_engine.isRunning ||
        (_engine.elapsed.inMilliseconds ~/ 500).isEven;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: finished ? null : _engine.toggle,
      child: Scaffold(
        backgroundColor: LedColors.bg,
        body: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.13),
                blurRadius: 140,
                spreadRadius: -20,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    children: [
                      _StackLights(active: finished ? PhaseType.work : (warning ? PhaseType.prep : pos.phase.type)),
                      const SizedBox(height: 14),
                      Text(roundLabel, style: LedText.roundLabel),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SevenSegmentClock(
                    duration: finished ? Duration.zero : pos.remaining,
                    color: flashOff ? LedColors.ghost : color,
                    blinkColon: blink,
                  ),
                ),
                Column(
                  children: [
                    Text(stateLabel, style: LedText.stateLabel.copyWith(color: color)),
                    const SizedBox(height: 6),
                    Text(
                      finished
                          ? ''
                          : 'TAP ANYWHERE TO ${_engine.isRunning ? 'PAUSE' : 'RESUME'}',
                      style: const TextStyle(
                        color: LedColors.textFaint,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ControlButton(label: 'END', onTap: () => Navigator.of(context).pop()),
                          const SizedBox(width: 12),
                          if (!finished)
                            _ControlButton(label: 'SKIP', onTap: _engine.skipPhase),
                          const SizedBox(width: 12),
                          _ControlButton(
                            label: _sounds.muted ? 'UNMUTE' : 'MUTE',
                            onTap: () => setState(() => _sounds.muted = !_sounds.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StackLights extends StatelessWidget {
  const _StackLights({required this.active});
  final PhaseType active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: PhaseType.values.map((t) {
        final on = t == active;
        final c = LedColors.forPhase(t);
        return Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? c : LedColors.border,
            boxShadow: on ? [BoxShadow(color: c, blurRadius: 12)] : null,
          ),
        );
      }).toList(),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LedColors.panel,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 96),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LedColors.border, width: 2),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB9C0B9),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.5,
            ),
          ),
        ),
      ),
    );
  }
}

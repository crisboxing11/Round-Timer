import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine/timer_engine.dart';
import '../models/models.dart';
import '../theme/led_theme.dart';
import 'timer_screen.dart';

/// Build-your-own timer: rounds, work, rest. Uniform rounds are free;
/// per-round overrides are the Pro upsell later.
class CustomConfigScreen extends StatefulWidget {
  const CustomConfigScreen({super.key, this.initial});

  /// Prefill (e.g. the last-used custom config); defaults otherwise.
  final TimerConfig? initial;

  @override
  State<CustomConfigScreen> createState() => _CustomConfigScreenState();
}

class _CustomConfigScreenState extends State<CustomConfigScreen> {
  late int _rounds;
  late Duration _work;
  late Duration _rest;

  static const _workStep = Duration(seconds: 15);
  static const _restStep = Duration(seconds: 15);
  static const _minWork = Duration(seconds: 15);
  static const _maxWork = Duration(minutes: 60);
  static const _maxRest = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _rounds = i?.rounds ?? 5;
    _work = i?.work ?? const Duration(minutes: 3);
    _rest = i?.rest ?? const Duration(minutes: 1);
  }

  TimerConfig get _config => TimerConfig(
        id: 'custom',
        name: 'Custom',
        rounds: _rounds,
        work: _work,
        rest: _rest,
      );

  void _start() {
    HapticFeedback.mediumImpact();
    LastConfigStore.save(_config);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TimerScreen(config: _config)),
    );
  }

  String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final total = buildSchedule(_config)
        .fold(Duration.zero, (Duration a, p) => a + p.duration);
    return Scaffold(
      backgroundColor: LedColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.chevron_left,
                      color: LedColors.textDim, size: 34),
                ),
                const Spacer(),
                const Text('CUSTOM TIMER', style: LedText.eyebrow),
                const Spacer(),
                const SizedBox(width: 50),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _Stepper(
                    label: 'ROUNDS',
                    value: '$_rounds',
                    color: LedColors.text,
                    onMinus: _rounds > 1
                        ? () => setState(() => _rounds--)
                        : null,
                    onPlus: _rounds < 99
                        ? () => setState(() => _rounds++)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _Stepper(
                    label: 'WORK',
                    value: _fmt(_work),
                    color: LedColors.green,
                    onMinus: _work > _minWork
                        ? () => setState(() => _work -= _workStep)
                        : null,
                    onPlus: _work < _maxWork
                        ? () => setState(() => _work += _workStep)
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _Stepper(
                    label: 'REST',
                    value: _rest == Duration.zero ? 'OFF' : _fmt(_rest),
                    color: LedColors.red,
                    onMinus: _rest > Duration.zero
                        ? () => setState(() => _rest -= _restStep)
                        : null,
                    onPlus: _rest < _maxRest
                        ? () => setState(() => _rest += _restStep)
                        : null,
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: Text(
                      'TOTAL ${_fmt(total)} · 0:10 PREP INCLUDED',
                      style: const TextStyle(
                        color: LedColors.textFaint,
                        fontSize: 13,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Material(
                color: LedColors.panel,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _start,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: LedColors.green, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: LedColors.green.withValues(alpha: 0.15),
                          blurRadius: 24,
                          spreadRadius: -4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'START',
                        style: LedText.presetName.copyWith(
                          color: LedColors.green,
                          fontSize: 30,
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.color,
    required this.onMinus,
    required this.onPlus,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: LedColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LedColors.border, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: LedText.eyebrow.copyWith(letterSpacing: 3)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: LedText.presetName.copyWith(
                    color: color,
                    fontSize: 34,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          _StepButton(icon: Icons.remove, onTap: onMinus),
          const SizedBox(width: 10),
          _StepButton(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

/// Big square tap target — usable with wraps on.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: LedColors.bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? LedColors.border : LedColors.ghost,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            size: 30,
            color: enabled ? LedColors.text : LedColors.textFaint,
          ),
        ),
      ),
    );
  }
}

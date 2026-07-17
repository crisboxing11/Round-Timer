import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/led_theme.dart';
import 'timer_screen.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  void _start(BuildContext context, TimerConfig c) {
    LastConfigStore.save(c);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TimerScreen(config: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LedColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 28),
            const Center(child: Text('ROUND TIMER', style: LedText.eyebrow)),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'PICK YOUR FIGHT',
                style: LedText.presetName.copyWith(fontSize: 38),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: presets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final p = presets[i];
                  return _PresetTile(config: p, onTap: () => _start(context, p));
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'AMBER · GET READY    GREEN · FIGHT    RED · REST',
                  style: TextStyle(
                    color: LedColors.textFaint,
                    fontSize: 13,
                    letterSpacing: 1.2,
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

class _PresetTile extends StatelessWidget {
  const _PresetTile({required this.config, required this.onTap});
  final TimerConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LedColors.panel,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: LedColors.border, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(config.name.toUpperCase(), style: LedText.presetName),
              Text(config.subtitle, style: LedText.presetSub),
            ],
          ),
        ),
      ),
    );
  }
}

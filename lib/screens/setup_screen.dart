import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/led_theme.dart';
import 'custom_config_screen.dart';
import 'timer_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  TimerConfig? _last;

  @override
  void initState() {
    super.initState();
    LastConfigStore.load().then((c) {
      if (mounted) setState(() => _last = c);
    });
  }

  void _start(TimerConfig c) {
    LastConfigStore.save(c);
    setState(() => _last = c);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TimerScreen(config: c)),
    );
  }

  Future<void> _openCustom() async {
    final last = _last;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomConfigScreen(
          initial: (last != null && last.id == 'custom') ? last : null,
        ),
      ),
    );
    // Refresh the quick-start tile in case a custom session was started.
    final refreshed = await LastConfigStore.load();
    if (mounted) setState(() => _last = refreshed);
  }

  @override
  Widget build(BuildContext context) {
    final last = _last;
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
            if (last != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _QuickStartTile(config: last, onTap: () => _start(last)),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: presets.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i == presets.length) {
                    return _CustomTile(onTap: _openCustom);
                  }
                  final p = presets[i];
                  return _PresetTile(config: p, onTap: () => _start(p));
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

/// Last-used config, front and center: the whole app is one tap to start.
class _QuickStartTile extends StatelessWidget {
  const _QuickStartTile({required this.config, required this.onTap});
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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'START · ${config.name.toUpperCase()}',
                    style: LedText.presetName.copyWith(color: LedColors.green),
                  ),
                  const SizedBox(height: 2),
                  Text(config.subtitle, style: LedText.presetSub),
                ],
              ),
              const Icon(Icons.play_arrow_rounded,
                  color: LedColors.green, size: 44),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomTile extends StatelessWidget {
  const _CustomTile({required this.onTap});
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
            border: Border.all(color: LedColors.amber, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CUSTOM',
                style: LedText.presetName.copyWith(color: LedColors.amber),
              ),
              const Icon(Icons.tune, color: LedColors.amber, size: 26),
            ],
          ),
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

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum PhaseType { prep, work, rest }

class Phase {
  const Phase({required this.type, required this.round, required this.duration});
  final PhaseType type;
  final int round; // 0 for prep
  final Duration duration;
}

class TimerConfig {
  const TimerConfig({
    required this.id,
    required this.name,
    required this.rounds,
    required this.work,
    required this.rest,
    this.prep = const Duration(seconds: 10),
  });

  final String id;
  final String name;
  final int rounds;
  final Duration work;
  final Duration rest;
  final Duration prep;

  String get subtitle {
    String f(Duration d) =>
        '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    if (rounds == 1) return '1 × ${f(work)}';
    final r = rest > Duration.zero ? ' · ${f(rest)} rest' : '';
    return '$rounds × ${f(work)}$r';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rounds': rounds,
        'work': work.inSeconds,
        'rest': rest.inSeconds,
        'prep': prep.inSeconds,
      };

  static TimerConfig fromJson(Map<String, dynamic> j) => TimerConfig(
        id: j['id'] as String,
        name: j['name'] as String,
        rounds: j['rounds'] as int,
        work: Duration(seconds: j['work'] as int),
        rest: Duration(seconds: j['rest'] as int),
        prep: Duration(seconds: (j['prep'] ?? 10) as int),
      );
}

/// Exact rules per sport. Grappling done right is our wedge.
const presets = <TimerConfig>[
  TimerConfig(id: 'boxing', name: 'Boxing', rounds: 12, work: Duration(minutes: 3), rest: Duration(minutes: 1)),
  TimerConfig(id: 'boxing_am', name: 'Boxing (Amateur)', rounds: 3, work: Duration(minutes: 3), rest: Duration(minutes: 1)),
  TimerConfig(id: 'mma', name: 'MMA', rounds: 5, work: Duration(minutes: 5), rest: Duration(minutes: 1)),
  TimerConfig(id: 'muaythai', name: 'Muay Thai', rounds: 5, work: Duration(minutes: 3), rest: Duration(minutes: 2)),
  TimerConfig(id: 'judo', name: 'Judo', rounds: 1, work: Duration(minutes: 4), rest: Duration.zero),
  TimerConfig(id: 'bjj', name: 'BJJ', rounds: 6, work: Duration(minutes: 5), rest: Duration(minutes: 1)),
  TimerConfig(id: 'wrestling', name: 'Wrestling', rounds: 2, work: Duration(minutes: 3), rest: Duration(seconds: 30)),
];

/// Persist/restore the last used config so the app opens ready to go.
/// Stores the full config as JSON so custom setups survive restarts too.
class LastConfigStore {
  static const _key = 'last_config';
  static const _legacyKey = 'last_config_id';

  static Future<void> save(TimerConfig c) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(c.toJson()));
  }

  static Future<TimerConfig> load() async {
    final p = await SharedPreferences.getInstance();
    final json = p.getString(_key);
    if (json != null) {
      try {
        return TimerConfig.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt entry — fall through to defaults.
      }
    }
    final legacyId = p.getString(_legacyKey);
    return presets.firstWhere(
      (c) => c.id == legacyId,
      orElse: () => presets.first,
    );
  }
}

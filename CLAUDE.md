# Round Timer: Boxing, MMA, Judo

Best-in-class combat sports round timer. Flutter, iOS + Android, offline-first, no account, no ads.

## Product principles (non-negotiable)
1. The timer NEVER drifts, NEVER sleeps the screen, NEVER stops the user's music. Bells mix OVER background audio (iOS: `.mixWithOthers` audio session; Android: transient audio focus with ducking disabled — play over, don't duck).
2. Opens directly into the last-used configuration. One tap to start.
3. Whole timer screen is a pause/resume button (gloved hands).
4. Free tier is fully usable forever. Pro is a one-time purchase. Nothing ever gets locked retroactively.
5. Tiny app. No analytics SDKs beyond store defaults, no network calls in v1, no permissions except wake lock.

## Sport presets (exact rules)
| Preset | Rounds | Work | Rest |
|---|---|---|---|
| Boxing | 12 | 3:00 | 1:00 |
| Boxing (amateur) | 3 | 3:00 | 1:00 |
| MMA | 5 | 5:00 | 1:00 |
| Muay Thai | 5 | 3:00 | 2:00 |
| Judo | 1 | 4:00 | — |
| BJJ | 6 | 5:00 | 1:00 |
| Wrestling | 2 | 3:00 | 0:30 |
| Custom | user-defined, per-round overrides (Pro) |

10-second prep phase before round 1. Warning clapper (3 wood clacks) at 10s remaining in every work round. Bell at every phase transition.

## Visual language (matches physical gym LED timers)
- Near-black background `#0A0B0A`
- Seven-segment digits (custom painter, ghost segments `#161917`)
- Phase colors: prep/warning amber `#FFB324`, work green `#3DF25B`, rest red `#FF3B3B`
- Stack-light phase dots, round label "ROUND 3 OF 12"
- Digits flash amber during final 10s of work
- Type: Barlow Condensed (bundled), heavy weights, wide letterspacing

## Architecture
- `lib/engine/` — pure Dart timer engine. Schedule = list of phases built from config. Elapsed computed from a monotonic clock (`Stopwatch`) + accumulated-pause offset. NEVER count ticks. Engine is UI-independent and unit-tested.
- `lib/audio/` — bell + clapper. Pre-loaded low-latency players (`soundpool` or `just_audio` with prepared sources). Sounds scheduled off phase boundaries computed by the engine, fired by the tick loop; tolerate ±50ms.
- `lib/models/` — SportPreset, TimerConfig, Phase. Persist last config with `shared_preferences` (v1) — move to drift/sqlite when history ships.
- `lib/screens/` — setup_screen (preset list), timer_screen (the LED display).
- `lib/theme/` — colors, text styles.
- State: plain `ChangeNotifier` + `ValueListenableBuilder`. No heavy state library for v1.

## Platform must-dos
- `wakelock_plus` while running
- iOS: audio session category `playback` with `mixWithOthers`; background audio capability so bells fire when locked
- Android: foreground service while timer runs (notification shows round + time); `USE_EXACT_ALARM` not needed — the foreground service tick is enough
- Test: lock phone mid-round with Spotify playing → bell must ring at exactly the boundary, music must not stop

## Roadmap after v1
- Pro IAP (one-time): per-round custom durations, reaction/callout engine, custom sounds, TV cast, history
- Watch companions
- Coach/class mode

## Conventions
- `flutter_lints` defaults, no warnings at commit
- Unit tests required for engine (schedule building, pause math, warning triggers)
- Conventional commits

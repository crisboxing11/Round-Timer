# Round Timer: Boxing, MMA, Judo

Combat sports round timer. Offline-first, no ads, no account. Free core + one-time Pro unlock.

Styled after the physical LED timer on every boxing gym wall: seven-segment digits, stack-light phase colors (amber = get ready, green = fight, red = rest), 10-second clapper warning, authentic bell.

## Status
v0.1 scaffold — engine, models, audio service, LED display, setup + timer screens, engine unit tests. See `CLAUDE.md` for the full product spec and architecture rules.

## Getting started

This repo contains the Dart source (`lib/`, `test/`), spec, and pubspec — not the generated platform folders. To bootstrap:

```bash
# 1. Create the platform scaffolding around this source
flutter create . --project-name round_timer --platforms ios,android

# 2. Install dependencies
flutter pub get

# 3. Run tests
flutter test

# 4. Run it
flutter run
```

## Before v1 ships
- [ ] Bundle `assets/audio/bell.wav` + `clapper.wav` (record or license; SoundService no-ops until present) and uncomment assets in `pubspec.yaml`
- [ ] Bundle Barlow Condensed fonts, uncomment in `pubspec.yaml`
- [ ] iOS: enable Background Modes → Audio; verify bells fire when locked with Spotify playing
- [ ] Android: foreground service while timer runs (notification with round + time)
- [ ] Custom round builder (rounds / work / rest steppers)
- [ ] App icons + store screenshots (lead with the LED display)

## Architecture (short version)
- `lib/engine/` — pure Dart, drift-free (monotonic Stopwatch + pause offset, never tick counting), unit-tested
- `lib/audio/` — bells mix OVER the user's music, never pause or duck it
- `lib/screens/` — setup (preset list), timer (LED display, tap-anywhere pause)
- Full rules in `CLAUDE.md`

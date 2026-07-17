# Audio sources

Both files are placeholder assets derived from CC0 (public domain) recordings on freesound.org.
No attribution is legally required; recorded here for provenance. Plan: replace the bell with
an authentic gym bell recording before launch.

Assets ship as AAC (.m4a): raw PCM WAV decoded as static via just_audio/AVPlayer on iOS 26,
so keep bundled sounds in a compressed container.

- `bell.m4a` — the single clang (found at ~11.1s of the source) from
  "G39-09-Boxing Fight Bell.wav" by craigsmith,
  https://freesound.org/people/craigsmith/sounds/438626/ (CC0). Vintage Hollywood optical
  sound effect, digitized by USC Cinema. Peak-normalized to -1 dBFS, 1s fade-out, 3.1s total.
- `clapper.m4a` — three repeats of "Wood block hit" by thomasjaunism,
  https://freesound.org/people/thomasjaunism/sounds/218460/ (CC0), 280ms onset spacing,
  peak-normalized.

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// Bell + clapper playback that mixes OVER the user's music.
///
/// Product rule: we never stop or duck Spotify. iOS uses playback category
/// with mixWithOthers; Android requests transient focus configured to
/// overlay rather than duck.
///
/// v1 ships with bundled assets (assets/audio/bell.wav, clapper.wav).
/// Until assets are added, calls are safe no-ops.
class SoundService {
  final _bell = AudioPlayer();
  final _clapper = AudioPlayer();
  bool _ready = false;
  bool muted = false;

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.mixWithOthers,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        usage: AndroidAudioUsage.assistanceSonification,
      ),
      androidAudioFocusGainType:
          AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: false,
    ));
    try {
      await _bell.setAsset('assets/audio/bell.wav', preload: true);
      await _clapper.setAsset('assets/audio/clapper.wav', preload: true);
      _ready = true;
    } catch (_) {
      // Assets not bundled yet — run silent rather than crash.
      _ready = false;
    }
  }

  Future<void> bell() => _play(_bell);
  Future<void> clapper() => _play(_clapper);

  Future<void> _play(AudioPlayer p) async {
    if (!_ready || muted) return;
    await p.seek(Duration.zero);
    await p.play();
  }

  void dispose() {
    _bell.dispose();
    _clapper.dispose();
  }
}

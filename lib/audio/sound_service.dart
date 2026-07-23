import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Bell + clapper playback that mixes OVER the user's music.
///
/// Product rule: we never stop or duck Spotify. iOS uses playback category
/// with mixWithOthers; Android requests transient focus configured to
/// overlay rather than duck.
class SoundService {
  final _bell = AudioPlayer();
  final _clapper = AudioPlayer();
  // Looping silence at zero volume while the timer runs: an actively
  // rendering audio session is what stops iOS from suspending the app when
  // the screen locks — otherwise the engine freezes and bells never fire.
  final _keepAlive = AudioPlayer();
  bool _ready = false;
  bool muted = false;

  Future<void> init() async {
    try {
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
    } catch (e) {
      // A failed session config shouldn't kill the bells entirely.
      debugPrint('SoundService: audio session config failed: $e');
    }
    try {
      await _bell.setAsset('assets/audio/bell.m4a', preload: true);
      await _clapper.setAsset('assets/audio/clapper.m4a', preload: true);
      await _keepAlive.setAsset('assets/audio/silence.m4a', preload: true);
      await _keepAlive.setLoopMode(LoopMode.all);
      await _keepAlive.setVolume(0);
      _ready = true;
    } catch (e) {
      // Assets not bundled yet — run silent rather than crash.
      debugPrint('SoundService: asset load failed, running silent: $e');
      _ready = false;
    }
  }

  /// Keep the audio session rendering while [on]. Called every engine tick;
  /// cheap when the state already matches.
  Future<void> keepAlive(bool on) async {
    if (!_ready || on == _keepAlive.playing) return;
    try {
      if (on) {
        _keepAlive.play();
      } else {
        await _keepAlive.pause();
      }
    } catch (e) {
      debugPrint('SoundService: keep-alive toggle failed: $e');
    }
  }

  Future<void> bell() => _play(_bell, 'bell');
  Future<void> clapper() => _play(_clapper, 'clapper');

  Future<void> _play(AudioPlayer p, String name) async {
    if (!_ready || muted) {
      debugPrint('SoundService: skipped $name (ready=$_ready muted=$muted)');
      return;
    }
    try {
      await p.pause();
      await p.seek(Duration.zero);
      p.play();
      debugPrint('SoundService: played $name');
    } catch (e) {
      debugPrint('SoundService: $name playback failed: $e');
    }
  }

  void dispose() {
    _bell.dispose();
    _clapper.dispose();
    _keepAlive.dispose();
  }
}

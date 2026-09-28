import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Centralized audio manager for all game sounds and music.
class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _musicVolume = 0.35;

  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  final List<String> _exitSounds = [
    'swoosh_18.mp3',
  ];
  int _exitSoundIndex = 0;

  late AudioPool _clickPool;
  bool _clickPoolInitialized = false;
  final List<AudioPool> _exitPools = [];
  bool _exitPoolsInitialized = false;

  // AudioPool can't change pitch, so pitched SFX rotate through these players.
  final List<AudioPlayer> _pitchedPlayers = [];
  int _pitchedIndex = 0;
  static const int _pitchedPlayerCount = 3;

  Future<void> initialize() async {
    try {
      FlameAudio.bgm.initialize();
      // Precache the audio files during splash screen load
      await FlameAudio.audioCache.loadAll([
        'click.ogg',
        'underwater.mp3',
        ..._exitSounds,
      ]);
      // Pre-warm a pool of players for the click sound to ensure zero latency
      _clickPool = await FlameAudio.createPool(
        'click.ogg',
        minPlayers: 3,
        maxPlayers: 5,
      );
      _clickPoolInitialized = true;

      // Pre-warm a pool of players for each arrow exit sound effect
      for (final sound in _exitSounds) {
        final pool = await FlameAudio.createPool(
          sound,
          minPlayers: 2,
          maxPlayers: 4,
        );
        _exitPools.add(pool);
      }
      _exitPoolsInitialized = true;

      for (int i = 0; i < _pitchedPlayerCount; i++) {
        final player = AudioPlayer()..audioCache = FlameAudio.audioCache;
        await player.setReleaseMode(ReleaseMode.stop);
        _pitchedPlayers.add(player);
      }
    } catch (e) {
      debugPrint('Error initializing FlameAudio: $e');
    }
  }

  // ── Music ─────────────────────────────────────────────────────────────────────

  Future<void> playBgMusic() async {
    if (!_musicEnabled) return;
    try {
      if (FlameAudio.bgm.isPlaying) return;
      await FlameAudio.bgm.play('underwater.mp3', volume: 0.35);
    } catch (e) {
      debugPrint('Error playing background music: $e');
    }
  }

  Future<void> playMenuMusic() async {
    _musicVolume = 0.35;
    await playBgMusic();
    await _setMusicVolume(0.35);
  }

  Future<void> playGameMusic() async {
    await playBgMusic();
    await setBoardFill(0);
  }

  /// Raises the bed as arrows leave, so an emptying board feels louder.
  Future<void> setBoardFill(double clearedFraction) async {
    final volume = 0.2 + clearedFraction.clamp(0.0, 1.0) * 0.5;
    if ((volume - _musicVolume).abs() < 0.02) return;
    _musicVolume = volume;
    await _setMusicVolume(volume);
  }

  Future<void> _setMusicVolume(double volume) async {
    if (!_musicEnabled) return;
    try {
      await FlameAudio.bgm.audioPlayer.setVolume(volume);
    } catch (e) {
      debugPrint('Error setting music volume: $e');
    }
  }

  Future<void> stopMusic() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('Error stopping background music: $e');
    }
  }

  // ── SFX ───────────────────────────────────────────────────────────────────────

  Future<void> playClick() async {
    if (!_soundEnabled) return;
    try {
      if (_clickPoolInitialized) {
        await _clickPool.start(volume: 0.8);
      } else {
        await FlameAudio.play('click.ogg', volume: 0.8);
      }
    } catch (e) {
      debugPrint('Error playing click sound: $e');
    }
  }

  Future<void> playArrowTap() async {
    await playClick();
  }

  /// Rises in pitch with [combo] so streaks sound like a climbing scale.
  Future<void> playArrowExit({int combo = 0}) async {
    if (!_soundEnabled) return;
    if (combo >= 2) {
      final step = (combo.clamp(2, 10) - 1).toDouble();
      await _playPitched(_exitSounds.first, 1.0 + step * 0.06, 0.8);
      return;
    }
    try {
      final poolIndex = _exitSoundIndex;
      _exitSoundIndex = (_exitSoundIndex + 1) % _exitSounds.length;

      if (_exitPoolsInitialized && poolIndex < _exitPools.length) {
        await _exitPools[poolIndex].start(volume: 0.8);
      } else {
        await FlameAudio.play(_exitSounds[poolIndex], volume: 0.8);
      }
    } catch (e) {
      debugPrint('Error playing arrow exit sound: $e');
    }
  }

  Future<void> playArrowBlock() async {
    if (!_soundEnabled) return;
    await _playPitched('click.ogg', 0.55, 1.0);
  }

  /// Each power-up gets its own pitch so they don't share one click.
  Future<void> playPowerUp(String id) async {
    if (!_soundEnabled) return;
    switch (id) {
      case 'hint':
        await _playPitched('click.ogg', 1.4, 0.85);
      case 'eraser':
        await _playPitched('click.ogg', 0.58, 0.95);
      case 'wand':
        await _playPitched('swoosh_18.mp3', 1.55, 0.75);
      case 'ruler':
        await _playPitched('swoosh_18.mp3', 0.85, 0.7);
      default:
        await playClick();
    }
  }

  Future<void> _playPitched(String file, double rate, double volume) async {
    if (_pitchedPlayers.isEmpty) return;
    try {
      final player = _pitchedPlayers[_pitchedIndex];
      _pitchedIndex = (_pitchedIndex + 1) % _pitchedPlayers.length;
      await player.stop();
      await player.setSource(AssetSource(file));
      await player.setVolume(volume);
      await player.setPlaybackRate(rate);
      await player.resume();
    } catch (e) {
      debugPrint('Error playing pitched sound $file: $e');
    }
  }

  Future<void> playLevelComplete() async {}

  Future<void> playLifeLost() async {}

  Future<void> playGameOver() async {}

  Future<void> playStreakExtended() async {}

  // ── Settings ──────────────────────────────────────────────────────────────────

  void setSoundEnabled(bool value) {
    _soundEnabled = value;
  }

  void setMusicEnabled(bool value) {
    _musicEnabled = value;
    if (!value) {
      stopMusic();
    } else {
      playBgMusic();
    }
  }

  void dispose() {
    for (final p in _pitchedPlayers) {
      p.dispose();
    }
    _pitchedPlayers.clear();
    try {
      FlameAudio.bgm.dispose();
    } catch (e) {
      debugPrint('Error disposing FlameAudio bgm: $e');
    }
  }
}

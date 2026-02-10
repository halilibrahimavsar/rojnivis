import 'package:audioplayers/audioplayers.dart';
import 'package:injectable/injectable.dart';

/// Available ambient soundscape presets.
enum AmbientSoundscape {
  coffeeShop('sounds/ambient_coffee_shop.mp3', 'Coffee Shop'),
  library('sounds/ambient_library.mp3', 'Library'),
  nature('sounds/ambient_nature.mp3', 'Nature'),
  rain('sounds/ambient_rain.mp3', 'Rain');

  final String assetPath;
  final String label;
  const AmbientSoundscape(this.assetPath, this.label);
}

@lazySingleton
class SoundService {
  final AudioPlayer _player = AudioPlayer();
  final AudioPlayer _ambientPlayer = AudioPlayer();

  bool _enabled = true;
  bool _ambientEnabled = false;
  double _ambientVolume = 0.3;
  AmbientSoundscape? _currentSoundscape;

  // ── Getters ──────────────────────────────────────────────────

  bool get isEnabled => _enabled;
  bool get isAmbientPlaying => _ambientEnabled;
  double get ambientVolume => _ambientVolume;
  AmbientSoundscape? get currentSoundscape => _currentSoundscape;

  // ── Sound Effects ────────────────────────────────────────────

  void setEnabled(bool value) {
    _enabled = value;
  }

  Future<void> playPencilTap() async {
    if (!_enabled) return;
    await _player.stop();
    await _player.play(AssetSource('sounds/pencil_tap.mp3'));
  }

  Future<void> playPageFlip() async {
    if (!_enabled) return;
    await _player.stop();
    await _player.play(AssetSource('sounds/page_flip.mp3'));
  }

  Future<void> playPencilWrite() async {
    if (!_enabled) return;
    await _player.stop();
    await _player.play(AssetSource('sounds/pencil_write.mp3'));
  }

  Future<void> playNotificationChime() async {
    if (!_enabled) return;
    await _player.stop();
    await _player.play(AssetSource('sounds/notification_chime.mp3'));
  }

  // ── Ambient Soundscapes ──────────────────────────────────────

  /// Starts playing an ambient soundscape on loop.
  ///
  /// If a soundscape is already playing, it is stopped first.
  /// The volume fades in over [fadeInDuration].
  Future<void> startAmbient(
    AmbientSoundscape soundscape, {
    Duration fadeInDuration = const Duration(milliseconds: 800),
  }) async {
    // Stop current ambient if different
    if (_currentSoundscape == soundscape && _ambientEnabled) return;
    await stopAmbient();

    _currentSoundscape = soundscape;
    _ambientEnabled = true;

    await _ambientPlayer.setReleaseMode(ReleaseMode.loop);
    await _ambientPlayer.setVolume(0);
    await _ambientPlayer.play(AssetSource(soundscape.assetPath));

    // Fade in volume
    await _fadeAmbientVolume(
      from: 0,
      to: _ambientVolume,
      duration: fadeInDuration,
    );
  }

  /// Stops the current ambient soundscape with a fade-out.
  Future<void> stopAmbient({
    Duration fadeOutDuration = const Duration(milliseconds: 600),
  }) async {
    if (!_ambientEnabled) return;

    await _fadeAmbientVolume(
      from: _ambientVolume,
      to: 0,
      duration: fadeOutDuration,
    );

    await _ambientPlayer.stop();
    _ambientEnabled = false;
    _currentSoundscape = null;
  }

  /// Sets the ambient volume (0.0 to 1.0).
  Future<void> setAmbientVolume(double volume) async {
    _ambientVolume = volume.clamp(0.0, 1.0);
    if (_ambientEnabled) {
      await _ambientPlayer.setVolume(_ambientVolume);
    }
  }

  /// Internal helper to smoothly fade ambient volume.
  Future<void> _fadeAmbientVolume({
    required double from,
    required double to,
    required Duration duration,
  }) async {
    const steps = 10;
    final stepDuration = Duration(
      milliseconds: duration.inMilliseconds ~/ steps,
    );
    final increment = (to - from) / steps;

    for (var i = 0; i <= steps; i++) {
      final volume = (from + increment * i).clamp(0.0, 1.0);
      await _ambientPlayer.setVolume(volume);
      await Future.delayed(stepDuration);
    }
  }

  // ── Lifecycle ────────────────────────────────────────────────

  void dispose() {
    _player.dispose();
    _ambientPlayer.dispose();
  }
}

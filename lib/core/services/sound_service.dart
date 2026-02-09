import 'package:audioplayers/audioplayers.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class SoundService {
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

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
    // For writing, we might want a loop or a specific sound
    await _player.stop();
    await _player.play(AssetSource('sounds/pencil_write.mp3'));
  }

  void dispose() {
    _player.dispose();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _ambientPlayer = AudioPlayer();

  Future<void> playAmbient(String assetPath) async {
    await _ambientPlayer.setAsset('assets/audio/$assetPath');
    await _ambientPlayer.setLoopMode(LoopMode.one);
    await _ambientPlayer.play();
  }

  Future<void> stopAmbient() async => await _ambientPlayer.stop();
  Future<void> setVolume(double vol) async => await _ambientPlayer.setVolume(vol);
  bool get isPlaying => _ambientPlayer.playing;

  void dispose() {
    _ambientPlayer.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

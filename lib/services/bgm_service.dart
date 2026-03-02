import 'package:audioplayers/audioplayers.dart';

class BgmService {
  static final BgmService _instance = BgmService._internal();
  factory BgmService() => _instance;
  BgmService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  Future<void> initialize() async {
    await _player.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playBgm(String fileName) async {
    print('BGM: Attempting to play $fileName');
    if (_isPlaying) {
      print('BGM: Already playing');
      return;
    }
    try {
      final source = AssetSource('audio/$fileName');
      print('BGM: Setting source...');
      await _player.play(source);
      _isPlaying = true;
      print('BGM: Playback started successfully');
    } catch (e, stack) {
      print('BGM: Error playing BGM: $e');
      print('BGM: Stacktrace: $stack');
    }
  }

  Future<void> stopBgm() async {
    await _player.stop();
    _isPlaying = false;
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }
}

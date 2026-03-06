import 'package:audioplayers/audioplayers.dart';
import 'settings_service.dart';

class BgmService {
  static final BgmService _instance = BgmService._internal();
  factory BgmService() => _instance;
  BgmService._internal() {
    // 設定の変更を監視してBGMの停止・再開を制御
    SettingsService().addListener(_onSettingsChanged);
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _currentFileName;

  void _onSettingsChanged() {
    _player.setVolume(SettingsService().bgmVolume);
    if (!SettingsService().bgmEnabled && _isPlaying) {
      // 消音になっても即座に停止はせず、ボリューム0として扱う（再開時の挙動をスムーズにするため）
    } else if (SettingsService().bgmEnabled &&
        !_isPlaying &&
        _currentFileName != null) {
      playBgm(_currentFileName!);
    }
  }

  Future<void> initialize() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setVolume(SettingsService().bgmVolume);
  }

  Future<void> playBgm(String fileName) async {
    _currentFileName = fileName;

    print('BGM: Attempting to play $fileName');
    if (_isPlaying) {
      print('BGM: Already playing');
      return;
    }
    try {
      final source = AssetSource('audio/$fileName');
      print('BGM: Setting source...');
      await _player.setVolume(SettingsService().bgmVolume);
      await _player.play(source);
      _isPlaying = true;
      print('BGM: Playback started successfully');
    } catch (e, stack) {
      print('BGM: Error playing BGM: $e');
      print('BGM: Stacktrace: $stack');
    }
  }

  Future<void> stopBgm() async {
    _currentFileName = null;
    await _stopBgmInternal();
  }

  Future<void> _stopBgmInternal() async {
    await _player.stop();
    _isPlaying = false;
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }
}

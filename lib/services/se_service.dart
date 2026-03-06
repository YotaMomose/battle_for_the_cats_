import 'package:audioplayers/audioplayers.dart';
import 'settings_service.dart';

class SeService {
  static final SeService _instance = SeService._internal();
  factory SeService() => _instance;
  SeService._internal();

  // 短い音（SE）を再生する
  Future<void> play(String fileName) async {
    try {
      // SEは重なる可能性があるため、再生のたびに一時的なプレイヤーを使用する
      final player = AudioPlayer();
      await player.setVolume(SettingsService().seVolume);
      await player.play(AssetSource('audio/$fileName'));

      // 再生完了後にプレイヤーを破棄してメモリを解放
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      print('SE Error: $e');
    }
  }
}

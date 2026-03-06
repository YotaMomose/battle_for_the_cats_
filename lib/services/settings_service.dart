import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService with ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _bgmVolumeKey = 'bgm_volume';
  static const String _seVolumeKey = 'se_volume';

  double _bgmVolume = 0.5;
  double _seVolume = 0.5;

  double get bgmVolume => _bgmVolume;
  double get seVolume => _seVolume;

  // 後方互換性またはON/OFF扱いのためのフラグ
  bool get bgmEnabled => _bgmVolume > 0;
  bool get seEnabled => _seVolume > 0;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _bgmVolume = prefs.getDouble(_bgmVolumeKey) ?? 0.5;
    _seVolume = prefs.getDouble(_seVolumeKey) ?? 0.5;
    notifyListeners();
  }

  Future<void> setBgmVolume(double volume) async {
    _bgmVolume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_bgmVolumeKey, volume);
    notifyListeners();
  }

  Future<void> setSeVolume(double volume) async {
    _seVolume = volume;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_seVolumeKey, volume);
    notifyListeners();
  }
}

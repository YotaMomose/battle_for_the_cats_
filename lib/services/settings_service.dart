import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class SettingsService with ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _bgmEnabledKey = 'bgm_enabled';
  static const String _seEnabledKey = 'se_enabled';

  bool _bgmEnabled = true;
  bool _seEnabled = true;

  bool get bgmEnabled => _bgmEnabled;
  bool get seEnabled => _seEnabled;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _bgmEnabled = prefs.getBool(_bgmEnabledKey) ?? true;
    _seEnabled = prefs.getBool(_seEnabledKey) ?? true;
    notifyListeners();
  }

  Future<void> setBgmEnabled(bool enabled) async {
    _bgmEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bgmEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> setSeEnabled(bool enabled) async {
    _seEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seEnabledKey, enabled);
    notifyListeners();
  }
}

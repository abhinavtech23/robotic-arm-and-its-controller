import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  static const String _themeKey = 'ogarm_is_dark_mode';
  bool _isDarkMode = true; // Default to dark mode

  bool get isDarkMode => _isDarkMode;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_themeKey)) {
      _isDarkMode = prefs.getBool(_themeKey) ?? true;
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
  }
}

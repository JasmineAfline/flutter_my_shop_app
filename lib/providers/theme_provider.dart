import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeStatusKey = "THEME_STATUS";

  bool _isDarkTheme = false;

  bool get isDarkTheme => _isDarkTheme;

  ThemeProvider() {
    _loadTheme(); // Load saved theme when provider is created
  }

  /// Toggle between dark and light theme
  Future<void> toggleTheme() async {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
    await _saveTheme(_isDarkTheme);
  }

  /// Set a specific theme
  Future<void> setDarkTheme(bool value) async {
    _isDarkTheme = value;
    notifyListeners();
    await _saveTheme(value);
  }

  /// Save theme to SharedPreferences
  Future<void> _saveTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeStatusKey, value);
  }

  /// Load theme from SharedPreferences
  Future<void> _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkTheme = prefs.getBool(_themeStatusKey) ?? false;
    notifyListeners();
  }
}

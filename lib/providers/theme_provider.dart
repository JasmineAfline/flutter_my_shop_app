import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String THEMESTATUS = "THEME_STATUS";

  bool _darkTheme = false;

  
  bool get isDarkTheme => _darkTheme;

  ThemeProvider() {
    loadTheme(); 
  }

  // Set + save theme
  Future<void> setDarkTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(THEMESTATUS, value);
    _darkTheme = value;
    notifyListeners();
  }

  // Load saved theme
  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _darkTheme = prefs.getBool(THEMESTATUS) ?? false;
    notifyListeners();
  }
}

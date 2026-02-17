import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _userThemeOverrideKey = "USER_THEME_OVERRIDE";
  static const String _userOverrideEnabledKey = "USER_OVERRIDE_ENABLED";
  
  // Firestore collection for global settings
  static const String _globalSettingsDoc = 'settings';
  static const String _globalThemeField = 'isDarkTheme';

  bool _isDarkTheme = false;
  bool _userOverrideEnabled = false;
  bool _isAdminThemeGlobal = false; // Track if admin set global theme

  bool get isDarkTheme => _isDarkTheme;
  bool get userOverrideEnabled => _userOverrideEnabled;
  bool get isUsingGlobalTheme => !_userOverrideEnabled && _isAdminThemeGlobal;

  ThemeProvider() {
    _initialize();
  }

  /// Initialize theme - load both global and user preferences
  Future<void> _initialize() async {
    // First, load global theme from Firestore
    await _loadGlobalTheme();
    
    // Then, load user's override preference
    await _loadUserPreferences();
    
    notifyListeners();
  }

  /// Load global theme from Firestore (set by admin)
  Future<void> _loadGlobalTheme() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_globalSettingsDoc)
          .doc('app_settings')
          .get();
      
      if (doc.exists && doc.data() != null) {
        _isAdminThemeGlobal = true;
        _isDarkTheme = doc.data()![_globalThemeField] ?? false;
      } else {
        // Default to light theme if no global setting exists
        _isAdminThemeGlobal = false;
        _isDarkTheme = false;
      }
    } catch (e) {
      // If permission denied or any other error, use default theme
      debugPrint('Error loading global theme: $e');
      _isDarkTheme = false;
      _isAdminThemeGlobal = false;
    }
  }

  /// Load user preferences from SharedPreferences
  Future<void> _loadUserPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userOverrideEnabled = prefs.getBool(_userOverrideEnabledKey) ?? false;
    
    if (_userOverrideEnabled) {
      // If user has override enabled, load their preference
      _isDarkTheme = prefs.getBool(_userThemeOverrideKey) ?? false;
    }
    // Otherwise, _isDarkTheme already has the global theme value
  }

  /// Admin: Set global theme (called from AdminDashboard)
  Future<void> setGlobalTheme(bool isDark) async {
    try {
      await FirebaseFirestore.instance
          .collection(_globalSettingsDoc)
          .doc('app_settings')
          .set({
        _globalThemeField: isDark,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Only apply globally if user hasn't enabled their override
      if (!_userOverrideEnabled) {
        _isDarkTheme = isDark;
        notifyListeners();
      }
      
      _isAdminThemeGlobal = true;
    } catch (e) {
      debugPrint('Error setting global theme: $e');
    }
  }

  /// Toggle between dark and light theme (for user override)
  Future<void> toggleTheme() async {
    await setUserTheme(!_isDarkTheme);
  }

  /// User: Enable/disable their own theme override
  Future<void> setUserOverrideEnabled(bool enabled) async {
    _userOverrideEnabled = enabled;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_userOverrideEnabledKey, enabled);
    
    if (enabled) {
      // If enabling override, keep current theme as user's choice
      await prefs.setBool(_userThemeOverrideKey, _isDarkTheme);
    } else {
      // If disabling override, reload global theme
      await _loadGlobalTheme();
    }
    
    notifyListeners();
  }

  /// User: Set their own theme preference (when override is enabled)
  Future<void> setUserTheme(bool isDark) async {
    _isDarkTheme = isDark;
    
    if (_userOverrideEnabled) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userThemeOverrideKey, isDark);
    }
    
    notifyListeners();
  }

  /// Refresh global theme (useful when app comes back to foreground)
  Future<void> refreshGlobalTheme() async {
    if (!_userOverrideEnabled) {
      await _loadGlobalTheme();
      notifyListeners();
    }
  }

  /// Get current theme mode
  ThemeMode get themeMode => _isDarkTheme ? ThemeMode.dark : ThemeMode.light;
}

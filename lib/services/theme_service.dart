import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';

class ThemeService extends ChangeNotifier {
  static const _storageKey = 'dark_mode';

  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_storageKey) ?? false;
    AppColors.isDark = _isDarkMode;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    AppColors.isDark = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_storageKey, value);
    notifyListeners();
  }
}

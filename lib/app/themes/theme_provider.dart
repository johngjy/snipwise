import 'package:flutter/material.dart';

/// 主题状态管理
class ThemeProvider extends ChangeNotifier {
  // 当前主题模式
  ThemeMode _themeMode = ThemeMode.system;

  // 获取当前主题模式
  ThemeMode get themeMode => _themeMode;

  // 是否是暗色主题
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // 是否跟随系统
  bool get isSystemMode => _themeMode == ThemeMode.system;

  // 设置主题模式
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  // 切换明暗主题
  void toggleTheme() {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      // 如果当前是跟随系统，则切换到亮色主题
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }
}

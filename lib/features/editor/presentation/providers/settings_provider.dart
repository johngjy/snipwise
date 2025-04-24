import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 设置状态管理
class SettingsProvider extends ChangeNotifier {
  // 共享首选项实例
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // 设置键名
  static const String _keyLanguage = 'language';
  static const String _keyDefaultDpi = 'default_dpi';
  static const String _keyDefaultFormat = 'default_format';
  static const String _keyHiResEnabled = 'hires_enabled';
  static const String _keyUnit = 'unit';

  // 设置默认值
  String _language = 'zh_CN';
  int _defaultDpi = 300;
  String _defaultFormat = 'PNG';
  bool _hiResEnabled = true;
  String _unit = 'mm';

  // Getters
  String get language => _language;
  int get defaultDpi => _defaultDpi;
  String get defaultFormat => _defaultFormat;
  bool get hiResEnabled => _hiResEnabled;
  String get unit => _unit;
  bool get isInitialized => _isInitialized;

  /// 初始化
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  /// 加载设置
  void _loadSettings() {
    _language = _prefs.getString(_keyLanguage) ?? 'zh_CN';
    _defaultDpi = _prefs.getInt(_keyDefaultDpi) ?? 300;
    _defaultFormat = _prefs.getString(_keyDefaultFormat) ?? 'PNG';
    _hiResEnabled = _prefs.getBool(_keyHiResEnabled) ?? true;
    _unit = _prefs.getString(_keyUnit) ?? 'mm';
  }

  /// 设置语言
  Future<void> setLanguage(String language) async {
    _language = language;
    await _prefs.setString(_keyLanguage, language);
    notifyListeners();
  }

  /// 设置默认DPI
  Future<void> setDefaultDpi(int dpi) async {
    _defaultDpi = dpi;
    await _prefs.setInt(_keyDefaultDpi, dpi);
    notifyListeners();
  }

  /// 设置默认格式
  Future<void> setDefaultFormat(String format) async {
    _defaultFormat = format;
    await _prefs.setString(_keyDefaultFormat, format);
    notifyListeners();
  }

  /// 设置高清截图启用状态
  Future<void> setHiResEnabled(bool enabled) async {
    _hiResEnabled = enabled;
    await _prefs.setBool(_keyHiResEnabled, enabled);
    notifyListeners();
  }

  /// 设置单位
  Future<void> setUnit(String unit) async {
    _unit = unit;
    await _prefs.setString(_keyUnit, unit);
    notifyListeners();
  }

  /// 重置所有设置
  Future<void> resetToDefaults() async {
    _language = 'zh_CN';
    _defaultDpi = 300;
    _defaultFormat = 'PNG';
    _hiResEnabled = true;
    _unit = 'mm';

    await _prefs.remove(_keyLanguage);
    await _prefs.remove(_keyDefaultDpi);
    await _prefs.remove(_keyDefaultFormat);
    await _prefs.remove(_keyHiResEnabled);
    await _prefs.remove(_keyUnit);

    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import '../../data/models/capture_mode.dart';

/// 截图模式管理提供者
class CaptureModeProvider extends ChangeNotifier {
  /// 当前截图模式
  CaptureMode _currentMode = CaptureMode.region;

  /// 获取当前截图模式
  CaptureMode get currentMode => _currentMode;

  /// 设置截图模式
  void setMode(CaptureMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }
}

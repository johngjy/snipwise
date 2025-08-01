import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/hires_settings_model.dart';

/// 高清截图状态管理
class HiResCapureProvider extends ChangeNotifier {
  // 高清截图设置
  HiResSettings _settings = const HiResSettings();

  // 原始图像
  ui.Image? _sourceImage;

  // 是否正在处理中
  bool _isProcessing = false;

  // 状态消息
  String? _statusMessage;

  // 错误信息
  String? _errorMessage;

  // Getters
  HiResSettings get settings => _settings;
  ui.Image? get sourceImage => _sourceImage;
  bool get isProcessing => _isProcessing;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasSourceImage => _sourceImage != null;
  bool get hasSelectedRegion => _settings.selectedRegion != null;

  /// 设置原始图像
  Future<void> setSourceImage(ui.Image image) async {
    _sourceImage = image;
    _settings = _settings.copyWith(
      sourceScale: 1.0,
      clearSelectedRegion: true,
    );
    _clearError();
    notifyListeners();
  }

  /// 设置选择区域
  void setSelectedRegion(Rect region) {
    // 将屏幕坐标转换为原始图像坐标
    final Rect sourceRegion = _convertToSourceCoordinates(region);
    _settings = _settings.copyWith(selectedRegion: sourceRegion);
    _clearError();
    notifyListeners();
  }

  /// 清除选择区域
  void clearSelectedRegion() {
    _settings = _settings.copyWith(clearSelectedRegion: true);
    notifyListeners();
  }

  /// 更新设置
  void updateSettings(HiResSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  /// 更新源图像缩放比例
  void updateSourceScale(double scale) {
    _settings = _settings.copyWith(sourceScale: scale);
    notifyListeners();
  }

  /// 执行高清截图
  Future<Uint8List?> captureHighRes() async {
    if (_sourceImage == null) {
      _setError('没有源图像');
      return null;
    }

    if (_settings.selectedRegion == null) {
      _setError('未选择截图区域');
      return null;
    }

    try {
      _setProcessing(true);
      _setStatus('正在处理高清截图...');

      // 获取选定区域的图像数据
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final region = _settings.selectedRegion!;

      // 计算目标DPI的缩放比例
      final dpiScale = _settings.defaultDpi / 72.0; // 基准DPI为72

      // 绘制选定区域
      canvas.save();
      canvas.scale(dpiScale);
      canvas.drawImage(
        _sourceImage!,
        Offset(-region.left, -region.top),
        Paint(),
      );
      canvas.restore();

      // 创建高清图像
      final picture = recorder.endRecording();
      final width = (region.width * dpiScale).toInt();
      final height = (region.height * dpiScale).toInt();
      final image = await picture.toImage(width, height);

      // 转换为字节数据
      final format = _settings.outputFormat == 'PNG'
          ? ui.ImageByteFormat.png
          : ui.ImageByteFormat.rawRgba;

      final byteData = await image.toByteData(format: format);
      if (byteData == null) {
        throw Exception('无法获取图像数据');
      }

      _setStatus('高清截图处理完成');
      return byteData.buffer.asUint8List();
    } catch (e) {
      _setError('高清截图处理失败: ${e.toString()}');
      return null;
    } finally {
      _setProcessing(false);
    }
  }

  /// 将屏幕坐标转换为源图像坐标
  Rect _convertToSourceCoordinates(Rect screenRect) {
    if (_sourceImage == null) return screenRect;

    final double scale = _settings.sourceScale;
    return Rect.fromLTWH(
      screenRect.left / scale,
      screenRect.top / scale,
      screenRect.width / scale,
      screenRect.height / scale,
    );
  }

  // 辅助方法
  void _setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  void _setStatus(String? message) {
    _statusMessage = message;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

// import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:clipboard_watcher/clipboard_watcher.dart';

/// 剪贴板服务，处理图像和文本的复制功能
class ClipboardService with ClipboardListener {
  final Logger _logger = Logger();
  final ClipboardWatcher _clipboardWatcher = ClipboardWatcher.instance;

  /// 单例模式
  static final ClipboardService _instance = ClipboardService._internal();

  /// 获取实例
  static ClipboardService get instance => _instance;

  /// 私有构造函数
  ClipboardService._internal() {
    // 初始化剪贴板监听
    _initClipboardWatcher();
  }

  /// 创建工厂构造函数，返回单例实例
  factory ClipboardService() => _instance;

  /// 初始化剪贴板监听
  void _initClipboardWatcher() {
    _clipboardWatcher.addListener(this);

    try {
      _clipboardWatcher.start();
      _logger.d('Clipboard watcher started');
    } catch (e) {
      _logger.e('Failed to start clipboard watcher: $e');
    }
  }

  @override
  void onClipboardChanged() {
    _logger.d('Clipboard content changed');
    // 此处可以添加剪贴板变化的回调处理
  }

  /// 复制文本到剪贴板
  Future<bool> copyText(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    } catch (e) {
      _logger.e('Error copying text to clipboard: $e');
      return false;
    }
  }

  /// 复制图像到剪贴板
  ///
  /// 使用系统自带的剪贴板功能复制图像
  Future<bool> copyImage(Uint8List imageData) async {
    try {
      // 使用Flutter的Clipboard API
      // 注意：目前Flutter的标准Clipboard API不直接支持图像复制
      // 因此我们使用平台通道或保存图像并显示提示

      // 保存图像到临时文件以备其他用途
      final tempFile = await _saveImageToTemp(imageData);
      if (tempFile == null) {
        _logger.e('Failed to save image to temporary file');
        await Clipboard.setData(const ClipboardData(text: '[无法复制图片到剪贴板]'));
        return false;
      }

      // 使用平台通道实现图像复制
      try {
        // 这里可以实现特定平台的图像复制逻辑
        // 如 Android、iOS 或 macOS 通过平台通道
        const MethodChannel platform = MethodChannel('com.snipwise/clipboard');
        final bool? success = await platform.invokeMethod<bool>(
          'copyImageToClipboard',
          {'imagePath': tempFile.path},
        );

        if (success == true) {
          _logger.d('Image copied to clipboard via platform channel');
          return true;
        }
      } catch (platformError) {
        _logger.e('Platform channel error: $platformError');
        // 如果平台通道失败，继续执行下一步
      }

      // 回退：设置文本提示
      _logger.d('Falling back to text message');
      await Clipboard.setData(const ClipboardData(text: '[图片已保存，但无法直接复制到剪贴板]'));
      return true;
    } catch (e) {
      _logger.e('Error copying image to clipboard: $e');
      // 在出错的情况下，尝试降级为文本提示
      try {
        await Clipboard.setData(const ClipboardData(text: '[无法复制图片到剪贴板]'));
      } catch (_) {
        // 忽略文本复制失败
      }
      return false;
    }
  }

  /// 保存图像到临时文件
  Future<File?> _saveImageToTemp(Uint8List imageData) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          path.join(tempDir.path, 'clipboard_image_$timestamp.png');

      final file = File(filePath);
      await file.writeAsBytes(imageData);

      return file;
    } catch (e) {
      _logger.e('Error saving image to temp file: $e');
      return null;
    }
  }

  /// 清理资源
  void dispose() {
    try {
      _clipboardWatcher.removeListener(this);
      _clipboardWatcher.stop();
      _logger.d('Clipboard watcher stopped');
    } catch (e) {
      _logger.e('Error stopping clipboard watcher: $e');
    }
  }
}

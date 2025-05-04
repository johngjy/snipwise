import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';

/// 捕获的截图数据
class CapturedData {
  final String path;
  final Uint8List bytes;
  final int width;
  final int height;

  CapturedData({
    required this.path,
    required this.bytes,
    required this.width,
    required this.height,
  });
}

/// 长截图服务 - 处理滚动截图并拼接
class LongScreenshotService {
  LongScreenshotService._();
  static final LongScreenshotService _instance = LongScreenshotService._();
  static LongScreenshotService get instance => _instance;

  final _logger = Logger();

  // 暂存的截图列表
  final List<CapturedData> _screenshots = [];

  // 状态标志
  bool _isCapturing = false;

  // 记录选定的截图区域
  Rect? _selectedRegion;

  /// 执行长截图操作
  /// [maxScreens] - 最大截取屏数（防止内存溢出）
  /// [scrollDelayMs] - 每次滚动后等待的毫秒数
  Future<File?> captureLongScreenshot({
    required BuildContext context,
    int maxScreens = 20,
    int scrollDelayMs = 500,
  }) async {
    if (_isCapturing) {
      _logger.w('长截图操作已在进行中');
      return null;
    }

    try {
      _isCapturing = true;
      _screenshots.clear();

      _logger.i('开始长截图操作');

      // 1. 请求截屏权限
      if (!await _checkPermissions()) {
        _logger.e('未获得截屏权限');
        return null;
      }

      // 2. 显示引导界面，要求用户选择要截图的区域
      final captureRegion = await _showRegionSelector(context);
      if (captureRegion == null) {
        _logger.i('用户取消了区域选择');
        return null;
      }

      // 3. 提示用户准备开始滚动截图
      bool? shouldProceed = await _showStartConfirmation(context);
      if (shouldProceed != true) {
        _logger.i('用户取消了长截图操作');
        return null;
      }

      // 4. 执行多次截图（最多maxScreens次）
      for (int i = 0; i < maxScreens; i++) {
        // 4.1 捕获当前屏幕
        final screenshot = await _captureScreen();
        if (screenshot == null) {
          _logger.e('截图失败，中止长截图操作');
          break;
        }

        _screenshots.add(screenshot);
        _logger.d('已捕获第 ${i + 1} 张截图');

        // 4.2 询问是否继续滚动
        bool? shouldContinue = await _showContinuePrompt(context);
        if (shouldContinue != true) {
          _logger.i('用户结束了长截图操作，已捕获 ${i + 1} 张图片');
          break;
        }

        // 4.3 等待用户滚动并稳定
        await Future.delayed(Duration(milliseconds: scrollDelayMs));
      }

      // 5. 检查是否有足够的截图
      if (_screenshots.isEmpty) {
        _logger.w('没有捕获到任何截图');
        return null;
      }

      // 6. 拼接图片
      _logger.i('开始拼接 ${_screenshots.length} 张截图');
      final outputFile = await _stitchImages();

      if (outputFile != null) {
        _logger.i('长截图完成，已保存到: ${outputFile.path}');
        return outputFile;
      } else {
        _logger.e('图片拼接失败');
        return null;
      }
    } catch (e, stackTrace) {
      _logger.e('长截图过程中发生错误', error: e, stackTrace: stackTrace);
      return null;
    } finally {
      _isCapturing = false;
    }
  }

  /// 检查截屏权限
  Future<bool> _checkPermissions() async {
    try {
      bool isAccessAllowed = await ScreenCapturer.instance.isAccessAllowed();
      if (!isAccessAllowed) {
        // 请求权限
        try {
          await ScreenCapturer.instance.requestAccess();
          // 重新检查权限
          return await ScreenCapturer.instance.isAccessAllowed();
        } catch (e) {
          _logger.e('请求截屏权限时出错', error: e);
          return false;
        }
      }
      return true;
    } catch (e) {
      _logger.e('检查截屏权限时出错', error: e);
      return false;
    }
  }

  /// 显示区域选择器
  Future<Rect?> _showRegionSelector(BuildContext context) async {
    // 使用系统的区域选择，简化实现
    try {
      _logger.i('正在等待用户选择要截图的区域...');

      // 提示用户
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择要长截图的区域 (在需要滚动截图的内容上拖动选择)'),
          duration: Duration(seconds: 3),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      // 尝试最小化窗口，而不是隐藏窗口，这样更安全
      bool wasMinimized = false;
      try {
        await windowManager.minimize();
        wasMinimized = true;
        _logger.d('成功最小化窗口，以方便用户选择区域');
        // 添加更长的延迟，确保窗口已完全最小化
        await Future.delayed(const Duration(milliseconds: 800));
      } catch (e) {
        _logger.w('无法最小化窗口: $e');
      }

      try {
        // 确保截屏权限
        final isAccessAllowed = await ScreenCapturer.instance.isAccessAllowed();
        if (!isAccessAllowed) {
          _logger.w('截屏权限未授予，请求权限');
          await ScreenCapturer.instance.requestAccess();

          final permissionGranted =
              await ScreenCapturer.instance.isAccessAllowed();
          if (!permissionGranted) {
            _logger.e('用户拒绝了截屏权限');
            //
            await _restoreWindow(wasMinimized);
            return null;
          }
        }

        // 使用区域选择模式调用屏幕捕获
        final data = await ScreenCapturer.instance.capture(
          mode: CaptureMode.region,
          copyToClipboard: false,
          silent: true, // 设置为true以减少不必要的通知
        );

        // 恢复窗口显示
        await _restoreWindow(wasMinimized);

        if (data != null && data.imagePath != null) {
          // 解析捕获的区域
          // 尝试从图像尺寸推断区域
          double width = data.imageWidth?.toDouble() ?? 800.0;
          double height = data.imageHeight?.toDouble() ?? 600.0;

          _selectedRegion = Rect.fromLTWH(0, 0, width, height);
          return _selectedRegion;
        } else {
          _logger.e('用户取消了区域选择或选择失败');
          return null;
        }
      } catch (e) {
        _logger.e('区域选择过程中发生错误', error: e);
        await _restoreWindow(wasMinimized);
        return null;
      }
    } catch (e) {
      _logger.e('区域选择过程中发生严重错误', error: e);
      return null;
    }
  }

  /// 恢复窗口显示
  Future<void> _restoreWindow(bool wasMinimized) async {
    if (wasMinimized) {
      try {
        await windowManager.restore();
        await windowManager.focus();
        _logger.d('成功恢复窗口显示');
      } catch (e) {
        _logger.e('恢复窗口显示时出错', error: e);
      }
    }
  }

  /// 显示开始确认对话框
  Future<bool?> _showStartConfirmation(BuildContext context) async {
    if (!context.mounted) return false;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('准备开始长截图'),
        content: const Text(
            '请准备好滚动内容。点击"开始"后，对内容进行滚动，然后每次滚动后点击"继续"捕获下一部分，直到完成所有内容。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('开始'),
          ),
        ],
      ),
    );
  }

  /// 显示继续提示对话框
  Future<bool?> _showContinuePrompt(BuildContext context) async {
    if (!context.mounted) return false;
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('继续滚动截图'),
        content: Text(
            '已捕获 ${_screenshots.length} 张截图。\n\n滚动到下一部分后，点击"继续"捕获下一屏幕，或点击"完成"结束滚动截图。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('完成'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('继续'),
          ),
        ],
      ),
    );
  }

  /// 执行单次屏幕截图
  Future<CapturedData?> _captureScreen() async {
    try {
      // 1. 最小化自己的窗口
      bool wasMinimized = false;
      try {
        await windowManager.minimize();
        wasMinimized = true;
        // 等待窗口最小化
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        _logger.w('无法最小化窗口: $e');
      }

      try {
        // 2. 创建临时文件
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath =
            path.join(tempDir.path, 'long_screenshot_$timestamp.png');

        // 3. 执行截图
        final data = await ScreenCapturer.instance.capture(
          mode: CaptureMode.screen, // 全屏截图
          imagePath: filePath,
          copyToClipboard: false,
          silent: true,
        );

        // 4. 恢复窗口
        if (wasMinimized) {
          await windowManager.restore();
          await windowManager.focus();
        }

        // 5. 检查截图结果
        if (data == null || data.imagePath == null) {
          _logger.e('截图失败');
          return null;
        }

        // 6. 读取图片数据
        final file = File(data.imagePath!);
        if (!await file.exists()) {
          _logger.e('截图文件不存在: ${data.imagePath}');
          return null;
        }

        final imageBytes = await file.readAsBytes();
        if (imageBytes.isEmpty) {
          _logger.e('截图文件为空');
          return null;
        }

        // 获取图像尺寸
        final width = data.imageWidth ?? 0;
        final height = data.imageHeight ?? 0;

        _logger.d('成功捕获截图: ${width}x${height}, 大小: ${imageBytes.length} 字节');

        // 7. 创建截图数据对象
        return CapturedData(
          path: data.imagePath!,
          bytes: imageBytes,
          width: width,
          height: height,
        );
      } catch (e) {
        _logger.e('截图过程中发生错误', error: e);

        // 确保恢复窗口
        if (wasMinimized) {
          await windowManager.restore();
          await windowManager.focus();
        }

        return null;
      }
    } catch (e) {
      _logger.e('截图操作失败', error: e);
      return null;
    }
  }

  /// 拼接截图
  Future<File?> _stitchImages() async {
    try {
      if (_screenshots.isEmpty) {
        _logger.e('没有截图可供拼接');
        return null;
      }

      // 1. 获取基本信息
      int maxWidth = 0;
      int totalHeight = 0;

      // 2. 计算最大宽度和总高度
      for (final shot in _screenshots) {
        maxWidth = math.max(maxWidth, shot.width);
        totalHeight += shot.height;
      }

      // 限制最大尺寸，防止内存溢出
      if (totalHeight > 10000) {
        _logger.w('拼接图片过高，限制为10000像素');
        totalHeight = 10000;
      }

      _logger.d('拼接图片尺寸: ${maxWidth}x${totalHeight}');

      // 3. 创建新图像
      final image = img.Image(
        width: maxWidth,
        height: totalHeight,
      );

      // 4. 逐一拼接图片
      int yOffset = 0;
      for (final shot in _screenshots) {
        try {
          // 解码图片
          final shotImage = img.decodeImage(shot.bytes);
          if (shotImage == null) {
            _logger.w('无法解码图片');
            continue;
          }

          // 计算水平居中偏移
          final xOffset = (maxWidth - shot.width) ~/ 2;

          // 复制像素到新图像
          img.compositeImage(
            image,
            shotImage,
            dstX: xOffset,
            dstY: yOffset,
          );

          // 更新垂直偏移
          yOffset += shot.height;

          // 如果超出了最大高度，则停止拼接
          if (yOffset >= totalHeight) {
            _logger.w('已达到最大高度限制，停止拼接');
            break;
          }
        } catch (e) {
          _logger.e('拼接单张图片时出错', error: e);
          // 继续处理下一张，尽可能完成拼接
        }
      }

      // 5. 保存结果
      final outputDirectory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(
          outputDirectory.path, 'long_screenshot_result_$timestamp.png');

      final outputBytes = img.encodePng(image);
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(outputBytes);

      _logger.i('拼接完成，保存到: $outputPath');
      return outputFile;
    } catch (e) {
      _logger.e('拼接图片过程中发生错误', error: e);
      return null;
    }
  }
}

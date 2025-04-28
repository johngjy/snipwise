import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:window_manager/window_manager.dart';

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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请选择要长截图的区域 (在需要滚动截图的内容上拖动选择)'),
            duration: Duration(seconds: 3),
          ),
        );
      }

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
            // 恢复窗口显示
            _restoreWindow(wasMinimized);
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
          _logger.d('用户选择了截图区域: $_selectedRegion (图像尺寸: ${width}x${height})');

          return _selectedRegion;
        }

        _logger.w('用户未选择区域或取消了选择');
        return null;
      } finally {
        // 确保窗口被恢复显示
        await _restoreWindow(wasMinimized);
      }
    } catch (e) {
      _logger.e('显示区域选择器时出错', error: e);
      return null;
    }
  }

  /// 辅助方法：恢复窗口
  Future<void> _restoreWindow(bool wasMinimized) async {
    if (wasMinimized) {
      try {
        await windowManager.restore();
        await Future.delayed(const Duration(milliseconds: 300));
        await windowManager.focus();
        _logger.d('成功恢复窗口显示');
      } catch (e) {
        _logger.e('恢复窗口显示失败: $e');
        // 备用恢复方法
        try {
          await Future.delayed(const Duration(milliseconds: 500));
          await windowManager.show();
          _logger.d('使用备用方法恢复窗口显示');
        } catch (e2) {
          _logger.e('备用恢复窗口方法也失败: $e2');
        }
      }
    }
  }

  /// 显示开始确认对话框
  Future<bool?> _showStartConfirmation(BuildContext context) async {
    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('长截图准备'),
        content: const Text('1. 将在选定区域进行长截图\n'
            '2. 请准备滚动内容\n'
            '3. 每次截图后，请滚动内容并点击"继续"\n'
            '4. 完成后点击"结束并拼接"'),
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
    if (!context.mounted) return null;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('继续截图？'),
        content: Text('已截取 ${_screenshots.length} 张图片'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('结束并拼接'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('继续截取'),
          ),
        ],
      ),
    );
  }

  /// 捕获当前屏幕
  Future<CapturedData?> _captureScreen() async {
    try {
      if (_selectedRegion == null) {
        _logger.e('未选择截图区域，无法进行截图');
        return null;
      }

      // 生成临时文件路径
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imagePath =
          path.join(tempDir.path, 'long_screenshot_$timestamp.png');

      _logger.d('开始捕获屏幕 - 区域: $_selectedRegion, 保存路径: $imagePath');

      // 尝试最小化窗口以便捕获其下内容
      bool wasMinimized = false;
      try {
        await windowManager.minimize();
        wasMinimized = true;
        _logger.d('成功最小化窗口，准备截图');
        // 给UI一点时间刷新
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        _logger.w('无法最小化窗口: $e');
      }

      CapturedData? data;
      try {
        // 先检查权限
        final hasAccess = await ScreenCapturer.instance.isAccessAllowed();
        if (!hasAccess) {
          _logger.w('截图权限未授予，请求权限');
          await ScreenCapturer.instance.requestAccess();
          final permissionGranted =
              await ScreenCapturer.instance.isAccessAllowed();
          if (!permissionGranted) {
            _logger.e('用户拒绝了截屏权限');
            await _restoreWindow(wasMinimized);
            return null;
          }
        }

        // 捕获屏幕
        data = await ScreenCapturer.instance.capture(
          mode: CaptureMode.region,
          imagePath: imagePath,
          copyToClipboard: false,
          silent: true,
        );
      } finally {
        // 确保窗口被恢复显示
        await _restoreWindow(wasMinimized);
      }

      if (data == null || data.imagePath == null) {
        _logger.w('截图操作未返回有效数据');
        return null;
      }

      // 检查图像文件是否存在及有效
      try {
        final file = File(data.imagePath!);
        if (!await file.exists()) {
          _logger.e('截图文件不存在: ${data.imagePath}');
          return null;
        }

        final fileSize = await file.length();
        if (fileSize == 0) {
          _logger.e('截图文件大小为0: ${data.imagePath}');
          return null;
        }

        _logger.d('成功截取屏幕: ${data.imagePath}, 文件大小: ${fileSize}字节');
      } catch (e) {
        _logger.e('检查截图文件时出错', error: e);
        return null;
      }

      return data;
    } catch (e) {
      _logger.e('捕获屏幕时出错', error: e);
      return null;
    }
  }

  /// 拼接所有捕获的图片
  Future<File?> _stitchImages() async {
    if (_screenshots.isEmpty) return null;

    try {
      // 1. 加载所有图片
      List<img.Image> images = [];
      int totalHeight = 0;
      int width = 0;

      for (var screenshot in _screenshots) {
        if (screenshot.imagePath == null) continue;

        // 读取图片文件
        final bytes = await File(screenshot.imagePath!).readAsBytes();
        final image = img.decodeImage(bytes);

        if (image != null) {
          images.add(image);
          totalHeight += image.height;
          // 使用第一张图片的宽度作为基准
          if (width == 0) width = image.width;
        }
      }

      if (images.isEmpty) return null;

      // 2. 创建一个新的大图片
      _logger.d('创建合成图: $width x $totalHeight');
      final img.Image result = img.Image(width: width, height: totalHeight);

      // 3. 拼接图片
      int yOffset = 0;
      for (var image in images) {
        // 将图片复制到结果图片中 - 使用blit方法代替copyInto
        img.compositeImage(
          result,
          image,
          dstY: yOffset,
        );

        yOffset += image.height;
      }

      // 4. 编码并保存结果
      final outputBytes = img.encodePng(result);

      // 创建输出文件
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath =
          path.join(directory.path, 'long_screenshot_result_$timestamp.png');
      final outputFile = File(outputPath);

      // 写入文件
      await outputFile.writeAsBytes(outputBytes);
      return outputFile;
    } catch (e, stackTrace) {
      _logger.e('拼接图片时出错', error: e, stackTrace: stackTrace);
      return null;
    }
  }
}

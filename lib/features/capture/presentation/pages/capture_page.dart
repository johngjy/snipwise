import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/toolbar.dart';
import '../widgets/window_controls.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/window_service.dart';
import '../../../editor/presentation/pages/editor_page.dart';

/// 截图选择页面 - 打开软件时显示的主页面
class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  /// 是否正在加载截图
  bool _isLoadingCapture = false;

  /// 获取基于操作系统的快捷键提示文本
  String get _shortcutPromptText {
    if (Platform.isMacOS) {
      return 'Press Command + Shift + 4 to take a screenshot';
    } else if (Platform.isWindows) {
      return 'Press Win + Shift + S to take a screenshot';
    } else {
      // 默认文本，可以根据其他平台扩展
      return 'Press shortcut keys to take a screenshot';
    }
  }

  @override
  void initState() {
    super.initState();
    // 注册快捷键
    _registerShortcuts();
  }

  /// 注册键盘快捷键
  void _registerShortcuts() {
    // 注册快捷键逻辑
    // 这里可以添加全局热键监听的实现
  }

  @override
  Widget build(BuildContext context) {
    // 设置固定尺寸为1000w x 180h
    return SizedBox(
      width: 1000,
      height: 180,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(40), // 减小AppBar高度
          child: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false, // 不显示默认的返回按钮
            title: Padding(
              padding: const EdgeInsets.only(top: 5.0), // 减少顶部padding
              child: const Text(
                'SNIPWISE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryText,
                  letterSpacing: 0.5,
                  height: 1.0, // 减小行高
                ),
              ),
            ),
            centerTitle: false,
            elevation: 0.5,
            actions: [
              // 使用提取的窗口控制组件
              WindowControls(
                onMinimize: () => WindowService.instance.minimizeWindow(),
                onClose: () => WindowService.instance.closeWindow(),
              ),
            ],
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 使用提取的工具栏组件
            Toolbar(
              onCaptureRegion: _captureRegion,
              onCaptureHDScreen: _captureHDScreen,
              onCaptureVideo: _captureVideo,
              onCaptureWindow: _captureWindow,
              onDelayCapture: _delayCapture,
              onPerformOCR: _performOCR,
              onOpenImage: _openImage,
              onShowHistory: _showHistory,
            ),

            // 主内容区
            Expanded(
              child: Stack(
                children: [
                  // 提示文本居中
                  Center(
                    child: _isLoadingCapture
                        ? const CircularProgressIndicator()
                        : Text(
                            _shortcutPromptText,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 区域截图
  Future<void> _captureRegion() async {
    if (_isLoadingCapture) return;

    setState(() {
      _isLoadingCapture = true;
    });

    try {
      // 这里实现区域截图逻辑
      // ...

      // 模拟获取截图数据
      final Uint8List? capturedData = await _simulateCapture();

      // 如果成功获取截图，打开编辑器
      if (capturedData != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditorPage(imageData: capturedData),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('截图失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCapture = false;
        });
      }
    }
  }

  /// 高清屏幕截图
  Future<void> _captureHDScreen() async {
    // 实现高清屏幕截图
  }

  /// 视频录制
  Future<void> _captureVideo() async {
    // 实现视频录制
  }

  /// 窗口截图
  Future<void> _captureWindow() async {
    // 实现窗口截图
  }

  /// 延时截图
  Future<void> _delayCapture() async {
    // 实现延时截图
  }

  /// 执行OCR识别
  Future<void> _performOCR() async {
    // 实现OCR识别
  }

  /// 打开图片
  Future<void> _openImage() async {
    // 实现打开图片
  }

  /// 显示历史记录
  Future<void> _showHistory() async {
    // 实现显示历史记录
  }

  /// 模拟获取截图数据（临时方法，实际项目中应使用真实的截图API）
  Future<Uint8List?> _simulateCapture() async {
    // 模拟截图过程的延迟
    await Future.delayed(const Duration(seconds: 1));

    // 返回一个空白图像（1x1透明像素）
    // 实际项目中应替换为真实的截图逻辑
    return Uint8List.fromList([0, 0, 0, 0]);
  }
}

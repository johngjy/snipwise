import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../widgets/toolbar.dart';
import '../widgets/window_controls.dart';
import '../providers/capture_mode_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/window_service.dart';
import '../../services/capture_service.dart';
import '../../data/models/capture_result.dart';
import '../../../hires_capture/presentation/providers/hires_capture_provider.dart';
import '../../data/models/capture_mode.dart';
import '../widgets/capture_toolbar.dart';

/// 截图选择页面 - 打开软件时显示的主页面
class CapturePage extends StatefulWidget {
  const CapturePage({super.key});

  @override
  State<CapturePage> createState() => _CapturePageState();
}

class _CapturePageState extends State<CapturePage> {
  /// 是否正在加载截图
  bool _isLoadingCapture = false;

  // 日志记录器
  final _logger = Logger();

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
            title: const Padding(
              padding: EdgeInsets.only(top: 5.0), // 减少顶部padding
              child: Text(
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
            CaptureToolbar(
              onCaptureRegion: () =>
                  _startCapture(context, CaptureMode.rectangle),
              onCaptureHDScreen: () =>
                  _startCapture(context, CaptureMode.fullscreen),
              onCaptureVideo: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('视频录制功能尚未实现')),
                );
              },
              onCaptureWindow: () => _startCapture(context, CaptureMode.window),
              onDelayCapture: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('延时截图将在 3 秒后进行')),
                );
                _startCapture(context, CaptureMode.fullscreen,
                    delay: const Duration(seconds: 3));
              },
            ),

            // 主内容区
            Expanded(
              child: Stack(
                children: [
                  // 提示文本居中
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _isLoadingCapture
                            ? const CircularProgressIndicator()
                            : Text(
                                _shortcutPromptText,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isLoadingCapture
                              ? null
                              : _testScreenCapturerRegion,
                          child: const Text('测试系统区域截图功能'),
                        ),
                      ],
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

  /// 开始截图
  Future<void> _startCapture(BuildContext context, CaptureMode mode,
      {Duration? delay}) async {
    if (_isLoadingCapture) return;

    setState(() {
      _isLoadingCapture = true;
    });

    try {
      _logger.d('开始截图，模式: $mode, 延时: $delay');

      // 显示加载指示器
      if (delay != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('截图将在 ${delay.inSeconds} 秒后开始...')),
        );
      }

      // 执行截图
      final result = await CaptureService.instance.capture(mode, delay: delay);

      // 处理截图结果
      if (context.mounted) {
        await CaptureService.instance.handleCaptureResult(context, result);
      }
    } catch (e) {
      _logger.e('截图过程中出错', error: e);
      if (context.mounted) {
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
    if (_isLoadingCapture) return;

    setState(() {
      _isLoadingCapture = true;
    });

    try {
      // 获取当前选择的截图模式
      final provider = context.read<CaptureModeProvider>();
      final mode = provider.currentMode;
      final fixedSize = provider.fixedSize;

      // 获取高清截图设置
      final hiResProvider = context.read<HiResCapureProvider>();

      // 执行普通截图
      final result = await CaptureService.instance.capture(
        mode,
        fixedSize: fixedSize,
      );

      // 检查组件是否仍然挂载
      if (!mounted) return;

      if (result?.imageBytes != null) {
        // 将截图结果设置为高清截图的源图像
        final image = await decodeImageFromList(result!.imageBytes!);

        // 检查组件是否仍然挂载
        if (!mounted) return;

        await hiResProvider.setSourceImage(image);

        // 检查组件是否仍然挂载
        if (!mounted) return;

        if (result.region != null) {
          hiResProvider.setSelectedRegion(Rect.fromLTWH(
            result.region!.x,
            result.region!.y,
            result.region!.width,
            result.region!.height,
          ));
        }

        // 执行高清截图处理
        final hiResImageBytes = await hiResProvider.captureHighRes();

        // 检查组件是否仍然挂载
        if (!mounted) return;

        if (hiResImageBytes != null) {
          // 处理高清截图结果
          await CaptureService.instance.handleCaptureResult(
            context,
            CaptureResult(
              imageBytes: hiResImageBytes,
              imagePath: result.imagePath,
              region: result.region,
            ),
          );

          // 最终检查
          if (!mounted) return;

          _logger.d('高清截图处理完成');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('高清截图失败: $e')),
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
    final selectedDelay = await showDialog<Duration>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Delay'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('3 seconds'),
                onTap: () => Navigator.pop(context, const Duration(seconds: 3)),
              ),
              ListTile(
                title: const Text('5 seconds'),
                onTap: () => Navigator.pop(context, const Duration(seconds: 5)),
              ),
              ListTile(
                title: const Text('10 seconds'),
                onTap: () =>
                    Navigator.pop(context, const Duration(seconds: 10)),
              ),
            ],
          ),
        );
      },
    );

    if (selectedDelay != null) {
      // 检查组件是否仍然挂载
      if (!mounted) return;

      // 获取当前选择的截图模式
      final provider = context.read<CaptureModeProvider>();
      final mode = provider.currentMode;
      final fixedSize = provider.fixedSize;

      // 显示倒计时提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Screenshot will be taken in ${selectedDelay.inSeconds} seconds...'),
          duration: selectedDelay,
        ),
      );

      // 执行延时截图
      final result = await CaptureService.instance.capture(
        mode,
        fixedSize: fixedSize,
        delay: selectedDelay,
      );

      // 检查组件是否仍然挂载
      if (!mounted) return;

      // 处理截图结果
      await CaptureService.instance.handleCaptureResult(context, result);

      // 检查组件是否仍然挂载
      if (!mounted) return;

      _logger.d('延时截图处理完成');
    }
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

  /// 测试系统区域截图功能
  Future<void> _testScreenCapturerRegion() async {
    setState(() {
      _isLoadingCapture = true;
    });

    try {
      final success = await CaptureService.instance.testScreenCapturerRegion();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? '测试成功：系统区域截图功能正常工作！' : '测试失败：系统区域截图功能不可用。',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('测试出错: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCapture = false;
        });
      }
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for RawKeyboardListener
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import '../widgets/toolbar.dart';
import '../providers/capture_mode_provider.dart';
import '../../data/models/capture_mode.dart';
// import '../../../../core/services/window_service.dart'; // Unused import
import '../../../../core/widgets/standard_app_bar.dart'; // 导入标准化顶部栏
import '../../services/capture_service.dart';
// import '../../data/models/capture_result.dart'; // Unused import - REMOVE
// import '../../../hires_capture/presentation/providers/hires_capture_provider.dart'; // Unused import - REMOVE
// import 'package:path/path.dart' as path; // Unused import - REMOVE
// import 'package:path_provider/path_provider.dart'; // Unused import - REMOVE

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

  // FocusNode for keyboard shortcuts
  final FocusNode _focusNode = FocusNode();

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
    // Request focus for keyboard listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if mounted before requesting focus
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 使用 KeyboardListener 监听全局快捷键
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.white, // 将透明背景改为白色
        body: Column(
          children: [
            // 使用标准化顶部栏
            StandardAppBar(
              backgroundColor: const Color(0xFFF5F5F5), // 浅灰色背景
              centerTitle: true,
              forceShowWindowControls:
                  Platform.isWindows, // 在Windows上强制显示窗口控制按钮
            ),

            // 浅灰色背景的工具栏区域
            Container(
              color: const Color(0xFFF5F5F5), // 浅灰色背景
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 2.0), // 进一步减小vertical padding
              child: Align(
                alignment: Alignment.centerLeft,
                child: Consumer<CaptureModeProvider>(
                  builder: (context, provider, child) => Toolbar(
                    // 连接按钮到 _triggerCapture 或特定方法
                    onCaptureRegion: () => _triggerCapture(CaptureMode.region),
                    // 新增的回调
                    onCaptureRectangle: () =>
                        _triggerCapture(CaptureMode.rectangle),
                    onCaptureFullscreen: () =>
                        _triggerCapture(CaptureMode.fullscreen),
                    onCaptureWindow: () => _triggerCapture(CaptureMode.window),

                    // 旧/其他回调保持
                    onCaptureHDScreen: () =>
                        _triggerCapture(CaptureMode.fullscreen), // Snip 按钮仍触发全屏
                    onCaptureVideo: _captureVideo,
                    onDelayCapture: _delayCapture,
                    onPerformOCR: _performOCR,
                    onOpenImage: _openImage,
                    onShowHistory: _showHistory,
                  ),
                ),
              ),
            ),

            // 内容区域（白色背景）
            Expanded(
              child: Container(
                color: Colors.white,
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 快捷键提示文本
                    _isLoadingCapture
                        ? const CircularProgressIndicator(strokeWidth: 2.0)
                        : Text(
                            _shortcutPromptText,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 统一触发截图流程
  Future<void> _triggerCapture(CaptureMode mode, {Duration? delay}) async {
    _logger.i('>>> _triggerCapture called for mode: $mode, delay: $delay');
    if (_isLoadingCapture) {
      _logger.w('Capture already in progress, ignoring trigger for $mode.');
      return;
    }

    if (!mounted) {
      _logger.w('Context unmounted, cannot trigger capture for $mode.');
      return;
    }

    setState(() {
      _isLoadingCapture = true;
    });

    _logger.i('Triggering capture for mode: $mode with delay: $delay');

    try {
      // 调用 CaptureService 执行截图并直接导航到编辑器
      await CaptureService.instance.captureAndNavigateToEditor(context, mode);
      _logger.i('Capture completed and navigated to editor for mode: $mode');
    } catch (e, stackTrace) {
      _logger.e('Error during _triggerCapture for mode $mode',
          error: e, stackTrace: stackTrace);
      // CaptureService 内部已经处理错误显示，这里只记录
      if (mounted) {
        // 可以选择在这里显示通用错误提示
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(content: Text('截图时发生未知错误: $e')),
        // );
      }
    } finally {
      // 确保在完成后重置加载状态
      if (mounted) {
        setState(() {
          _isLoadingCapture = false;
        });
      }
    }
  }

  /// 视频录制 (保留提示)
  Future<void> _captureVideo() async {
    _logger.i('Video capture action triggered.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('视频录制功能待实现')),
      );
    }
  }

  /// 延时截图
  Future<void> _delayCapture() async {
    if (_isLoadingCapture || !mounted) return;

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

    if (selectedDelay != null && mounted) {
      final provider = context.read<CaptureModeProvider>();
      final mode = provider.currentMode;
      _logger.d(
          'Delay capture selected: ${selectedDelay.inSeconds}s for mode $mode');

      // 显示倒计时提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Screenshot will be taken in ${selectedDelay.inSeconds} seconds...'),
          duration: selectedDelay,
        ),
      );

      // 直接调用 triggerCapture，将 delay 传递给 CaptureService 处理
      await _triggerCapture(mode, delay: selectedDelay);
    }
  }

  /// 执行OCR识别 (保留提示)
  Future<void> _performOCR() async {
    _logger.i('OCR action triggered.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OCR识别功能待实现')),
      );
    }
  }

  /// 打开图片 (保留提示)
  Future<void> _openImage() async {
    _logger.i('Open image action triggered.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('打开图片功能待实现')),
      );
    }
  }

  /// 显示历史记录 (保留提示)
  Future<void> _showHistory() async {
    _logger.i('Show history action triggered.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('显示历史记录功能待实现')),
      );
    }
  }

  // Handle keyboard events
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
      final isMetaPressed =
          HardwareKeyboard.instance.isMetaPressed; // Command on macOS
      final isControlPressed =
          HardwareKeyboard.instance.isControlPressed; // Control on Win/Linux

      if (!mounted) return; // Check mount status
      final provider = context.read<CaptureModeProvider>();
      CaptureMode? targetMode;

      // Rectangle/Region capture shortcut
      if (isShiftPressed &&
          (isMetaPressed || isControlPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyR) {
        _logger.d('Rectangle/Region capture shortcut triggered');
        targetMode = CaptureMode.region; // 使用 region 模式
      }
      // Fullscreen shortcut
      else if (isShiftPressed &&
          (isMetaPressed || isControlPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyS) {
        _logger.d('Fullscreen capture shortcut triggered');
        targetMode = CaptureMode.fullscreen;
      }
      // Window shortcut
      else if (isShiftPressed &&
          (isMetaPressed || isControlPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyW) {
        _logger.d('Window capture shortcut triggered');
        targetMode = CaptureMode.window;
      }

      // 如果匹配到截图快捷键，则设置模式并触发截图
      if (targetMode != null) {
        provider.setMode(targetMode);
        _triggerCapture(targetMode); // 直接触发
      }

      // ESC key listener
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _logger.d('ESC key pressed');
        // TODO: Add cancellation logic if applicable (e.g., close preview)
      }
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for RawKeyboardListener
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart'; // 添加 window_manager 导入
import '../widgets/toolbar.dart';
import '../providers/capture_mode_provider.dart';
import '../../data/models/capture_mode.dart';
// import '../../../../core/services/window_service.dart'; // Unused import
import '../../../../core/widgets/standard_app_bar.dart'; // 导入标准化顶部栏
import '../../services/capture_service.dart';
import '../../../../core/services/window_service.dart'; // 重新导入窗口服务
import '../../services/long_screenshot_service.dart'; // 导入长截图服务
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

  // 为工具栏容器添加一个 GlobalKey，以便在渲染后测量其宽度
  final GlobalKey _toolbarContainerKey = GlobalKey();

  // 记录是否已调整过窗口大小
  bool _hasAdjustedWindowSize = false;

  // 记录调整窗口尺寸的尝试次数
  int _windowSizeAdjustAttempts = 0;
  static const int _maxWindowAdjustAttempts = 3;

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

    // 在第一帧渲染后请求焦点和调整窗口大小
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 请求焦点以便接收键盘事件
        FocusScope.of(context).requestFocus(_focusNode);

        // 调整窗口大小
        _adjustWindowSizeToToolbar();
      }
    });
  }

  /// 调整窗口大小以适应工具栏宽度
  void _adjustWindowSizeToToolbar() {
    if (!mounted || _hasAdjustedWindowSize) return;

    // 超过最大尝试次数则停止
    if (_windowSizeAdjustAttempts >= _maxWindowAdjustAttempts) {
      _logger.w('调整窗口尺寸已达最大尝试次数($_maxWindowAdjustAttempts)，使用默认尺寸');
      _hasAdjustedWindowSize = true;
      return;
    }

    _windowSizeAdjustAttempts++;

    // 延迟获取尺寸，确保布局已完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasAdjustedWindowSize) return;

      // 获取工具栏容器的 RenderBox
      final RenderBox? toolbarBox =
          _toolbarContainerKey.currentContext?.findRenderObject() as RenderBox?;

      if (toolbarBox != null && toolbarBox.hasSize) {
        // 测量工具栏宽度
        final toolbarWidth = toolbarBox.size.width;

        // 计算窗口最小宽度 = 工具栏宽度 + 左右边距 (20+20)
        final minWindowWidth = toolbarWidth + 40.0;

        _logger.d('调整窗口最小宽度: 工具栏宽度 = $toolbarWidth, 最小窗口宽度 = $minWindowWidth');

        // 先设置窗口的最小尺寸
        windowManager.setMinimumSize(Size(minWindowWidth, 180.0)).then((_) {
          // 如果当前窗口尺寸小于计算出的最小宽度，则调整窗口大小
          windowManager.getSize().then((currentSize) {
            if (currentSize.width < minWindowWidth) {
              WindowService.instance.resizeWindow(Size(minWindowWidth, 180.0));
            }

            // 标记已调整，避免重复调整
            _hasAdjustedWindowSize = true;
          });
        });
      } else {
        _logger.w(
            '无法获取工具栏渲染框，窗口尺寸未调整 (尝试 $_windowSizeAdjustAttempts/$_maxWindowAdjustAttempts)');

        // 再次尝试，但使用延迟以确保布局完成
        if (_windowSizeAdjustAttempts < _maxWindowAdjustAttempts) {
          Future.delayed(const Duration(milliseconds: 500), () {
            _adjustWindowSizeToToolbar();
          });
        }
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

            // 浅灰色背景的工具栏区域 - 添加 key
            Container(
              key: _toolbarContainerKey, // 添加 key 以便测量尺寸
              color: const Color(0xFFF5F5F5), // 浅灰色背景
              padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, vertical: 0.0), // 减小vertical padding为0
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
                    // 新增长截图回调
                    onCaptureLongScreenshot: _captureLongScreenshot,

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
                child: Center(
                  child: _isLoadingCapture
                      ? const CircularProgressIndicator(strokeWidth: 2.0)
                      : Text(
                          _shortcutPromptText,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
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

  /// 长截图功能
  Future<void> _captureLongScreenshot() async {
    _logger.i('长截图功能被触发');

    if (_isLoadingCapture || !mounted) {
      _logger.w('当前已有截图任务进行中或组件未挂载，无法执行长截图');
      return;
    }

    try {
      setState(() {
        _isLoadingCapture = true;
      });

      // 显示准备提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('准备长截图模式，请稍候...'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      // 短暂延迟，让用户有时间准备
      await Future.delayed(const Duration(seconds: 1));

      // 调用长截图服务
      final result = await LongScreenshotService.instance.captureLongScreenshot(
        context: context,
      );

      if (result != null) {
        _logger.i('长截图完成，图片路径: ${result.path}');

        // 显示成功消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('长截图已完成，正在打开编辑器...')),
          );

          // 导航到编辑器页面
          await Navigator.pushNamed(
            context,
            '/editor',
            arguments: {
              'imagePath': result.path,
              'imageBytes': await result.readAsBytes(),
            },
          );
        }
      } else {
        _logger.w('长截图操作未完成或被取消');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('长截图操作未完成'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.e('长截图过程中发生错误', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('长截图失败: ${e.toString()}'),
            duration: const Duration(seconds: 5),
          ),
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
      // Long screenshot shortcut
      else if (isShiftPressed &&
          (isMetaPressed || isControlPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyJ) {
        _logger.d('Long screenshot shortcut triggered');
        _captureLongScreenshot();
        return; // 直接返回，不需要设置模式
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

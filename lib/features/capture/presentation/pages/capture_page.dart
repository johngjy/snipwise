import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for RawKeyboardListener
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart'; // 添加 window_manager 导入
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../widgets/toolbar.dart';
import '../providers/capture_mode_provider.dart';
import '../../data/models/capture_mode.dart';
// import '../../../../core/services/window_service.dart'; // Unused import
import '../../../../core/widgets/standard_app_bar.dart'; // 导入标准化顶部栏
import '../../services/capture_service.dart';
import '../../../../core/services/window_service.dart'; // 重新导入窗口服务
import '../../services/long_screenshot_service.dart'; // 导入长截图服务
import '../widgets/capture_menu_item.dart';
import '../widgets/delay_menu.dart';
import '../widgets/video_menu.dart';
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

  /// 延时菜单的可见性
  bool _isDelayMenuVisible = false;

  /// 视频菜单的可见性
  bool _isVideoMenuVisible = false;

  /// 延时菜单的引用点
  final LayerLink _delayLayerLink = LayerLink();

  /// 视频菜单的引用点
  final LayerLink _videoLayerLink = LayerLink();

  /// 延时菜单的浮层
  OverlayEntry? _delayOverlayEntry;

  /// 视频菜单的浮层
  OverlayEntry? _videoOverlayEntry;

  // 日志记录器
  final _logger = Logger();

  // FocusNode for keyboard shortcuts
  final FocusNode _focusNode = FocusNode();

  // 为整个容器添加一个 GlobalKey，以便在渲染后测量其宽度
  final GlobalKey _containerKey = GlobalKey();

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
        _adjustWindowSize();
      }
    });
  }

  /// 调整窗口大小
  void _adjustWindowSize() {
    if (!mounted || _hasAdjustedWindowSize) return;

    // 超过最大尝试次数则停止
    if (_windowSizeAdjustAttempts >= _maxWindowAdjustAttempts) {
      _logger.w('调整窗口尺寸已达最大尝试次数($_maxWindowAdjustAttempts)，使用默认尺寸');
      _hasAdjustedWindowSize = true;
      return;
    }

    _windowSizeAdjustAttempts++;

    // 设置固定窗口大小，符合设计规格
    WindowService.instance.resizeWindow(const Size(300, 550));
    _hasAdjustedWindowSize = true;
  }

  @override
  void dispose() {
    _hideDelayMenu();
    _hideVideoMenu();
    _focusNode.dispose();
    super.dispose();
  }

  /// 显示延时菜单
  void _showDelayMenu() {
    _hideVideoMenu(); // 确保其他菜单隐藏

    if (_delayOverlayEntry != null) {
      _hideDelayMenu();
      return;
    }

    _delayOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _delayLayerLink,
          offset: const Offset(300, 0), // 在右侧显示
          child: DelayMenu(
            onDelay3Seconds: () =>
                _handleDelaySelection(const Duration(seconds: 3)),
            onDelay5Seconds: () =>
                _handleDelaySelection(const Duration(seconds: 5)),
            onDelay10Seconds: () =>
                _handleDelaySelection(const Duration(seconds: 10)),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_delayOverlayEntry!);
    setState(() {
      _isDelayMenuVisible = true;
    });
  }

  /// 显示视频菜单
  void _showVideoMenu() {
    _hideDelayMenu(); // 确保其他菜单隐藏

    if (_videoOverlayEntry != null) {
      _hideVideoMenu();
      return;
    }

    _videoOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _videoLayerLink,
          offset: const Offset(300, 0), // 在右侧显示
          child: VideoMenu(
            onVideoCapture: _captureVideo,
            onGifCapture: () {
              _hideVideoMenu();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('GIF录制功能待实现')),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_videoOverlayEntry!);
    setState(() {
      _isVideoMenuVisible = true;
    });
  }

  /// 隐藏延时菜单
  void _hideDelayMenu() {
    _delayOverlayEntry?.remove();
    _delayOverlayEntry = null;
    if (mounted) {
      setState(() {
        _isDelayMenuVisible = false;
      });
    }
  }

  /// 隐藏视频菜单
  void _hideVideoMenu() {
    _videoOverlayEntry?.remove();
    _videoOverlayEntry = null;
    if (mounted) {
      setState(() {
        _isVideoMenuVisible = false;
      });
    }
  }

  /// 处理延时选择
  void _handleDelaySelection(Duration delay) {
    _hideDelayMenu();
    if (mounted) {
      final provider = context.read<CaptureModeProvider>();
      final mode = provider.currentMode;
      _triggerCapture(mode, delay: delay);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 KeyboardListener 监听全局快捷键
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          onTap: () {
            _hideDelayMenu();
            _hideVideoMenu();
          },
          child: Column(
            key: _containerKey,
            children: [
              // 使用标准化顶部栏 - 只显示标题和控制按钮
              StandardAppBar(
                backgroundColor: Colors.white,
                centerTitle: true,
                forceShowWindowControls: true,
              ),

              // 主菜单区域
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Consumer<CaptureModeProvider>(
                    builder: (context, provider, child) => ListView(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      children: [
                        // 区域截图
                        CaptureMenuItem(
                          icon: PhosphorIcons.squaresFour(
                              PhosphorIconsStyle.light),
                          label: 'Capture area',
                          shortcut: Platform.isMacOS ? '⌘2' : 'Ctrl+2',
                          onTap: () => _triggerCapture(CaptureMode.region),
                        ),

                        // 窗口截图
                        CaptureMenuItem(
                          icon: PhosphorIcons.browser(PhosphorIconsStyle.light),
                          label: 'Window',
                          shortcut: Platform.isMacOS ? '⌘3' : 'Ctrl+3',
                          onTap: () => _triggerCapture(CaptureMode.window),
                        ),

                        // 全屏截图
                        CaptureMenuItem(
                          icon: PhosphorIcons.monitorPlay(
                              PhosphorIconsStyle.light),
                          label: 'Full Screen',
                          shortcut: Platform.isMacOS ? '⌘4' : 'Ctrl+4',
                          onTap: () => _triggerCapture(CaptureMode.fullscreen),
                        ),

                        // 视频录制
                        CompositedTransformTarget(
                          link: _videoLayerLink,
                          child: CaptureMenuItem(
                            icon: PhosphorIcons.filmStrip(
                                PhosphorIconsStyle.light),
                            label: 'Video & GIF',
                            showRightArrow: true,
                            isSelected: _isVideoMenuVisible,
                            onTap: _showVideoMenu,
                          ),
                        ),

                        // 滚动截图
                        CaptureMenuItem(
                          icon: PhosphorIcons.arrowsOutLineVertical(
                              PhosphorIconsStyle.light),
                          label: 'Scrolling Capture',
                          onTap: _captureLongScreenshot,
                        ),

                        // OCR识别
                        CaptureMenuItem(
                          icon: PhosphorIcons.textT(PhosphorIconsStyle.light),
                          label: 'OCR',
                          onTap: _performOCR,
                        ),

                        // 延时截图
                        CompositedTransformTarget(
                          link: _delayLayerLink,
                          child: CaptureMenuItem(
                            icon: PhosphorIcons.clock(PhosphorIconsStyle.light),
                            label: 'Delay',
                            showRightArrow: true,
                            isSelected: _isDelayMenuVisible,
                            onTap: _showDelayMenu,
                          ),
                        ),

                        // 打开图片
                        CaptureMenuItem(
                          icon: PhosphorIcons.folderOpen(
                              PhosphorIconsStyle.light),
                          label: 'Open',
                          onTap: _openImage,
                        ),

                        // 历史记录
                        CaptureMenuItem(
                          icon: PhosphorIcons.clockCounterClockwise(
                              PhosphorIconsStyle.light),
                          label: 'History',
                          onTap: _showHistory,
                        ),

                        // 设置
                        CaptureMenuItem(
                          icon: PhosphorIcons.gear(PhosphorIconsStyle.light),
                          label: 'Setting',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('设置功能待实现')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 底部加载指示器（如果正在加载）
              if (_isLoadingCapture)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: const CircularProgressIndicator(strokeWidth: 2.0),
                ),
            ],
          ),
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

  /// 视频录制
  Future<void> _captureVideo() async {
    _hideVideoMenu();
    _logger.i('Video capture action triggered.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('视频录制功能待实现')),
      );
    }
  }

  /// 执行OCR识别
  Future<void> _performOCR() async {
    _logger.i('OCR action triggered.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OCR识别功能待实现')),
      );
    }
  }

  /// 打开图片
  Future<void> _openImage() async {
    _logger.i('Open image action triggered.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('打开图片功能待实现')),
      );
    }
  }

  /// 显示历史记录
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

  // 处理键盘事件
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

      // 快捷键2: 区域截图
      if ((isMetaPressed || isControlPressed) &&
          event.logicalKey == LogicalKeyboardKey.digit2) {
        _logger.d('Rectangle/Region capture shortcut triggered');
        targetMode = CaptureMode.region;
      }
      // 快捷键3: 窗口截图
      else if ((isMetaPressed || isControlPressed) &&
          event.logicalKey == LogicalKeyboardKey.digit3) {
        _logger.d('Window capture shortcut triggered');
        targetMode = CaptureMode.window;
      }
      // 快捷键4: 全屏截图
      else if ((isMetaPressed || isControlPressed) &&
          event.logicalKey == LogicalKeyboardKey.digit4) {
        _logger.d('Fullscreen capture shortcut triggered');
        targetMode = CaptureMode.fullscreen;
      }
      // 长截图快捷键
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

      // ESC key - 隐藏所有菜单
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _logger.d('ESC key pressed');
        _hideDelayMenu();
        _hideVideoMenu();
      }
    }
  }
}

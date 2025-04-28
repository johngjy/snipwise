import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for RawKeyboardListener
import 'package:provider/provider.dart';
import 'package:logger/logger.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/capture_mode_provider.dart';
import '../../data/models/capture_mode.dart';
import '../../../../core/widgets/standard_app_bar.dart'; // 导入标准化顶部栏
import '../../services/capture_service.dart';
import '../../../../core/services/window_service.dart'; // 重新导入窗口服务
import '../../services/long_screenshot_service.dart'; // 导入长截图服务
import '../widgets/delay_menu.dart';
import '../widgets/video_menu.dart';
import 'dart:async';

/// 截图选择页面 - 打开软件时显示的主页面
class CapturePage extends StatefulWidget {
  final CaptureMode? initialCaptureMode;
  const CapturePage({super.key, this.initialCaptureMode});

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

  // 菜单项配置列表 - 集中管理所有菜单项
  late final List<MenuItemConfig> _menuItems;

  // Make fields final since they're only set once
  Timer? _delayMenuHideTimer; // Add timer for delay menu
  Timer? _videoMenuHideTimer; // Add timer for video menu

  /// 获取实际菜单项高度 - 从组件构建方法中提取
  double get _actualMenuItemHeight {
    // 从_buildMenuItem方法中的padding和内容高度计算
    const double verticalPadding = 4.0 * 2; // Padding.symmetric(vertical: 4.0)
    const double containerPadding = 12.0 * 2; // 内部Container的vertical: 12.0
    const double iconHeight = 22.0; // 图标高度
    // 菜单项实际高度 = 外部padding + 内部padding + 图标高度(至少内容高度)
    return verticalPadding + containerPadding + iconHeight;
  }

  /// 获取菜单项之间的间距 - 从实际构建方法中提取
  double get _actualMenuItemGap {
    // 在ListView中的padding和各菜单项之间的间距
    return 8.0; // ListView padding设置的vertical值
  }

  @override
  void initState() {
    super.initState();

    // 初始化菜单项配置
    _initMenuItems();

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

  /// 初始化菜单项配置
  void _initMenuItems() {
    _menuItems = [
      // 区域截图
      MenuItemConfig(
        icon: PhosphorIcons.squaresFour(PhosphorIconsStyle.light),
        label: 'Capture area',
        shortcut: Platform.isMacOS ? '⌘2' : 'Ctrl+2',
        onTap: () => _triggerCapture(CaptureMode.region),
      ),

      // 窗口截图
      MenuItemConfig(
        icon: PhosphorIcons.browser(PhosphorIconsStyle.light),
        label: 'Window',
        shortcut: Platform.isMacOS ? '⌘3' : 'Ctrl+3',
        onTap: () => _triggerCapture(CaptureMode.window),
      ),

      // 全屏截图
      MenuItemConfig(
        icon: PhosphorIcons.monitorPlay(PhosphorIconsStyle.light),
        label: 'Full Screen',
        shortcut: Platform.isMacOS ? '⌘4' : 'Ctrl+4',
        onTap: () => _triggerCapture(CaptureMode.fullscreen),
      ),

      // 视频录制
      MenuItemConfig(
        icon: PhosphorIcons.filmStrip(PhosphorIconsStyle.light),
        label: 'Video & GIF',
        showRightArrow: true,
        useLayerLink: true,
        layerLinkKey: 'video',
        onTap: _showVideoMenu,
      ),

      // 滚动截图
      MenuItemConfig(
        icon: PhosphorIcons.arrowsOutLineVertical(PhosphorIconsStyle.light),
        label: 'Scrolling Capture',
        onTap: _captureLongScreenshot,
      ),

      // OCR识别
      MenuItemConfig(
        icon: PhosphorIcons.textT(PhosphorIconsStyle.light),
        label: 'OCR',
        onTap: _performOCR,
      ),

      // 延时截图
      MenuItemConfig(
        icon: PhosphorIcons.clock(PhosphorIconsStyle.light),
        label: 'Delay',
        showRightArrow: true,
        useLayerLink: true,
        layerLinkKey: 'delay',
        onTap: _showDelayMenu,
      ),

      // 打开图片
      MenuItemConfig(
        icon: PhosphorIcons.folderOpen(PhosphorIconsStyle.light),
        label: 'Open',
        onTap: _openImage,
      ),

      // 历史记录
      MenuItemConfig(
        icon: PhosphorIcons.clockCounterClockwise(PhosphorIconsStyle.light),
        label: 'History',
        onTap: _showHistory,
      ),

      // 设置
      MenuItemConfig(
        icon: PhosphorIcons.gear(PhosphorIconsStyle.light),
        label: 'Setting',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('设置功能待实现')),
          );
        },
      ),
    ];
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

    // 菜单项相关尺寸计算 - 直接从实际UI元素中获取
    final int menuItemCount = _menuItems.length; // 总菜单项数量
    final double menuItemHeight = _actualMenuItemHeight; // 从组件获取实际高度
    final double menuItemGap = _actualMenuItemGap; // 从组件获取实际间距

    // 标准应用栏高度 - 从StandardAppBar组件获取
    const double topBarHeight = 30.0; // StandardAppBar设置的height值

    // 窗口内边距 - 确保有足够的上下空间，但不要过多
    const double windowPadding = 8.0; // 减小窗口内边距

    // 动态计算窗口高度 = 顶部栏 + 所有菜单项高度和间距 + 窗口内边距
    final double calculatedHeight = topBarHeight +
        (menuItemHeight * menuItemCount) +
        (menuItemGap * (menuItemCount - 1)) +
        windowPadding;

    _logger.d(
        '动态计算窗口高度: 顶部栏($topBarHeight) + 菜单项(${menuItemHeight}*$menuItemCount) + 间距(${menuItemGap}*${menuItemCount - 1}) + 内边距($windowPadding) = $calculatedHeight px');

    // 设置窗口大小，宽度保持固定，高度动态计算
    WindowService.instance.resizeWindow(Size(300, calculatedHeight));
    _hasAdjustedWindowSize = true;
  }

  @override
  void dispose() {
    _hideDelayMenu();
    _hideVideoMenu();
    _delayMenuHideTimer?.cancel(); // Cancel delay timer
    _videoMenuHideTimer?.cancel(); // Cancel video timer
    _focusNode.dispose();
    super.dispose();
  }

  /// 显示延时菜单
  void _showDelayMenu() {
    _hideVideoMenu(); // Ensure other menus are hidden

    if (_delayOverlayEntry != null) {
      _hideDelayMenu();
      return;
    }

    _delayOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 120,
        child: CompositedTransformFollower(
          link: _delayLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 40), // Position below the button
          child: MouseRegion(
            onEnter: (event) => _cancelDelayMenuHideTimer(),
            onExit: (event) => _startDelayMenuHideTimer(),
            child: DelayMenu(
              onDelaySelected: (delayInSeconds) {
                final Duration delayDuration =
                    Duration(seconds: delayInSeconds);
                _delayCapture(delayDuration);
                _hideDelayMenu();
              },
            ),
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
    _hideDelayMenu(); // Ensure other menus are hidden

    if (_videoOverlayEntry != null) {
      _hideVideoMenu();
      return;
    }

    _videoOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: 200,
        child: CompositedTransformFollower(
          link: _videoLayerLink,
          offset: const Offset(300, 0), // Position to the right
          child: MouseRegion(
            onEnter: (event) => _cancelVideoMenuHideTimer(),
            onExit: (event) => _startVideoMenuHideTimer(),
            child: VideoMenu(
              onVideoCapture: _captureVideo,
              onGifCapture: () {
                _hideVideoMenu();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('GIF recording feature pending')),
                );
              },
            ),
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
    _delayMenuHideTimer?.cancel(); // Cancel timer when hiding
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
    _videoMenuHideTimer?.cancel(); // Cancel timer when hiding
    _videoOverlayEntry?.remove();
    _videoOverlayEntry = null;
    if (mounted) {
      setState(() {
        _isVideoMenuVisible = false;
      });
    }
  }

  /// 处理延时选择
  void _delayCapture(Duration delay) {
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
        backgroundColor: const Color(0xFFEAEAEA), // 灰色背景，与设计图一致
        body: GestureDetector(
          onTap: () {
            _hideDelayMenu();
            _hideVideoMenu();
          },
          child: Column(
            key: _containerKey,
            children: [
              // 使用自定义顶部栏，实现跨平台一致的系统按钮样式
              _buildCustomTitleBar(),

              // 主菜单区域
              Expanded(
                child: _buildMenuList(),
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

  /// 构建自定义顶部栏
  Widget _buildCustomTitleBar() {
    return StandardAppBar(
      centerTitle: true,
      backgroundColor: const Color(0xFFEAEAEA),
      titleColor: Colors.grey[800]!,
    );
  }

  /// 构建菜单列表
  Widget _buildMenuList() {
    return Container(
      color: const Color(0xFFEAEAEA), // 确保背景色与父容器一致
      child: Consumer<CaptureModeProvider>(
        builder: (context, provider, child) => ListView.builder(
          // 减少顶部边距，让菜单项更紧凑
          padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 2.0),
          itemCount: _menuItems.length,
          itemBuilder: (context, index) {
            final item = _menuItems[index];

            // 处理需要使用LayerLink的特殊菜单项
            if (item.useLayerLink) {
              return CompositedTransformTarget(
                link: item.layerLinkKey == 'delay'
                    ? _delayLayerLink
                    : _videoLayerLink,
                child: _buildMenuItem(
                  icon: item.icon,
                  label: item.label,
                  showRightArrow: item.showRightArrow,
                  isSelected: item.layerLinkKey == 'delay'
                      ? _isDelayMenuVisible
                      : _isVideoMenuVisible,
                  onTap: item.onTap,
                ),
              );
            }

            // 常规菜单项
            return _buildMenuItem(
              icon: item.icon,
              label: item.label,
              shortcut: item.shortcut,
              onTap: item.onTap,
            );
          },
        ),
      ),
    );
  }

  /// 构建自定义菜单项 - 完全符合设计图风格
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? shortcut,
    bool showRightArrow = false,
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.white, // 纯白色背景
        borderRadius: BorderRadius.circular(8),
        elevation: 0.5,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            width: double.infinity,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22.0,
                  color: Colors.black87,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (shortcut != null)
                  Container(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Row(
                      children: [
                        // 向上箭头
                        Icon(
                          Icons.arrow_upward,
                          size: 12.0,
                          color: Colors.grey[600],
                        ),
                        Text(
                          shortcut,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (showRightArrow)
                  Icon(
                    Icons.chevron_right,
                    size: 22.0,
                    color: Colors.grey[600],
                  ),
              ],
            ),
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
      } else {
        setState(() {
          _isLoadingCapture = false;
        });
        return;
      }

      // 短暂延迟，让用户有时间准备
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) {
        _logger.w('Page unmounted during long screenshot preparation delay.');
        return;
      }

      // 调用长截图服务
      final result = await LongScreenshotService.instance.captureLongScreenshot(
        context: context,
      );

      if (!mounted) return;

      if (result != null) {
        _logger.i('长截图完成，图片路径: ${result.path}');

        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('长截图已完成，正在打开编辑器...')),
        );

        // Read bytes before navigation check
        final imageBytes = await result.readAsBytes();

        // Final mount check before navigation
        if (!mounted) return;

        // 导航到编辑器页面
        await Navigator.pushNamed(
          context,
          '/editor',
          arguments: {
            'imageBytes': imageBytes,
          },
        );
      } else {
        _logger.w('长截图操作未完成或被取消');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('长截图操作未完成'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.e('长截图过程中发生错误', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('长截图失败: $e'),
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

  // --- Timer Methods ---

  void _startDelayMenuHideTimer() {
    _delayMenuHideTimer?.cancel();
    _delayMenuHideTimer = Timer(const Duration(milliseconds: 300), () {
      _hideDelayMenu();
    });
  }

  void _cancelDelayMenuHideTimer() {
    _delayMenuHideTimer?.cancel();
  }

  void _startVideoMenuHideTimer() {
    _videoMenuHideTimer?.cancel();
    _videoMenuHideTimer = Timer(const Duration(milliseconds: 300), () {
      _hideVideoMenu();
    });
  }

  void _cancelVideoMenuHideTimer() {
    _videoMenuHideTimer?.cancel();
  }
}

/// 菜单项配置类 - 封装单个菜单项的所有属性
class MenuItemConfig {
  final IconData icon;
  final String label;
  final String? shortcut;
  final VoidCallback onTap;
  final bool showRightArrow;
  final bool useLayerLink;
  final String? layerLinkKey;

  const MenuItemConfig({
    required this.icon,
    required this.label,
    required this.onTap,
    this.shortcut,
    this.showRightArrow = false,
    this.useLayerLink = false,
    this.layerLinkKey,
  });
}

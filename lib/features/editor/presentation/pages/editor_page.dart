import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';

import '../../application/helpers/canvas_transform_connector.dart';
import '../../application/providers/editor_providers.dart';
import '../../application/services/new_button_menu_service.dart';
import '../../application/services/screenshot_service.dart';
import '../../application/services/window_manager_service.dart';
import '../../application/services/zoom_menu_service.dart';
import '../../application/states/canvas_transform_state.dart';
import '../../../capture/data/models/capture_mode.dart';
import '../../../capture/services/capture_service.dart';
import '../../../../core/services/window_service.dart';
import '../widgets/editor_status_bar.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/screenshot_display_area.dart';
import '../widgets/wallpaper_panel/wallpaper_panel.dart';
import '../../application/notifiers/canvas_transform_notifier.dart'
    show canvasTransformProvider, canvasScaleProvider;

/// 图片编辑页面 - 截图完成后的编辑界面
class EditorPage extends ConsumerStatefulWidget {
  /// 图片Rect(用于显示)
  final ui.Rect? logicalRect;

  /// 屏幕截图数据
  final Uint8List? imageData;

  /// 截图比例
  final double? scale;

  const EditorPage({
    super.key,
    this.logicalRect,
    this.imageData,
    this.scale,
  });

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> with WindowListener {
  final Logger _logger = Logger();
  final TransformationController _transformController =
      TransformationController();
  Size? _availableEditorSize;

  // 各种菜单和交互状态
  OverlayEntry? _tooltip;

  // 定位链接
  final LayerLink _newButtonLayerLink = LayerLink();
  final LayerLink _zoomLayerLink = LayerLink();

  // 按钮引用键
  final GlobalKey _statusBarZoomButtonKey = GlobalKey();
  final GlobalKey _toolbarZoomButtonKey = GlobalKey();

  bool _isLoading = false;
  final NewButtonMenuService _newButtonMenuService = NewButtonMenuService();

  @override
  void initState() {
    super.initState();
    // 使用WindowManagerService注册窗口监听器
    WindowManagerService().registerWindowListener(this);

    // 初始化变换控制器
    _transformController.value = Matrix4.identity();

    // 记录捕获比例，在 _loadImageData 中一并设置到状态中
    final capturedScale = widget.scale ?? 1.0;
    _logger.d('EditorPage received scale: $capturedScale');

    // 加载图像数据（会在内部设置捕获比例）
    _loadImageData();

    // 注册键盘事件处理
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    // 使用WindowManagerService注销窗口监听器
    WindowManagerService().unregisterWindowListener(this);
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _transformController.dispose();

    // 清理各种覆盖项
    _tooltip?.remove();

    // 使用服务清理资源
    ZoomMenuService().dispose();
    _newButtonMenuService.dispose();

    super.dispose();
  }

  /// 加载图像数据并调整窗口大小
  Future<void> _loadImageData() async {
    try {
      final imageData = widget.imageData;
      if (imageData == null) {
        throw Exception('Image data is null');
      }

      // 解码图像获取尺寸
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;
      final imageSize = Size(
        uiImage.width.toDouble(),
        uiImage.height.toDouble(),
      );
      final capturedScale = widget.scale ?? 1.0;

      // 确保在 post-frame 回调中更新状态，而不是在 initState 中直接修改
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // 更新状态
        ref.read(editorStateProvider.notifier).loadFullScreenshotData(
            imageData, uiImage, imageSize, capturedScale);

        _logger.d(
          'Image loaded: Physical Size=${imageSize.width}x${imageSize.height}, Scale=$capturedScale, Logical Size=${widget.logicalRect?.width}x${widget.logicalRect?.height}',
        );

        _adjustWindowSize();
      });
    } catch (e, stackTrace) {
      _logger.e('Error loading image data', error: e, stackTrace: stackTrace);
      if (mounted) {
        // 确保状态更新在 post-frame 回调中
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(editorStateProvider.notifier).setLoading(false);
        });
      }
    }
  }

  /// 基于图像尺寸和屏幕限制调整窗口大小
  void _adjustWindowSize() async {
    if (!mounted) return;

    try {
      // 使用WindowManagerService调整窗口大小
      final initialScale = await WindowManagerService().adjustWindowSize(
        ref,
        logicalRect: widget.logicalRect,
        imageData: widget.imageData,
        capturedScale: widget.scale ?? 1.0,
      );

      if (!mounted) return;

      setState(() {
        _transformController.value = Matrix4.identity();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _setZoomLevel(initialScale, fromInit: true);
        _logger.d('通过post frame callback设置初始缩放级别: $initialScale');
      });
    } catch (e, stackTrace) {
      _logger.e('调整窗口大小失败', error: e, stackTrace: stackTrace);
      if (mounted) {
        ref.read(editorStateProvider.notifier).setLoading(false);
      }
    }
  }

  /// 设置缩放级别并更新变换控制器
  void _setZoomLevel(
    double newZoom, {
    bool fromInit = false,
    Offset? focalPointOverride,
  }) {
    if (!mounted) return;

    final double clampedZoom = newZoom.clamp(
        CanvasTransformState.minZoom, CanvasTransformState.maxZoom);

    _logger.d(
        'Setting zoom level: $clampedZoom, Focal Point: $focalPointOverride');

    // Update the desired scale state
    ref.read(canvasScaleProvider.notifier).state = clampedZoom;

    // Update the general transform state
    ref.read(canvasTransformProvider.notifier).setZoomLevel(
          clampedZoom,
          focalPoint: focalPointOverride,
        );
  }

  /// 处理键盘事件
  bool _handleKeyEvent(KeyEvent event) {
    // 对于 KeyDown 和 KeyUp 事件，都更新 Modifier Keys
    final bool isShiftPressed =
        HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.shiftLeft,
            ) ||
            HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.shiftRight,
            );

    final bool isCtrlPressed = HardwareKeyboard.instance.isControlPressed;

    final bool isAltPressed =
        HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.alt,
            ) ||
            HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.altLeft,
            ) ||
            HardwareKeyboard.instance.logicalKeysPressed.contains(
              LogicalKeyboardKey.altRight,
            );

    // 无论是 KeyDown 还是 KeyUp 事件，都更新工具状态中的修饰键
    // 确保使用 post-frame 回调
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // 确保组件仍然挂载
      ref.read(toolProvider.notifier).updateModifierKeys(
            isShiftPressed: isShiftPressed,
            isCtrlPressed: isCtrlPressed,
            isAltPressed: isAltPressed,
          );
    });

    return false; // 表示此处未处理事件（允许进一步处理）
  }

  /// 显示缩放菜单 - 使用ZoomMenuService
  void _showZoomMenu(BuildContext context, {bool isFromToolbar = false}) {
    // 使用ZoomMenuService显示缩放菜单
    // 根据调用来源使用不同的按钮上下文
    BuildContext? buttonContext;
    GlobalKey buttonKey;

    if (isFromToolbar) {
      buttonContext = _toolbarZoomButtonKey.currentContext;
      buttonKey = _toolbarZoomButtonKey;
    } else {
      buttonContext = _statusBarZoomButtonKey.currentContext;
      buttonKey = _statusBarZoomButtonKey;
    }

    if (buttonContext == null) {
      _logger.e('Zoom button context is null');
      return;
    }

    // 从状态获取当前缩放级别
    final currentZoom = ref.read(canvasTransformProvider).zoomLevel;

    // 计算适配缩放级别
    final fitZoomLevel =
        (_availableEditorSize != null && widget.logicalRect != null)
            ? ScreenshotDisplayArea.calculateFitZoomLevel(
                _availableEditorSize!,
                widget.logicalRect!.size,
              )
            : 1.0;

    ZoomMenuService().showZoomMenu(
      context: context,
      ref: ref,
      buttonContext: buttonContext,
      buttonKey: buttonKey,
      availableEditorSize: _availableEditorSize,
      imageSize: widget.logicalRect?.size ??
          ref.read(editorStateProvider).originalImageSize,
      currentZoom: currentZoom,
      fitZoomLevel: fitZoomLevel,
    );
  }

  /// 处理鼠标滚轮事件
  void _handleMouseScroll(PointerScrollEvent event) {
    if (!mounted) return; // 确保组件仍然挂载

    final deltaY = event.scrollDelta.dy;
    final position = event.position;
    final kind = event.kind;

    if (kDebugMode) {
      print('Mouse Wheel Event: delta=$deltaY, position=$position, kind=$kind');
    }

    // 传递事件给CanvasTransformConnector处理
    ref.read(canvasTransformConnectorProvider).handleMouseWheelZoom(
          event,
          event.localPosition,
        );
  }

  /// 显示New按钮菜单 - 使用NewButtonMenuService
  void _showNewButtonMenu() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _newButtonMenuService.showNewButtonMenu(
        context: context,
        ref: ref,
        buttonLayerLink: _newButtonLayerLink,
        onCaptureModeSelected: _handleCaptureModeSelected,
      );
    });
  }

  /// 隐藏New按钮菜单 - 使用NewButtonMenuService
  void _hideNewButtonMenu() {
    _newButtonMenuService.startHideTimer(ref);
  }

  /// 处理截图模式选择
  void _handleCaptureModeSelected(CaptureMode mode) {
    _performCapture(mode);
  }

  /// 执行截图
  Future<void> _performCapture(CaptureMode mode) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 暂时隐藏编辑器窗口（使用minimizeWindow方法）
      await WindowService.instance.minimizeWindow();

      // 执行截图
      final result = await CaptureService.instance.capture(mode);

      // 手动延迟，确保窗口有时间最小化
      await Future.delayed(const Duration(milliseconds: 500));

      // 无法自动恢复窗口，只能依赖用户手动点击任务栏图标
      _logger.i('截图完成，请手动点击任务栏图标恢复窗口');

      if (result != null && result.hasData) {
        // 如果在同一个编辑器页面，更新图片
        if (mounted) {
          // 使用正确的方法更新编辑器状态
          if (result.imageBytes != null) {
            // 设置当前图像数据
            ref
                .read(editorStateProvider.notifier)
                .setCurrentImageData(result.imageBytes);

            // 计算图像尺寸，更新原始尺寸
            if (result.logicalRect != null) {
              final size =
                  Size(result.logicalRect!.width, result.logicalRect!.height);
              ref
                  .read(editorStateProvider.notifier)
                  .updateOriginalImageSize(size);
            } else if (result.region != null) {
              // 如果有区域信息，使用区域尺寸
              final size = Size(result.region!.width, result.region!.height);
              ref
                  .read(editorStateProvider.notifier)
                  .updateOriginalImageSize(size);
            }

            // 更新捕获比例
            ref
                .read(editorStateProvider.notifier)
                .setCapturedScale(result.scale);
          }
        }
      }
    } catch (e) {
      _logger.e('执行截图时出错', error: e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 保存图片 - 使用ScreenshotService
  Future<void> _saveImage() async {
    await ScreenshotService().saveImage(ref);
  }

  /// 复制到剪贴板 - 使用ScreenshotService
  Future<void> _copyToClipboard() async {
    final success = await ScreenshotService().copyToClipboard(ref);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? '图片已复制到剪贴板' : '复制图片失败')),
      );
    }
  }

  /// 窗口关闭事件处理 - 使用WindowManagerService
  @override
  Future<void> onWindowClose() async {
    bool shouldClose =
        await WindowManagerService().handleWindowCloseRequest(context);
    if (shouldClose) {
      await WindowManagerService().closeWindow();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 在 build 方法中监听状态变化
    return Consumer(
      builder: (context, ref, child) {
        // 获取编辑器状态
        final editorState = ref.watch(editorStateProvider);
        final isWallpaperPanelVisible =
            ref.watch(wallpaperPanelVisibleProvider);

        // 在每次构建时更新可用尺寸，使用安全的方式
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return; // 确保组件仍然挂载
          final size = MediaQuery.of(context).size;
          if (_availableEditorSize != size) {
            setState(() {
              _availableEditorSize = size;
            });
          }
        });

        // 使用Scaffold作为页面基础框架
        return Scaffold(
          backgroundColor: const Color(0xFFEEEEEE), // 浅灰背景
          body: LayoutBuilder(builder: (context, constraints) {
            // 直接在这里更新可用尺寸以供调整窗口大小使用
            _availableEditorSize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );

            return Stack(
              children: [
                // 1. 底层 - 放置壁纸画布，确保能覆盖整个界面
                Positioned.fill(
                  child: ScreenshotDisplayArea(
                    imageData: editorState.currentImageData,
                    capturedScale: editorState.capturedScale,
                    transformController: _transformController,
                    onMouseScroll: _handleMouseScroll,
                    availableSize: _availableEditorSize!,
                    imageLogicalSize: widget.logicalRect?.size ??
                        editorState.originalImageSize,
                  ),
                ),

                // 2. 上层 - 放置工具面板和UI组件
                Column(
                  children: [
                    // 工具栏区域
                    _buildToolbar(),

                    // 主内容区域
                    Expanded(
                      child: Row(
                        children: [
                          // 可选的Wallpaper设置面板
                          if (isWallpaperPanelVisible)
                            Container(
                              width: 250,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFF5F5F5).withOpacity(0.95),
                                border: Border(
                                  right: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.0,
                                  ),
                                ),
                              ),
                              child: const WallpaperPanel(),
                            ),

                          // 填充剩余空间，但不放置内容（画布内容已在底层显示）
                          const Expanded(child: SizedBox()),
                        ],
                      ),
                    ),

                    // 底部状态栏
                    _buildStatusBar(),
                  ],
                ),

                // 3. 加载指示器覆盖层
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          }),
        );
      },
    );
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return Consumer(
      builder: (context, ref, child) {
        final toolState = ref.watch(toolProvider);
        final selectedToolString =
            toolState.currentTool.toString().split('.').last;

        return EditorToolbar(
          newButtonLayerLink: _newButtonLayerLink,
          zoomButtonKey: _toolbarZoomButtonKey,
          onShowNewButtonMenu: _showNewButtonMenu,
          onHideNewButtonMenu: _hideNewButtonMenu,
          onShowSaveConfirmation: () =>
              _handleCaptureModeSelected(CaptureMode.region), // 直接调用区域截图
          onSelectTool: (tool) =>
              ref.read(toolProvider.notifier).handleToolSelect(tool),
          selectedTool: selectedToolString,
          onUndo: () => _logger.i('Undo pressed'),
          onRedo: () => _logger.i('Redo pressed'),
          onZoom: () => _showZoomMenu(context, isFromToolbar: true),
          onSaveImage: _saveImage,
          onCopyToClipboard: _copyToClipboard,
          onToggleWallpaperPanel: _toggleWallpaperPanel,
          isWallpaperPanelVisible: ref.watch(wallpaperPanelVisibleProvider),
        );
      },
    );
  }

  /// 构建状态栏
  Widget _buildStatusBar() {
    return Consumer(
      builder: (context, ref, child) {
        final canvasTransform = ref.watch(canvasTransformProvider);
        final editorState = ref.watch(editorStateProvider);

        return EditorStatusBar(
          imageData: editorState.currentImageData,
          zoomLevel: canvasTransform.zoomLevel,
          minZoom: CanvasTransformState.minZoom,
          maxZoom: CanvasTransformState.maxZoom,
          onZoomChanged: (newZoom) =>
              ref.read(canvasTransformProvider.notifier).setZoomLevel(newZoom),
          onZoomMenuTap: () => _showZoomMenu(context),
          zoomLayerLink: _zoomLayerLink,
          zoomButtonKey: _statusBarZoomButtonKey,
          onExportImage: _saveImage,
          onCopyToClipboard: _copyToClipboard,
          onCrop: () => _logger.i('Crop button pressed'),
          onOpenFileLocation: () => _logger.i('Files button pressed'),
          onDragSuccess: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('图像拖拽已启动，可拖放到目标应用程序'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          onDragError: (message) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('拖拽失败: $message'),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        );
      },
    );
  }

  /// 切换Wallpaper面板的显示状态
  void _toggleWallpaperPanel() {
    ref.read(wallpaperPanelVisibleProvider.notifier).state =
        !ref.read(wallpaperPanelVisibleProvider);
  }
}

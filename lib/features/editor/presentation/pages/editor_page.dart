import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector4;
import 'package:window_manager/window_manager.dart';

import '../../../../core/services/clipboard_service.dart';
import '../../../../core/services/window_service.dart';
import '../../../capture/data/models/capture_mode.dart';
import '../../../capture/services/capture_service.dart';
import '../../application/providers/editor_providers.dart';
import '../../application/states/tool_state.dart';
import '../../application/states/canvas_transform_state.dart';
import '../widgets/hover_menu.dart';
import '../widgets/image_viewer.dart';
import '../widgets/zoom_menu.dart';
import '../widgets/editor_status_bar.dart';
import '../widgets/editor_toolbar.dart';

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
  Uint8List? _imageData;
  ui.Image? _imageAsUiImage;
  Size? _imageSize;
  double _capturedScale = 1.0;
  static const double _minZoom = 0.1;
  static const double _maxZoom = 5.0;
  OverlayEntry? _tooltip;
  bool _isZoomMenuVisible = false;
  OverlayEntry? _zoomOverlayEntry;

  final GlobalKey _statusBarZoomButtonKey = GlobalKey();
  final GlobalKey _toolbarZoomButtonKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();
  final LayerLink _newButtonLayerLink = LayerLink();
  OverlayEntry? _newButtonOverlay;
  Timer? _newButtonHideTimer;
  Timer? _zoomMenuHideTimer;
  OverlayEntry? _zoomMenuOverlay;
  final LayerLink _zoomLayerLink = LayerLink();
  Size? _availableEditorSize;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _capturedScale = widget.scale ?? 1.0;
    _logger.d('EditorPage received scale: $_capturedScale');

    _transformController.value = Matrix4.identity();

    _loadImageData();
    // Use HardwareKeyboard
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    // Use HardwareKeyboard
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _transformController.dispose();
    _tooltip?.remove();
    _newButtonOverlay?.remove();
    _zoomMenuOverlay?.remove();
    _newButtonHideTimer?.cancel();
    _zoomMenuHideTimer?.cancel();
    super.dispose();
  }

  /// Load image data and then adjust window size
  Future<void> _loadImageData() async {
    try {
      _imageData = widget.imageData;
      if (_imageData == null) {
        throw Exception('Image data is null');
      }

      // Decode image to get dimensions
      final codec = await ui.instantiateImageCodec(_imageData!);
      final frame = await codec.getNextFrame();
      _imageAsUiImage = frame.image;
      _imageSize = Size(
        _imageAsUiImage!.width.toDouble(),
        _imageAsUiImage!.height.toDouble(),
      );
      _capturedScale = widget.scale ?? 1.0;
      _logger.d(
        'Image loaded: Physical Size=${_imageSize?.width}x${_imageSize?.height}, Scale=$_capturedScale, Logical Size=${widget.logicalRect?.width}x${widget.logicalRect?.height}',
      );
      await _adjustWindowSize();
    } catch (e, stackTrace) {
      _logger.e('Error loading image data', error: e, stackTrace: stackTrace);
      if (mounted) {
        ref.read(editorStateProvider.notifier).setLoading(false);
      }
    }
  }

  /// Adjust window size based on image dimensions and screen limits
  Future<void> _adjustWindowSize() async {
    if (!mounted) return;
    if (widget.logicalRect == null || _imageSize == null) {
      _logger.w(
        'Cannot adjust window size: Image logical rect or size is missing.',
      );
      if (mounted) {
        ref.read(editorStateProvider.notifier).setLoading(false);
      }
      return;
    }

    try {
      ref.read(editorStateProvider.notifier).setLoading(true);
      final Size imageSize = Size(
        widget.logicalRect!.width,
        widget.logicalRect!.height,
      );
      final Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final Size screenSize = primaryDisplay.visibleSize ?? primaryDisplay.size;
      _logger.d('开始使用Riverpod计算窗口尺寸，图像尺寸: $imageSize, 屏幕尺寸: $screenSize');

      ref.read(layoutProvider.notifier).initialize(screenSize);
      final initialScale = ref
          .read(editorStateProvider.notifier)
          .loadScreenshotWithLayout(_imageData, imageSize);
      _logger.d('计算得到的初始缩放比例: $initialScale');

      final editorWindowSize = ref.read(layoutProvider).editorWindowSize;
      _logger.d('计算得到的窗口尺寸: $editorWindowSize');

      await WindowService.instance.resizeWindow(editorWindowSize);
      await windowManager.center();
      _logger.d('窗口大小调整完成');

      if (mounted) {
        setState(() {
          _transformController.value = Matrix4.identity();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _setZoomLevel(initialScale, fromInit: true);
            _logger.d('通过post frame callback设置初始缩放级别: $initialScale');
          }
        });
      }
    } catch (e, stackTrace) {
      _logger.e(
        'Error adjusting window size using Riverpod',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        ref.read(editorStateProvider.notifier).setLoading(false);
      }
    }
  }

  /// Calculate the zoom level to fit the image within the available editor area.
  /// Accepts availableSize and imageLogicalSize parameters.
  double _calculateFitZoomLevel(Size availableSize, Size imageLogicalSize) {
    if (imageLogicalSize.width <= 0 ||
        imageLogicalSize.height <= 0 ||
        availableSize.width <= 0 ||
        availableSize.height <= 0) {
      _logger.w(
        'Cannot calculate fit zoom level: Invalid dimensions. Available: $availableSize, Image: $imageLogicalSize',
      );
      return 1.0; // Avoid division by zero or invalid calculation
    }

    // 记录原始尺寸信息
    _logger
        .d('计算Fit zoom - 原始尺寸: 可用区域=$availableSize, 图片逻辑尺寸=$imageLogicalSize');

    // 直接使用传入的图片原始尺寸，不再从当前缩放比例计算
    final double imageWidth = imageLogicalSize.width;
    final double imageHeight = imageLogicalSize.height;

    // 获取可用白色背景区域的尺寸
    // 考虑到顶部工具栏和底部状态栏的高度
    final double availableWidth = availableSize.width * 0.94; // 减去6%的水平边距
    final double availableHeight = availableSize.height * 0.94; // 减去6%的垂直边距

    // 计算宽高比
    final double viewAspectRatio = availableWidth / availableHeight;
    final double imageAspectRatio = imageWidth / imageHeight;

    double scale;
    // 根据宽高比决定是以宽度为基准还是以高度为基准进行缩放
    if (viewAspectRatio > imageAspectRatio) {
      // 视图比图片更宽，以高度为基准进行缩放
      scale = availableHeight / imageHeight;
      _logger.d('Fit zoom: 以高度为基准缩放 (视图更宽), scale = $scale');
    } else {
      // 视图比图片更高或宽高比接近，以宽度为基准进行缩放
      scale = availableWidth / imageWidth;
      _logger.d('Fit zoom: 以宽度为基准缩放 (视图更高), scale = $scale');
    }

    _logger.d(
      'Fit zoom计算结果: 有效区域=${availableWidth.toStringAsFixed(1)} x ${availableHeight.toStringAsFixed(1)}, 图片=$imageWidth x $imageHeight, 缩放比例=${scale.toStringAsFixed(3)}',
    );

    return scale;
  }

  /// Set zoom level and update transformation controller
  /// Optional flag 'fromInit' to potentially handle initial setup differently
  /// Optional 'focalPointOverride' allows specifying the zoom center (e.g., cursor position)
  void _setZoomLevel(
    double newZoom, {
    bool fromInit = false,
    Offset? focalPointOverride,
  }) {
    ref.read(canvasTransformProvider.notifier).setZoomLevel(
          newZoom,
          focalPoint: focalPointOverride,
        );
  }

  /// 保存编辑后的图片
  Future<void> _saveImage() async {
    if (_imageData == null) {
      _logger.w('No image data available to save');
      return;
    }

    String? filePath;
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        _logger.e('Failed to get downloads directory');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('获取下载目录失败')));
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      filePath = '${directory.path}/screenshot_$timestamp.png';
      await File(filePath).writeAsBytes(_imageData!);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('图片已保存到: $filePath')));
      _logger.d('Image saved to: $filePath');
    } catch (e) {
      _logger.e('Error saving image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存图片失败')));
    }
  }

  /// 复制图片到剪贴板
  Future<void> _copyToClipboard() async {
    if (_imageData == null) {
      _logger.w('No image data available to copy');
      return;
    }
    bool success = false;
    try {
      final ClipboardService clipboardService = ClipboardService();
      success = await clipboardService.copyImage(_imageData!);
      _logger.d('Image copied to clipboard attempt finished');
    } catch (e) {
      _logger.e('Error copying image to clipboard: $e');
      success = false;
    } finally {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            SnackBar(content: Text(success ? '图片已复制到剪贴板' : '复制图片失败')));
      }
    }
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
    ref.read(toolProvider.notifier).updateModifierKeys(
          isShiftPressed: isShiftPressed,
          isCtrlPressed: isCtrlPressed,
          isAltPressed: isAltPressed,
        );

    return false; // Indicate the event was not handled here (allow further processing)
  }

  /// 显示缩放菜单 - 使用ZoomMenu组件
  void _showZoomMenu(BuildContext context, {bool isFromToolbar = false}) {
    if (_isZoomMenuVisible) {
      _hideZoomMenu();
      return;
    }

    final List<String> zoomOptions = [
      'Fit window',
      '50%',
      '100%',
      '150%',
      '200%',
      '300%',
    ];

    // 根据调用来源使用不同的按钮上下文
    BuildContext? buttonContext;
    if (isFromToolbar) {
      buttonContext = _toolbarZoomButtonKey.currentContext;
    } else {
      buttonContext = _statusBarZoomButtonKey.currentContext;
    }

    if (buttonContext == null) {
      _logger.e('Zoom button context is null');
      return;
    }

    // 处理菜单项点击
    void handleMenuItemTap(String option) {
      switch (option) {
        case 'Fit window':
          if (_availableEditorSize != null && widget.logicalRect != null) {
            // 使用canvasTransformProvider的fitToWindow方法
            ref.read(canvasTransformProvider.notifier).fitToWindow(
                  widget.logicalRect!.size,
                  _availableEditorSize!,
                );
          } else {
            _logger.e('Cannot fit to window: Missing size information');
          }
          break;
        default:
          // 处理百分比选项
          if (option.endsWith('%')) {
            try {
              final double percentage =
                  double.parse(option.substring(0, option.length - 1)) / 100;
              _setZoomLevel(percentage);
            } catch (e) {
              _logger.e('Error parsing zoom percentage: $e');
            }
          }
      }
      _hideZoomMenu();
    }

    // 创建覆盖条目 - 定位在屏幕左下角
    _zoomOverlayEntry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        left: 15, // 左边距离
        bottom: 35, // 调整到选择器上方
        child: Material(
          color: Colors.transparent,
          elevation: 0,
          child: MouseRegion(
            onEnter: (_) {
              _zoomMenuHideTimer?.cancel();
            },
            onExit: (_) {
              _startZoomMenuHideTimer();
            },
            child: ZoomMenu(
              zoomOptions: zoomOptions,
              currentZoom: _transformController.value.getTranslation().z,
              // Pass the actual calculated fit level for comparison
              fitZoomLevel:
                  (_availableEditorSize != null && widget.logicalRect != null)
                      ? _calculateFitZoomLevel(
                          _availableEditorSize!,
                          widget.logicalRect!.size,
                        )
                      : 1.0, // Default if cannot calculate
              onOptionSelected: handleMenuItemTap,
            ),
          ),
        ),
      ),
    );

    Overlay.of(buttonContext).insert(_zoomOverlayEntry!);
    setState(() {
      _isZoomMenuVisible = true;
    });
  }

  /// 开始定时器以隐藏缩放菜单
  void _startZoomMenuHideTimer() {
    _zoomMenuHideTimer?.cancel();
    _zoomMenuHideTimer = Timer(const Duration(milliseconds: 300), () {
      _hideZoomMenu();
    });
  }

  /// 隐藏缩放菜单
  void _hideZoomMenu() {
    if (_zoomOverlayEntry != null) {
      _zoomOverlayEntry!.remove();
      _zoomOverlayEntry = null;
    }
    if (mounted) {
      setState(() {
        _isZoomMenuVisible = false;
      });
    }
  }

  /// 处理鼠标滚轮事件以进行缩放
  void _handleMouseScroll(PointerScrollEvent event) {
    // Check modifier keys using HardwareKeyboard
    if (event.kind == PointerDeviceKind.mouse &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      // Calculate new zoom level
      final double scrollDelta = event.scrollDelta.dy;
      final double zoomFactor = scrollDelta < 0 ? 1.1 : (1 / 1.1);
      final double newZoom =
          (_transformController.value.getTranslation().z * zoomFactor).clamp(
        _minZoom,
        _maxZoom,
      );

      Offset? focalPointToUse;
      final Matrix4 currentMatrix = _transformController.value;
      try {
        final Matrix4 invMatrix = Matrix4.inverted(currentMatrix);
        final Offset cursorInViewport = event.localPosition;
        final Vector4 cursorVec = Vector4(
          cursorInViewport.dx,
          cursorInViewport.dy,
          0,
          1,
        );
        final Vector4 transformedVec = invMatrix.transformed(cursorVec);
        final Offset cursorInImageCoords = Offset(
          transformedVec.x / transformedVec.w,
          transformedVec.y / transformedVec.w,
        );

        if (_imageSize != null &&
            cursorInImageCoords.dx >= 0 &&
            cursorInImageCoords.dx < _imageSize!.width &&
            cursorInImageCoords.dy >= 0 &&
            cursorInImageCoords.dy < _imageSize!.height) {
          focalPointToUse = cursorInViewport;
          _logger.d(
            'Mouse scroll zoom: Cursor inside image, using cursor focal point',
          );
        } else {
          _logger.d(
            'Mouse scroll zoom: Cursor outside image, using image center focal point',
          );
        }
      } catch (e) {
        _logger.e('Matrix inversion failed during mouse scroll: $e');
        _logger.d(
          'Mouse scroll zoom: Matrix inversion failed, using image center focal point',
        );
      }

      _setZoomLevel(newZoom, focalPointOverride: focalPointToUse);
    }
  }

  /// 处理工具选择
  void _handleToolSelect(String tool) {
    // 将字符串工具名称转换为枚举值
    EditorTool? selectedTool;
    switch (tool) {
      case 'select':
        selectedTool = EditorTool.select;
        break;
      case 'rectangle':
        selectedTool = EditorTool.rectangle;
        break;
      case 'ellipse':
        selectedTool = EditorTool.ellipse;
        break;
      case 'arrow':
        selectedTool = EditorTool.arrow;
        break;
      case 'line':
        selectedTool = EditorTool.line;
        break;
      case 'text':
        selectedTool = EditorTool.text;
        break;
      case 'blur':
        selectedTool = EditorTool.blur;
        break;
      case 'highlight':
        selectedTool = EditorTool.highlight;
        break;
      default:
        selectedTool = EditorTool.select;
    }

    // 更新工具状态
    ref.read(toolProvider.notifier).setCurrentTool(selectedTool);
  }

  @override
  Widget build(BuildContext context) {
    // 获取编辑器状态（不变的部分）
    final imageData = _imageData;

    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE), // 浅灰背景
      body: Column(
        children: [
          // 使用 Consumer 包裹工具栏，只在工具状态变化时重建
          Consumer(
            builder: (context, ref, child) {
              final toolState = ref.watch(toolProvider);
              final selectedToolString =
                  toolState.currentTool.toString().split('.').last;

              return EditorToolbar(
                newButtonLayerLink: _newButtonLayerLink,
                zoomButtonKey: _toolbarZoomButtonKey,
                onShowNewButtonMenu: _showNewButtonMenu,
                onHideNewButtonMenu: () {
                  // 使用延迟隐藏菜单，防止菜单立即消失
                  _newButtonHideTimer =
                      Timer(const Duration(milliseconds: 200), () {
                    _hideNewButtonMenu();
                  });
                },
                onShowSaveConfirmation: () =>
                    _captureWithMode(CaptureMode.region), // 直接调用区域截图
                onSelectTool: _handleToolSelect,
                selectedTool: selectedToolString,
                onUndo: () => _logger.i('Undo pressed'),
                onRedo: () => _logger.i('Redo pressed'),
                onZoom: () => _showZoomMenu(context, isFromToolbar: true),
                onSaveImage: _saveImage,
                onCopyToClipboard: _copyToClipboard,
              );
            },
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 更新可用尺寸以供调整窗口大小使用
                _availableEditorSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                // 使用 Consumer 包裹主内容区域，只在相关状态变化时重建
                return Consumer(
                  builder: (context, ref, child) {
                    // 监听画布变换状态
                    final canvasTransform = ref.watch(canvasTransformProvider);
                    final zoomLevel = canvasTransform.zoomLevel;

                    return Center(
                      child: ImageViewer(
                        imageData: imageData,
                        capturedScale: _capturedScale,
                        transformController: _transformController,
                        minZoom: CanvasTransformState.minZoom,
                        maxZoom: CanvasTransformState.maxZoom,
                        zoomLevel: zoomLevel,
                        onMouseScroll: _handleMouseScroll,
                        onZoomChanged: (scale) {
                          if (mounted && (zoomLevel - scale).abs() > 0.01) {
                            ref
                                .read(canvasTransformProvider.notifier)
                                .setZoomLevel(scale);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 使用 Consumer 包裹状态栏，只在相关状态变化时重建
          Consumer(
            builder: (context, ref, child) {
              final canvasTransform = ref.watch(canvasTransformProvider);
              return EditorStatusBar(
                imageData: imageData,
                zoomLevel: canvasTransform.zoomLevel,
                minZoom: CanvasTransformState.minZoom,
                maxZoom: CanvasTransformState.maxZoom,
                onZoomChanged: (newZoom) => ref
                    .read(canvasTransformProvider.notifier)
                    .setZoomLevel(newZoom),
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
          ),
        ],
      ),
    );
  }

  /// 显示New按钮菜单 - 使用紧凑型菜单组件
  void _showNewButtonMenu() {
    _newButtonHideTimer?.cancel();
    if (_newButtonOverlay != null) {
      _hideNewButtonMenu();
    }

    final List<HoverMenuItem> menuItems = [
      HoverMenuItem(
        icon: PhosphorIcons.square(PhosphorIconsStyle.light),
        label: 'Capture Area',
        onTap: () => _captureWithMode(CaptureMode.region),
      ),
      HoverMenuItem(
        icon: PhosphorIcons.monitorPlay(PhosphorIconsStyle.light),
        label: 'Fullscreen',
        onTap: () => _captureWithMode(CaptureMode.fullscreen),
      ),
      HoverMenuItem(
        icon: PhosphorIcons.browser(PhosphorIconsStyle.light),
        label: 'Window',
        onTap: () => _captureWithMode(CaptureMode.window),
      ),
    ];

    // "New"按钮的上下文可能不直接可用，直接创建菜单
    _newButtonOverlay = OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: _newButtonLayerLink,
        offset: const Offset(0, 26), // 精确定位到按钮底部
        // 使用Align包裹，强制其左上对齐，阻止扩展
        child: Align(
          alignment: Alignment.topLeft,
          child: MouseRegion(
            onEnter: (_) {
              _newButtonHideTimer?.cancel();
            },
            onExit: (_) {
              // 使用延迟隐藏菜单，给用户更多时间操作
              _newButtonHideTimer =
                  Timer(const Duration(milliseconds: 200), () {
                _hideNewButtonMenu();
              });
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: HoverMenu(items: menuItems),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_newButtonOverlay!);
  }

  /// 隐藏New按钮菜单
  void _hideNewButtonMenu() {
    _newButtonHideTimer?.cancel();
    _newButtonOverlay?.remove();
    _newButtonOverlay = null;
  }

  /// 使用指定的捕获模式进行截图
  void _captureWithMode(CaptureMode mode) {
    _hideNewButtonMenu();

    // 如果当前有未保存的截图，先保存然后执行新截图
    if (_imageData != null) {
      // 自动保存当前截图，然后执行新截图
      _saveImage().then((_) {
        _logger.d('已自动保存当前截图，准备执行新的截图');
        // 执行截图 - 注意：这里不需要特殊处理，_performCapture中已经包含了完整的状态重置流程
        _performCapture(mode);
      }).catchError((e) {
        _logger.e('自动保存截图失败，但仍继续执行新的截图', error: e);
        // 即使保存失败，也尝试执行截图
        _performCapture(mode);
      });
    } else {
      // 直接执行截图，不需要保存
      _performCapture(mode);
    }
  }

  /// 执行截图动作
  Future<void> _performCapture(CaptureMode mode) async {
    _logger.i('直接执行截图: $mode');
    bool captureSuccess = false;

    try {
      final result = await CaptureService.instance.capture(mode);

      if (!mounted) return;

      if (result != null && result.hasData) {
        captureSuccess = true; // Mark success

        // 获取新截图数据
        _imageData = result.imageBytes;
        _capturedScale = result.scale;

        final codec = await ui.instantiateImageCodec(_imageData!);
        final frame = await codec.getNextFrame();
        _imageAsUiImage = frame.image;
        _imageSize = Size(
          _imageAsUiImage!.width.toDouble(),
          _imageAsUiImage!.height.toDouble(),
        );

        if (!mounted) return;

        // 新增：使用更强大的状态重置方法
        await _resetStatesForNewScreenshot(
          result.imageBytes!,
          result.logicalRect?.size ?? _imageSize!,
        );
      } else {
        _logger.w('截图未返回结果或已取消');
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('截图未完成或已取消')));
      }
    } catch (e, stackTrace) {
      _logger.e('截图过程中发生错误', error: e, stackTrace: stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('截图失败: $e')));
    }
  }

  /// 为新截图重置所有相关状态并调整窗口尺寸
  /// 这是一个完整的状态重置流程，确保二次截图时UI正确更新
  Future<void> _resetStatesForNewScreenshot(
      Uint8List imageData, Size imageSize) async {
    _logger.d('开始为新截图重置状态: 图像尺寸=$imageSize');

    try {
      // 1. 首先重置所有状态（包括画布变换、标注等）
      ref.read(editorStateProvider.notifier).resetAllState();

      // 2. 获取屏幕尺寸信息
      final Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final Size screenSize = primaryDisplay.visibleSize ?? primaryDisplay.size;
      _logger.d('重置状态 - 获取屏幕尺寸: $screenSize');

      // 3. 初始化布局计算器
      ref.read(layoutProvider.notifier).initialize(screenSize);

      // 4. 加载新截图数据到编辑器状态（这会触发布局重新计算）
      final initialScale = ref
          .read(editorStateProvider.notifier)
          .loadScreenshotWithLayout(imageData, imageSize);
      _logger.d('初始缩放比例: $initialScale');

      // 5. 获取计算出的新窗口尺寸
      final editorWindowSize = ref.read(layoutProvider).editorWindowSize;
      _logger.d('新窗口尺寸: $editorWindowSize');

      // 6. 调整窗口尺寸
      await WindowService.instance.resizeWindow(editorWindowSize);
      await windowManager.center();
      _logger.d('窗口大小调整完成');

      // 7. 在下一帧中设置变换和缩放
      if (mounted) {
        setState(() {
          _transformController.value = Matrix4.identity();
        });

        // 使用 PostFrameCallback 确保UI更新后再设置缩放
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _setZoomLevel(initialScale, fromInit: true);
            _logger.d('状态重置完成，已设置初始缩放: $initialScale');

            // 打印关键状态值，用于验证
            final editorState = ref.read(editorStateProvider);
            final layoutState = ref.read(layoutProvider);
            final transformState = ref.read(canvasTransformProvider);

            _logger.d(
                '状态验证 - EditorState.imageSize: ${editorState.originalImageSize}');
            _logger.d(
                '状态验证 - LayoutState.windowSize: ${layoutState.editorWindowSize}');
            _logger.d(
                '状态验证 - CanvasTransform.scale: ${transformState.scaleFactor}');
          }
        });
      }
    } catch (e, stackTrace) {
      _logger.e('重置状态过程中发生错误', error: e, stackTrace: stackTrace);
      if (mounted) {
        ref.read(editorStateProvider.notifier).setLoading(false);
      }
    }
  }
}

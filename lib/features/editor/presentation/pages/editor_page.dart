import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector4;
import '../../../../core/services/clipboard_service.dart';
import '../../../../core/services/window_service.dart';
import '../widgets/hover_menu.dart';
import '../widgets/zoom_menu.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:math' as math;
import '../../../capture/services/capture_service.dart';
import '../../../capture/data/models/capture_mode.dart';
import '../widgets/image_viewer.dart';
import '../widgets/editor_status_bar.dart';
import '../widgets/editor_toolbar.dart';

/// 图片编辑页面 - 截图完成后的编辑界面
class EditorPage extends StatefulWidget {
  /// 图片数据
  final Uint8List? imageData;

  /// 截图时的屏幕缩放比例
  final double? scale;

  /// 逻辑矩形
  final Rect? logicalRect;

  const EditorPage({super.key, this.imageData, this.scale, this.logicalRect});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

/// 截图编辑工具类型
enum SnipToolType {
  none,
  pen,
  text,
  arrow,
  rectangle,
  highlight,
  circle,
  eraser,
  measure,
  magnifier,
  ocr,
}

class _EditorPageState extends State<EditorPage> with WindowListener {
  final Logger _logger = Logger();
  Uint8List? _imageData;
  ui.Image? _imageAsUiImage;
  Size? _imageSize;
  bool _isLoading = true;
  double _zoomLevel = 1.0;
  double _capturedScale = 1.0;
  static const double _minZoom = 0.1;
  static const double _maxZoom = 5.0;
  bool _isShiftPressed = false;
  OverlayEntry? _tooltip;
  bool _isZoomMenuVisible = false;
  OverlayEntry? _zoomOverlayEntry;

  String _selectedToolString = '';
  final GlobalKey _zoomButtonKey = GlobalKey();
  final TransformationController _transformController =
      TransformationController();
  final LayerLink _newButtonLayerLink = LayerLink();
  OverlayEntry? _newButtonOverlay;
  Timer? _newButtonHideTimer;
  Timer? _zoomMenuHideTimer;
  OverlayEntry? _zoomMenuOverlay;
  final LayerLink _zoomLayerLink = LayerLink();
  Size? _availableEditorSize;
  static const double _toolbarHeight = 38.0;
  static const double _statusBarHeight = 38.0;
  static const double _totalUIHeight = _toolbarHeight + _statusBarHeight;

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
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
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

      // Use provided scale or default to 1.0
      _capturedScale = widget.scale ?? 1.0;

      _logger.d(
        'Image loaded: Physical Size=${_imageSize?.width}x${_imageSize?.height}, Scale=$_capturedScale, Logical Size=${widget.logicalRect?.width}x${widget.logicalRect?.height}',
      );

      // Set initial zoom level based on window adjustment
      await _adjustWindowSize();
    } catch (e, stackTrace) {
      _logger.e('Error loading image data', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // 1. Get Screen Size
      final Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
      final Size screenSize = primaryDisplay.visibleSize ?? primaryDisplay.size;
      _logger.d(
        'Screen size (visible or total): ${screenSize.width}x${screenSize.height}',
      );

      // 2. Define Constraints
      const double minWidth = 900.0;
      const double minHeight = 500.0;
      final double maxWidth = screenSize.width * 0.9;
      final double maxHeight = screenSize.height * 0.9;
      _logger.d(
        'Window constraints: Min=${minWidth}x$minHeight, Max=$maxWidth.toStringAsFixed(2)x$maxHeight.toStringAsFixed(2)',
      );

      // 3. Calculate Base Size (Image + UI)
      final double baseWidth = widget.logicalRect!.width;
      final double baseHeight = widget.logicalRect!.height + _totalUIHeight;
      _logger.d(
        'Base desired size (Image + UI): ${baseWidth.toStringAsFixed(2)}x${baseHeight.toStringAsFixed(2)}',
      );

      // 4. Determine if Padding Needed (Image forces size > min)
      final bool needsPadding = baseWidth > minWidth || baseHeight > minHeight;
      if (needsPadding) {
        _logger.d('Image size exceeds minimums, padding will be added.');
      } else {
        _logger.d('Image size fits within minimums, no extra padding added.');
      }

      // 5. Calculate Potentially Padded Size
      final double paddedWidth = baseWidth + (needsPadding ? 40.0 : 0.0);
      final double paddedHeight = baseHeight + (needsPadding ? 40.0 : 0.0);
      _logger.d(
        'Size after potential padding: ${paddedWidth.toStringAsFixed(2)}x${paddedHeight.toStringAsFixed(2)}',
      );

      // 6. Apply Minimums to Padded Size
      double targetWidth = max(minWidth, paddedWidth);
      double targetHeight = max(minHeight, paddedHeight);
      _logger.d(
        'Size after applying minimums: ${targetWidth.toStringAsFixed(2)}x${targetHeight.toStringAsFixed(2)}',
      );

      // 7. Check and Apply Maximums, Determine if Fit is Needed
      bool needsFit = false;
      double finalWidth = targetWidth;
      double finalHeight = targetHeight;

      if (targetWidth > maxWidth) {
        finalWidth = maxWidth;
        needsFit = true;
        _logger.i(
          'Width exceeds max limit ($maxWidth). Setting width to $finalWidth and enabling fit.',
        );
      }
      if (targetHeight > maxHeight) {
        finalHeight = maxHeight;
        needsFit = true;
        _logger.i(
          'Height exceeds max limit ($maxHeight). Setting height to $finalHeight and enabling fit.',
        );
      }
      _logger.d(
        'Final target window size: ${finalWidth.toStringAsFixed(2)}x${finalHeight.toStringAsFixed(2)}',
      );

      // 8. Resize Window
      await WindowService.instance.resizeWindow(Size(finalWidth, finalHeight));
      await windowManager.center();
      _logger.d('Window resize requested to $finalWidth x $finalHeight');

      // 9. Set Initial Zoom (after potential resize)
      double initialZoom;
      if (needsFit) {
        _logger.d(
          'Calculating fit zoom level because window size was constrained.',
        );
        // Calculate available editor size based on the FINAL window size
        final Size finalEditorSize = Size(
          finalWidth,
          finalHeight - _totalUIHeight,
        );
        initialZoom = _calculateFitZoomLevel(
          finalEditorSize,
          widget.logicalRect!.size,
        );
        _logger.i(
          'Fit needed. Setting initial zoom to ${initialZoom.toStringAsFixed(3)}',
        );
      } else {
        initialZoom = 1.0; // 100% zoom
        _logger.d('No fit needed. Setting initial zoom to 100%.');
      }

      // Set loading to false *before* setting zoom state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Use addPostFrameCallback to set zoom after layout is updated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setZoomLevel(initialZoom, fromInit: true);
          _logger.d('Initial zoom level set via post frame callback.');
        }
      });
    } catch (e, stackTrace) {
      _logger.e(
        'Error adjusting window size',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

    final double availableWidth = availableSize.width;
    final double availableHeight = availableSize.height;
    final double imageWidth = imageLogicalSize.width;
    final double imageHeight = imageLogicalSize.height;

    // Calculate aspect ratios
    final double viewAspectRatio = availableWidth / availableHeight;
    final double imageAspectRatio = imageWidth / imageHeight;

    double scale;
    // Compare aspect ratios to determine whether to fit width or height
    if (viewAspectRatio > imageAspectRatio) {
      // View is wider than image, fit height
      scale = availableHeight / imageHeight;
    } else {
      // View is taller than image (or aspect ratios are equal), fit width
      scale = availableWidth / imageWidth;
    }

    _logger.d(
      'Calculated Fit Zoom: available=$availableWidth x $availableHeight, image=$imageWidth x $imageHeight, scale=$scale',
    );
    // 添加一个小边距，避免完全贴边
    return scale * 0.98;
  }

  /// Set zoom level and update transformation controller
  /// Optional flag 'fromInit' to potentially handle initial setup differently
  /// Optional 'focalPointOverride' allows specifying the zoom center (e.g., cursor position)
  void _setZoomLevel(
    double newZoom, {
    bool fromInit = false,
    Offset? focalPointOverride,
  }) {
    if (!mounted) return;

    final clampedZoom = newZoom.clamp(_minZoom, _maxZoom);
    final double currentZoom = _zoomLevel;

    if (clampedZoom == currentZoom || clampedZoom <= 0) {
      return;
    }

    final Matrix4 currentMatrix = _transformController.value.clone();
    final double scaleDelta = clampedZoom / currentZoom;

    Matrix4 targetMatrix;

    if (focalPointOverride != null) {
      // --- Method 1: Scale around the provided focal point (cursor) ---
      final Offset P = focalPointOverride;
      final Matrix4 translationToFocal = Matrix4.identity()
        ..translate(P.dx, P.dy);
      final Matrix4 scale = Matrix4.identity()..scale(scaleDelta, scaleDelta);
      final Matrix4 translationBackFromFocal = Matrix4.identity()
        ..translate(-P.dx, -P.dy);
      targetMatrix =
          translationToFocal * scale * translationBackFromFocal * currentMatrix;
      _logger.d('Zooming around viewport point: $P with delta $scaleDelta');
    } else {
      // --- Method 2: 修复 - 使用视口中心作为缩放点而不是图片中心 ---
      final Size currentEditorSize =
          _availableEditorSize ?? MediaQuery.of(context).size;

      if (currentEditorSize.width <= 0 || currentEditorSize.height <= 0) {
        _logger.w(
          "Cannot set zoom level: Invalid editor size $currentEditorSize",
        );
        return;
      }

      // 直接使用视口中心作为缩放点
      final Offset viewportCenter = Offset(
        currentEditorSize.width / 2,
        currentEditorSize.height / 2,
      );

      _logger.d(
        'Zooming around viewport center: $viewportCenter with delta $scaleDelta',
      );

      final Matrix4 translationToCenter = Matrix4.identity()
        ..translate(viewportCenter.dx, viewportCenter.dy);
      final Matrix4 scaleMatrix = Matrix4.identity()
        ..scale(scaleDelta, scaleDelta);
      final Matrix4 translationBackFromCenter = Matrix4.identity()
        ..translate(-viewportCenter.dx, -viewportCenter.dy);

      targetMatrix = translationToCenter *
          scaleMatrix *
          translationBackFromCenter *
          currentMatrix;
    }

    _transformController.value = targetMatrix;

    setState(() {
      _zoomLevel = clampedZoom;
      _logger.d('Zoom level set to: ${_zoomLevel.toStringAsFixed(3)}');
    });

    _keepContentInView();
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
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      // Check for Shift key state using HardwareKeyboard
      final bool currentShiftState =
          HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.shiftLeft,
              ) ||
              HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.shiftRight,
              );

      if (currentShiftState != _isShiftPressed) {
        setState(() {
          _isShiftPressed = currentShiftState;
        });
      }
    } else if (event is KeyUpEvent) {
      // Check for Shift key state on KeyUp as well
      final bool currentShiftState =
          HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.shiftLeft,
              ) ||
              HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.shiftRight,
              );

      if (currentShiftState != _isShiftPressed) {
        setState(() {
          _isShiftPressed = currentShiftState;
        });
      }
    }
    return false; // Indicate the event was not handled here (allow further processing)
  }

  /// 显示缩放菜单 - 使用ZoomMenu组件
  void _showZoomMenu(BuildContext context) {
    // 如果菜单已显示，则隐藏
    if (_isZoomMenuVisible) {
      _hideZoomMenu();
      return;
    }

    // 处理菜单项选择
    void handleMenuItemTap(String option) {
      if (option == 'Fit window') {
        // Ensure _availableEditorSize is available before calculating
        if (_availableEditorSize != null && widget.logicalRect != null) {
          _setZoomLevel(
            _calculateFitZoomLevel(
              _availableEditorSize!,
              widget.logicalRect!.size,
            ),
          );
        } else {
          _logger.w(
            'Cannot calculate fit zoom level from menu: Missing available editor size or logical rect.',
          );
          // Optionally provide feedback or default behavior
        }
      } else {
        final percentage = double.parse(option.replaceAll('%', '')) / 100;
        _setZoomLevel(percentage);
      }
      _hideZoomMenu();
    }

    // 创建缩放选项列表
    final List<String> zoomOptions = [
      'Fit window',
      '100%',
      '200%',
    ]; // Updated list

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
              currentZoom: _zoomLevel,
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

    Overlay.of(context).insert(_zoomOverlayEntry!);
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
      final double newZoom = (_zoomLevel * zoomFactor).clamp(
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

  /// 设置当前工具
  void _selectTool(String tool) {
    setState(() {
      _selectedToolString = tool;
    });
    _logger.i('Selected tool: $tool');
  }

  // Action methods
  void _handleUndo() => _logger.i('Undo action triggered');
  void _handleRedo() => _logger.i('Redo action triggered');
  void _handleZoom() {
    // 通过按钮触发缩放菜单
    final BuildContext? context = _zoomButtonKey.currentContext;
    if (context != null) {
      _showZoomMenu(context);
    } else {
      _logger.w('缩放按钮上下文不可用');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEEEEE), // 浅灰背景
      body: Column(
        children: [
          // 工具栏 - 新设计 (图2样式)
          EditorToolbar(
            newButtonLayerLink: _newButtonLayerLink,
            zoomButtonKey: _zoomButtonKey,
            onShowNewButtonMenu: _showNewButtonMenu,
            onHideNewButtonMenu: _startNewButtonHideTimer,
            onShowSaveConfirmation: _showSaveConfirmationDialog,
            onSelectTool: _selectTool,
            selectedTool: _selectedToolString,
            onUndo: _handleUndo,
            onRedo: _handleRedo,
            onZoom: _handleZoom,
            onSaveImage: _saveImage,
            onCopyToClipboard: _copyToClipboard,
          ),

          // 主要内容区域 - 使用ImageViewer组件
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 更新可用尺寸以供调整窗口大小使用
                _availableEditorSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return Center(
                  child: ImageViewer(
                    imageData: _imageData,
                    capturedScale: _capturedScale,
                    transformController: _transformController,
                    minZoom: _minZoom,
                    maxZoom: _maxZoom,
                    zoomLevel: _zoomLevel,
                    onMouseScroll: _handleMouseScroll,
                    onZoomChanged: (scale) {
                      if (mounted && (_zoomLevel - scale).abs() > 0.01) {
                        setState(() {
                          _zoomLevel = scale;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // 底部状态栏 - macOS风格设计
          EditorStatusBar(
            imageData: _imageData,
            zoomLevel: _zoomLevel,
            minZoom: _minZoom,
            maxZoom: _maxZoom,
            onZoomChanged: _setZoomLevel,
            onZoomMenuTap: () => _showZoomMenu(context),
            zoomLayerLink: _zoomLayerLink,
            zoomButtonKey: _zoomButtonKey,
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
            onExit: (_) => _startNewButtonHideTimer(),
            child: HoverMenu(items: menuItems),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_newButtonOverlay!);
  }

  /// 开始定时器以隐藏New按钮菜单
  void _startNewButtonHideTimer() {
    _newButtonHideTimer?.cancel();
    _newButtonHideTimer = Timer(const Duration(milliseconds: 300), () {
      _hideNewButtonMenu();
    });
  }

  /// 隐藏New按钮菜单
  void _hideNewButtonMenu() {
    _newButtonOverlay?.remove();
    _newButtonOverlay = null;
    if (mounted) {
      // setState 内部为空，直接删除
    }
  }

  /// 使用指定的捕获模式进行截图
  void _captureWithMode(CaptureMode mode) {
    _hideNewButtonMenu();

    // 如果当前有未保存更改，先询问用户是否保存
    if (_imageData != null) {
      _showSaveConfirmationDialog(mode);
    } else {
      // 直接执行截图，不需要保存确认
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
        setState(() {
          _isLoading = true;
        });

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
        await _adjustWindowSize();
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
    } finally {
      if (!captureSuccess && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 显示保存确认对话框
  void _showSaveConfirmationDialog([CaptureMode? captureMode]) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Current Screenshot'),
          content: const Text(
            'Would you like to save your current screenshot before taking a new one?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Discard'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ).then((saveFirst) async {
      if (!mounted) return;

      if (saveFirst ?? false) {
        await _saveImage();
      }

      if (!mounted) return;
      if (captureMode != null) {
        await _performCapture(captureMode);
      } else {
        await _performCapture(CaptureMode.region); // 默认使用区域截图
      }
    });
  }

  void _keepContentInView() {
    if (!mounted || _imageSize == null || _availableEditorSize == null) return;

    final Matrix4 currentMatrix = _transformController.value;
    final Rect imageBoundsLocal = Rect.fromLTWH(
      0,
      0,
      _imageSize!.width,
      _imageSize!.height,
    );
    final Rect transformedBounds = transformRect(
      currentMatrix,
      imageBoundsLocal,
    );

    final Size viewportSize = _availableEditorSize!;
    double dx = 0;
    double dy = 0;

    // Correct position if image bounds exceed viewport
    if (transformedBounds.width > viewportSize.width) {
      if (transformedBounds.left > 0) {
        dx = -transformedBounds.left;
      }
      if (transformedBounds.right < viewportSize.width) {
        dx = viewportSize.width - transformedBounds.right;
      }
    } else {
      // Center horizontally if smaller than viewport
      dx = (viewportSize.width - transformedBounds.width) / 2 -
          transformedBounds.left;
    }

    if (transformedBounds.height > viewportSize.height) {
      if (transformedBounds.top > 0) {
        dy = -transformedBounds.top;
      }
      if (transformedBounds.bottom < viewportSize.height) {
        dy = viewportSize.height - transformedBounds.bottom;
      }
    } else {
      // Center vertically if smaller than viewport
      dy = (viewportSize.height - transformedBounds.height) / 2 -
          transformedBounds.top;
    }

    if (dx.abs() > 1e-3 || dy.abs() > 1e-3) {
      // Add tolerance
      _logger.d(
        'Applying boundary correction: dx=${dx.toStringAsFixed(2)}, dy=${dy.toStringAsFixed(2)}',
      );
      // Use post-frame callback to avoid setState during build/layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _transformController.value = currentMatrix.clone()..translate(dx, dy);
        }
      });
    }
  }

  // Helper function to transform a Rect using a Matrix4
  Rect transformRect(Matrix4 matrix, Rect rect) {
    // Transform corner points using Vector4
    final Vector4 topLeft = matrix.transformed(
      Vector4(rect.left, rect.top, 0, 1),
    );
    final Vector4 topRight = matrix.transformed(
      Vector4(rect.right, rect.top, 0, 1),
    );
    final Vector4 bottomLeft = matrix.transformed(
      Vector4(rect.left, rect.bottom, 0, 1),
    );
    final Vector4 bottomRight = matrix.transformed(
      Vector4(rect.right, rect.bottom, 0, 1),
    );

    // Normalize W component
    final double topLeftX = topLeft.x / topLeft.w;
    final double topLeftY = topLeft.y / topLeft.w;
    final double topRightX = topRight.x / topRight.w;
    final double topRightY = topRight.y / topRight.w;
    final double bottomLeftX = bottomLeft.x / bottomLeft.w;
    final double bottomLeftY = bottomLeft.y / bottomLeft.w;
    final double bottomRightX = bottomRight.x / bottomRight.w;
    final double bottomRightY = bottomRight.y / bottomRight.w;

    final double minX = math.min(
      math.min(topLeftX, topRightX),
      math.min(bottomLeftX, bottomRightX),
    );
    final double maxX = math.max(
      math.max(topLeftX, topRightX),
      math.max(bottomLeftX, bottomRightX),
    );
    final double minY = math.min(
      math.min(topLeftY, topRightY),
      math.min(bottomLeftY, bottomRightY),
    );
    final double maxY = math.max(
      math.max(topLeftY, topRightY),
      math.max(bottomLeftY, bottomRightY),
    );

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:window_manager/window_manager.dart';

import '../../application/core/editor_state_core.dart';
import '../../application/providers/state_providers.dart';
import '../../application/states/canvas_state.dart';
import '../../application/states/wallpaper_state.dart';
import '../widgets/canvas_container.dart';
import '../widgets/editor_status_bar.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/wallpaper_panel.dart';

/// 图片编辑页面
/// 新版编辑器的主页面，使用统一状态管理
class NewEditorPage extends ConsumerStatefulWidget {
  /// 图片数据
  final Uint8List? imageData;

  /// 图片逻辑尺寸
  final Size? imageSize;

  /// 捕获比例
  final double? scale;

  /// 构造函数
  const NewEditorPage({
    Key? key,
    this.imageData,
    this.imageSize,
    this.scale,
  }) : super(key: key);

  @override
  ConsumerState<NewEditorPage> createState() => _NewEditorPageState();
}

class _NewEditorPageState extends ConsumerState<NewEditorPage>
    with WindowListener {
  // 窗口服务
  final windowManager = WindowManager.instance;

  // 日志记录器
  final _logger = Logger();

  // 窗口当前状态
  bool _isMinimized = false;
  bool _isFullScreen = false;
  bool _isMaximized = false;
  bool _isLoading = true;
  bool _isInResizeMode = false;

  // 可用空间大小 - 考虑到工具栏和状态栏的高度
  Size? _availableEditorSize;

  // 层链接和按钮Key - 用于菜单定位
  final LayerLink _newButtonLayerLink = LayerLink();
  final LayerLink _statusBarZoomLayerLink = LayerLink();
  final GlobalKey _toolbarZoomButtonKey = GlobalKey();
  final GlobalKey _statusBarZoomButtonKey = GlobalKey();

  // 跟踪手动调整窗口大小
  bool _userHasManuallyResized = false;

  @override
  void initState() {
    super.initState();

    // 注册窗口监听器
    windowManager.addListener(this);

    // 记录捕获比例
    final capturedScale = widget.scale ?? 1.0;
    _logger.d('NewEditorPage: 初始化，捕获比例=$capturedScale');
    _logger.d('NewEditorPage: imageData是否为空: ${widget.imageData == null}');
    if (widget.imageData != null) {
      _logger.d('NewEditorPage: imageData大小: ${widget.imageData!.length} 字节');
    }
    _logger.d('NewEditorPage: imageSize: ${widget.imageSize}');

    // 使用microtask确保在build完成后加载图像数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _logger.d('NewEditorPage: 界面构建完成，开始加载图像数据');
        // 加载图像数据
        _loadImageData();
      }
    });
  }

  @override
  void dispose() {
    // 移除窗口监听器
    windowManager.removeListener(this);
    super.dispose();
  }

  /// 加载图像数据
  Future<void> _loadImageData() async {
    _logger.d('NewEditorPage: 开始加载图像数据');

    try {
      final imageData = widget.imageData;
      if (imageData == null) {
        _logger.e('NewEditorPage: 图像数据为空');
        throw Exception('图像数据为空');
      }

      if (imageData.isEmpty) {
        _logger.e('NewEditorPage: 图像数据长度为0');
        throw Exception('图像数据长度为0，无效的图像');
      }

      _logger.d('NewEditorPage: 图像数据有效，长度为 ${imageData.length} 字节');

      // 先设置加载状态，提供视觉反馈
      _logger.d('NewEditorPage: 设置加载状态为true');
      // 使用Future.microtask确保在widget树构建完成后更新状态
      await Future.microtask(() {
        ref.read(canvasProvider.notifier).setLoading(true);
      });

      // 解码图像获取尺寸
      _logger.d('NewEditorPage: 开始解码图像');
      ui.Image? uiImage;
      Size imageSize;

      try {
        _logger.d('NewEditorPage: 使用instantiateImageCodec解码图像...');
        final codec = await ui.instantiateImageCodec(imageData);
        _logger.d('NewEditorPage: 解码成功，获取第一帧...');
        final frame = await codec.getNextFrame();
        uiImage = frame.image;
        _logger
            .d('NewEditorPage: 获取到图像帧，尺寸: ${uiImage.width}x${uiImage.height}');

        imageSize = widget.imageSize ??
            Size(
              uiImage.width.toDouble(),
              uiImage.height.toDouble(),
            );

        _logger.d(
            'NewEditorPage: 图像解码完成, 尺寸=${imageSize.width}x${imageSize.height}, 比例=${widget.scale ?? 1.0}');
      } catch (decodeError) {
        _logger.e('NewEditorPage: 图像解码失败', error: decodeError);
        throw Exception('图像解码失败: $decodeError');
      }

      final capturedScale = widget.scale ?? 1.0;

      // 如果组件已销毁，直接返回
      if (!mounted) {
        _logger.w('NewEditorPage: 组件已销毁，取消加载');
        // 释放资源
        uiImage?.dispose();
        return;
      }

      // 获取核心状态管理器
      _logger.d('NewEditorPage: 获取editorStateCoreProvider');
      try {
        // 使用Future.microtask确保在widget树构建完成后获取Provider
        final editorCore =
            await Future.microtask(() => ref.read(editorStateCoreProvider));
        _logger.d('NewEditorPage: 成功获取editorCore');

        // 直接加载截图数据，不延迟到下一帧
        _logger.d('NewEditorPage: 调用editorCore.loadScreenshot');
        final initialScaleFactor = await editorCore.loadScreenshot(
          imageData,
          imageSize,
          capturedScale: capturedScale,
          uiImage: uiImage,
        );

        _logger.d(
            'NewEditorPage: 图像加载完成，尺寸=${imageSize.width}x${imageSize.height}，初始缩放因子=$initialScaleFactor');
      } catch (providerError) {
        _logger.e('NewEditorPage: 获取或使用editorCore时出错', error: providerError);
        throw providerError; // 重新抛出，以便被外层catch捕获
      } finally {
        // 确保释放uiImage资源，避免内存泄漏
        // 注意：uiImage已经传递给Provider，可能已经被其他地方使用，慎重考虑是否需要在这里释放
        // uiImage?.dispose();
      }
    } catch (e, stackTrace) {
      _logger.e('NewEditorPage: 加载图像失败', error: e, stackTrace: stackTrace);
      // 确保即使出错也取消加载状态
      if (mounted) {
        // 使用Future.microtask确保在widget树构建完成后更新状态
        await Future.microtask(() {
          ref.read(canvasProvider.notifier).setLoading(false);
        });

        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('加载图像失败: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10), // 延长错误显示时间
          ),
        );
      }
    }
  }

  /// 处理新截图
  Future<void> handleNewScreenshot(Uint8List imageData, Size size,
      {double capturedScale = 1.0, ui.Image? uiImage}) async {
    _logger.d('NewEditorPage: 处理新截图，尺寸=${size.width}x${size.height}');

    try {
      // 设置加载状态为true
      await Future.microtask(() {
        ref.read(canvasProvider.notifier).setLoading(true);
      });
      _logger.d('NewEditorPage: 设置加载状态为true');

      // 如果没有传入uiImage，则解码获取
      if (uiImage == null) {
        _logger.d('NewEditorPage: 开始解码图像');
        try {
          final codec = await ui.instantiateImageCodec(imageData);
          final frame = await codec.getNextFrame();
          uiImage = frame.image;
          _logger.d('NewEditorPage: 图像解码完成');
        } catch (decodeError) {
          _logger.e('NewEditorPage: 图像解码失败', error: decodeError);
          // 继续执行，uiImage将保持为null
        }
      }

      // 使用Future.microtask确保在widget树构建完成后获取Provider
      final editorCore =
          await Future.microtask(() => ref.read(editorStateCoreProvider));
      _logger.d('NewEditorPage: 成功获取editorCore');

      // 对于后续截图，使用handleSubsequentScreenshot重置状态
      await editorCore.handleSubsequentScreenshot(
        imageData,
        size,
        capturedScale: capturedScale,
        uiImage: uiImage,
      );

      _logger.d('NewEditorPage: 新截图处理完成');
    } catch (e, stackTrace) {
      _logger.e('NewEditorPage: 处理新截图失败', error: e, stackTrace: stackTrace);
      // 确保即使出错也取消加载状态
      if (mounted) {
        await Future.microtask(() {
          ref.read(canvasProvider.notifier).setLoading(false);
        });

        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('处理截图失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 这里不需要释放uiImage，因为它可能是外部传入的
      // 或者已经传递给了Provider
    }
  }

  /// 处理鼠标滚轮事件
  void _handleMouseWheel(PointerScrollEvent event) {
    // 获取当前缩放级别
    final canvasState = ref.read(canvasProvider);
    final currentScale = canvasState.scale;

    // 计算新的缩放级别
    // 滚轮向上滚动时delta为负，表示放大；向下滚动时delta为正，表示缩小
    final scaleFactor = event.scrollDelta.dy > 0 ? 0.9 : 1.1;
    final newScale = currentScale * scaleFactor;

    // 应用新的缩放级别
    final editorCore = ref.read(editorStateCoreProvider);
    editorCore.setZoomLevel(newScale, focalPoint: event.position);
  }

  /// 构建工具栏
  Widget _buildToolbar() {
    return EditorToolbar(
      newButtonLayerLink: _newButtonLayerLink,
      zoomButtonKey: _toolbarZoomButtonKey,
      onShowNewButtonMenu: _showNewButtonMenu,
      onHideNewButtonMenu: _hideNewButtonMenu,
      onShowSaveConfirmation: _showSaveConfirmationDialog,
      onSaveImage: _saveImage,
      onCopyToClipboard: _copyToClipboard,
      onExportImage: _exportImage,
      onUndo: () => _logger.i('撤销操作'),
      onRedo: () => _logger.i('重做操作'),
      onZoom: () => _showZoomMenu(isFromToolbar: true),
    );
  }

  /// 构建状态栏
  Widget _buildStatusBar() {
    return EditorStatusBar(
      onSaveImage: _saveImage,
      onCopyToClipboard: _copyToClipboard,
      onExportImage: _exportImage,
      onCrop: _cropImage,
      onOpenFileLocation: _openImageLocation,
      onZoomMenuTap: () => _showZoomMenu(isFromToolbar: false),
      zoomLayerLink: _statusBarZoomLayerLink,
      zoomButtonKey: _statusBarZoomButtonKey,
    );
  }

  /// 显示缩放菜单
  void _showZoomMenu({bool isFromToolbar = false}) {
    _logger.d('显示缩放菜单, isFromToolbar=$isFromToolbar');
    // 这里实现缩放菜单逻辑
  }

  /// 保存图像
  void _saveImage() {
    _logger.i('保存图像');
    // 实现保存图像逻辑
  }

  /// 复制到剪贴板
  void _copyToClipboard() {
    _logger.i('复制到剪贴板');
    // 实现复制到剪贴板逻辑
  }

  /// 导出图像
  void _exportImage() {
    _logger.i('导出图像');
    // 实现导出图像逻辑
  }

  /// 裁剪图像
  void _cropImage() {
    _logger.i('裁剪图像');
    // 实现裁剪图像逻辑
  }

  /// 打开图像位置
  void _openImageLocation() {
    _logger.i('打开图像位置');
    // 实现打开图像位置逻辑
  }

  /// 显示保存确认对话框
  void _showSaveConfirmationDialog() {
    _logger.i('显示保存确认对话框');
    // 实现显示保存确认对话框逻辑
  }

  /// 显示新建按钮菜单
  void _showNewButtonMenu() {
    _logger.i('显示新建按钮菜单');
    // 实现显示新建按钮菜单逻辑
  }

  /// 隐藏新建按钮菜单
  void _hideNewButtonMenu() {
    _logger.i('隐藏新建按钮菜单');
    // 实现隐藏新建按钮菜单逻辑
  }

  @override
  Widget build(BuildContext context) {
    // 计算可用编辑区域大小
    final screenSize = MediaQuery.of(context).size;
    final toolbarHeight = 48.0; // 工具栏高度
    final statusBarHeight = 36.0; // 状态栏高度
    _availableEditorSize = Size(
      screenSize.width,
      screenSize.height - toolbarHeight - statusBarHeight,
    );

    // 监听加载状态
    final isLoading = ref.watch(isLoadingProvider);

    // 监听壁纸面板显示状态
    final isWallpaperPanelVisible = ref.watch(wallpaperPanelVisibleProvider);

    return Scaffold(
      body: Column(
        children: [
          // 顶部工具栏
          _buildToolbar(),

          // 主内容区域
          Expanded(
            child: Stack(
              children: [
                // 画布容器
                CanvasContainer(
                  availableSize: _availableEditorSize!,
                  onScroll: _handleMouseWheel,
                ),

                // 壁纸面板
                if (isWallpaperPanelVisible)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: WallpaperPanel(),
                  ),

                // 加载指示器
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),

          // 底部状态栏
          _buildStatusBar(),
        ],
      ),
    );
  }

  @override
  void onWindowResize() {
    _logger.d('NewEditorPage: 窗口大小变化');
    // 窗口大小变化时重新计算可用编辑区域大小
    setState(() {});

    // 获取新的窗口尺寸并通知编辑器核心
    windowManager.getSize().then((size) {
      if (mounted) {
        final editorCore = ref.read(editorStateCoreProvider);
        editorCore.handleWindowResize(size);
      }
    });
  }
}

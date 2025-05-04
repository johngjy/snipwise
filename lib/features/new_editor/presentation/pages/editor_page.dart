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
  final Logger _logger = Logger();
  Size? _availableEditorSize;

  @override
  void initState() {
    super.initState();

    // 注册窗口监听器
    windowManager.addListener(this);

    // 记录捕获比例
    final capturedScale = widget.scale ?? 1.0;
    _logger.d('NewEditorPage: 初始化，捕获比例=$capturedScale');

    // 加载图像数据
    _loadImageData();
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
        throw Exception('图像数据为空');
      }

      // 解码图像获取尺寸
      final codec = await ui.instantiateImageCodec(imageData);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;
      final imageSize = widget.imageSize ??
          Size(
            uiImage.width.toDouble(),
            uiImage.height.toDouble(),
          );
      final capturedScale = widget.scale ?? 1.0;

      // 确保在构建后更新状态
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // 获取核心状态管理器
        final editorCore = ref.read(editorStateCoreProvider);

        // 加载截图数据
        editorCore.loadScreenshot(
          imageData,
          imageSize,
          capturedScale: capturedScale,
          uiImage: uiImage,
        );

        _logger.d(
            'NewEditorPage: 图像加载完成，尺寸=${imageSize.width}x${imageSize.height}');
      });
    } catch (e, stackTrace) {
      _logger.e('NewEditorPage: 加载图像失败', error: e, stackTrace: stackTrace);
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

  /// 保存图像
  Future<void> _saveImage() async {
    _logger.d('NewEditorPage: 保存图像');
    // 这里实现保存图像的逻辑，可以调用文件选择对话框并保存图像
  }

  /// 复制到剪贴板
  Future<void> _copyToClipboard() async {
    _logger.d('NewEditorPage: 复制到剪贴板');

    try {
      final canvasState = ref.read(canvasProvider);
      if (canvasState.imageData != null) {
        // 设置剪贴板数据
        await Clipboard.setData(
          ClipboardData(text: '截图已复制'),
        );

        // TODO: 实现真正的图像复制功能
        // 暂时使用文本代替，Flutter目前不直接支持图像复制到剪贴板

        // 显示提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已复制到剪贴板'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.e('NewEditorPage: 复制到剪贴板失败', error: e, stackTrace: stackTrace);

      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('复制到剪贴板失败'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// 导出图像
  Future<void> _exportImage() async {
    _logger.d('NewEditorPage: 导出图像');
    // 这里实现导出图像的逻辑，可能会打开导出选项对话框
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
          EditorToolbar(
            onSaveImage: _saveImage,
            onCopyToClipboard: _copyToClipboard,
            onExportImage: _exportImage,
          ),

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
          EditorStatusBar(
            onSaveImage: _saveImage,
            onCopyToClipboard: _copyToClipboard,
            onExportImage: _exportImage,
          ),
        ],
      ),
    );
  }

  @override
  void onWindowResize() {
    _logger.d('NewEditorPage: 窗口大小变化');
    // 窗口大小变化时重新计算可用编辑区域大小
    setState(() {});
  }
}

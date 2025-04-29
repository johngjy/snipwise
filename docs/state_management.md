# Snipwise 状态管理 - Riverpod实现

本文档描述了Snipwise截图应用使用Riverpod v2的状态管理实现，该实现遵循了最佳实践，特别是使用NotifierProvider和不可变状态模式。

## 状态类设计

### LayoutState (布局状态)

管理窗口和画布的尺寸相关状态：

- `availableScreenSize`: 可用屏幕尺寸
- `minCanvasSize`: 最小画布尺寸
- `editorWindowSize`: 编辑器窗口尺寸
- `currentCanvasViewSize`: 当前画布视觉尺寸
- `isHistoryPanelOpen`: 历史面板是否打开
- `topToolbarHeight`/`bottomToolbarHeight`: 工具栏高度
- `userHasManuallyResized`: 用户是否手动调整过窗口大小

派生值:
- `totalToolbarHeight`: 工具栏总高度
- `minWindowBaseSize`: 最小窗口基础尺寸
- `maxCanvasSize`: 最大画布尺寸 (屏幕尺寸-20-工具栏高度)

### EditorState (编辑器状态)

管理编辑器的核心状态：

- `originalImageSize`: 原始截图尺寸
- `currentImageData`: 当前图像数据
- `wallpaperColor`: 背景颜色
- `wallpaperPadding`: 背景边距
- `isLoading`: 加载状态
- `isWallpaperEnabled`: 是否启用背景

### CanvasTransformState (画布变换状态)

管理画布的变换：

- `scaleFactor`: 缩放比例
- `canvasOffset`: 画布偏移量

### AnnotationState (标注状态)

管理标注数据：

- `annotations`: 标注列表
- `selectedAnnotationId`: 当前选中的标注ID
- `currentTool`: 当前使用的工具

## Notifier类设计

### LayoutNotifier

负责布局计算和窗口尺寸调整：

- `initialize(screenSize)`: 初始化屏幕尺寸信息
- `toggleHistoryPanel()`: 切换历史面板
- `updateToolbarHeights()`: 更新工具栏高度
- `handleManualResize(newWindowSize)`: 处理用户手动调整窗口大小
- `recalculateLayoutForNewContent(originalImageSize, currentPadding)`: 核心方法，为新内容重新计算布局
- `resetLayout()`: 重置布局为初始状态

### EditorStateNotifier

管理编辑器的核心状态：

- `loadScreenshot(data, size)`: 加载截图数据
- `cropImage(rect)`: 裁剪图像
- `updateWallpaperColor(color)`: 更新背景颜色
- `updateWallpaperPadding(padding)`: 更新背景边距
- `resetEditorState()`: 重置编辑器状态

### CanvasTransformNotifier

管理画布的变换操作：

- `setInitialScale(scale)`: 设置初始缩放比例
- `updateZoom(newScale, focalPoint)`: 更新缩放比例，focalPoint是缩放中心
- `updateOffset(delta)`: 更新偏移量
- `resetTransform()`: 重置变换
- `fitToWindow(imageSize, availableSize)`: 适应窗口

### AnnotationNotifier

管理标注数据：

- `addAnnotation(annotation)`: 添加标注
- `updateAnnotation(updatedAnnotation)`: 更新标注
- `removeAnnotation(id)`: 移除标注
- `selectAnnotation(id)`: 选择标注
- `setCurrentTool(tool)`: 设置当前工具
- `clearAnnotations()`: 清除所有标注

## Provider设计

```dart
// 布局管理Provider
final layoutProvider = NotifierProvider<LayoutNotifier, LayoutState>(() {
  return LayoutNotifier();
});

// 编辑器状态Provider
final editorStateProvider = NotifierProvider<EditorStateNotifier, EditorState>(() {
  return EditorStateNotifier();
});

// 画布变换Provider
final canvasTransformProvider = NotifierProvider<CanvasTransformNotifier, CanvasTransformState>(() {
  return CanvasTransformNotifier();
});

// 标注管理Provider
final annotationProvider = NotifierProvider<AnnotationNotifier, AnnotationState>(() {
  return AnnotationNotifier();
});

// 滚动条显示Provider
final showScrollbarsProvider = Provider<bool>((ref) {
  // 根据画布状态、图像尺寸、背景边距和画布尺寸计算是否需要显示滚动条
  // ...
});
```

## 跨Provider通信

通过扩展方法实现跨Provider通信，避免循环依赖：

```dart
// 扩展EditorStateNotifier，添加跨Provider方法
extension EditorStateNotifierExtension on EditorStateNotifier {
  // 加载截图并计算布局
  double loadScreenshotWithLayout(dynamic data, Size size) { ... }
  
  // 更新背景边距并重新计算布局
  void updateWallpaperPaddingWithLayout(EdgeInsets padding) { ... }
  
  // 重置所有状态
  void resetAllState() { ... }
}

// 扩展LayoutNotifier，添加跨Provider方法
extension LayoutNotifierExtension on LayoutNotifier {
  // 根据当前内容重新计算布局
  void recalculateLayoutBasedOnCurrentContent() { ... }
}

// 扩展AnnotationNotifier，添加跨Provider方法
extension AnnotationNotifierExtension on AnnotationNotifier {
  // 检查并扩展Wallpaper边距
  void checkAndExpandWallpaper(List<EditorObject> annotations) { ... }
}
```

## 窗口尺寸计算逻辑

1. 当加载新截图时，LayoutNotifier会根据截图尺寸和当前设置重新计算布局：
   - 如果内容尺寸小于最小画布尺寸，则使用最小画布尺寸
   - 如果内容尺寸介于最小和最大画布尺寸之间，则使用内容尺寸
   - 如果内容尺寸大于最大画布尺寸，则使用最大画布尺寸，并计算需要的缩放因子

2. 缩放因子计算：
   - 如果内容宽度或高度超过最大尺寸限制，则计算`scaleFactorX`或`scaleFactorY`
   - 选择较小的缩放因子作为最终缩放因子，确保内容完全可见

## Wallpaper自动扩展逻辑

当添加或修改标注时，系统会检查标注是否超出当前Wallpaper边距区域。如果超出，则会自动扩展边距以容纳标注：

1. 计算所有标注的边界
2. 比较边界与当前图像+边距的区域
3. 如果标注超出了边界，则增加相应方向的边距
4. 更新边距，这会触发布局重新计算和可能的缩放调整

## 滚动条显示逻辑

`showScrollbarsProvider`根据以下条件决定是否显示滚动条：

1. 如果缩放后的内容宽度大于当前画布视觉宽度，显示水平滚动条
2. 如果缩放后的内容高度大于当前画布视觉高度，显示垂直滚动条
3. 如果存在画布偏移（即用户已经平移了画布），显示滚动条

## 用户手动调整窗口

当用户手动调整窗口大小时：

1. 窗口检测到调整事件，调用`handleManualResize`
2. 更新`editorWindowSize`并设置`userHasManuallyResized = true`
3. 立即重新计算画布视觉尺寸，但不会触发内容的自动缩放
4. 如果内容超出了可视区域，自动启用滚动条

## 状态依赖关系

1. `EditorState` → `LayoutState`: 图像尺寸和边距影响布局计算
2. `LayoutState` → `CanvasTransformState`: 布局变化可能需要调整缩放
3. `AnnotationState` → `EditorState`: 标注边界影响Wallpaper边距

## 优化策略

1. 状态分离：将不同关注点的状态分离到不同的Provider中
2. 精细依赖：UI组件仅订阅所需的状态部分，使用`select`优化性能
3. 延迟计算：使用延迟计算派生值，避免不必要的重新计算
4. 扩展方法：使用扩展方法实现跨Provider通信，避免循环依赖 
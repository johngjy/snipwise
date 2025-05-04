# Snipwise 状态管理文档

本文档详细说明 Snipwise 应用的状态管理架构，特别是编辑器模块的状态管理。

## 状态管理概览

Snipwise 使用 Flutter Riverpod 作为状态管理解决方案，采用分层架构设计，主要包括：

- **状态定义层**：定义状态数据结构和模型
- **状态更新层**：通过 Notifier 类实现状态更新逻辑
- **状态提供层**：使用 Provider 提供状态访问接口
- **状态协调层**：核心状态管理器协调复杂状态间的交互
- **业务功能层**：通过 Manager 类实现跨状态的业务功能

## 编辑器模块状态架构

### 1. 核心状态管理器 (EditorStateCore)

`EditorStateCore` 是编辑器状态的核心协调者，位于 `lib/features/editor/application/core/editor_state_core.dart`。

```dart
/// 编辑器核心状态管理器
/// 提供统一的状态访问和更新接口，协调所有子状态间的交互
class EditorStateCore {
  final Ref _ref;

  EditorStateCore(this._ref);

  // 状态访问接口
  EditorState get editorState => _ref.read(editorStateProvider);
  CanvasTransformState get canvasTransform => _ref.read(canvasTransformProvider);
  // ...

  // 高级操作接口
  double loadScreenshot(Uint8List data, Size size, {double capturedScale = 1.0}) {
    // 协调多个状态的更新逻辑
  }

  void updateWallpaperPadding(double padding) {
    // 统一处理内边距更新
  }

  // ...更多跨状态操作
}
```

#### 核心原则：

1. **单一入口**：为复杂操作提供单一API入口
2. **状态协调**：负责跨状态的协调和同步
3. **功能聚合**：将业务逻辑从UI和Notifier中抽离

### 2. 分类状态提供者

状态提供者按功能域分类组织，每类状态都有专门的提供者文件：

#### 2.1 核心Provider (Core Providers)

位于 `lib/features/editor/application/providers/core_providers.dart`，管理基础状态：

```dart
/// 编辑器核心状态提供者
final editorStateCoreProvider = Provider<EditorStateCore>((ref) {
  return EditorStateCore(ref);
});

/// 编辑器基础状态提供者
final editorStateProvider = NotifierProvider<EditorStateNotifier, EditorState>(() {
  return EditorStateNotifier();
});

/// 布局管理提供者
final layoutProvider = NotifierProvider<LayoutNotifier, LayoutState>(() {
  return LayoutNotifier();
});

// ...其他核心状态
```

#### 2.2 画布Provider (Canvas Providers)

位于 `lib/features/editor/application/providers/canvas_providers.dart`，管理画布相关状态：

```dart
/// 画布尺寸提供者
final canvasSizeProvider = Provider<Size>((ref) {
  final editorState = ref.watch(editorStateProvider);
  return editorState.originalImageSize ?? const Size(800, 600);
});

/// 画布缩放比例提供者
final canvasScaleProvider = StateProvider<double>((ref) {
  final transformState = ref.watch(canvasTransformProvider);
  return transformState.zoomLevel;
});

// ...其他画布状态
```

#### 2.3 壁纸Provider (Wallpaper Providers)

位于 `lib/features/editor/application/providers/wallpaper_providers.dart`，管理背景装饰相关状态：

```dart
/// 画布背景装饰提供者
final canvasBackgroundDecorationProvider = Provider<BoxDecoration?>((ref) {
  final wallpaperSettings = ref.watch(wallpaperSettingsProvider);
  // 构建装饰对象...
});

// ...其他壁纸状态
```

#### 2.4 绘图Provider (Painter Providers)

位于 `lib/features/editor/application/providers/painter_providers.dart`，管理绘图和标注相关状态：

```dart
/// FlutterPainter控制器提供者
final painterControllerProvider = StateProvider<PainterController>((ref) {
  final controller = PainterController();
  return controller;
});

/// 绘图模式提供者
final drawingModeProvider = StateProvider<DrawingMode>((ref) {
  return DrawingMode.line;
});

// ...其他绘图状态
```

### 3. 管理器 (Managers)

管理器层负责实现业务功能逻辑，减少状态间的直接依赖：

#### 3.1 画布管理器 (CanvasManager)

位于 `lib/features/editor/application/managers/canvas_manager.dart`：

```dart
/// 画布管理器类
/// 提供高级画布管理功能，统一多个Provider间的协调
class CanvasManager {
  final Ref _ref;
  final Logger _logger = Logger();

  CanvasManager(this._ref);

  /// 计算内容适合窗口的缩放因子
  double calculateContentFitScale(Size contentSize, Size availableArea) {
    // 缩放计算逻辑...
  }

  /// 调整画布以适应绘制物对象边界
  void adjustCanvasForDrawableBounds(Rect bounds) {
    // 画布调整逻辑...
  }

  // ...其他画布管理功能
}
```

## 状态更新流程

### 1. 基本状态更新

最简单的状态更新直接通过Notifier执行：

```dart
// UI组件中
ref.read(toolProvider.notifier).selectTool(EditorTool.rectangle);
```

### 2. 跨状态协调更新

需要协调多个状态的更新通过EditorStateCore执行：

```dart
// UI组件中
final editorCore = ref.read(editorStateCoreProvider);
editorCore.updateWallpaperPadding(10.0); // 内部会协调多个状态的更新
```

### 3. 业务功能更新

特定业务功能通过Manager类执行：

```dart
// UI组件中
final canvasManager = ref.read(canvasManagerProvider);
canvasManager.fitContentToViewport(availableSize); // 执行适应视口的业务逻辑
```

## 状态监听与反应

Riverpod提供强大的状态监听机制：

```dart
// 监听特定状态变化
ref.listen(editorStateProvider, (previous, current) {
  if (previous?.currentImageData != current.currentImageData) {
    // 图像数据变化时执行的逻辑
  }
});

// 派生状态 (Computed State)
final canvasOverflowProvider = Provider<bool>((ref) {
  final transformState = ref.watch(canvasTransformProvider);
  final layoutState = ref.watch(layoutProvider);
  final canvasSize = ref.watch(canvasTotalSizeProvider);
  
  // 基于多个状态计算派生状态
  final isScaledUp = transformState.zoomLevel > 1.0;
  final isWidthOverflow = canvasSize.width * transformState.zoomLevel > layoutState.currentCanvasViewSize.width;
  final isHeightOverflow = canvasSize.height * transformState.zoomLevel > layoutState.currentCanvasViewSize.height;
  
  return isScaledUp || isWidthOverflow || isHeightOverflow;
});
```

## 状态重置与初始化

各状态提供统一的重置方法：

```dart
// 重置所有状态
void resetAllState() {
  // 重置编辑器状态
  _ref.read(editorStateProvider.notifier).resetEditorState();
  
  // 重置布局
  _ref.read(layoutProvider.notifier).resetLayout();
  
  // 重置变换
  _ref.read(canvasTransformProvider.notifier).resetTransform();
  
  // ...重置其他状态
}
```

## 最佳实践

1. **状态分类**：按功能域组织状态提供者
2. **最小状态原则**：每个状态只存储必要的数据
3. **单一职责**：每个 Notifier 只负责一种状态的更新
4. **协调分离**：复杂状态协调逻辑放在 EditorStateCore 或 Manager 中
5. **派生状态**：尽量使用 Provider 计算派生状态，避免冗余存储
6. **状态文档**：为每个状态和重要操作添加详细注释说明

## 性能优化

1. **选择性监听**：UI组件只监听真正需要的状态
2. **延迟计算**：使用 Provider.family 和参数化 Provider 延迟计算
3. **保持状态轻量**：避免在状态中存储大量数据或复杂对象
4. **缓存结果**：对计算密集型操作结果进行缓存

## 调试与测试

1. **日志记录**：关键状态变化添加日志
2. **状态快照**：实现状态快照功能便于调试
3. **单元测试**：为 Notifier 和 Manager 编写单元测试
4. **模拟依赖**：使用 Riverpod 的 ProviderContainer 模拟依赖 
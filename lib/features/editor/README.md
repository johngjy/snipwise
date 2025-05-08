# Snipwise 编辑器模块优化文档

## 状态管理优化

为了提高 Snipwise 截图编辑器的性能和可维护性，我们对状态管理结构进行了全面优化，采用 Riverpod v2 的最新特性和 Flutter 最佳实践。

### 优化目标

1. 简化状态结构，减少碎片化
2. 降低状态间的复杂依赖关系
3. 提高性能，减少不必要的重建
4. 提高代码可读性和可维护性
5. 采用 Riverpod v2 的 Notifier API

### 核心状态类

我们将原有的分散状态整合为三个主要状态类：

1. **EditorState** - 管理编辑器核心状态
   - 图像数据和尺寸
   - 当前工具和选中对象
   - 历史记录

2. **LayoutState** - 管理所有布局和尺寸相关状态
   - 画布尺寸和内边距
   - 缩放级别
   - 工具栏高度
   - 可绘制区域边界

3. **WallpaperState** - 管理壁纸相关状态
   - 壁纸类型和图像数据
   - 背景颜色和渐变
   - 内边距和样式设置

### 状态管理器 (Notifier)

每个状态类都有对应的 Notifier 类负责状态更新逻辑：

1. **EditorNotifier** - 处理编辑器核心功能
2. **LayoutNotifier** - 处理布局和尺寸调整
3. **WallpaperNotifier** - 处理壁纸设置

### 优化的 Provider 结构

我们使用 Riverpod v2 的 Provider 系统，将相关功能组织为：

1. **核心状态 Provider** - 管理主要状态
   ```dart
   final editorProvider = NotifierProvider<EditorNotifier, EditorState>(() {
     return EditorNotifier();
   });
   ```

2. **派生状态 Provider** - 计算或过滤状态的特定部分
   ```dart
   final canvasTotalSizeProvider = Provider<Size>((ref) {
     return ref.watch(layoutProvider.select((state) => state.totalSize));
   });
   ```

3. **参数化 Provider** - 根据输入参数计算值
   ```dart
   final contentFitScaleProvider = Provider.family<double, Size>((ref, availableSize) {
     return ref.watch(layoutProvider.notifier).calculateContentFitScale(availableSize);
   });
   ```

## 迁移指南

### 1. 添加依赖

确保 `pubspec.yaml` 中包含以下依赖：

```yaml
dependencies:
  flutter_riverpod: ^2.3.0
  freezed_annotation: ^2.2.0

dev_dependencies:
  build_runner: ^2.3.0
  freezed: ^2.3.0
```

### 2. 生成 freezed 代码

运行以下命令生成 freezed 所需的代码文件：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. 更新导入路径

在需要使用新状态管理的文件中，更新导入路径：

```dart
// 使用现有提供者
import '../../application/providers/canvas_providers.dart';
import '../../application/providers/editor_providers.dart';
import '../../application/providers/wallpaper_providers.dart';
```

### 4. 更新状态访问方式

使用新的 Provider 和 select 方法访问状态：

```dart
// 旧方式
final canvasSize = ref.watch(canvasSizeProvider);
final padding = ref.watch(canvasPaddingProvider);

// 新方式
final layoutState = ref.watch(layoutProvider);
final canvasSize = layoutState.canvasSize;
final padding = layoutState.padding;

// 或者使用 select 只监听所需部分
final zoomLevel = ref.watch(
  layoutProvider.select((state) => state.zoomLevel)
);
```

### 5. 更新状态更新方式

使用 Notifier 类的方法更新状态：

```dart
// 旧方式
ref.read(canvasSizeProvider.notifier).state = newSize;

// 新方式
ref.read(layoutProvider.notifier).updateCanvasSize(newSize);
```

## 性能优化技巧

1. **使用 select 减少重建**
   ```dart
   // 只在 zoomLevel 变化时重建
   final zoomLevel = ref.watch(
     layoutProvider.select((state) => state.zoomLevel)
   );
   ```

2. **条件状态更新**
   ```dart
   // 只在值变化时更新状态
   if (state.zoomLevel != newZoom) {
     state = state.copyWith(zoomLevel: newZoom);
   }
   ```

3. **使用 addPostFrameCallback**
   ```dart
   // 确保在当前帧渲染完成后更新状态
   WidgetsBinding.instance.addPostFrameCallback((_) {
     ref.read(layoutProvider.notifier).updateCanvasSize(newSize);
   });
   ```

## 示例组件

我们提供了几个使用新状态管理结构的示例组件：

1. `OptimizedScreenshotDisplayArea` - 优化版截图显示区域
2. `OptimizedWallpaperCanvasContainer` - 优化版壁纸画布容器
3. `OptimizedEditorPage` - 优化版编辑器页面

## 后续工作

1. 完成所有组件的迁移
2. 添加单元测试和集成测试
3. 性能测试和优化
4. 完善文档和注释

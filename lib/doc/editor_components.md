# Snipwise 编辑器组件文档

本文档详细介绍了Snipwise截图编辑器(`/lib/features/editor`)模块中的所有组件和状态管理类，以便开发人员能够快速了解项目架构并进行维护和扩展。

## 状态管理

Snipwise使用Riverpod进行状态管理，遵循单一数据源原则，确保UI与状态一致性。

### 核心状态类

#### 1. `EditorState`（editor_state.dart）
核心编辑器状态，管理截图数据、尺寸和UI状态：
```dart
class EditorState {
  final Size? originalImageSize;        // 原始截图尺寸
  final dynamic currentImageData;       // 当前图像数据
  final ui.Image? imageAsUiImage;       // UI显示图像
  final double capturedScale;           // 捕获比例
  final Color wallpaperColor;           // 背景颜色
  final EdgeInsets wallpaperPadding;    // 背景边距
  final bool isLoading;                 // 加载状态
  final bool isWallpaperEnabled;        // 是否启用背景
  final bool isZoomMenuVisible;         // 缩放菜单是否可见
  final bool isNewButtonMenuVisible;    // 新建按钮菜单是否可见
}
```

#### 2. `ToolState`（tool_state.dart）
管理编辑工具选择和设置：
```dart
enum EditorTool {
  select, rectangle, ellipse, arrow, line, text, 
  blur, highlight, freehand, erase, crop, magnifier, dimension, none
}

class ToolState {
  final EditorTool currentTool;         // 当前工具
  final ModifierKeys modifierKeys;      // 修饰键状态
  final Map<String, ToolSettings> toolSettings;  // 工具设置
}
```

#### 3. `CanvasTransformState`（canvas_transform_state.dart）
管理画布变换状态，处理缩放和平移：
```dart
class CanvasTransformState {
  final double scaleFactor;            // 缩放比例
  final Offset canvasOffset;           // 画布偏移
  final double zoomLevel;              // 缩放级别
}
```

#### 4. `LayoutState`（layout_state.dart）
管理布局相关状态：
```dart
class LayoutState {
  final Size screenSize;               // 屏幕尺寸
  final Size editorWindowSize;         // 编辑器窗口尺寸
  final Size currentCanvasViewSize;    // 当前画布视图尺寸
}
```

### 状态提供者（Providers）

#### 编辑器核心Providers（editor_providers.dart）
```dart
final editorStateProvider = NotifierProvider<EditorStateNotifier, EditorState>();
final toolProvider = NotifierProvider<ToolNotifier, ToolState>();
final canvasTransformProvider = NotifierProvider<CanvasTransformNotifier, CanvasTransformState>();
final layoutProvider = NotifierProvider<LayoutNotifier, LayoutState>();
final currentToolProvider = Provider<String>(); // 当前工具字符串表示
```

#### 壁纸背景相关Providers（wallpaper_providers.dart）
```dart
final canvasSizeProvider = Provider<Size>(); // 原始截图尺寸
final canvasScaleProvider = StateProvider<double>(); // 画布缩放比例
final canvasPaddingProvider = StateProvider<EdgeInsets>(); // 画布内边距
final uniformPaddingProvider = StateProvider<double>(); // 统一内边距值
final wallpaperImageProvider = Provider<Uint8List?>(); // 壁纸背景图像
final canvasTotalSizeProvider = Provider<Size>(); // 画布总尺寸（含内边距）
```

#### 绘图相关Providers（painter_providers.dart）
```dart
final painterControllerProvider = Provider<PainterController>(); // FlutterPainter控制器
final selectedObjectDrawableProvider = StateProvider<ObjectDrawable?>(); // 当前选中的绘图对象
final textCacheProvider = StateNotifierProvider<TextCacheNotifier, List<String>>(); // 文本缓存
final showTextCacheDialogProvider = StateProvider<bool>(); // 显示文本缓存对话框
```

## UI组件

### 核心组件

#### 1. `EditorPage`（editor_page.dart）
主编辑页面，组织和协调所有UI组件：
- 管理窗口尺寸和状态
- 处理键盘和鼠标事件
- 集成工具栏、显示区域和状态栏

#### 2. `ScreenshotDisplayArea`（screenshot_display_area.dart）
截图显示区域，支持缩放和平移：
```dart
class ScreenshotDisplayArea extends ConsumerWidget {
  final Uint8List? imageData;               // 图像数据
  final double capturedScale;               // 捕获比例
  final TransformationController transformController; // 变换控制器
  final void Function(PointerScrollEvent) onMouseScroll; // 鼠标滚轮处理
  final Size availableSize;                 // 可用尺寸
  final Size? imageLogicalSize;             // 图像逻辑尺寸
}
```
- 支持鼠标滚轮缩放和触控板手势
- 使用GestureDetector实现拖拽和缩放功能

#### 3. `WallpaperCanvasContainer`（wallpaper_canvas_container.dart）
统一封装截图显示与绘图区域：
```dart
class WallpaperCanvasContainer extends ConsumerWidget {
  final Color? backgroundColor;            // 背景颜色
  final BoxFit backgroundFit;              // 填充模式
  final bool showBorder;                   // 是否显示边框
  final Color borderColor;                 // 边框颜色
  final double borderWidth;                // 边框宽度
  final double minPadding;                 // 最小内边距
  final Function(Size)? onSizeChanged;     // 尺寸变化回调
}
```
- 管理背景图像显示
- 内嵌PainterView处理绘图操作
- 自动响应内容变化调整大小

#### 4. `PainterView`（painter_view.dart）
使用flutter_painter_v2实现绘图功能：
```dart
class PainterView extends ConsumerWidget {
  final Function(Rect?)? onDrawableBoundsChanged; // 绘图对象边界变化回调
}
```
- 处理绘图对象创建、删除和选择
- 跟踪绘图边界用于自动扩展画布
- 集成文本缓存功能

#### 5. `EditorToolbar`（editor_toolbar.dart）
顶部工具栏，提供工具选择和操作：
```dart
class EditorToolbar extends ConsumerWidget {
  final LayerLink newButtonLayerLink;           // 新建按钮图层链接
  final GlobalKey zoomButtonKey;                // 缩放按钮键
  final VoidCallback onShowNewButtonMenu;       // 显示新建菜单回调
  final VoidCallback onHideNewButtonMenu;       // 隐藏新建菜单回调
  final VoidCallback onShowSaveConfirmation;    // 显示保存确认回调
  final Function(String) onSelectTool;          // 选择工具回调
  final String selectedTool;                    // 当前选中工具
  final VoidCallback onUndo;                    // 撤销回调
  final VoidCallback onRedo;                    // 重做回调
  final VoidCallback onZoom;                    // 缩放回调
  final VoidCallback onSaveImage;               // 保存图像回调
  final VoidCallback onCopyToClipboard;         // 复制到剪贴板回调
}
```
- 支持选择、矩形、椭圆、线条、箭头、文本、自由绘图、高亮、橡皮擦工具
- 提供撤销、重做、删除选中对象功能
- 集成文本缓存访问和图像保存功能

#### 6. `EditorStatusBar`（editor_status_bar.dart）
底部状态栏，显示图像信息和操作：
```dart
class EditorStatusBar extends StatelessWidget {
  final Uint8List? imageData;                   // 图像数据
  final double zoomLevel;                       // 缩放级别
  final double minZoom;                         // 最小缩放
  final double maxZoom;                         // 最大缩放
  final Function(double) onZoomChanged;         // 缩放变化回调
  final VoidCallback onZoomMenuTap;             // 缩放菜单点击回调
  final LayerLink zoomLayerLink;                // 缩放图层链接
  final GlobalKey zoomButtonKey;                // 缩放按钮键
  // 其他功能回调...
}
```
- 显示当前缩放级别和图像信息
- 提供缩放控制、导出、复制等功能
- 支持图像拖拽功能

### 辅助组件

#### 1. `ZoomControl`（zoom_control.dart）
缩放控制组件：
```dart
class ZoomControl extends StatelessWidget {
  final double zoomLevel;                      // 缩放级别
  final double minZoom;                        // 最小缩放
  final double maxZoom;                        // 最大缩放
  final Function(double) onZoomChanged;        // 缩放变化回调
  final VoidCallback onZoomMenuTap;            // 缩放菜单点击回调
  final LayerLink zoomLayerLink;               // 缩放图层链接
  final double fitZoomLevel;                   // 适合窗口的缩放级别
  // 其他配置项...
}

class ZoomMenu extends StatelessWidget {
  final List<String> zoomOptions;              // 缩放选项
  final double currentZoom;                    // 当前缩放
  final Function(String) onOptionSelected;     // 选项选择回调
  final double fitZoomLevel;                   // 适合窗口的缩放级别
}
```
- 提供缩放滑块和缩放菜单功能
- 支持预设缩放级别选择

#### 2. `TextCacheDialog`（text_cache_dialog.dart）
文本缓存对话框：
```dart
class TextCacheDialog extends ConsumerWidget {}
```
- 显示和管理缓存的文本内容
- 支持搜索、复制、删除功能

#### 3. `HoverMenu`（hover_menu.dart）
悬浮菜单：
```dart
class HoverMenu extends StatelessWidget {
  final List<HoverMenuItem> items;           // 菜单项
}

class HoverMenuItem {
  final dynamic icon;                        // 图标
  final String label;                        // 标签
  final VoidCallback onTap;                  // 点击回调
}
```
- 用于显示新建按钮和其他悬浮菜单
- 支持图标和文字展示

#### 4. `ToolButton`（tool_button.dart）
工具按钮：
```dart
class ToolButton extends StatelessWidget {
  final dynamic icon;                        // 图标（支持IconData或Widget）
  final bool isSelected;                     // 是否选中
  final VoidCallback onTap;                  // 点击回调
  final Color? color;                        // 自定义颜色
  final Key? buttonKey;                      // 按钮Key
}
```
- 用于工具栏中的工具选择按钮
- 支持选中状态显示

## 最佳实践

### 组件使用指南

1. **添加新工具**
   - 在`EditorTool`枚举中添加新工具类型
   - 在`ToolState`中添加对应的设置类
   - 在`EditorToolbar`中添加工具按钮和处理逻辑

2. **扩展绘图功能**
   - 使用`flutter_painter_v2`的API创建新的绘图类型
   - 在`PainterView`中处理新绘图对象

3. **自定义缩放行为**
   - 修改`CanvasTransformNotifier`中的缩放逻辑
   - 更新`ScreenshotDisplayArea`中的手势处理

### 状态管理最佳实践

1. 使用`WidgetsBinding.instance.addPostFrameCallback`进行状态更新，避免在构建过程中修改状态
2. 避免直接在构建方法中调用状态修改函数
3. 使用`ref.watch`监听状态变化，使用`ref.read`读取状态但不监听变化
4. 优先使用`NotifierProvider`管理复杂状态
5. 使用计算型Provider派生其他状态

## 注意事项

1. `PainterView`组件必须包裹在具有确定尺寸的容器中
2. 图像缩放时，确保使用`Transform`组件而非直接修改`PainterController`的变换
3. 工具切换时需要正确设置`PainterController`的绘图模式
4. 文本缓存在添加新文本时会自动更新
5. 在处理大尺寸图像时，注意性能优化

## 最近更新

### 菜单交互体验优化

* **延长菜单显示时间**: 将`NewButtonMenuService`和`ZoomMenuService`中的菜单隐藏延迟时间从200/300毫秒增加到800毫秒，大幅提高用户菜单选项的点击成功率。
* **改进悬停菜单组件**: 增加菜单项的点击区域高度，从10px增加到14px，并添加更明显的视觉反馈效果(悬停、点击高亮)。
* **增强菜单视觉层次**: 为悬停菜单添加阴影效果，提升用户界面层次感和交互感知度。
* **支持自定义图标**: 悬停菜单项现支持自定义Widget作为图标，增强界面定制能力。

### 状态管理整合

* **整合提供者文件**: 将`wallpaper_providers.dart`中的所有提供者合并到`editor_providers.dart`中，简化了状态管理结构。
* **画布变换优化**: 优化了缩放、平移等变换操作的实现，提高了用户体验。
* **移除未使用组件**: 移除了未使用的组件和冗余代码，提高代码质量。

### 绘图功能集成

* **合并缩放控制功能**: 将缩放控制功能与画布变换系统整合，确保一致的用户体验。

## 待办事项

- [ ] 优化状态管理，减少Provider之间的依赖
- [ ] 整合`wallpaper_providers.dart`到`editor_providers.dart`
- [ ] 改进缩放和平移交互体验
- [ ] 增强工具状态管理，使用命令模式重构工具操作 
 
 
 
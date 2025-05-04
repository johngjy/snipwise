# 新版编辑器迁移计划

## 依赖问题

- [X] 添加 flutter_painter_v2: ^2.1.0+1 依赖
- [X] 更新 Flutter 兼容性
- [X] 解决 painteroller 工具集成问题

## 文件迁移

### 状态文件

- [X] canvas_state.dart -> new_editor/core/state/canvas_state.dart
- [X] canvas_providers.dart -> new_editor/application/providers/canvas_providers.dart  
- [X] painter_providers.dart -> new_editor/application/providers/painter_providers.dart

### 核心状态管理

- [X] editor_state_core.dart
- [X] canvas_transform_state.dart
- [X] canvas_manager.dart
- [X] canvas_notifier.dart

### 接口组件

- [X] canvas_container.dart 重构为使用 FlutterPainter
- [X] canvas_transform_connector.dart
- [X] painter_canvas_connector.dart

## 功能模块重构

### 画布与缩放

- [X] 放大缩小功能
- [X] 拖拽功能
- [X] 尺寸自动计算
- [X] 边界检测

### 绘图功能

- [X] 集成 FlutterPainter
- [X] 绘图模式管理
- [X] 图形绘制设置
- [X] 背景图片设置

### 工具栏

- [X] 绘图工具栏
- [X] 颜色选择器
- [X] 线宽选择器
- [X] 绘图历史

### 壁纸背景

- [X] 壁纸背景设置
- [X] 分辨率设置

## 测试与验证

- [ ] 单元测试
- [ ] UI测试
- [ ] 性能测试

## 未解决问题

### Flutter Painter API 兼容性问题

在迁移过程中我们发现 Flutter Painter v2 的API有以下关键问题需要解决：

1. 文本添加和编辑 - API与预期不同
   - `TextSettings`参数设置方式与文档不符
   - 需要特殊处理文本添加流程

2. 形状填充和描边设置
   - `ShapeSettings`填充和描边设置需要通过`Paint`对象配置
   - 不支持直接设置`filled`和`fillColor`属性

3. 背景图像设置
   - 使用`ImageBackgroundDrawable`时必须使用命名参数`image`

### 解决方案

1. 对Flutter Painter进行更简洁的API包装
2. 参考最新的Flutter Painter文档和源码
3. 考虑创建自定义绘图功能（长期解决方案）

## 已完成工具

1. 绘图工具栏
   - [X] 选择工具
   - [X] 矩形工具
   - [X] 椭圆工具
   - [X] 箭头工具
   - [X] 手绘工具
   - [X] 文本工具
   - [X] 橡皮擦工具
   - [X] 撤销/重做功能
   - [X] 颜色选择器
   - [X] 线宽调整器
   - [X] 填充控制

2. 状态栏
   - [X] 缩放控制
   - [X] 拖拽复制功能
   - [X] 尺寸显示
   - [X] 文件操作按钮

3. 壁纸背景设置
   - [X] 无背景选项
   - [X] 渐变背景
   - [X] 纯色背景
   - [X] 模糊背景
   - [X] 边距和圆角设置
   - [X] 阴影设置

## 最近完成的工作

### 壁纸功能整合
- [x] 合并wallpaper_providers.dart和wallpaper_notifier.dart，统一API
- [x] 确保所有组件使用新的统一API
- [x] 更新CanvasContainer、WallpaperPanel等组件以使用新的API
- [x] 设置canvasBackgroundDecorationProvider为转发到wallpaperDecorationProvider的过渡提供者，并标记为已弃用
- [x] 删除冗余的wallpaper_notifier.dart文件 
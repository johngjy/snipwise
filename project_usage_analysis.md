# Snipwise 项目文件使用分析

本文档分析了 Snipwise 项目中各文件的使用情况，并对项目架构和功能进行了概述。

## 项目概述

Snipwise 是一款使用 Flutter 开发的跨平台截图标注工具，主要功能包括：
- 屏幕截图捕获
- 图像标注编辑
- 高清截图功能
- 放大镜工具
- OCR 文字识别
- 比例尺设置等

项目采用特性优先(feature-first)的架构，使用 Provider/Riverpod 进行状态管理，包含多个功能模块。

## 核心依赖项

项目主要使用以下关键依赖：
- **状态管理**：provider, riverpod, flutter_riverpod, hooks_riverpod, freezed_annotation
- **UI组件**：flutter_svg, google_fonts, phosphor_flutter
- **编辑功能**：flutter_painter_v2, perfect_freehand, flex_color_picker
- **截图功能**：screenshot, screen_capturer, screen_retriever
- **窗口管理**：window_manager, desktop_window
- **文件处理**：path_provider, file_picker, file_saver, file_selector

## 项目结构分析

### 正在使用的核心文件/模块

#### 核心应用文件
- `/lib/main.dart` - 应用入口点，初始化窗口管理器和Riverpod
- `/lib/core/main_app.dart` - 主应用程序组件
- `/lib/core/services/window_service.dart` - 窗口服务管理
- `/lib/app/routes/app_router.dart` - 应用路由管理
- `/lib/app/routes/app_routes.dart` - 路由定义常量

#### 编辑器模块 (活跃使用)
- `/lib/features/editor/` - 编辑器功能模块
  - `application/states/` - 核心状态定义
    - `canvas_transform_state.dart` - 画布变换状态
    - `editor_state.dart` - 编辑器主状态
    - `layout_state.dart` - 布局状态
  - `application/notifiers/` - 状态变更通知器
  - `application/core/editor_state_core.dart` - 编辑器核心状态管理
  - `application/providers/` - 状态提供器
  - `presentation/pages/editor_page.dart` - 编辑器页面
  - `presentation/widgets/` - 编辑器UI组件

#### 截图模块 (活跃使用)
- `/lib/features/capture/` - 截图功能模块
  - `services/capture_service.dart` - 截图服务
  - `services/long_screenshot_service.dart` - 长截图服务
  - `data/models/capture_mode.dart` - 截图模式定义
  - `data/models/capture_result.dart` - 截图结果模型
  - `presentation/pages/capture_page.dart` - 截图页面

#### macOS 原生集成
- `/macos/Runner/AppDelegate.swift` - macOS应用代理，使用window_manager插件

### 其他活跃使用的功能模块
- `/lib/features/annotation/` - 图像标注功能
- `/lib/features/hires_capture/` - 高分辨率截图功能
- `/lib/features/status_bar/` - 状态栏功能
- `/lib/features/window_controls/` - 窗口控制功能

### 未充分使用或废弃的文件

1. `/WindowManager.swift` - 项目根目录下的Swift文件，已被window_manager插件替代
2. `/lib/features/new_editor/` - 可能是编辑器模块的新版本尝试，未被主流程使用
3. `/lib/features/ocr/` - OCR功能模块，可能处于开发中状态
4. `/lib/features/gif_recording/` - GIF录制功能，可能处于开发中状态
5. `/lib/features/demo/` - 演示模块，可能仅用于开发测试

### Freezed 生成文件状态

以下Freezed生成的状态文件被正确使用并由build_runner生成：
- `canvas_transform_state.freezed.dart` 
- `editor_state.freezed.dart`
- `layout_state.freezed.dart`

这些文件是项目状态管理的核心部分，定义了不可变状态模型。

## 功能与模块分析

### 1. 截图与捕获模块

**用途**：实现屏幕区域捕获、窗口捕获和延时捕获功能
**核心文件**：
- `/lib/features/capture/services/capture_service.dart` - 截图核心服务
- `/lib/features/capture/presentation/pages/capture_page.dart` - 截图界面

此模块使用 `screen_capturer` 和 `window_manager` 插件实现跨平台截图功能，可支持区域选择、窗口捕获等。

### 2. 编辑器模块

**用途**：提供图像编辑、标注和尺寸测量功能
**核心文件**：
- `/lib/features/editor/application/core/editor_state_core.dart` - 编辑状态核心
- `/lib/features/editor/presentation/pages/editor_page.dart` - 编辑器页面
- `/lib/features/editor/application/states/` - 状态模型定义

编辑器模块采用 Freezed 生成的不可变状态模型，结合 Riverpod 状态管理，实现绘图、标注、文本编辑等功能。

### 3. 高清截图模块

**用途**：提供高分辨率截图功能
**核心文件**：
- `/lib/features/hires_capture/` - 高清截图功能模块

此模块保留原始像素分辨率，适合图纸和精确工作场景。

### 4. 标注工具模块

**用途**：提供各种标注工具
**核心文件**：
- `/lib/features/annotation/` - 标注工具模块
- `/lib/features/editor/application/states/tool_state.dart` - 工具状态定义

包含箭头、矩形、圆形、文本等多种标注工具，支持自定义样式和属性。

### 5. 窗口管理模块

**用途**：管理应用窗口行为
**核心文件**：
- `/lib/core/services/window_service.dart` - 窗口服务
- `/macos/Runner/AppDelegate.swift` - macOS窗口管理集成

通过 `window_manager` 插件实现窗口控制功能，如隐藏、显示、截图时临时隐藏等。

## 结论与建议

1. **活跃开发的模块**：
   - 编辑器模块
   - 截图捕获模块
   - 窗口管理功能
   - macOS集成

2. **可能需要清理的文件**：
   - 项目根目录的 `WindowManager.swift`（已被集成到AppDelegate中）
   - 未被引用的演示模块和测试文件

3. **待完成的功能**：
   - OCR文字识别功能
   - GIF录制功能
   - 新版编辑器（如果正在开发）

项目整体架构清晰，采用了现代Flutter开发模式，使用Freezed生成的不可变状态模型和Riverpod进行状态管理。主要功能模块之间的边界清晰，模块内部采用适当的层次结构。 
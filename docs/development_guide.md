# Snipwise 开发指南

本文档详细说明 Snipwise 项目的开发进度、组件设计和实现计划。

## 目录

1. [项目状态](#项目状态)
2. [组件状态管理](#组件状态管理)
3. [导航结构](#导航结构)
4. [开发前准备工作](#开发前准备工作)
5. [代码规范](#代码规范)

## 项目状态

### 已完成部分

1. **基础结构搭建**
   - 项目目录结构规划
   - 依赖项配置
   - 多平台支持配置

2. **核心状态管理**
   - Provider依赖注入系统
   - 全局Theme管理
   - 应用设置管理

3. **数据模型定义**
   - ProjectModel - 项目数据模型
   - HiResSettings - 高清截图设置模型
   - MagnifierModel - 放大镜模型

4. **状态提供器实现**
   - ThemeProvider
   - ToolsProvider
   - ProjectProvider
   - SettingsProvider
   - HiResCapureProvider
   - MagnifierProvider

5. **核心服务实现**
   - FileService - 文件处理服务
   - ScreenshotService - 截图服务
   - ExportService - 导出服务

6. **统一常量系统**
   - AppColors - 颜色常量
   - AppDimensions - 尺寸常量
   - AppStrings - 字符串常量
   - AppAssets - 资源路径常量

7. **路由系统**
   - 简化的两页面导航结构

### 正在进行

1. **用户界面实现**
   - 截图选择页面
   - 图片编辑页面

## 组件状态管理

Snipwise 采用 Provider 模式进行状态管理，每个功能模块通常包含以下几个关键部分：

### 1. 数据模型

定义功能所需的数据结构，如：

```dart
class HiResSettings extends Equatable {
  final bool enabled;
  final int defaultDpi;
  final String outputFormat;
  final int jpgQuality;
  final double sourceScale;
  final Rect? selectedRegion;
  
  // 构造函数、方法等...
}
```

### 2. 状态Provider

管理功能状态与业务逻辑：

```dart
class HiResCapureProvider extends ChangeNotifier {
  HiResSettings _settings = const HiResSettings();
  ui.Image? _sourceImage;
  bool _isProcessing = false;
  
  // Getters, 方法等...
  
  void updateSettings(HiResSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }
}
```

### 3. 组件状态流转

典型的状态流转过程：
1. 用户交互触发Provider方法
2. Provider更新内部状态
3. 调用notifyListeners()通知UI更新
4. 消费Provider的UI组件重建

## 导航结构

Snipwise 使用简化的两页面导航结构，符合截图工具的用户体验需求：

### 1. 截图选择页面 (`/capture`)

- **功能**: 打开软件时显示的主页面，提供各种截图方式选择
- **实现**: `CapturePage` 组件
- **关键元素**: 
  - 主工具栏 - 提供新建、高清截图、视频录制等功能
  - 提示区域 - 显示快捷键提示
  - 截图操作按钮 - 直接触发截图功能

### 2. 图片编辑页面 (`/editor`)

- **功能**: 截图完成后的编辑界面，提供各种标注和编辑工具
- **实现**: `EditorPage` 组件
- **关键元素**:
  - 主工具栏 - 提供新建、高清截图等功能
  - 编辑工具栏 - 提供标注、绘图、测量等功能
  - 图片编辑区 - 显示图片并支持缩放、拖动
  - 工具操作区 - 根据选择的工具显示相应操作选项

### 页面间导航

1. **从截图页面到编辑页面**: 
   ```dart
   Navigator.pushNamed(
     context, 
     AppRoutes.editor,
     arguments: {
       'imageData': capturedImageData,
     },
   );
   ```

2. **从编辑页面返回截图页面**:
   ```dart
   Navigator.pop(context);
   ```

## 开发前准备工作

在进一步开发界面前，需要完成以下工作：

### 1. 依赖安装

确保项目中添加以下依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  equatable: ^2.0.0
  path_provider: ^2.0.0
  file_picker: ^5.0.0
  image: ^4.0.0
  screenshot: ^2.0.0
```

### 2. 平台特定配置

#### macOS 权限配置

在 `macos/Runner/DebugProfile.entitlements` 和 `macos/Runner/Release.entitlements` 中添加：

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
```

#### 其他平台

为其他平台配置相应权限，如Android的文件访问权限、Windows的文件操作权限等。

## 代码规范

### Provider模式最佳实践

1. **状态集中管理**
   - 相关状态应集中在同一Provider中
   - 避免跨Provider直接依赖

2. **UI与逻辑分离**
   - Provider负责业务逻辑和状态管理
   - Widget只负责渲染和事件传递

3. **Consumer精确使用**
   - 尽可能使用小粒度的Consumer
   - 避免整页重建造成性能问题

4. **状态更新优化**
   - 批量状态更改集中调用notifyListeners()
   - 避免频繁、不必要的通知

### 性能优化注意事项

1. **图像处理优化**
   - 大图像处理放在隔离区(Isolate)中进行
   - 使用缓存避免重复处理

2. **UI渲染优化**
   - 使用const构造器
   - 合理使用RepaintBoundary
   - 避免深层次Widget树

### 开发文档维护

1. **实时更新**
   - 每当实现新功能或修改现有功能时，同步更新文档
   - 保持README和开发指南的最新状态

2. **代码注释**
   - 为复杂逻辑添加详细注释
   - 使用文档注释(///)为公共API提供说明

3. **状态流程图**
   - 为复杂交互添加状态流程图
   - 说明各组件间的状态传递关系 
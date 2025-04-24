# Snipwise 开发指南

本文档详细说明 Snipwise 项目的开发进度、组件设计和实现计划。

## 目录

1. [项目状态](#项目状态)
2. [组件状态管理](#组件状态管理)
3. [下一步开发计划](#下一步开发计划)
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

### 正在进行

1. **基础设施完善**
   - 路由管理系统
   - 核心服务实现
   - 常量定义文件

2. **用户界面设计**
   - 规划主编辑界面
   - 工具栏组件设计

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

## 下一步开发计划

项目发展顺序按照用户体验重要性和基础设施需求依次进行：

### 基础设施完善

1. **路由管理系统**
   - 实现应用路由配置
   - 支持页面间导航
   - 处理深层链接

2. **核心服务层**
   - 文件服务 - 负责文件读写操作
   - 截图服务 - 封装截图功能
   - 导出服务 - 处理导出功能

3. **常量管理**
   - 颜色常量
   - 尺寸常量
   - 字符串常量

### 编辑器主界面开发

1. **主布局结构**
   - 创建主页面架构
   - 实现响应式布局
   - 准备工具栏和画布区域

2. **工具栏组件**
   - 实现工具选择UI
   - 与ToolsProvider集成
   - 工具状态反馈

3. **画布实现**
   - 基础图像显示
   - 缩放和平移功能
   - 图层管理基础结构

### 功能模块开发

1. **截图功能**
   - 基础截图工具
   - 窗口捕获
   - 区域选择

2. **标注工具**
   - 基础图形标注
   - 文本标注
   - 标注样式设置

3. **高级功能**
   - 放大镜功能
   - 高清截图功能
   - 灰度遮罩功能

## 开发前准备工作

在开发具体UI页面前，需要完成以下基础设施工作：

### 1. 路由管理系统

```dart
// app/routes/routes.dart
class Routes {
  static const String home = '/';
  static const String editor = '/editor';
  static const String settings = '/settings';
  static const String about = '/about';
}

// app/routes/app_router.dart
class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    Routes.home: (context) => const HomeScreen(),
    Routes.editor: (context) => const EditorScreen(),
    Routes.settings: (context) => const SettingsScreen(),
    Routes.about: (context) => const AboutScreen(),
  };
}
```

### 2. 核心服务实现

```dart
// core/services/file_service.dart
class FileService {
  Future<File?> pickImage() async {
    // 实现文件选择逻辑
  }
  
  Future<bool> saveFile(Uint8List data, String fileName) async {
    // 实现文件保存逻辑
  }
}

// core/services/screenshot_service.dart
class ScreenshotService {
  Future<ui.Image?> captureScreen(Rect? area) async {
    // 实现屏幕截图逻辑
  }
}
```

### 3. 常量定义

```dart
// core/constants/app_colors.dart
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF4CAF50);
  static const Color background = Color(0xFFF5F5F5);
  // 更多颜色...
}

// core/constants/app_dimensions.dart
class AppDimensions {
  static const double toolbarWidth = 60.0;
  static const double propertyPanelWidth = 280.0;
  static const double spacing = 16.0;
  // 更多尺寸...
}
```

### 4. 平台特定配置

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

### 5. 国际化框架

设置基础国际化结构，为后续添加多语言支持做准备。

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
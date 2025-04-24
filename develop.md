# SmartSnipping 开发细节文档

本文档详细说明 SmartSnipping（Snipwise）项目的开发步骤、技术实现方案和关键代码片段。

## 目录

1. [环境准备](#环境准备)
   - [Flutter 环境配置](#flutter-环境配置)
   - [IDE 配置](#ide-配置)
   - [核心依赖项](#核心依赖项)
   - [多平台配置](#多平台配置)
2. [项目架构](#项目架构)
   - [目录结构详解](#目录结构详解)
   - [状态管理设计](#状态管理设计)
3. [核心功能实现](#核心功能实现)
4. [特殊功能详解](#特殊功能详解)
5. [多平台适配](#多平台适配)
6. [性能优化](#性能优化)
7. [测试计划](#测试计划)
8. [发布流程](#发布流程)

## 环境准备

### Flutter 环境配置

#### Flutter SDK 安装

Flutter SDK 3.19.x 是当前的稳定版本，提供了良好的多平台支持和性能优化。推荐使用 Flutter 版本管理工具如 fvm 来管理不同项目的 Flutter 版本。

##### Windows 安装
```bash
# 下载 Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
# 添加到 PATH (PowerShell)
$env:Path += ";$pwd\flutter\bin"
# 验证安装
flutter doctor
```

##### macOS 安装
```bash
# 下载 Flutter SDK
git clone https://github.com/flutter/flutter.git -b stable
# 添加到 PATH (bash/zsh)
export PATH="$PATH:`pwd`/flutter/bin"
echo 'export PATH="$PATH:`pwd`/flutter/bin"' >> ~/.zshrc  # 或 ~/.bash_profile
# 验证安装
flutter doctor
```

##### fvm 安装和使用 (推荐)
```bash
# 安装 fvm
dart pub global activate fvm

# 安装特定版本的 Flutter
fvm install 3.19.3

# 使用特定版本
fvm use 3.19.3
```

#### Dart SDK

Flutter 3.19.x 对应的 Dart SDK 版本为 3.2.x，它提供了多项性能改进和语言特性：
- 支持模式匹配和记录
- 改进的空安全支持
- 增强的异步编程支持

### IDE 配置

#### VS Code 配置

1. **安装扩展**:
   - Flutter (官方扩展)
   - Dart (官方扩展)
   - Flutter Widget Snippets
   - Awesome Flutter Snippets
   - Better Comments
   - Flutter Intl (国际化支持)
   - bloc (如果使用bloc状态管理)

2. **推荐设置**:
   ```json
   {
     "editor.formatOnSave": true,
     "editor.formatOnType": true,
     "dart.previewFlutterUiGuides": true,
     "dart.openDevTools": "flutter",
     "dart.debugExternalPackageLibraries": true,
     "dart.debugSdkLibraries": false,
     "dart.analyzerPath": null,
     "editor.codeActionsOnSave": {
       "source.fixAll": "explicit",
       "source.organizeImports": "explicit"
     },
     "[dart]": {
       "editor.rulers": [80],
       "editor.selectionHighlight": false,
       "editor.suggestSelection": "first",
       "editor.tabCompletion": "onlySnippets",
       "editor.wordBasedSuggestions": "off"
     }
   }
   ```

#### Android Studio / IntelliJ IDEA 配置

1. **安装插件**:
   - Flutter 插件
   - Dart 插件
   - Rainbow Brackets (用于匹配括号)
   - Bloc (如果使用bloc状态管理)
   - .ignore (Git忽略文件支持)
   - Markdown Navigator

2. **推荐设置**:
   - 启用 `Preferences > Editor > Code Style > Dart > Formatting > Format code on save`
   - 配置 `Preferences > Languages & Frameworks > Flutter` 确保 Flutter SDK 路径正确
   - 启用 `Preferences > Editor > General > Auto Import > Add unambiguous imports on the fly`

### 核心依赖项

项目的核心依赖项在 `pubspec.yaml` 中配置，以下是推荐的最新稳定版本：

```yaml
name: smartsnipping
description: A cross-platform screenshot and annotation tool for architecture and drawing communication.
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.2.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
    
  # 状态管理
  provider: ^6.1.1        # 轻量级状态管理
  flutter_riverpod: ^2.4.9 # 可选的响应式状态管理
  
  # UI 工具
  cupertino_icons: ^1.0.6
  flutter_phosphor_icons: ^0.0.1+6
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  
  # 功能性包
  image: ^4.1.3            # 图像处理
  pdf: ^3.10.7             # PDF创建和操作
  path_provider: ^2.1.2    # 文件路径管理
  shared_preferences: ^2.2.2 # 本地设置存储
  file_picker: ^6.1.1      # 文件选择
  screenshot: ^2.1.0       # 屏幕截图
  
  # 高级功能
  flutter_tesseract_ocr: ^0.4.24  # OCR文字识别
  opencv_flutter: ^1.0.0   # 线段识别
  desktop_window: ^0.4.0   # 桌面窗口管理
  flutter_acrylic: ^1.1.3  # 窗口特效 (Windows/macOS)
  
  # 国际化
  intl: ^0.19.0
  flutter_localization: ^0.1.14
  
  # 工具类
  uuid: ^4.2.2           # 唯一ID生成
  equatable: ^2.0.5      # 值类型比较
  logger: ^2.0.2+1       # 日志
  connectivity_plus: ^5.0.2 # 网络连接状态
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  mockito: ^5.4.3
  flutter_launcher_icons: ^0.13.1
```

### 多平台配置

#### Windows 平台配置

1. **前置条件**:
   - Windows 10 或更高版本
   - Visual Studio 2022 带有"使用C++的桌面开发"工作负载
   - Git

2. **配置步骤**:
   ```bash
   # 启用 Windows 桌面支持
   flutter config --enable-windows-desktop
   
   # 验证配置
   flutter devices
   ```

3. **Windows 特有依赖**:
   ```yaml
   msix: ^3.16.7       # Windows MSIX打包
   win32: ^5.2.0       # Windows原生API
   system_theme: ^2.3.1 # 系统主题检测
   ```

#### macOS 平台配置

1. **前置条件**:
   - macOS 12.0 (Monterey) 或更高版本
   - Xcode 14 或更高版本
   - CocoaPods

2. **配置步骤**:
   ```bash
   # 安装依赖
   sudo gem install cocoapods
   
   # 启用 macOS 桌面支持
   flutter config --enable-macos-desktop
   
   # 验证配置
   flutter devices
   ```

3. **macOS 特有依赖**:
   ```yaml
   macos_ui: ^2.0.2  # macOS风格UI组件
   ```

4. **应用沙盒权限** (`macos/Runner/DebugProfile.entitlements` 和 `macos/Runner/Release.entitlements`):
   ```xml
   <key>com.apple.security.app-sandbox</key>
   <true/>
   <key>com.apple.security.network.client</key>
   <true/>
   <key>com.apple.security.files.user-selected.read-write</key>
   <true/>
   <key>com.apple.security.files.downloads.read-write</key>
   <true/>
   ```

#### iOS 平台配置

1. **前置条件**:
   - macOS 系统
   - Xcode 14 或更高版本
   - iOS 开发者账号 (发布时需要)

2. **配置步骤**:
   ```bash
   # 打开 iOS 项目并配置签名
   open ios/Runner.xcworkspace
   ```

3. **权限配置** (`ios/Runner/Info.plist`):
   ```xml
   <key>NSPhotoLibraryUsageDescription</key>
   <string>需要访问相册以保存和读取图片</string>
   <key>NSCameraUsageDescription</key>
   <string>需要访问相机以支持扫描功能</string>
   ```

#### Android 平台配置

1. **前置条件**:
   - Android Studio
   - Android SDK 33 或更高版本
   - Java 11 或更高版本

2. **配置步骤**:
   - 设置 `android/app/build.gradle` 中的最小和目标SDK版本:
     ```gradle
     minSdkVersion 21
     targetSdkVersion 34
     ```

3. **权限配置** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
   <uses-permission android:name="android.permission.MANAGE_DOCUMENTS" />
   ```

4. **Gradle 配置** (android/build.gradle):
   ```gradle
   buildscript {
       ext.kotlin_version = '1.9.20'
       repositories {
           google()
           mavenCentral()
       }
       dependencies {
           classpath 'com.android.tools.build:gradle:8.1.0'
           classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
       }
   }
   ```

## 项目架构

### 目录结构详解

SmartSnipping 使用多模块组织的特性优先(feature-first)架构，这种方式使应用更易于维护和扩展：

```
lib/
├── app/                     # 应用级配置和入口
│   ├── app.dart             # 应用根组件
│   ├── di/                  # 依赖注入
│   │   └── provider_setup.dart # 全局 Provider 配置
│   ├── routes/              # 路由管理
│   │   ├── app_router.dart  # 路由配置
│   │   └── routes.dart      # 路由常量
│   └── themes/              # 主题配置
│       ├── app_theme.dart   # 主题数据
│       └── theme_provider.dart # 主题状态管理
├── core/                    # 核心模块
│   ├── constants/           # 常量定义
│   │   ├── app_constants.dart
│   │   ├── asset_paths.dart
│   │   └── string_constants.dart
│   ├── errors/              # 错误处理
│   │   ├── app_exceptions.dart # 自定义异常
│   │   └── error_handler.dart # 错误处理机制
│   ├── services/            # 核心服务
│   │   ├── analytics_service.dart # 分析服务
│   │   ├── logging_service.dart # 日志服务
│   │   └── storage_service.dart # 存储服务
│   └── utils/               # 工具类
│       ├── file_utils.dart  # 文件操作工具
│       ├── image_utils.dart # 图像处理工具
│       └── platform_utils.dart # 平台相关工具
├── features/                # 功能模块
│   ├── editor/              # 编辑器功能
│   │   ├── data/            # 数据层
│   │   │   ├── models/      # 数据模型
│   │   │   └── repositories/# 数据仓库
│   │   ├── presentation/    # 表现层
│   │   │   ├── pages/       # 页面
│   │   │   ├── widgets/     # 组件
│   │   │   └── providers/   # 状态管理
│   │   └── domain/          # 领域层
│   │       ├── entities/    # 实体
│   │       └── use_cases/   # 用例
│   ├── screenshot/          # 截图功能
│   │   ├── data/            # 数据层
│   │   ├── presentation/    # 表现层
│   │   └── domain/          # 领域层
│   ├── annotation/          # 标注功能
│   │   ├── data/            # 数据层
│   │   ├── presentation/    # 表现层
│   │   └── domain/          # 领域层
│   ├── gif_recording/       # GIF录制功能
│   │   ├── data/            # 数据层
│   │   ├── presentation/    # 表现层
│   │   └── domain/          # 领域层
│   └── ocr/                 # OCR功能
│       ├── data/            # 数据层
│       ├── presentation/    # 表现层
│       └── domain/          # 领域层
├── l10n/                    # 国际化
│   ├── app_en.arb           # 英文
│   ├── app_zh.arb           # 中文
│   └── l10n.dart            # 本地化代理
├── shared/                  # 共享组件和模型
│   ├── widgets/             # 通用组件
│   │   ├── app_bar/         # 自定义AppBar
│   │   ├── buttons/         # 按钮组件
│   │   └── dialogs/         # 对话框组件
│   └── models/              # 共享模型
│       └── project_model.dart # 项目数据模型
└── main.dart                # 应用入口点
```

#### 特殊目录说明

1. **app/**: 包含应用级配置，负责初始化、路由管理和全局状态
2. **core/**: 包含核心功能和工具，这些是应用中多个功能模块共用的
3. **features/**: 按功能拆分的模块，每个功能都遵循类似的结构:
   - **data/**: 数据层，包括数据模型和数据源
   - **domain/**: 业务逻辑层，包含用例和实体
   - **presentation/**: 表现层，包含UI组件和状态管理
4. **l10n/**: 国际化资源
5. **shared/**: 共享组件和模型，各特性模块可共用的内容

### 状态管理设计

SmartSnipping 使用 Provider 进行状态管理，采用 MVVM (Model-View-ViewModel) 架构模式。

#### Provider 配置

在 `app/di/provider_setup.dart` 中配置全局 Provider:

```dart
/// 全局Provider配置
List<SingleChildWidget> globalProviders = [
  ChangeNotifierProvider(create: (_) => ThemeProvider()),
  ChangeNotifierProvider(create: (_) => LocaleProvider()),
  Provider(create: (_) => LoggingService()),
  Provider(create: (_) => AnalyticsService()),
  Provider(create: (_) => StorageService()),
];

/// 特性级Provider配置
List<SingleChildWidget> featureProviders = [
  ChangeNotifierProvider(create: (_) => ProjectProvider()),
  ChangeNotifierProvider(create: (_) => ToolsProvider()),
  ChangeNotifierProvider(create: (_) => SettingsProvider()),
];

/// 依赖型Provider配置
List<SingleChildWidget> dependentProviders = [
  ProxyProvider<StorageService, ProjectRepository>(
    update: (_, storageService, __) => ProjectRepository(storageService),
  ),
  ProxyProvider2<ProjectRepository, AnalyticsService, ProjectProvider>(
    update: (_, projectRepo, analyticsService, __) => 
      ProjectProvider(projectRepo, analyticsService),
  ),
];
```

#### 项目状态模型

`features/editor/presentation/providers/project_provider.dart`:

```dart
/// 管理项目状态的Provider
class ProjectProvider with ChangeNotifier {
  final ProjectRepository _projectRepository;
  final AnalyticsService _analyticsService;
  
  ProjectModel? _currentProject;
  List<ProjectModel> _recentProjects = [];
  bool _isLoading = false;
  String? _error;
  
  ProjectProvider(this._projectRepository, this._analyticsService);
  
  // Getters
  ProjectModel? get currentProject => _currentProject;
  List<ProjectModel> get recentProjects => _recentProjects;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  
  /// 创建新项目
  Future<void> createProject(String name, ui.Image? baseImage) async {
    try {
      _setLoading(true);
      _clearError();
      
      final project = ProjectModel(
        id: const Uuid().v4(),
        name: name,
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
      );
      
      if (baseImage != null) {
        await _setBaseImage(project, baseImage);
      }
      
      await _projectRepository.saveProject(project);
      _currentProject = project;
      _addToRecentProjects(project);
      
      _analyticsService.logEvent('project_created', {
        'project_id': project.id,
        'has_base_image': baseImage != null,
      });
      
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('创建项目失败: ${e.toString()}');
      _analyticsService.logError('project_creation_error', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }
  
  /// 加载项目
  Future<void> loadProject(String projectId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final project = await _projectRepository.getProject(projectId);
      _currentProject = project;
      _addToRecentProjects(project);
      
      _analyticsService.logEvent('project_loaded', {
        'project_id': project.id,
      });
      
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('加载项目失败: ${e.toString()}');
      _analyticsService.logError('project_load_error', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }
  
  /// 保存当前项目
  Future<void> saveCurrentProject() async {
    if (_currentProject == null) {
      _setError('没有活动项目可保存');
      return;
    }
    
    try {
      _setLoading(true);
      _clearError();
      
      // 更新修改时间
      _currentProject = _currentProject!.copyWith(
        modifiedAt: DateTime.now(),
      );
      
      await _projectRepository.saveProject(_currentProject!);
      
      _analyticsService.logEvent('project_saved', {
        'project_id': _currentProject!.id,
      });
      
      notifyListeners();
    } catch (e, stackTrace) {
      _setError('保存项目失败: ${e.toString()}');
      _analyticsService.logError('project_save_error', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }
  
  /// 关闭当前项目
  void closeCurrentProject() {
    _currentProject = null;
    notifyListeners();
  }
  
  // 私有辅助方法
  Future<void> _setBaseImage(ProjectModel project, ui.Image image) async {
    // 实现图像保存逻辑
  }
  
  void _addToRecentProjects(ProjectModel project) {
    // 避免重复
    _recentProjects.removeWhere((p) => p.id == project.id);
    
    // 添加到最前
    _recentProjects.insert(0, project);
    
    // 限制数量
    if (_recentProjects.length > 10) {
      _recentProjects = _recentProjects.sublist(0, 10);
    }
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
}
```

#### 工具状态管理

`features/editor/presentation/providers/tools_provider.dart`:

```dart
/// 工具类型枚举
enum ToolType {
  selection,      // 选择
  rectangle,      // 矩形截图
  freeform,       // 自由形状截图
  window,         // 窗口截图
  gifRecording,   // GIF录制
  text,           // 文本标注
  dimension,      // 尺寸标注
  shape,          // 形状标注
  magnifier,      // 放大镜
  mask,           // 灰度遮罩
  hiRes,          // 高分辨率截图
}

/// 工具设置基类
abstract class ToolSettings {
  final String toolId;
  
  ToolSettings({required this.toolId});
}

/// 工具状态管理
class ToolsProvider with ChangeNotifier {
  ToolType _currentTool = ToolType.selection;
  final Map<ToolType, ToolSettings> _toolSettings = {};
  final AnalyticsService _analyticsService;
  
  ToolsProvider(this._analyticsService);
  
  // Getters
  ToolType get currentTool => _currentTool;
  ToolSettings? getToolSettings(ToolType type) => _toolSettings[type];
  bool get isDrawingTool => _currentTool != ToolType.selection;
  
  /// 选择工具
  void selectTool(ToolType tool) {
    if (_currentTool != tool) {
      _currentTool = tool;
      
      _analyticsService.logEvent('tool_selected', {
        'tool_type': tool.toString(),
      });
      
      notifyListeners();
    }
  }
  
  /// 更新工具设置
  void updateToolSettings(ToolType type, ToolSettings settings) {
    _toolSettings[type] = settings;
    
    _analyticsService.logEvent('tool_settings_updated', {
      'tool_type': type.toString(),
      'settings_id': settings.toolId,
    });
    
    notifyListeners();
  }
  
  /// 重置工具到默认选择工具
  void resetToSelectionTool() {
    selectTool(ToolType.selection);
  }
  
  /// 检查是否为特定工具类型
  bool isToolType(ToolType type) {
    return _currentTool == type;
  }
}
```

#### Provider 的使用方式

在 UI 层，使用 Consumer 和 Provider.of 来访问状态：

```dart
// 使用 Consumer 重建 UI
Consumer<ProjectProvider>(
  builder: (context, projectProvider, child) {
    if (projectProvider.isLoading) {
      return const CircularProgressIndicator();
    }
    
    if (projectProvider.hasError) {
      return Text('Error: ${projectProvider.error}');
    }
    
    final project = projectProvider.currentProject;
    if (project == null) {
      return const Text('No project loaded');
    }
    
    return Text('Project: ${project.name}');
  },
),

// 使用 Provider.of 获取状态但不监听变化
final toolsProvider = Provider.of<ToolsProvider>(context, listen: false);
toolsProvider.selectTool(ToolType.rectangle);

// 使用 context.read 获取状态但不监听变化(推荐)
context.read<ToolsProvider>().selectTool(ToolType.rectangle);

// 使用 context.watch 监听状态变化(推荐)
final currentTool = context.watch<ToolsProvider>().currentTool;
```

#### 为什么选择 Provider 而不是其他状态管理方案

1. **学习曲线低**: Provider API 简单清晰，易于学习
2. **轻量级**: 没有太多的样板代码和复杂概念
3. **官方支持**: 作为 Flutter 官方推荐的状态管理方案之一
4. **良好的测试支持**: 易于创建 mock Provider 进行测试
5. **按需传递**: 状态可以在需要的层级传递，而非全局

如果应用规模进一步扩大，可以考虑使用 Riverpod (Provider 的升级版)，它提供了更好的类型安全和依赖管理。

## 核心功能实现

### 1. 截图功能实现

#### 矩形截图工具

```dart
class RectangleScreenshotTool extends BaseTool {
  Offset? _startPoint;
  Offset? _endPoint;
  
  @override
  void onPointerDown(PointerDownEvent event) {
    _startPoint = event.localPosition;
    _endPoint = _startPoint;
  }
  
  @override
  void onPointerMove(PointerMoveEvent event) {
    _endPoint = event.localPosition;
    notifyListeners();
  }
  
  @override
  void onPointerUp(PointerUpEvent event) {
    if (_startPoint != null && _endPoint != null) {
      final rect = Rect.fromPoints(_startPoint!, _endPoint!);
      captureScreenshot(rect);
    }
    _startPoint = null;
    _endPoint = null;
    notifyListeners();
  }
  
  @override
  void paint(Canvas canvas, Size size) {
    if (_startPoint != null && _endPoint != null) {
      final rect = Rect.fromPoints(_startPoint!, _endPoint!);
      final paint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
      
      final borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(rect, borderPaint);
    }
  }
}
```

#### GIF 录制功能实现

使用 Dart 的 `image` 包实现 GIF 录制功能：

```dart
class GifRecorder {
  final List<ui.Image> _frames = [];
  bool _isRecording = false;
  DateTime? _startTime;
  int _fps = 10;
  Timer? _captureTimer;
  
  bool get isRecording => _isRecording;
  
  void startRecording(int fps) {
    _fps = fps;
    _frames.clear();
    _isRecording = true;
    _startTime = DateTime.now();
    
    // 定时捕获帧
    _captureTimer = Timer.periodic(Duration(milliseconds: 1000 ~/ _fps), (_) {
      captureFrame();
    });
  }
  
  Future<void> captureFrame() async {
    if (!_isRecording) return;
    
    // 捕获屏幕区域
    final ui.Image screenshot = await _captureScreenArea();
    _frames.add(screenshot);
  }
  
  Future<String> stopRecording() async {
    _isRecording = false;
    _captureTimer?.cancel();
    
    // 使用 image 包处理 GIF 生成
    final gif = image.GifEncoder();
    
    // 设置 GIF 参数
    gif.samplingFactor = 10; // 压缩因子，影响文件大小
    gif.repeat = 0; // 循环次数，0表示无限循环
    
    // 将捕获的帧转换为 image 包可用的格式
    for (final frame in _frames) {
      final bytes = await _imageToBytes(frame);
      final imgFrame = image.Image.fromBytes(
        width: frame.width,
        height: frame.height,
        bytes: bytes.buffer.asUint8List(),
      );
      
      // 每帧延迟时间 (1/fps 秒，转换为毫秒)
      gif.addFrame(imgFrame, delay: 1000 ~/ _fps);
    }
    
    // 编码 GIF
    final Uint8List gifData = Uint8List.fromList(gif.finish());
    
    // 保存 GIF 文件
    final path = await _saveGif(gifData);
    
    // 清理
    _frames.clear();
    
    return path;
  }
  
  Future<Uint8List> _imageToBytes(ui.Image image) async {
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return byteData!.buffer.asUint8List();
  }
  
  Future<ui.Image> _captureScreenArea() async {
    // 实现屏幕区域捕获的逻辑
    // ...
  }
  
  Future<String> _saveGif(Uint8List data) async {
    final directory = await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.gif';
    final File file = File(path);
    await file.writeAsBytes(data);
    return path;
  }
}
```

### 2. 高清截图功能

```dart
class HiResCaptureTool {
  ui.Image? _sourceImage;
  Rect? _selectedArea;
  double _screenZoom = 1.0;
  
  void setSourceImage(ui.Image image) {
    _sourceImage = image;
  }
  
  void setSelectedArea(Rect area) {
    // 转换为实际图像坐标
    _selectedArea = Rect.fromLTWH(
      area.left / _screenZoom,
      area.top / _screenZoom,
      area.width / _screenZoom,
      area.height / _screenZoom
    );
  }
  
  void setScreenZoom(double zoom) {
    _screenZoom = zoom;
  }
  
  Future<ui.Image> captureHighRes() async {
    if (_sourceImage == null || _selectedArea == null) {
      throw Exception('Source image or selected area not set');
    }
    
    // 使用原始图像的像素进行裁剪，而不是屏幕显示的缩放像素
    return _cropImage(_sourceImage!, _selectedArea!);
  }
  
  Future<ui.Image> _cropImage(ui.Image image, Rect rect) async {
    // 实现高精度图像裁剪
    // ...
  }
  
  Future<File> saveWithSettings(ui.Image image, int dpi, String format, {int jpgQuality = 90}) async {
    // 实现图像保存，带有DPI和格式设置
    // ...
  }
}
```

### 3. 比例尺系统

```dart
class ScaleSystem {
  double _pixelsPerUnit = 1.0; // 每单位实际长度对应的像素数
  String _unit = 'mm'; // 度量单位
  
  void setScale(double pixelDistance, double realWorldDistance) {
    _pixelsPerUnit = pixelDistance / realWorldDistance;
  }
  
  double convertPixelsToRealWorld(double pixels) {
    return pixels / _pixelsPerUnit;
  }
  
  double convertRealWorldToPixels(double realWorld) {
    return realWorld * _pixelsPerUnit;
  }
  
  void setUnit(String unit) {
    _unit = unit;
  }
  
  String formatMeasurement(double pixels) {
    final realWorld = convertPixelsToRealWorld(pixels);
    return '${realWorld.toStringAsFixed(2)} $_unit';
  }
}
```

## 特殊功能详解

### 1. GIF 录制完整实现

#### GIF 录制服务

```dart
class GifRecordingService {
  final int _defaultFps = 10;
  final int _defaultMaxDuration = 10; // 最大录制秒数
  final int _defaultQuality = 75; // 默认质量 (0-100)
  
  late GifRecorder _recorder;
  Rect _recordingArea = Rect.zero;
  
  GifRecordingService() {
    _recorder = GifRecorder();
  }
  
  void setRecordingArea(Rect area) {
    _recordingArea = area;
  }
  
  Future<void> startRecording({
    int? fps,
    int? maxDuration,
    int? quality,
  }) async {
    fps ??= _defaultFps;
    maxDuration ??= _defaultMaxDuration;
    quality ??= _defaultQuality;
    
    // 配置录制器
    _recorder.setQuality(quality);
    _recorder.setArea(_recordingArea);
    
    // 开始录制
    await _recorder.startRecording(fps);
    
    // 设置最大录制时间
    Future.delayed(Duration(seconds: maxDuration), () {
      if (_recorder.isRecording) {
        stopRecording();
      }
    });
  }
  
  Future<String> stopRecording() async {
    if (!_recorder.isRecording) {
      return '';
    }
    
    // 停止录制并返回文件路径
    final filePath = await _recorder.stopRecording();
    return filePath;
  }
  
  Future<void> optimizeGif(String filePath, {int? targetSizeKB}) async {
    // 优化GIF文件大小
    if (targetSizeKB != null) {
      await _optimizeGifSize(filePath, targetSizeKB);
    }
  }
  
  Future<void> _optimizeGifSize(String filePath, int targetSizeKB) async {
    final file = File(filePath);
    final originalSize = await file.length();
    
    // 如果原始文件已经小于目标大小，无需优化
    if (originalSize <= targetSizeKB * 1024) {
      return;
    }
    
    // 读取原始GIF
    final gifData = await file.readAsBytes();
    final decoder = image.GifDecoder();
    final originalGif = decoder.decodeAnimation(gifData.buffer.asUint8List());
    
    if (originalGif == null) {
      throw Exception('Failed to decode GIF');
    }
    
    // 计算压缩比例
    final compressionRatio = (targetSizeKB * 1024) / originalSize;
    
    // 创建新的编码器
    final encoder = image.GifEncoder();
    
    // 设置更高的压缩率
    encoder.samplingFactor = (10 / compressionRatio).round().clamp(1, 30);
    
    // 可能需要降低颜色数量
    final colorLimit = (256 * compressionRatio).round().clamp(16, 256);
    
    // 重新编码每一帧
    for (int i = 0; i < originalGif.frames.length; i++) {
      final frame = originalGif.frames[i];
      
      // 降低颜色数量
      final quantized = image.quantize(frame.image, numberOfColors: colorLimit);
      
      // 可能需要调整尺寸
      var resizedImage = quantized;
      if (compressionRatio < 0.5) {
        final newWidth = (frame.image.width * sqrt(compressionRatio)).round();
        final newHeight = (frame.image.height * sqrt(compressionRatio)).round();
        resizedImage = image.copyResize(quantized, width: newWidth, height: newHeight);
      }
      
      // 添加到新GIF
      encoder.addFrame(resizedImage, delay: frame.duration);
    }
    
    // 完成编码
    final optimizedData = Uint8List.fromList(encoder.finish());
    
    // 保存优化后的GIF
    await file.writeAsBytes(optimizedData);
  }
}
```

#### GIF 录制UI组件

```dart
class GifRecordingControls extends StatefulWidget {
  final Function(Rect) onAreaSelected;
  final Function(int) onFpsChanged;
  final Function() onStartRecording;
  final Function() onStopRecording;
  
  const GifRecordingControls({
    Key? key,
    required this.onAreaSelected,
    required this.onFpsChanged,
    required this.onStartRecording,
    required this.onStopRecording,
  }) : super(key: key);
  
  @override
  _GifRecordingControlsState createState() => _GifRecordingControlsState();
}

class _GifRecordingControlsState extends State<GifRecordingControls> {
  bool _isRecording = false;
  int _fps = 10;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void _startRecording() {
    setState(() {
      _isRecording = true;
      _elapsedTime = Duration.zero;
    });
    
    widget.onStartRecording();
    
    // 开始计时
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      setState(() {
        _elapsedTime += Duration(seconds: 1);
      });
    });
  }
  
  void _stopRecording() {
    _timer?.cancel();
    
    setState(() {
      _isRecording = false;
    });
    
    widget.onStopRecording();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GIF 录制',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 12),
          if (!_isRecording) ...[
            Row(
              children: [
                Text('帧率: $_fps FPS'),
                Expanded(
                  child: Slider(
                    value: _fps.toDouble(),
                    min: 5,
                    max: 30,
                    divisions: 5,
                    label: '$_fps FPS',
                    onChanged: (value) {
                      setState(() {
                        _fps = value.round();
                      });
                      widget.onFpsChanged(_fps);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              icon: Icon(Icons.fiber_manual_record),
              label: Text('开始录制'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: _startRecording,
            ),
          ] else ...[
            Row(
              children: [
                Icon(Icons.timer, size: 16),
                SizedBox(width: 8),
                Text(
                  '${_elapsedTime.inMinutes.toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              icon: Icon(Icons.stop),
              label: Text('停止录制'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
              ),
              onPressed: _stopRecording,
            ),
          ],
        ],
      ),
    );
  }
}
```

### 2. OCR 文字识别实现

```dart
class OcrService {
  late FlutterTesseractOcr _tesseract;
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 初始化 Tesseract OCR
    _tesseract = FlutterTesseractOcr();
    
    // 确保语言数据已下载
    await _ensureLanguageData(['eng', 'chi_sim', 'jpn']);
    
    _isInitialized = true;
  }
  
  Future<void> _ensureLanguageData(List<String> languages) async {
    for (final language in languages) {
      final hasData = await _tesseract.hasLanguageData(language);
      if (!hasData) {
        await _tesseract.downloadLanguageData(language);
      }
    }
  }
  
  Future<List<OcrTextBlock>> recognizeText(ui.Image image, {String language = 'eng'}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // 将图像转换为字节数据
    final bytes = await _imageToBytes(image);
    
    // 执行OCR识别
    final result = await _tesseract.recognizeText(
      bytes,
      language: language,
      args: {
        'preserve_interword_spaces': '1',
        'include_block_info': '1',
      },
    );
    
    // 解析OCR结果
    return _parseOcrResult(result, image.width, image.height);
  }
  
  Future<Uint8List> _imageToBytes(ui.Image image) async {
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return byteData!.buffer.asUint8List();
  }
  
  List<OcrTextBlock> _parseOcrResult(String result, int imageWidth, int imageHeight) {
    // 实现OCR结果解析逻辑，提取文本块及其位置信息
    // ...
    
    return [];
  }
}

class OcrTextBlock {
  final String text;
  final Rect bounds;
  final double confidence;
  
  OcrTextBlock({
    required this.text,
    required this.bounds,
    required this.confidence,
  });
}
```

## 多平台适配

### 平台特定代码封装

```dart
class PlatformService {
  bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  bool get isMobile => Platform.isAndroid || Platform.isIOS;
  
  Future<ui.Image?> captureScreenshot() async {
    if (Platform.isWindows) {
      return _captureWindowsScreenshot();
    } else if (Platform.isMacOS) {
      return _captureMacOSScreenshot();
    } else if (Platform.isAndroid) {
      return _captureAndroidScreenshot();
    } else if (Platform.isIOS) {
      return _captureIOSScreenshot();
    }
    return null;
  }
  
  Future<ui.Image?> _captureWindowsScreenshot() async {
    // Windows平台特定的截图实现
    // ...
  }
  
  Future<ui.Image?> _captureMacOSScreenshot() async {
    // macOS平台特定的截图实现
    // ...
  }
  
  Future<ui.Image?> _captureAndroidScreenshot() async {
    // Android平台特定的截图实现
    // ...
  }
  
  Future<ui.Image?> _captureIOSScreenshot() async {
    // iOS平台特定的截图实现
    // ...
  }
  
  Future<void> saveFile(Uint8List data, String suggestedName) async {
    if (isDesktop) {
      await _saveFileDesktop(data, suggestedName);
    } else {
      await _saveFileMobile(data, suggestedName);
    }
  }
  
  Future<void> _saveFileDesktop(Uint8List data, String suggestedName) async {
    // 使用文件选择对话框实现桌面平台的文件保存
    // ...
  }
  
  Future<void> _saveFileMobile(Uint8List data, String suggestedName) async {
    // 实现移动平台的文件保存
    // ...
  }
}
```

## 性能优化

### 图像处理优化

```dart
class ImageProcessingOptimizer {
  static Future<ui.Image> resizeForDisplay(ui.Image image, Size targetSize) async {
    // 计算最佳尺寸，避免内存过度使用
    final double aspectRatio = image.width / image.height;
    int targetWidth, targetHeight;
    
    if (aspectRatio > targetSize.width / targetSize.height) {
      targetWidth = targetSize.width.toInt();
      targetHeight = (targetWidth / aspectRatio).toInt();
    } else {
      targetHeight = targetSize.height.toInt();
      targetWidth = (targetHeight * aspectRatio).toInt();
    }
    
    // 使用较低分辨率进行显示
    return _resizeImage(image, targetWidth, targetHeight);
  }
  
  static Future<ui.Image> _resizeImage(ui.Image image, int width, int height) async {
    // 实现图像缩放
    // ...
  }
  
  static Future<void> processImageInIsolate(Uint8List imageData, Function(Uint8List) callback) async {
    // 在隔离区处理大型图像，避免主线程阻塞
    final ReceivePort receivePort = ReceivePort();
    await Isolate.spawn(_isolateProcessing, [receivePort.sendPort, imageData]);
    
    // 接收处理结果
    receivePort.listen((resultData) {
      if (resultData is Uint8List) {
        callback(resultData);
      }
      receivePort.close();
    });
  }
  
  static void _isolateProcessing(List<dynamic> params) {
    final SendPort sendPort = params[0];
    final Uint8List imageData = params[1];
    
    // 在隔离区处理图像
    // ...
    
    sendPort.send(processedData);
  }
}
```

## 测试计划

### 单元测试示例

```dart
void main() {
  group('ScaleSystem Tests', () {
    late ScaleSystem scaleSystem;
    
    setUp(() {
      scaleSystem = ScaleSystem();
    });
    
    test('setScale correctly calculates pixels per unit', () {
      // 100 pixels 对应 50mm
      scaleSystem.setScale(100, 50);
      expect(scaleSystem.pixelsPerUnit, 2.0);
    });
    
    test('convertPixelsToRealWorld correctly converts values', () {
      scaleSystem.setScale(100, 50); // 2 pixels per mm
      expect(scaleSystem.convertPixelsToRealWorld(200), 100);
    });
    
    test('convertRealWorldToPixels correctly converts values', () {
      scaleSystem.setScale(100, 50); // 2 pixels per mm
      expect(scaleSystem.convertRealWorldToPixels(25), 50);
    });
    
    test('formatMeasurement returns correctly formatted string', () {
      scaleSystem.setScale(100, 50); // 2 pixels per mm
      scaleSystem.setUnit('mm');
      expect(scaleSystem.formatMeasurement(150), '75.00 mm');
    });
  });
}
```

### 集成测试示例

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Complete screenshot workflow test', (WidgetTester tester) async {
    // 启动应用
    app.main();
    await tester.pumpAndSettle();
    
    // 打开新项目
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    
    // 选择矩形截图工具
    await tester.tap(find.byIcon(Icons.crop));
    await tester.pumpAndSettle();
    
    // 执行截图操作
    final center = tester.getCenter(find.byType(EditorCanvas));
    await tester.dragFrom(
      Offset(center.dx - 100, center.dy - 100),
      Offset(200, 200),
    );
    await tester.pumpAndSettle();
    
    // 验证截图结果
    expect(find.byType(ScreenshotPreview), findsOneWidget);
    
    // 添加文本标注
    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EditorCanvas));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Test Annotation');
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    
    // 验证文本标注已添加
    expect(find.text('Test Annotation'), findsOneWidget);
    
    // 保存项目
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Test Project');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    
    // 验证保存成功
    expect(find.text('保存成功'), findsOneWidget);
  });
}
```

## 发布流程

### 发布清单

1. 版本号更新
   ```dart
   // 在 pubspec.yaml 中更新版本号
   version: 1.0.0+1  # 格式为 版本号+构建号
   ```

2. 构建脚本
   ```bash
   # Windows 构建
   flutter build windows --release
   
   # macOS 构建
   flutter build macos --release
   
   # iOS 构建
   flutter build ios --release
   
   # Android 构建
   flutter build appbundle --release
   ```

3. 发布前测试清单
   - 运行所有单元测试: `flutter test`
   - 运行所有集成测试: `flutter test integration_test`
   - 手动测试关键功能
   - 在目标平台测试性能与兼容性
   - 确认所有文档已更新

4. 应用商店发布步骤
   - App Store: 使用 XCode 归档并提交
   - Google Play: 上传 AAB 文件
   - Microsoft Store: 创建 MSIX 包并提交
   - Mac App Store: 创建 pkg 安装包并提交

5. 更新日志模板
   ```markdown
   # v1.0.0 (2023-06-01)
   
   ## 新功能
   - 添加高清截图功能
   - 支持GIF录制
   - 添加多语言支持
   
   ## 优化
   - 提高OCR识别精度
   - 优化大图像处理性能
   
   ## 修复
   - 修复在某些设备上截图失真的问题
   - 解决内存泄漏问题
   ``` 
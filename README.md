# Snipwise - 专业截图标注工具

一款专业的截图与标注工具，适用于建筑行业和图纸沟通，支持 Windows、macOS、iOS 和 Android 平台。

## 项目概述

Snipwise 是一款使用 Flutter 开发的跨平台截图标注工具，旨在提供类似 Windows Snipping Tool 的操作体验，同时具备更强大的标注、识别、比例控制与导出能力。特别适合建筑行业使用，方便图纸沟通和标注。支持多语言环境，满足国际用户需求。

## 项目结构

```
lib/
├── app/                     # 应用级配置和入口
│   ├── app.dart             # 应用根组件
│   ├── di/                  # 依赖注入
│   │   └── provider_setup.dart # 全局 Provider 配置
│   ├── routes/              # 路由管理
│   │   ├── app_routes.dart  # 路由定义
│   │   └── app_router.dart  # 路由器实现
│   └── themes/              # 主题配置
│       ├── app_theme.dart   # 主题数据
│       └── theme_provider.dart # 主题状态管理
├── core/                    # 核心模块
│   ├── constants/           # 常量定义
│   │   └── app_constants.dart # 应用常量
│   ├── errors/              # 错误处理
│   ├── services/            # 核心服务
│   │   ├── file_service.dart    # 文件处理服务
│   │   ├── screenshot_service.dart # 截图服务
│   │   └── export_service.dart     # 导出服务
│   └── utils/               # 工具类
├── features/                # 功能模块
│   ├── capture/             # 截图选择功能
│   │   └── presentation/    # 表现层
│   │       └── pages/       # 页面
│   │           └── capture_page.dart # 截图选择页面
│   ├── editor/              # 编辑器功能
│   │   ├── data/            # 数据层
│   │   │   ├── models/      # 数据模型
│   │   │   └── repositories/ # 数据仓库
│   │   ├── domain/          # 领域层
│   │   └── presentation/    # 表现层
│   │       ├── pages/       # 页面
│   │       │   └── editor_page.dart # 图片编辑页面
│   │       ├── widgets/     # 组件
│   │       └── providers/   # 状态管理
│   ├── hires_capture/       # 高清截图功能
│   └── annotation/          # 标注功能
├── l10n/                    # 国际化
└── shared/                  # 共享组件和模型
    └── widgets/             # 通用组件
```

## 核心功能

- 🖼️ **高清截图功能**：保持原始像素质量的高分辨率截图
- 📐 **比例尺设置**：用户可设置实际尺寸比例，自动计算标注尺寸
- 🔦 **灰度遮罩高亮**：添加半透明遮罩，突出显示关键区域
- 🔍 **放大镜工具**：局部放大显示细节，可添加多个放大镜
- ✒️ **OCR 功能**：自动识别图中文字，生成可编辑文本框
- 📏 **线段/交点识别**：自动检测直线与交点，提供精确标注
- 🔄 **拖拽导出功能**：支持将截图直接拖拽到其他应用程序中使用

## 开发状态

- [x] 项目结构搭建
- [x] 核心状态模型设计
- [x] 主题系统实现
- [x] 高清截图模型定义
- [x] 放大镜功能模型定义
- [x] Provider依赖注入系统
- [x] 核心服务实现
- [x] 常量定义系统
- [x] 路由管理系统
- [x] 拖拽导出功能实现（Flutter端）
- [ ] 截图选择页面完善
- [ ] 图片编辑页面完善
- [ ] 高级功能（放大镜、高清截图等）
- [ ] 国际化支持

## 应用导航结构

Snipwise 使用简化的导航结构，只包含两个主要页面：

1. **截图选择页面** (`/capture`)
   - 应用启动时显示的主页面
   - 提供各种截图方式选择
   - 快捷键提示与截图按钮

2. **图片编辑页面** (`/editor`)
   - 截图完成后的编辑界面
   - 提供多种标注和编辑工具
   - 支持各种绘图、测量和标注功能

这种简化的导航体验符合截图工具的使用场景，让用户能快速完成截图和编辑操作。

## 状态管理设计

每个功能模块的状态管理采用Provider模式，包含以下组成部分：

- **数据模型**：定义功能所需的数据结构和状态字段
- **状态Provider**：管理状态变更和业务逻辑
- **UI组件**：响应状态变化的视图层

### 主要状态提供器

- **ProjectProvider**：管理项目状态
- **ToolsProvider**：管理工具选择状态
- **SettingsProvider**：管理应用设置
- **HiResCapureProvider**：管理高清截图状态
- **MagnifierProvider**：管理放大镜状态

### 编辑器状态架构（2023年8月重构）

编辑器模块采用分层状态架构，提高模块化程度与可维护性：

- **EditorStateCore**：核心状态管理器，协调所有子状态
  - 位于 `lib/features/editor/application/core/editor_state_core.dart`
  - 提供统一状态访问和更新接口
  - 管理复杂的跨状态操作

- **核心Provider**：基础状态提供者
  - 位于 `lib/features/editor/application/providers/core_providers.dart`
  - 负责最基本的状态管理（编辑器状态、布局、工具等）

- **画布Provider**：画布与变换相关状态
  - 位于 `lib/features/editor/application/providers/canvas_providers.dart`
  - 管理画布尺寸、缩放、内边距等状态

- **壁纸Provider**：背景与装饰相关状态
  - 位于 `lib/features/editor/application/providers/wallpaper_providers.dart`
  - 管理背景颜色、装饰、边框等状态

- **绘图Provider**：标注与绘制相关状态
  - 位于 `lib/features/editor/application/providers/painter_providers.dart`
  - 管理绘图工具、线条样式、填充等状态

- **管理器层**：功能聚合与业务逻辑
  - 如 `CanvasManager`，位于 `lib/features/editor/application/managers`
  - 提供高级别功能聚合，减少状态耦合

## 开发计划

### 用户界面

1. **截图选择页面** *(进行中)*
   - 完善工具栏功能
   - 实现快捷键功能
   - 添加截图预览

2. **图片编辑页面** *(进行中)*
   - 完善编辑工具
   - 实现标注功能
   - 图像处理功能

### 核心功能

1. **截图功能**
   - 实现屏幕/窗口/区域截图
   - 添加截图延时选项
   - 高清截图功能

2. **标注工具**
   - 各种绘图工具实现
   - 测量功能
   - 文本标注

## 开发指南

详细的开发指南请参考 [docs/development_guide.md](docs/development_guide.md)。

### 环境配置

```bash
# 安装依赖
flutter pub get

# 运行应用
flutter run
```

### 添加新功能

1. 在 `features/` 目录下创建功能模块
2. 为功能创建数据模型和Provider
3. 在 `provider_setup.dart` 中注册Provider
4. 开发功能的UI组件
5. 更新开发文档和README

## 参与贡献

请确保遵循以下原则：
- 遵循项目的代码规范
- 保持文档更新与代码同步
- 编写必要的测试代码
- 提交前进行代码自审

## 贡献者

- [您的名字]

## 许可证

[待定]
# Snipwise 状态管理文档
- [状态管理详细文档](docs/state_management.md)

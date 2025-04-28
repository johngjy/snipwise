# Feature: 实现 Snipwise 编辑器图像的跨平台拖拽导出 (macOS & Windows)

---

## 目标 (Goal)

允许用户从 Snipwise 图像编辑器界面（例如，工具栏按钮或缩略图）**拖动图像**，并在拖动开始前**自动将当前编辑的图像保存**到一个临时的 `.png` 文件。用户可以将此图像**放置**到 **macOS 或 Windows 的外部应用程序**（如 Finder/Photoshop、资源管理器/画图）中，使其表现为图像文件或图像内容。拖拽操作结束后，临时文件应被自动清理。

---

## 平台 (Platform)

- 目标操作系统：macOS, Windows
- 开发语言：
  - Dart (Flutter 跨平台 UI + 业务逻辑)
  - Swift / Objective-C (macOS 原生实现)
  - C++ (Windows 原生实现 - 使用 Win32 API / COM)
- 框架：Flutter 桌面应用（macOS/Windows targets）

---

## 期望的用户体验 (Desired User Experience)

1. 用户按下并拖动 Flutter UI 元素 (GestureDetector)。
2. 保存当前图像为临时 `.png` 文件。
3. 调用 Platform Channel，传递临时文件路径和屏幕坐标。
4. 原生代码启动标准系统拖拽流程。
5. 拖动到外部应用时识别为图像文件或内容。
6. 拖拽结束后，原生端删除临时文件。

---

## UI 要求 (UI Requirements)

- 单独封装一个 Widget（如 `DraggableExportImageButton`）。
- 显示静态缩略图或图标。
- 没有图像时禁用拖拽按钮。

---

## 图像处理 (Image Handling)

- 图像源：Flutter端 `Uint8List` PNG 数据。
- 保存：写入系统临时目录，使用唯一文件名。
- 清理：必须在各平台原生端处理拖拽结束时清除临时文件。

---

## 详细开发步骤

### Flutter端实现 (已完成)

1. **创建核心服务类** (`lib/src/features/drag_export/drag_export_service.dart`)
   - 实现单例模式服务类管理拖拽操作
   - 创建处理临时文件保存与清理的逻辑
   - 通过MethodChannel与平台原生代码通信

2. **实现UI组件** (`lib/src/features/drag_export/draggable_export_button.dart`)
   - 创建自定义按钮组件，接收图像数据
   - 实现拖拽手势处理
   - 在拖拽开始时调用服务类处理导出逻辑
   - 实现可视化状态反馈

### 需要完成的平台特定实现

3. **macOS 原生实现** (`macos/Runner/DragImageHandler.swift`)
   - 创建拖拽处理器类实现 `NSDraggingSource` 协议
   - 设置 `NSPasteboard` 提供图像文件和数据
   - 处理拖拽结束事件并清理临时文件
   - 集成到 AppDelegate 注册 MethodChannel 处理器

4. **Windows 原生实现** (`windows/runner/win32_drag_handler.cpp`)
   - 创建 COM 接口实现 (`IDropSource`, `IDataObject`)
   - 设置 `CF_HDROP` 和 `CF_DIB` 格式
   - 调用 `DoDragDrop` 开始拖拽操作
   - 处理拖拽结束事件并清理临时文件

5. **集成到编辑器界面**
   - 在编辑器工具栏中添加 `DraggableExportButton` 组件
   - 将当前图像数据传递给组件
   - 确保正确处理各种状态和错误

---

## Flutter端集成步骤 (Flutter Side)

```dart
final MethodChannel _channel = const MethodChannel('snipwise_drag_export');

void _handleDragStart(DragStartDetails details) async {
  if (currentImageBytes == null) return;
  String? tempFilePath;
  try {
    final tempDir = await getTemporaryDirectory();
    tempFilePath = '${tempDir.path}${Platform.pathSeparator}snipwise_export_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(tempFilePath).writeAsBytes(currentImageBytes!, flush: true);
    final Offset screenPosition = details.globalPosition;
    await _channel.invokeMethod('startImageDrag', {
      'filePath': tempFilePath,
      'originX': screenPosition.dx,
      'originY': screenPosition.dy,
    });
  } on PlatformException catch (e) {
    print("Platform error: \$e");
    await _cleanupFailedTempFile(tempFilePath);
  } catch (e) {
    print("Error: \$e");
    await _cleanupFailedTempFile(tempFilePath);
  }
}

Future<void> _cleanupFailedTempFile(String? path) async {
  if (path != null && await File(path).exists()) {
    await File(path).delete();
  }
}
```

---

## 原生实现 (Native Side)

### macOS (Swift/ObjC)

- `NSDraggingSession`, `NSPasteboard`, `NSDraggingSource`
- 屏幕坐标 ➔ contentView 坐标正确转换
- 提供 `.fileURL` 和 `.tiff` 类型
- 拖拽结束后 (`draggingSession:endedAt:operation:`) 删除临时文件

### Windows (C++)

- `IDropSource`, `IDataObject`, `DoDragDrop`
- 构造 `CF_HDROP` (Unicode版DROPFILES)
- 可选支持 `CF_DIB` / `CF_BITMAP`
- 拖拽结束后 (`QueryContinueDrag`) 删除临时文件

---

## 技术说明与跨平台挑战

- 必须分别维护 macOS / Windows 两套原生逻辑
- 处理好坐标转换、文件路径编码
- 原生拖拽中临时文件生命周期管理要严格
- 错误处理要跨Dart/Swift/C++全面覆盖

---

## 建议的文件结构

```bash
lib/
  └── src/
      └── features/
          └── drag_export/
              ├── draggable_export_button.dart
              └── drag_export_service.dart

macos/
  └── Runner/
      ├── AppDelegate.swift
      └── DragImageHandler.swift

windows/
  └── runner/
      ├── win32_drag_handler.h
      ├── win32_drag_handler.cpp
      └── flutter_window.cpp
```

---

## 实现进度

- [x] Flutter 拖拽按钮组件 (`draggable_export_button.dart`) 
- [x] Flutter 拖拽服务类 (`drag_export_service.dart`)
- [x] macOS 原生拖拽实现 (`DragImageHandler.swift`)
- [x] Windows 原生拖拽实现 (`win32_drag_handler.cpp`)
- [x] 集成到编辑器页面

---

## 拓展目标 (Stretch Goals)

- 支持JPG格式导出
- Windows 使用 Shell API (`SHDoDragDrop`)

---

## 验收标准 (Acceptance Criteria)

- 用户在 macOS 和 Windows 成功发起拖拽。
- 图像能保存并正确放置到目标应用。
- 临时文件能在拖拽结束后可靠清理。
- 出错时能记录日志并清理资源。

---

# Tags

`#flutter` `#crossplatform` `#macos` `#windows` `#draganddrop` `#platformchannel` `#swift` `#cpp` `#nativeintegration` `#snipwise`

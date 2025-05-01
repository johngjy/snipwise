import Cocoa
import FlutterMacOS

// MARK: - 定义拖拽插件类

/// 图像拖拽导出插件类 - 直接在MainFlutterWindow.swift中定义以避免导入问题
class DragExportPlugin: NSObject, FlutterPlugin, NSDraggingSource {
    /// 临时文件路径
    private var tempFilePath: String?
    
    /// 注册插件
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "snipwise_drag_export", 
                                          binaryMessenger: registrar.messenger)
        let instance = DragExportPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        NSLog("DragExportPlugin: 插件注册成功")
    }
    
    /// 处理Flutter方法调用
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("DragExportPlugin: 收到方法调用 \(call.method) 参数: \(String(describing: call.arguments))")
        
        if call.method == "startImageDrag" {
            guard let args = call.arguments as? [String: Any],
                  let filePath = args["filePath"] as? String,
                  let originX = args["originX"] as? Double,
                  let originY = args["originY"] as? Double else {
                NSLog("DragExportPlugin: 无效参数")
                result(FlutterError(code: "INVALID_ARGS", 
                                   message: "Invalid arguments", 
                                   details: nil))
                return
            }
            
            NSLog("DragExportPlugin: 开始拖拽处理，文件路径: \(filePath), 坐标: (\(originX), \(originY))")
            startDrag(filePath: filePath, originX: originX, originY: originY, result: result)
        } else {
            NSLog("DragExportPlugin: 未实现的方法 \(call.method)")
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// 开始拖拽
    private func startDrag(filePath: String, originX: Double, originY: Double, result: @escaping FlutterResult) {
        self.tempFilePath = filePath
        
        NSLog("DragExportPlugin: 检查文件: \(filePath)")
        guard FileManager.default.fileExists(atPath: filePath) else {
            NSLog("DragExportPlugin: 文件不存在 \(filePath)")
            result(FlutterError(code: "FILE_NOT_FOUND", 
                               message: "File not found", 
                               details: nil))
            return
        }
        
        NSLog("DragExportPlugin: 加载图像")
        guard let image = NSImage(contentsOfFile: filePath) else {
            NSLog("DragExportPlugin: 无法加载图像 \(filePath)")
            result(FlutterError(code: "INVALID_IMAGE", 
                               message: "Failed to load image", 
                               details: nil))
            return
        }
        
        NSLog("DragExportPlugin: 获取窗口")
        guard let window = NSApplication.shared.mainWindow,
              let contentView = window.contentView else {
            NSLog("DragExportPlugin: 找不到主窗口")
            result(FlutterError(code: "NO_WINDOW", 
                               message: "Main window not found", 
                               details: nil))
            return
        }
        
        let fileURL = URL(fileURLWithPath: filePath)
        let fileExtension = fileURL.pathExtension.lowercased()
        let fileURLString = fileURL.absoluteString
        
        // 创建pasteboardItem
        let pasteboardItem = NSPasteboardItem()
        
        do {
            // 读取文件内容
            let fileData = try Data(contentsOf: fileURL)
            
            // 添加文件URL (兼容Finder)
            pasteboardItem.setString(fileURLString, forType: .fileURL)
            NSLog("DragExportPlugin: 已添加 fileURL 格式")
            
            // 添加文件内容 (直接提供文件数据)
            pasteboardItem.setData(fileData, forType: .fileContents)
            NSLog("DragExportPlugin: 已添加 fileContents 格式")
            
            // 添加图像数据 (TIFF格式，适合大多数macOS应用)
            if let tiffData = image.tiffRepresentation {
                pasteboardItem.setData(tiffData, forType: .tiff)
                NSLog("DragExportPlugin: 已添加 TIFF 格式")
            }
            
            // 根据文件扩展名提供特定类型
            if fileExtension == "png" {
                pasteboardItem.setData(fileData, forType: NSPasteboard.PasteboardType(rawValue: "public.png"))
                NSLog("DragExportPlugin: 已添加 PNG 格式")
            } else if fileExtension == "jpg" || fileExtension == "jpeg" {
                pasteboardItem.setData(fileData, forType: NSPasteboard.PasteboardType(rawValue: "public.jpeg"))
                NSLog("DragExportPlugin: 已添加 JPEG 格式")
            }
            
            // 添加通用图像类型
            pasteboardItem.setData(fileData, forType: NSPasteboard.PasteboardType(rawValue: "public.image"))
            NSLog("DragExportPlugin: 已添加通用图像格式")
            
            // 添加HTML格式 (适合Mail等)
            let imageFilename = fileURL.lastPathComponent
            let htmlString = "<img src=\"\(fileURLString)\" alt=\"\(imageFilename)\">"
            pasteboardItem.setString(htmlString, forType: NSPasteboard.PasteboardType(rawValue: "public.html"))
            NSLog("DragExportPlugin: 已添加 HTML 格式")
            
        } catch {
            NSLog("DragExportPlugin: 读取文件数据失败: \(error)")
            result(FlutterError(code: "READ_ERROR", 
                               message: "Failed to read file data", 
                               details: error.localizedDescription))
            return
        }
        
        // 创建拖拽项
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(NSRect(origin: .zero, size: image.size), 
                                     contents: image)
        
        // 坐标转换 - 修正坐标问题
        NSLog("DragExportPlugin: 原始坐标 (\(originX), \(originY))")
        // 确保y坐标的计算正确 - 使用绝对坐标
        let screenPoint = NSPoint(x: originX, y: originY)
        let windowPoint = window.convertPoint(fromScreen: screenPoint)
        let viewPoint = contentView.convert(windowPoint, from: nil)
        NSLog("DragExportPlugin: 转换后坐标 - 窗口: (\(windowPoint.x), \(windowPoint.y)), 视图: (\(viewPoint.x), \(viewPoint.y))")
        
        // 创建鼠标事件 - 使用转换后的坐标
        guard let mouseEvent = NSEvent.mouseEvent(with: .leftMouseDown,
                                                location: viewPoint,
                                                modifierFlags: [],
                                                timestamp: 0,
                                                windowNumber: window.windowNumber,
                                                context: nil,
                                                eventNumber: 0,
                                                clickCount: 1,
                                                pressure: 1) else {
            NSLog("DragExportPlugin: 无法创建鼠标事件")
            result(FlutterError(code: "EVENT_ERROR", 
                               message: "Failed to create mouse event", 
                               details: nil))
            return
        }
        
        // 开始拖拽会话
        NSLog("DragExportPlugin: 开始拖拽会话")
        let session = contentView.beginDraggingSession(with: [draggingItem], 
                                            event: mouseEvent, 
                                            source: self)
        
        // 设置拖拽图像 - 可选，增强视觉效果
        session.draggingFormation = .default
        
        NSLog("DragExportPlugin: 拖拽会话已开始 \(filePath)")
        result(true)
    }
    
    // MARK: - NSDraggingSource 协议实现
    
    public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        NSLog("DragExportPlugin: draggingSession sourceOperationMaskFor, context: \(context == .outsideApplication ? "外部应用" : "内部应用")")
        // 无论拖拽到应用内部还是外部，都允许复制操作
        return [.copy]
    }
    
    // 兼容旧版接口 - 确保在所有macOS版本上工作
    public func draggingSourceOperationMaskFor(local: Bool) -> NSDragOperation {
        NSLog("DragExportPlugin: draggingSourceOperationMaskFor(local: \(local))")
        return [.copy]
    }
    
    public func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        NSLog("DragExportPlugin: 拖拽会话结束，坐标: (\(screenPoint.x), \(screenPoint.y)), 操作类型: \(operation.rawValue)")
        guard let filePath = tempFilePath else { 
            NSLog("DragExportPlugin: 没有临时文件需要清理")
            return 
        }
        
        // 稍微延迟删除临时文件，确保接收方有足够时间处理
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            do {
                if FileManager.default.fileExists(atPath: filePath) {
                    try FileManager.default.removeItem(atPath: filePath)
                    NSLog("DragExportPlugin: 临时文件已清理 \(filePath)")
                } else {
                    NSLog("DragExportPlugin: 临时文件已不存在 \(filePath)")
                }
            } catch {
                NSLog("DragExportPlugin: 清理临时文件失败 \(error.localizedDescription)")
            }
            
            self.tempFilePath = nil
        }
    }
}

// MARK: - FilePromiseDelegate类

/// 文件拖拽代理 - 处理文件拖放到Finder的情况
class FilePromiseDelegate: NSObject, NSFilePromiseProviderDelegate {
    private let fileName: String
    private let fileData: Data
    
    init(fileName: String, fileData: Data) {
        self.fileName = fileName
        self.fileData = fileData
        super.init()
    }
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, fileNameForType fileType: String) -> String {
        return fileName
    }
    
    func filePromiseProvider(_ filePromiseProvider: NSFilePromiseProvider, writePromiseTo url: URL, completionHandler: @escaping (Error?) -> Void) {
        do {
            try fileData.write(to: url)
            NSLog("FilePromiseDelegate: 文件写入成功 \(url.path)")
            completionHandler(nil)
        } catch {
            NSLog("FilePromiseDelegate: 文件写入失败 \(error)")
            completionHandler(error)
        }
    }
    
    func operationQueue(for filePromiseProvider: NSFilePromiseProvider) -> OperationQueue {
        return OperationQueue.main
    }
}

// MARK: - UTI辅助函数

/// 根据文件扩展名获取UTI类型
func UTI(fileExtension: String) -> String {
    switch fileExtension {
    case "png":
        return "public.png"
    case "jpg", "jpeg":
        return "public.jpeg"
    case "pdf":
        return "com.adobe.pdf"
    default:
        return "public.data"
    }
}

// MARK: - 窗口通道处理类
class WindowChannel: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.snipwise.app/window", binaryMessenger: registrar.messenger)
        let instance = WindowChannel()
        registrar.addMethodCallDelegate(instance, channel: channel)
        NSLog("WindowChannel已注册 - 窗口操作处理器")
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("WindowChannel: 收到方法调用 \(call.method)")
        
        switch call.method {
        case "minimize":
            minimizeWindow(result: result)
        case "minimizeWithoutAnimation":
            minimizeWithoutAnimation(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func minimizeWindow(result: FlutterResult) {
        if let window = NSApplication.shared.mainWindow {
            window.miniaturize(nil)
            NSLog("WindowChannel: 普通最小化窗口")
            result(nil)
        } else {
            NSLog("WindowChannel: 找不到主窗口，无法最小化")
            result(FlutterError(code: "NO_WINDOW", message: "找不到主窗口", details: nil))
        }
    }
    
    private func minimizeWithoutAnimation(result: FlutterResult) {
        NSLog("WindowChannel: -> minimizeWithoutAnimation 开始执行")
        if let window = NSApplication.shared.mainWindow {
            NSLog("WindowChannel: 获取到主窗口，准备禁用动画")
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current.duration = 0
            NSLog("WindowChannel: 动画时长设置为0")
            window.miniaturize(nil)
            NSAnimationContext.endGrouping()
            NSLog("WindowChannel: 无动画最小化窗口已调用")
            result(nil)
        } else {
            NSLog("WindowChannel: 找不到主窗口，无法无动画最小化")
            result(FlutterError(code: "NO_WINDOW", message: "找不到主窗口", details: nil))
        }
    }
}

// MARK: - 主窗口类

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // 注册标准插件
    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // 手动注册拖拽导出插件
    let registrar = flutterViewController.registrar(forPlugin: "DragExportPlugin")
    DragExportPlugin.register(with: registrar)
    NSLog("DragExportPlugin已手动注册 - 使用MainFlutterWindow中的实现")
    
    // 注册窗口通道插件
    let windowRegistrar = flutterViewController.registrar(forPlugin: "WindowChannel")
    WindowChannel.register(with: windowRegistrar)
    
    // 注册状态栏管理器
    NSLog("MainFlutterWindow: 准备注册状态栏管理器")
    let statusBarRegistrar = flutterViewController.registrar(forPlugin: "StatusItemManager")
    
    // 将FlutterViewController传递给StatusItemManager - 使用延迟确保 Flutter 引擎已完全初始化
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        NSLog("MainFlutterWindow: 延迟设置FlutterViewController")
        StatusItemManager.shared.setFlutterViewController(flutterViewController)
        NSLog("MainFlutterWindow: 已将FlutterViewController设置到StatusItemManager")
    }
    
    // 注册状态栏管理器
    StatusItemManager.register(with: statusBarRegistrar)
    NSLog("MainFlutterWindow: 状态栏管理器注册完成")
    
    // 使用延迟执行初始化状态栏，确保其他组件已完成初始化
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        // 通过方法通道初始化状态栏
        let channel = FlutterMethodChannel(name: "com.snipwise.app/status_bar", binaryMessenger: flutterViewController.engine.binaryMessenger)
        channel.invokeMethod("initialize", arguments: nil)
        NSLog("StatusItemManager: 状态栏初始化完成")
    }

    super.awakeFromNib()
  }
}

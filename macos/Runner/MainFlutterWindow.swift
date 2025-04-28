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
        
        // 设置拖拽数据 - 多格式支持
        NSLog("DragExportPlugin: 准备多格式拖拽数据")
        let pasteboardItem = NSPasteboardItem()
        let fileURL = URL(fileURLWithPath: filePath)
        let fileExtension = fileURL.pathExtension.lowercased()
        
        // 1. 提供文件URL (适合拖放到Finder)
        pasteboardItem.setString(filePath, forType: .fileURL)
        NSLog("DragExportPlugin: 已添加 fileURL 格式")
        
        // 2. 提供NSImage格式 (适合拖放到支持NSImage的应用)
        if let tiffData = image.tiffRepresentation {
            pasteboardItem.setData(tiffData, forType: .tiff)
            NSLog("DragExportPlugin: 已添加 TIFF 格式")
        }
        
        // 3. 提供各种图像格式 (PNG, JPEG等)
        do {
            let imageData = try Data(contentsOf: fileURL)
            
            // 根据文件扩展名提供不同类型
            if fileExtension == "png" {
                pasteboardItem.setData(imageData, forType: NSPasteboard.PasteboardType(rawValue: "public.png"))
                NSLog("DragExportPlugin: 已添加 PNG 格式")
            } else if fileExtension == "jpg" || fileExtension == "jpeg" {
                pasteboardItem.setData(imageData, forType: NSPasteboard.PasteboardType(rawValue: "public.jpeg"))
                NSLog("DragExportPlugin: 已添加 JPEG 格式")
            }
            
            // 提供通用图像类型
            pasteboardItem.setData(imageData, forType: NSPasteboard.PasteboardType(rawValue: "public.image"))
            NSLog("DragExportPlugin: 已添加通用图像格式")
        } catch {
            NSLog("DragExportPlugin: 无法读取图像数据: \(error)")
        }
        
        // 4. 提供HTML格式 (适合邮件等富文本编辑器)
        let imageFilename = fileURL.lastPathComponent
        let htmlString = "<img src=\"file://\(filePath)\" alt=\"\(imageFilename)\">"
        pasteboardItem.setString(htmlString, forType: NSPasteboard.PasteboardType(rawValue: "public.html"))
        NSLog("DragExportPlugin: 已添加 HTML 格式")
        
        // 创建拖拽项
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(NSRect(origin: .zero, size: image.size), 
                                     contents: image)
        
        // 坐标转换
        NSLog("DragExportPlugin: 转换坐标 (\(originX), \(originY))")
        let windowPoint = contentView.convert(NSPoint(x: originX, 
                                                    y: window.frame.height - originY), 
                                            from: nil)
        NSLog("DragExportPlugin: 窗口坐标 (\(windowPoint.x), \(windowPoint.y))")
        
        // 创建鼠标事件
        guard let mouseEvent = NSEvent.mouseEvent(with: .leftMouseDown,
                                                location: windowPoint,
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
        _ = contentView.beginDraggingSession(with: [draggingItem], 
                                            event: mouseEvent, 
                                            source: self)
        
        NSLog("DragExportPlugin: 拖拽会话已开始 \(filePath)")
        result(true)
    }
    
    // MARK: - NSDraggingSource 协议实现
    
    public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        NSLog("DragExportPlugin: draggingSession sourceOperationMaskFor")
        // 允许复制操作
        return [.copy]
    }
    
    public func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        NSLog("DragExportPlugin: 拖拽会话结束，操作类型: \(operation.rawValue)")
        guard let filePath = tempFilePath else { 
            NSLog("DragExportPlugin: 没有临时文件需要清理")
            return 
        }
        
        do {
            try FileManager.default.removeItem(atPath: filePath)
            NSLog("DragExportPlugin: 临时文件已清理 \(filePath)")
        } catch {
            NSLog("DragExportPlugin: 清理临时文件失败 \(error.localizedDescription)")
        }
        
        tempFilePath = nil
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
    NSLog("DragExportPlugin已手动注册")

    super.awakeFromNib()
  }
}

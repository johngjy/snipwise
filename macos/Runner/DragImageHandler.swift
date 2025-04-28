import Cocoa
import FlutterMacOS

/// 处理图像拖拽的类
/// 实现了NSDraggingSource协议以支持从Flutter到其他应用的拖拽操作
class DragImageHandler: NSObject, NSDraggingSource, FlutterPlugin {
    // MARK: - 属性
    
    /// 临时文件路径，拖拽结束后需要清理
    private var tempFilePath: String?
    
    /// 记录器对象，用于日志记录
    private let logger = Logger()
    
    // MARK: - Flutter插件注册
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "snipwise_drag_export",
            binaryMessenger: registrar.messenger)
        let instance = DragImageHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    // MARK: - Flutter方法处理
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "startImageDrag" {
            guard let args = call.arguments as? [String: Any],
                  let filePath = args["filePath"] as? String,
                  let originX = args["originX"] as? Double,
                  let originY = args["originY"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", 
                                    message: "Invalid arguments", 
                                    details: nil))
                return
            }
            
            startDrag(filePath: filePath, origin: NSPoint(x: originX, y: originY), result: result)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - 拖拽实现
    
    /// 开始拖拽操作
    private func startDrag(filePath: String, origin: NSPoint, result: @escaping FlutterResult) {
        // 记录临时文件路径，以便后续清理
        self.tempFilePath = filePath
        
        // 确保文件存在
        let fileURL = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath) else {
            logger.log("文件不存在: \(filePath)")
            result(FlutterError(code: "FILE_NOT_FOUND", 
                               message: "File not found: \(filePath)", 
                               details: nil))
            return
        }
        
        // 加载图像数据
        guard let image = NSImage(contentsOfFile: filePath) else {
            logger.log("无法加载图像: \(filePath)")
            result(FlutterError(code: "INVALID_IMAGE", 
                               message: "Failed to load image", 
                               details: nil))
            return
        }
        
        // 获取主窗口及其contentView
        guard let window = NSApplication.shared.mainWindow,
              let contentView = window.contentView else {
            logger.log("找不到主窗口或contentView")
            result(FlutterError(code: "NO_WINDOW", 
                               message: "Main window not found", 
                               details: nil))
            return
        }
        
        // 创建拖拽图像并设置尺寸
        let dragImage = NSImage(size: image.size)
        
        // 设置pasteboard
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(filePath, forType: .fileURL)
        
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(NSRect(origin: .zero, size: image.size), 
                                     contents: image)
        
        // 转换坐标系：从Flutter全局坐标到窗口本地坐标
        // 注意：Y坐标需要翻转，因为macOS坐标系原点在左下角，而Flutter是左上角
        let flutterPoint = origin
        let windowPoint = contentView.convert(NSPoint(x: flutterPoint.x, 
                                                    y: window.frame.height - flutterPoint.y), 
                                            from: nil)
        
        // 创建并启动拖拽会话
        let draggingSession = contentView.beginDraggingSession(with: [draggingItem], 
                                                             event: NSEvent.mouseEvent(with: .leftMouseDown,
                                                                                    location: windowPoint,
                                                                                    modifierFlags: [],
                                                                                    timestamp: TimeInterval(0),
                                                                                    windowNumber: window.windowNumber,
                                                                                    context: nil,
                                                                                    eventNumber: 0,
                                                                                    clickCount: 1,
                                                                                    pressure: 1)!,
                                                             source: self)
        
        logger.log("开始拖拽会话，临时文件：\(filePath)")
        result(true)
    }
    
    // MARK: - NSDraggingSource协议实现
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        // 根据拖拽上下文返回不同的操作掩码
        switch context {
        case .outsideApplication:
            return [.copy]
        case .withinApplication:
            return [.copy]
        @unknown default:
            return []
        }
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        // 拖拽结束时清理临时文件
        cleanupTempFile()
    }
    
    // MARK: - 辅助方法
    
    /// 清理临时文件
    private func cleanupTempFile() {
        guard let filePath = tempFilePath else { return }
        
        do {
            try FileManager.default.removeItem(atPath: filePath)
            logger.log("临时文件已清理: \(filePath)")
        } catch {
            logger.log("清理临时文件失败: \(error.localizedDescription)")
        }
        
        // 清空保存的路径
        tempFilePath = nil
    }
}

// MARK: - 简单日志类

/// 简单的日志记录类
class Logger {
    func log(_ message: String) {
        NSLog("DragImageHandler: \(message)")
    }
} 
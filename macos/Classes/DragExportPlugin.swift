import Cocoa
import FlutterMacOS

/// 图像拖拽导出插件
public class DragExportPlugin: NSObject, FlutterPlugin, NSDraggingSource {
    
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
        NSLog("DragExportPlugin: 收到方法调用 \(call.method)")
        
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
            
            startDrag(filePath: filePath, originX: originX, originY: originY, result: result)
        } else {
            NSLog("DragExportPlugin: 未实现的方法 \(call.method)")
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// 开始拖拽
    private func startDrag(filePath: String, originX: Double, originY: Double, result: @escaping FlutterResult) {
        self.tempFilePath = filePath
        
        guard FileManager.default.fileExists(atPath: filePath) else {
            NSLog("DragExportPlugin: 文件不存在 \(filePath)")
            result(FlutterError(code: "FILE_NOT_FOUND", 
                               message: "File not found", 
                               details: nil))
            return
        }
        
        guard let image = NSImage(contentsOfFile: filePath) else {
            NSLog("DragExportPlugin: 无法加载图像 \(filePath)")
            result(FlutterError(code: "INVALID_IMAGE", 
                               message: "Failed to load image", 
                               details: nil))
            return
        }
        
        guard let window = NSApplication.shared.mainWindow,
              let contentView = window.contentView else {
            NSLog("DragExportPlugin: 找不到主窗口")
            result(FlutterError(code: "NO_WINDOW", 
                               message: "Main window not found", 
                               details: nil))
            return
        }
        
        // 设置拖拽数据
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(filePath, forType: .fileURL)
        
        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(NSRect(origin: .zero, size: image.size), 
                                     contents: image)
        
        // 坐标转换
        let windowPoint = contentView.convert(NSPoint(x: originX, 
                                                    y: window.frame.height - originY), 
                                            from: nil)
        
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
        _ = contentView.beginDraggingSession(with: [draggingItem], 
                                            event: mouseEvent, 
                                            source: self)
        
        NSLog("DragExportPlugin: 拖拽会话已开始 \(filePath)")
        result(true)
    }
    
    // MARK: - NSDraggingSource 协议实现
    
    public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return context == .outsideApplication ? .copy : .copy
    }
    
    public func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        guard let filePath = tempFilePath else { return }
        
        do {
            try FileManager.default.removeItem(atPath: filePath)
            NSLog("DragExportPlugin: 临时文件已清理 \(filePath)")
        } catch {
            NSLog("DragExportPlugin: 清理临时文件失败 \(error.localizedDescription)")
        }
        
        tempFilePath = nil
    }
} 
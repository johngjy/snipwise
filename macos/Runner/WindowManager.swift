import Cocoa
import FlutterMacOS

/// 处理窗口操作的类
class WindowManager: NSObject {
    private let logger = Logger()
    
    /// 处理窗口相关的方法调用
    func handleWindowMethods(call: FlutterMethodCall, result: @escaping FlutterResult) {
        logger.log("收到窗口操作调用: \(call.method)")
        
        switch call.method {
        case "hideWindow":
            hideWindow(result: result)
        case "showAndActivateWindow":
            showAndActivateWindow(result: result)
        case "startScreenshotFlow":
            startScreenshotFlow(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// 隐藏窗口 - 使用orderOut而不是minimize
    private func hideWindow(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.mainWindow {
                // 使用orderOut隐藏窗口，而不是最小化
                // 这确保窗口完全隐藏但App保持活跃
                window.orderOut(nil)
                self.logger.log("窗口已隐藏(orderOut)")
                result(true)
            } else {
                self.logger.log("无法获取主窗口进行隐藏")
                result(false)
            }
        }
    }
    
    /// 显示窗口并激活
    private func showAndActivateWindow(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.mainWindow {
                // 显示窗口并使其成为前台窗口
                window.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
                self.logger.log("窗口已显示并激活")
                result(true)
            } else {
                self.logger.log("无法获取主窗口进行显示")
                result(false)
            }
        }
    }
    
    /// 执行完整的截图流程
    private func startScreenshotFlow(call: FlutterMethodCall, result: @escaping FlutterResult) {
        logger.log("开始截图流程")
        
        // 创建临时文件路径
        let tempDir = NSTemporaryDirectory()
        let timestamp = Int(Date().timeIntervalSince1970)
        let tempFilePath = "\(tempDir)screenshot_\(timestamp).png"
        
        // 首先隐藏窗口
        DispatchQueue.main.async {
            if let window = NSApplication.shared.mainWindow {
                // 隐藏窗口
                window.orderOut(nil)
                self.logger.log("窗口已隐藏，准备截图")
                
                // 给UI一点时间隐藏
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.captureScreen(tempFilePath: tempFilePath) { success in
                        // 截图完成后，恢复窗口
                        DispatchQueue.main.async {
                            // 显示窗口并激活
                            window.makeKeyAndOrderFront(nil)
                            NSApplication.shared.activate(ignoringOtherApps: true)
                            self.logger.log("窗口已恢复显示")
                            
                            if success {
                                // 检查文件是否存在
                                if FileManager.default.fileExists(atPath: tempFilePath) {
                                    self.logger.log("截图成功: \(tempFilePath)")
                                    result(tempFilePath)
                                } else {
                                    self.logger.log("截图文件不存在")
                                    result(nil)
                                }
                            } else {
                                self.logger.log("截图失败或被取消")
                                result(nil)
                            }
                        }
                    }
                }
            } else {
                self.logger.log("无法获取主窗口")
                result(FlutterError(code: "NO_WINDOW", 
                                   message: "无法获取主窗口", 
                                   details: nil))
            }
        }
    }
    
    /// 执行屏幕截图
    private func captureScreen(tempFilePath: String, completion: @escaping (Bool) -> Void) {
        self.logger.log("启动屏幕截图")
        
        // 创建Process运行screencapture
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-i", tempFilePath]
        
        // 设置完成回调
        process.terminationHandler = { process in
            self.logger.log("截图进程结束，状态码: \(process.terminationStatus)")
            completion(process.terminationStatus == 0)
        }
        
        // 启动进程
        do {
            try process.run()
        } catch {
            self.logger.log("启动截图进程失败: \(error)")
            completion(false)
        }
    }
}

/// 简单日志类
class Logger {
    func log(_ message: String) {
        NSLog("WindowManager: \(message)")
    }
} 
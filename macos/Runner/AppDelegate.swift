import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // 添加窗口管理器实例
  private var windowManager: WindowManager?
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // 设置窗口样式
    if let window = NSApp.windows.first {
      // 确保关闭和最小化按钮可见
      window.standardWindowButton(.closeButton)?.isHidden = false
      window.standardWindowButton(.miniaturizeButton)?.isHidden = false
      
      // 只隐藏最大化按钮
      window.standardWindowButton(.zoomButton)?.isHidden = true
      window.standardWindowButton(.zoomButton)?.alphaValue = 0
      window.standardWindowButton(.zoomButton)?.frame = .zero
              
      // 设置窗口背景和属性
      window.backgroundColor = NSColor.white
      window.isOpaque = false
      window.hasShadow = true
      
      // 允许拖动整个窗口
      window.isMovableByWindowBackground = true
    }
    
    super.applicationDidFinishLaunching(notification)
    
    // 注册方法通道
    registerMethodChannels()
  }
  
  private func registerMethodChannels() {
    guard let controller = NSApplication.shared.mainWindow?.contentViewController as? FlutterViewController else {
      NSLog("警告: 无法获取FlutterViewController")
      return
    }
    
    // 初始化窗口管理器
    windowManager = WindowManager()
    
    // 注册窗口管理通道
    let windowChannel = FlutterMethodChannel(
      name: "com.snipwise.window",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    windowChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self, let windowManager = self.windowManager else {
        result(FlutterError(code: "UNAVAILABLE", 
                           message: "窗口管理器不可用", 
                           details: nil))
        return
      }
      
      windowManager.handleWindowMethods(call: call, result: result)
    }
    
    NSLog("窗口管理通道已注册")
  }
}

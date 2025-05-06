import Cocoa
import FlutterMacOS
import window_manager

@main
class AppDelegate: FlutterAppDelegate {
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
    
    // 让 window_manager 插件在此之后初始化
    // 不需要手动注册方法通道，window_manager 插件会自动注册
    // 窗口相关的操作应该使用 Flutter 侧的 window_manager 包来调用
  }
}

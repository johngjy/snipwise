import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false // Changed to false to keep app running when window is closed
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
  }
}

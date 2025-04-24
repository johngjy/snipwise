import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // 完全隐藏标题栏，移除所有系统控件
    self.titleVisibility = .hidden
    self.titlebarAppearsTransparent = true
    self.styleMask.insert(.fullSizeContentView)
    
    // 移除标题栏中的按钮
    self.standardWindowButton(.closeButton)?.isHidden = true
    self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    self.standardWindowButton(.zoomButton)?.isHidden = true
    
    // 设置窗口不透明度为1.0，移除背景遮罩
    self.backgroundColor = NSColor.clear
    self.isOpaque = false
    
    // 设置窗口可以被拖动，即使标题栏隐藏
    self.isMovableByWindowBackground = true
    
    // 注册Flutter方法通道，处理窗口操作
    let windowChannel = FlutterMethodChannel(
      name: "com.snipwise.app/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    
    windowChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      
      switch call.method {
      case "minimize":
        self.miniaturize(nil)
        result(nil)
      case "close":
        self.close()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

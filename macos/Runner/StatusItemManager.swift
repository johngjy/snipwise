import Cocoa
import FlutterMacOS

/// 状态栏管理器 - 负责创建和管理macOS顶部状态栏图标
class StatusItemManager: NSObject, FlutterPlugin {
    
    /// 单例实例
    static let shared = StatusItemManager()
    
    // 状态栏项
    private var statusItem: NSStatusItem?
    
    // 方法通道
    private var methodChannel: FlutterMethodChannel?
    
    // Flutter视图控制器
    private weak var flutterViewController: FlutterViewController?
    
    // 菜单
    private var menu: NSMenu?
    
    // 初始化状态
    private var isInitialized = false
    
    // 悬停计时器
    private var hoverTimer: Timer?
    
    // 悬停延迟（秒）
    private let hoverDelay: TimeInterval = 0.5
    
    // 鼠标跟踪区域
    private var trackingArea: NSTrackingArea?
    
    private override init() {
        super.init()
        NSLog("StatusItemManager: 实例已创建")
    }
    
    /// 设置FlutterViewController
    public func setFlutterViewController(_ viewController: FlutterViewController) {
        NSLog("StatusItemManager: 开始设置FlutterViewController")
        self.flutterViewController = viewController
        NSLog("StatusItemManager: FlutterViewController已设置，内存地址: \(Unmanaged.passUnretained(viewController).toOpaque())")
        
        // 如果方法通道已初始化，则重新创建
        if methodChannel == nil {
            NSLog("StatusItemManager: 创建方法通道")
            methodChannel = FlutterMethodChannel(name: "com.snipwise.app/status_bar", binaryMessenger: viewController.engine.binaryMessenger)
        }
    }
    
    /// 注册插件
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.snipwise.app/status_bar", 
                                         binaryMessenger: registrar.messenger)
        let instance = StatusItemManager.shared
        instance.methodChannel = channel
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        NSLog("StatusItemManager: 插件已注册")
        
        // 尝试获取FlutterViewController (现在应该已经通过setFlutterViewController设置)
        if instance.flutterViewController == nil {
            if let viewController = (NSApp.delegate as? FlutterAppDelegate)?.mainFlutterWindow.contentViewController as? FlutterViewController {
                instance.flutterViewController = viewController
                NSLog("StatusItemManager: 从AppDelegate获取到FlutterViewController")
            } else {
                NSLog("StatusItemManager: 错误 - 无法获取FlutterViewController")
            }
        }
        
        // 在主线程上延迟初始化状态栏，确保其他组件已完成初始化
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            instance.setupStatusItem()
        }
    }
    
    /// 处理方法调用
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        NSLog("StatusItemManager: 收到方法调用 \(call.method)")
        
        switch call.method {
        case "initialize":
            setupStatusItem()
            result(true)
            
        case "showPopover":
            showMenu()
            result(true)
            
        case "hidePopover":
            // 菜单会自动关闭，所以这里仅返回成功
            result(true)
            
        case "isPopoverVisible":
            // 菜单的可见性由系统管理，我们始终返回false
            result(false)
            
        case "updateMenuUI":
            // 简化版不支持更新菜单UI
            result(true)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    /// 初始化状态栏
    func setupStatusItem() {
        NSLog("StatusItemManager: 开始初始化状态栏")
        
        // 如果已经初始化过，则跳过
        if isInitialized {
            NSLog("StatusItemManager: 状态栏已初始化，跳过")
            return
        }
        
        // 检查FlutterViewController是否可用
        if flutterViewController == nil {
            NSLog("StatusItemManager: 尝试获取FlutterViewController")
            if let viewController = (NSApp.delegate as? FlutterAppDelegate)?.mainFlutterWindow.contentViewController as? FlutterViewController {
                setFlutterViewController(viewController)
            } else {
                NSLog("StatusItemManager: 错误 - 无法获取FlutterViewController")
            }
        } else {
            NSLog("StatusItemManager: FlutterViewController已存在，内存地址: \(Unmanaged.passUnretained(flutterViewController!).toOpaque())")
        }
        
        NSLog("StatusItemManager: 开始设置状态栏...")
        
        // 创建状态栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // 创建菜单
        menu = NSMenu()
        
        // 添加菜单项
        let screenshotItem = NSMenuItem(title: "截图工具", action: #selector(menuItemClicked(_:)), keyEquivalent: "")
        screenshotItem.tag = 1
        menu?.addItem(screenshotItem)
        
        let cachedTextItem = NSMenuItem(title: "缓存文本", action: #selector(menuItemClicked(_:)), keyEquivalent: "")
        cachedTextItem.tag = 2
        menu?.addItem(cachedTextItem)
        
        menu?.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        menu?.addItem(quitItem)
        
        // 设置状态栏图标
        if let button = statusItem?.button {
            if let iconImage = NSImage(named: "StatusBarIcon") {
                iconImage.isTemplate = true
                button.image = iconImage
                NSLog("StatusItemManager: 使用自定义图标")
            } else {
                let defaultIcon = NSImage(named: NSImage.Name("NSStatusAvailable"))
                defaultIcon?.isTemplate = true
                button.image = defaultIcon
                NSLog("StatusItemManager: 使用默认图标")
            }
            
            // 设置菜单
            statusItem?.menu = menu
            
            // 添加鼠标悬停检测
            setupHoverTracking(for: button)
            
            NSLog("StatusItemManager: 状态栏设置完成")
            isInitialized = true
        } else {
            NSLog("StatusItemManager: 错误 - 无法获取状态栏按钮")
        }
    }
    
    /// 显示菜单
    func showMenu() {
        NSLog("StatusItemManager: 尝试显示菜单")
        if !isInitialized {
            setupStatusItem()
        }
        
        // 点击通知
        DispatchQueue.main.async {
            self.methodChannel?.invokeMethod("statusItemClicked", arguments: nil)
        }
        
        // 菜单由系统自动显示，不需要手动触发
    }
    
    /// 菜单项点击事件
    @objc func menuItemClicked(_ sender: NSMenuItem) {
        NSLog("StatusItemManager: 菜单项被点击，tag: \(sender.tag)")
        
        switch sender.tag {
        case 1: // 主页
            DispatchQueue.main.async {
                self.methodChannel?.invokeMethod("navigateInMenu", arguments: ["route": "/"])
            }
            
        case 2: // 缓存文本
            DispatchQueue.main.async {
                self.methodChannel?.invokeMethod("navigateInMenu", arguments: ["route": "/cached-text-example"])
            }
            
        default:
            break
        }
    }
    
    /// 退出应用
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    /// 设置悬停检测
    private func setupHoverTracking(for button: NSButton) {
        // 移除已有的跟踪区域
        if let existingArea = trackingArea {
            button.removeTrackingArea(existingArea)
        }
        
        // 创建新的跟踪区域
        trackingArea = NSTrackingArea(
            rect: button.bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil)
        
        button.addTrackingArea(trackingArea!)
        NSLog("StatusItemManager: 已添加鼠标悬停检测")
    }
    
    /// 鼠标进入事件
    override func mouseEntered(with event: NSEvent) {
        NSLog("StatusItemManager: 鼠标进入状态栏图标区域")
        NSLog("StatusItemManager: 位置: \(event.locationInWindow)")
        startHoverTimer()
    }
    
    /// 鼠标离开事件
    override func mouseExited(with event: NSEvent) {
        NSLog("StatusItemManager: 鼠标离开状态栏图标区域")
        cancelHoverTimer()
    }
    
    /// 开始悬停计时器
    private func startHoverTimer() {
        // 取消已有计时器
        cancelHoverTimer()
        
        // 创建新计时器
        hoverTimer = Timer.scheduledTimer(
            timeInterval: hoverDelay,
            target: self,
            selector: #selector(hoverTimerFired),
            userInfo: nil,
            repeats: false)
    }
    
    /// 取消悬停计时器
    private func cancelHoverTimer() {
        hoverTimer?.invalidate()
        hoverTimer = nil
    }
    
    /// 悬停计时器触发事件
    @objc private func hoverTimerFired() {
        NSLog("StatusItemManager: 悬停计时器触发")
        
        // 检查是否有效的方法通道
        guard let channel = methodChannel else {
            NSLog("StatusItemManager: 无法显示菜单，因为方法通道为空")
            return
        }
        
        NSLog("StatusItemManager: 方法通道可用，准备显示菜单")
        
        // 尝试获取FlutterViewController（如果它为空）
        if flutterViewController == nil {
            if let viewController = (NSApp.delegate as? FlutterAppDelegate)?.mainFlutterWindow.contentViewController as? FlutterViewController {
                flutterViewController = viewController
                NSLog("StatusItemManager: 在悬停时成功获取FlutterViewController")
            } else {
                NSLog("StatusItemManager: 在悬停时仍无法获取FlutterViewController")
            }
        }
        
        // 获取状态栏图标在屏幕上的位置
        if let button = statusItem?.button,
           let window = button.window {
            let buttonRect = button.convert(button.bounds, to: nil)
            let windowRect = window.convertToScreen(buttonRect)
            
            // 计算菜单应该显示的位置（图标底部中心）
            let x = windowRect.midX
            let y = windowRect.minY
            
            NSLog("StatusItemManager: 菜单显示位置 (x: \(x), y: \(y))")
            NSLog("StatusItemManager: 状态栏按钮尺寸: \(button.bounds.size), 窗口尺寸: \(window.frame.size)")
            
            // 通过方法通道通知 Flutter 显示菜单
            DispatchQueue.main.async {
                NSLog("StatusItemManager: 发送showOverlayMenu消息到Flutter")
                channel.invokeMethod(
                    "showOverlayMenu",
                    arguments: ["x": x, "y": y])
            }
        } else {
            NSLog("StatusItemManager: 无法获取状态栏按钮或窗口")
        }
    }
    
    /// 清理资源
    func cleanup() {
        // 取消计时器
        cancelHoverTimer()
        
        // 移除状态栏图标
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
        
        // 清理其他资源
        trackingArea = nil
        menu = nil
        isInitialized = false
    }
    
    deinit {
        cleanup()
    }
}
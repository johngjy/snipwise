import Cocoa
import FlutterMacOS

/// 状态栏菜单管理器 - 负责在macOS顶部状态栏创建和管理应用图标
class StatusItemManager: NSObject, FlutterPlugin {
    // 单例实例
    static let shared = StatusItemManager()
    
    // 状态栏项
    private var statusItem: NSStatusItem?
    
    // 方法通道 - 用于与Flutter通信
    private var methodChannel: FlutterMethodChannel?
    
    // 菜单是否可见
    private var isMenuVisible = false
    
    // 当前主菜单窗口
    private var popover: NSPopover?
    
    // 事件监控
    private var eventMonitor: Any?
    
    // Flutter视图控制器
    private weak var flutterViewController: FlutterViewController?
    
    // Flutter菜单控制器 - 用于显示菜单UI
    private var flutterMenuViewController: FlutterViewController?
    
    // 私有初始化方法
    private override init() {
        super.init()
    }
    
    /// 设置Flutter视图控制器
    func setFlutterViewController(_ viewController: FlutterViewController) {
        self.flutterViewController = viewController
        
        // 注册方法通道
        methodChannel = FlutterMethodChannel(
            name: "com.snipwise.app/status_bar",
            binaryMessenger: viewController.engine.binaryMessenger)
        
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", 
                                   message: "StatusItemManager instance is not available", 
                                   details: nil))
                return
            }
            
            switch call.method {
            case "initialize":
                self.setupStatusItem()
                result(true)
                
            case "showPopover":
                self.showPopover()
                result(true)
                
            case "hidePopover":
                self.hidePopover()
                result(true)
                
            case "isPopoverVisible":
                result(self.isMenuVisible)
                
            case "updateMenuUI":
                if let args = call.arguments as? [String: Any],
                   let route = args["route"] as? String {
                    self.updateMenuUI(route: route)
                    result(true)
                } else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", 
                                       message: "缺少route参数", 
                                       details: nil))
                }
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    /// 设置状态栏项
    private func setupStatusItem() {
        NSLog("StatusItemManager: 开始设置状态栏图标...")
        
        // 获取系统状态栏
        let statusBar = NSStatusBar.system
        
        // 创建状态栏项，长度可变
        statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
        
        // 设置状态栏图标
        if let button = statusItem?.button {
            // 尝试加载应用资源中的图标
            if let iconImage = NSImage(named: "StatusBarIcon") {
                iconImage.isTemplate = true  // 使图标自动适配明暗模式
                button.image = iconImage
                NSLog("StatusItemManager: 使用自定义图标")
            } else {
                // 如果未找到自定义图标，使用默认图标
                let defaultIcon = NSImage(named: NSImage.Name("NSMenuOnStateTemplate"))
                defaultIcon?.isTemplate = true  // 使图标自动适配明暗模式
                button.image = defaultIcon
                NSLog("StatusItemManager: 使用默认图标，未找到自定义图标")
            }
            
            // 设置按钮行为
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            
            // 允许拖动状态栏图标
            button.sendAction(on: [.leftMouseDown, .rightMouseDown])
            
            NSLog("StatusItemManager: 状态栏图标设置完成")
        } else {
            NSLog("StatusItemManager: 错误 - 无法获取状态栏按钮")
        }
        
        // 创建菜单控制器
        createFlutterMenuViewController()
    }
    
    /// 创建Flutter菜单视图控制器
    private func createFlutterMenuViewController() {
        // 确保主Flutter引擎已初始化
        guard let mainEngine = flutterViewController?.engine else {
            NSLog("StatusItemManager: 错误 - 主Flutter引擎未初始化")
            return
        }
        
        // 创建新的Flutter菜单视图控制器，使用相同的引擎
        let menuViewController = FlutterViewController(engine: mainEngine, nibName: nil, bundle: nil)
        
        // 配置视图控制器属性
        menuViewController.view.frame = NSRect(x: 0, y: 0, width: 280, height: 400)
        menuViewController.view.wantsLayer = true
        
        self.flutterMenuViewController = menuViewController
    }
    
    /// 更新菜单UI
    private func updateMenuUI(route: String) {
        NSLog("StatusItemManager: 更新菜单UI，路由: \(route)")
        
        // 通知Flutter显示特定路由
        DispatchQueue.main.async {
            self.methodChannel?.invokeMethod("navigateInMenu", arguments: ["route": route])
        }
    }
    
    /// 状态栏图标点击事件
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        NSLog("StatusItemManager: 状态栏图标被点击")
        
        if isMenuVisible {
            hidePopover()
        } else {
            showPopover()
        }
    }
    
    /// 显示弹出菜单
    private func showPopover() {
        NSLog("StatusItemManager: 显示弹出菜单")
        guard let statusItem = statusItem, !isMenuVisible else { return }
        
        // 通知Flutter - 状态栏图标被点击
        DispatchQueue.main.async {
            self.methodChannel?.invokeMethod("statusItemClicked", arguments: nil)
        }
        
        // 创建弹出窗口，如果不存在
        if popover == nil {
            popover = NSPopover()
            popover?.behavior = .transient
            
            // 确保Flutter菜单视图控制器存在
            if flutterMenuViewController == nil {
                createFlutterMenuViewController()
            }
            
            // 使用Flutter视图作为内容
            if let menuViewController = flutterMenuViewController {
                popover?.contentViewController = menuViewController
                popover?.contentSize = menuViewController.view.frame.size
            } else {
                NSLog("StatusItemManager: 错误 - 无法创建Flutter菜单视图")
                return
            }
            
            // 设置监听器关闭弹出窗口
            if eventMonitor == nil {
                eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                    self?.hidePopover()
                }
            }
        }
        
        // 显示弹出窗口
        if let button = statusItem.button {
            popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            isMenuVisible = true
        }
    }
    
    /// 隐藏弹出菜单
    private func hidePopover() {
        NSLog("StatusItemManager: 隐藏弹出菜单")
        popover?.close()
        isMenuVisible = false
    }
    
    /// 注册插件
    static func register(with registrar: FlutterPluginRegistrar) {
        let instance = StatusItemManager.shared
        
        // 获取FlutterViewController
        if let viewController = NSApp.mainWindow?.contentViewController as? FlutterViewController {
            instance.setFlutterViewController(viewController)
        } else {
            NSLog("StatusItemManager: 错误 - 无法获取FlutterViewController")
        }
    }
    
    /// 清理资源
    func cleanup() {
        // 移除事件监视器
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        // 移除状态栏项
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
        
        // 关闭弹出窗口
        popover?.close()
        popover = nil
        flutterMenuViewController = nil
        isMenuVisible = false
    }
    
    deinit {
        cleanup()
    }
} 
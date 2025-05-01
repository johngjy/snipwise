import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:go_router/go_router.dart';
import '../routes/app_routes.dart';
import '../../features/capture/presentation/pages/capture_page.dart';

/// 状态栏服务 - 管理系统状态栏图标和菜单
class StatusBarService {
  /// 单例实例
  static final StatusBarService instance = StatusBarService._internal();

  /// 日志记录器
  final Logger _logger = Logger();

  /// 状态栏图标是否已初始化
  bool _isInitialized = false;

  /// 与原生代码通信的方法通道
  static const MethodChannel _channel =
      MethodChannel('com.snipwise.app/status_bar');

  /// 状态栏点击回调
  Function? onStatusBarItemClicked;
  
  /// 悬停菜单覆盖层
  OverlayEntry? _overlayEntry;

  /// 私有构造函数
  StatusBarService._internal();

  /// 初始化状态栏服务
  Future<bool> initialize() async {
    if (_isInitialized) {
      _logger.i('状态栏服务已经初始化过');
      return true;
    }

    if (!Platform.isMacOS && !Platform.isWindows) {
      _logger.d('非macOS/Windows平台，不支持状态栏功能');
      return false;
    }

    _logger.d('正在初始化状态栏服务...');

    // 设置方法调用处理器
    _channel.setMethodCallHandler(_handleMethodCall);

    try {
      // 调用原生方法初始化状态栏
      final result = await _channel.invokeMethod<bool>('initialize') ?? false;
      _logger.d('状态栏初始化${result ? '成功' : '失败'}');
      _isInitialized = result;
      return result;
    } catch (e) {
      _logger.e('状态栏初始化错误', error: e);
      return false;
    }
  }

  /// 处理来自原生代码的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    _logger.d('收到状态栏原生方法调用: ${call.method}');

    switch (call.method) {
      case 'statusItemClicked':
        _logger.d('状态栏图标被点击');
        onStatusBarItemClicked?.call();
        return true;

      case 'navigateInMenu':
        _logger.d('导航到菜单路由: ${call.arguments}');
        if (call.arguments is Map && call.arguments['route'] != null) {
          final route = call.arguments['route'] as String;
          navigateToRoute(route);
        }
        return true;
        
      case 'showOverlayMenu':
        _logger.d('显示悬停菜单: ${call.arguments}');
        if (call.arguments is Map && 
            call.arguments['x'] != null && 
            call.arguments['y'] != null) {
          final x = call.arguments['x'] as double;
          final y = call.arguments['y'] as double;
          _logger.d('准备显示悬停菜单，位置: ($x, $y)');
          
          // 使用延迟确保有足够时间初始化
          Future.delayed(const Duration(milliseconds: 100), () {
            _showOverlayMenu(Offset(x, y));
          });
        } else {
          _logger.e('无法显示悬停菜单，参数无效: ${call.arguments}');
        }
        return true;

      default:
        _logger.w('未知的状态栏方法调用: ${call.method}');
        throw PlatformException(
          code: 'UNSUPPORTED_METHOD',
          message: '不支持的方法: ${call.method}',
        );
    }
  }

  /// 导航到指定路由 - 使用GoRouter
  void navigateToRoute(String route) {
    _logger.d('导航到路由: $route');

    // 如果有悬停菜单，先关闭
    _hideOverlayMenu();

    // 防止在构建阶段调用导航
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 获取当前上下文
      final BuildContext? context = _getActiveContext();
      if (context != null) {
        // 根据不同路由进行处理
        switch (route) {
          case '/status_bar_menu':
            // 状态栏菜单特殊处理
            _showStatusBarMenu(context);
            break;
          case '/cached-text-example':
            // 缓存文本示例
            GoRouter.of(context).go(AppRoutes.cachedTextExample);
            break;
          case '/':
          default:
            // 默认回到主页（截图捕获页面）
            GoRouter.of(context).go(AppRoutes.home);
            break;
        }
      } else {
        _logger.e('无法获取有效的构建上下文进行导航');
      }
    });
  }

  /// 获取当前活动的构建上下文
  BuildContext? _getActiveContext() {
    // 尝试获取顶层导航器上下文
    BuildContext? context;
    try {
      // 首先尝试从路由获取上下文
      if (AppRoutes.router.routerDelegate.navigatorKey.currentContext != null) {
        context = AppRoutes.router.routerDelegate.navigatorKey.currentContext;
        _logger.d('从路由获取到上下文');
        return context;
      }
    } catch (e) {
      _logger.e('获取路由上下文时出错', error: e);
    }
    
    // 如果还没有上下文，则返回空
    if (context == null) {
      _logger.e('无法获取有效的构建上下文');
    }
    
    return context;
  }

  /// 显示状态栏菜单
  void _showStatusBarMenu(BuildContext context) {
    // 此处可以使用对话框或其他方式显示状态栏菜单
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('状态栏菜单'),
        content: Text('这是从状态栏打开的菜单'),
      ),
    );
  }
  
  /// 显示悬停覆盖菜单
  void _showOverlayMenu(Offset position) {
    _logger.d('开始显示悬停菜单，位置: $position');
    
    // 先关闭已有的覆盖层
    _hideOverlayMenu();

    try {
      // 获取当前上下文
      final context = _getActiveContext();
      if (context == null) {
        _logger.e('无法获取有效的构建上下文显示悬停菜单');
        
        // 尝试使用延迟重试
        Future.delayed(const Duration(milliseconds: 500), () {
          try {
            final retryContext = _getActiveContext();
            if (retryContext != null) {
              _logger.d('延迟后成功获取上下文，显示悬停菜单');
              _createAndShowOverlay(retryContext, position);
            } else {
              _logger.e('延迟重试后仍无法获取上下文');
              
              // 最后尝试使用全局导航器上下文
              final globalContext = WidgetsBinding.instance.rootElement as BuildContext?;
              if (globalContext != null) {
                _logger.d('使用全局上下文显示悬停菜单');
                _createAndShowOverlay(globalContext, position);
              }
            }
          } catch (e) {
            _logger.e('延迟重试时出错', error: e);
          }
        });
        return;
      }

      _logger.d('成功获取上下文，准备显示悬停菜单');
      _createAndShowOverlay(context, position);
    } catch (e) {
      _logger.e('显示悬停菜单时出错', error: e);
    }
  }
  
  /// 创建并显示覆盖层
  void _createAndShowOverlay(BuildContext context, Offset position) {
    _logger.d('开始创建并显示覆盖层');
    
    try {
      // 检查是否有效的Overlay
      final overlay = Overlay.of(context, debugRequiredFor: null);
      if (overlay == null) {
        _logger.e('无法获取Overlay实例');
        return;
      }
      
      _logger.d('成功获取Overlay实例，创建覆盖层');
      
      // 创建新的覆盖层
      _overlayEntry = OverlayEntry(
        builder: (context) {
          _logger.d('构建覆盖菜单UI');
          return _buildOverlayMenu(position);
        },
      );

      // 插入覆盖层
      _logger.d('插入覆盖层到Overlay');
      overlay.insert(_overlayEntry!);
      _logger.d('覆盖层插入成功');
    } catch (e) {
      _logger.e('创建并显示覆盖层时出错', error: e);
    }
  }

  /// 构建悬停覆盖菜单
  Widget _buildOverlayMenu(Offset position) {
    // 获取屏幕尺寸
    final screenSize = MediaQuery.of(_getActiveContext()!).size;
    
    // 菜单尺寸（估计值，可以根据实际情况调整）
    final menuWidth = screenSize.width * 0.8; // 使用屏幕宽度的80%
    final menuHeight = screenSize.height * 0.8; // 使用屏幕高度的80%
    
    // 计算菜单位置，确保不超出屏幕边界
    double left = (screenSize.width - menuWidth) / 2; // 居中显示
    double top = (screenSize.height - menuHeight) / 2; // 居中显示
    
    // 调整上边界，确保菜单显示在图标下方
    if (top + menuHeight > screenSize.height - 10) {
      top = position.dy - menuHeight - 10; // 如果下方空间不足，显示在图标上方
    }
    
    // 返回构建好的覆盖层，显示截图捕获页面
    return Stack(
      children: [
        // 透明遮罩层 - 点击时关闭覆盖层
        Positioned.fill(
          child: GestureDetector(
            onTap: _hideOverlayMenu,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.black.withOpacity(0.3), // 半透明背景
            ),
          ),
        ),
        
        // 截图捕获页面内容
        Positioned(
          left: left,
          top: top,
          width: menuWidth,
          height: menuHeight,
          child: Material(
            color: Colors.transparent,
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                // 使用导入的CapturePage组件
                child: const Material(
                  color: Colors.white,
                  child: CapturePage(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建菜单项
  Widget _buildMenuItems() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 截图工具
        _buildMenuItem(
          icon: Icons.screenshot,
          label: '截图工具',
          onTap: () => navigateToRoute('/'),
        ),
        
        // 缓存文本
        _buildMenuItem(
          icon: Icons.text_fields,
          label: '缓存文本示例',
          onTap: () => navigateToRoute('/cached-text-example'),
        ),
        
        // 设置
        _buildMenuItem(
          icon: Icons.settings,
          label: '设置',
          onTap: () {
            _hideOverlayMenu();
            // 显示设置页面（待实现）
          },
        ),
        
        // 关于
        _buildMenuItem(
          icon: Icons.info_outline,
          label: '关于',
          onTap: () {
            _hideOverlayMenu();
            // 显示关于页面（待实现）
          },
        ),
      ],
    );
  }

  /// 构建单个菜单项
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  /// 隐藏悬停覆盖菜单
  void _hideOverlayMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 显示弹出菜单
  Future<bool> showPopover() async {
    if (!Platform.isMacOS) return false;

    try {
      _logger.d('请求显示状态栏弹出菜单');
      final result = await _channel.invokeMethod<bool>('showPopover') ?? false;
      _logger.d('显示弹出菜单${result ? '成功' : '失败'}');
      return result;
    } catch (e) {
      _logger.e('显示弹出菜单错误', error: e);
      return false;
    }
  }

  /// 隐藏弹出菜单
  Future<bool> hidePopover() async {
    if (!Platform.isMacOS) return false;

    try {
      _logger.d('请求隐藏状态栏弹出菜单');
      final result = await _channel.invokeMethod<bool>('hidePopover') ?? false;
      _logger.d('隐藏弹出菜单${result ? '成功' : '失败'}');
      return result;
    } catch (e) {
      _logger.e('隐藏弹出菜单错误', error: e);
      return false;
    }
  }

  /// 检查弹出菜单是否可见
  Future<bool> isPopoverVisible() async {
    if (!Platform.isMacOS) return false;

    try {
      _logger.d('检查弹出菜单是否可见');
      final result =
          await _channel.invokeMethod<bool>('isPopoverVisible') ?? false;
      _logger.d('弹出菜单${result ? '可见' : '不可见'}');
      return result;
    } catch (e) {
      _logger.e('检查弹出菜单可见性错误', error: e);
      return false;
    }
  }

  /// 更新菜单UI
  Future<bool> updateMenuUI(String route) async {
    if (!Platform.isMacOS) return false;

    try {
      _logger.d('请求更新菜单UI，路由: $route');
      final result = await _channel.invokeMethod<bool>(
            'updateMenuUI',
            {'route': route},
          ) ??
          false;
      _logger.d('更新菜单UI${result ? '成功' : '失败'}');
      return result;
    } catch (e) {
      _logger.e('更新菜单UI错误', error: e);
      return false;
    }
  }
}

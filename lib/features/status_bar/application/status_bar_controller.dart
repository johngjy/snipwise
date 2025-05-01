import 'package:flutter/material.dart';
import '../domain/entities/status_bar_menu_item.dart';

/// 状态栏控制器 - 管理状态栏菜单的状态和行为
class StatusBarController extends ChangeNotifier {
  /// 菜单项列表
  List<StatusBarMenuItem> _menuItems = [];

  /// 构造函数 - 初始化默认菜单项
  StatusBarController() {
    _initializeMenuItems();
  }

  /// 获取菜单项列表
  List<StatusBarMenuItem> get menuItems => _menuItems;

  /// 初始化默认菜单项
  void _initializeMenuItems() {
    _menuItems = [
      StatusBarMenuItem(
        id: 'capture_area',
        title: 'Capture Area',
        icon: Icons.crop_square_outlined,
        onTap: _captureArea,
      ),
      StatusBarMenuItem(
        id: 'capture_window',
        title: 'Capture Window',
        icon: Icons.web_asset_outlined,
        onTap: _captureWindow,
      ),
      StatusBarMenuItem(
        id: 'capture_screen',
        title: 'Capture Screen',
        icon: Icons.desktop_windows_outlined,
        onTap: _captureScreen,
      ),
      StatusBarMenuItem.divider(),
      StatusBarMenuItem(
        id: 'recent_screenshots',
        title: 'Recent Screenshots',
        icon: Icons.history_outlined,
        onTap: _openRecentScreenshots,
      ),
      StatusBarMenuItem.divider(),
      StatusBarMenuItem(
        id: 'quit',
        title: 'Quit',
        icon: Icons.exit_to_app_outlined,
        onTap: _quitApp,
      ),
    ];
  }

  /// 设置菜单项列表
  void setMenuItems(List<StatusBarMenuItem> items) {
    _menuItems = items;
    notifyListeners();
  }

  /// 根据ID查找菜单项
  StatusBarMenuItem? findMenuItemById(String id) {
    try {
      return _menuItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 更新菜单项
  void updateMenuItem(String id, StatusBarMenuItem updatedItem) {
    final index = _menuItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      _menuItems[index] = updatedItem;
      notifyListeners();
    }
  }

  void _captureArea() {
    // TODO: Implement area capture functionality
    print('Capture area clicked');
  }

  void _captureWindow() {
    // TODO: Implement window capture functionality
    print('Capture window clicked');
  }

  void _captureScreen() {
    // TODO: Implement screen capture functionality
    print('Capture screen clicked');
  }

  void _openRecentScreenshots() {
    // TODO: Implement opening recent screenshots
    print('Recent screenshots clicked');
  }

  void _quitApp() {
    // TODO: Implement app quitting
    print('Quit clicked');
  }
}

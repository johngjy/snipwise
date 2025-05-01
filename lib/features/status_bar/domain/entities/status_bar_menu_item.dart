import 'package:flutter/material.dart';

/// 状态栏菜单项实体
class StatusBarMenuItem {
  /// 菜单项ID
  final String? id;

  /// 菜单项图标
  final IconData? icon;

  /// 菜单项标题
  final String title;

  /// 菜单项快捷键
  final String? shortcut;

  /// 点击回调
  final VoidCallback? onTap;

  /// 是否有子菜单
  final bool hasSubMenu;

  /// 是否为分隔符
  final bool isDivider;

  /// 构造函数
  const StatusBarMenuItem({
    this.id,
    required this.title,
    this.icon,
    this.shortcut,
    this.onTap,
    this.hasSubMenu = false,
    this.isDivider = false,
  });

  /// 基于现有菜单项创建新的菜单项
  StatusBarMenuItem copyWith({
    String? id,
    IconData? icon,
    String? title,
    String? shortcut,
    VoidCallback? onTap,
    bool? hasSubMenu,
    bool? isDivider,
  }) {
    return StatusBarMenuItem(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      title: title ?? this.title,
      shortcut: shortcut ?? this.shortcut,
      onTap: onTap ?? this.onTap,
      hasSubMenu: hasSubMenu ?? this.hasSubMenu,
      isDivider: isDivider ?? this.isDivider,
    );
  }

  factory StatusBarMenuItem.divider() {
    return StatusBarMenuItem(
      id: 'divider_${DateTime.now().millisecondsSinceEpoch}',
      title: '',
      isDivider: true,
    );
  }
}

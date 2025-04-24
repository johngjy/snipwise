import 'package:flutter/material.dart';

/// 应用颜色常量
class AppColors {
  /// 私有构造函数，防止实例化
  AppColors._();

  /// 主要文本颜色
  static const Color primaryText = Color(0xE5000000); // rgba(0, 0, 0, 0.8956)

  /// 次要文本颜色
  static const Color secondaryText = Color(0xFF888888);

  /// 边框颜色
  static const Color border = Color(0xFFE5E5E5);

  /// 背景颜色 - 更专业的macOS风格背景色
  static const Color background = Color(0xFFF2F2F2);

  /// 白色背景
  static const Color white = Colors.white;

  /// 按钮阴影色
  static const Color shadowColor = Color(0x08000000); // 3%透明度黑色
}

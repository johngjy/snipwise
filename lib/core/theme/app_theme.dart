import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 应用主题配置
class AppTheme {
  /// 私有构造函数，防止实例化
  AppTheme._();

  /// 获取应用主题
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      fontFamily: '.AppleSystemUIFont', // 使用系统字体代替
      iconTheme: const IconThemeData(
        size: 16,
        weight: 100, // 更细的图标
      ),
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 1,
        color: AppColors.border,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryText,
          letterSpacing: 0.5,
          height: 1.0,
        ),
        iconTheme: IconThemeData(
          color: AppColors.primaryText,
          size: 18,
        ),
      ),
    );
  }
}

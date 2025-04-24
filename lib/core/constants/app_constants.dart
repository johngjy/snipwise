import 'package:flutter/material.dart';

/// 应用常量类
class AppConstants {
  AppConstants._(); // 私有构造函数，防止实例化

  // 应用版本
  static const String appVersion = '0.1.0';

  // 应用名称
  static const String appName = 'Snipwise';

  // 文件扩展名
  static const String projectExtension = 'snp';
}

/// 颜色常量
class AppColors {
  AppColors._(); // 私有构造函数，防止实例化

  // 主题颜色
  static const Color primary = Color(0xFF4A86E8);
  static const Color secondary = Color(0xFF6C63FF);
  static const Color accent = Color(0xFFFFA726);

  // 文本颜色
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // 背景颜色
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;

  // 状态颜色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // 工具栏颜色
  static const Color toolbarBackground = Color(0xFF2C2C2C);
  static const Color toolbarItem = Color(0xFFE0E0E0);
  static const Color toolbarItemSelected = primary;

  // 绘图标注颜色
  static const List<Color> annotationColors = [
    Color(0xFFFF5252), // 红色
    Color(0xFF4CAF50), // 绿色
    Color(0xFF2196F3), // 蓝色
    Color(0xFFFFC107), // 黄色
    Color(0xFFE040FB), // 紫色
    Color(0xFF00BCD4), // 青色
    Color(0xFFFF9800), // 橙色
    Color(0xFF607D8B), // 蓝灰色
  ];
}

/// 尺寸常量
class AppDimensions {
  AppDimensions._(); // 私有构造函数，防止实例化

  // 通用间距
  static const double spacingXXS = 2.0;
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // 边框圆角
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 16.0;
  static const double borderRadiusXL = 24.0;

  // 卡片边距
  static const EdgeInsets cardPadding = EdgeInsets.all(spacingM);

  // 按钮尺寸
  static const double buttonHeight = 44.0;
  static const double buttonRadius = borderRadiusM;

  // 工具栏尺寸
  static const double toolbarHeight = 60.0;
  static const double toolbarIconSize = 24.0;
  static const double toolbarItemSpacing = spacingS;

  // 字体尺寸
  static const double fontSizeXS = 12.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 18.0;
  static const double fontSizeXL = 20.0;
  static const double fontSizeXXL = 24.0;

  // 标注尺寸
  static const double annotationLineWidthThin = 2.0;
  static const double annotationLineWidthMedium = 4.0;
  static const double annotationLineWidthThick = 6.0;
}

/// 应用字符串
class AppStrings {
  AppStrings._(); // 私有构造函数，防止实例化

  // 通用字符串
  static const String ok = '确定';
  static const String cancel = '取消';
  static const String save = '保存';
  static const String delete = '删除';
  static const String edit = '编辑';
  static const String close = '关闭';
  static const String loading = '加载中...';
  static const String error = '错误';
  static const String success = '成功';

  // 文件操作
  static const String fileOpen = '打开文件';
  static const String fileSave = '保存文件';
  static const String fileExport = '导出';
  static const String fileImport = '导入';
  static const String fileNew = '新建项目';

  // 编辑操作
  static const String editUndo = '撤销';
  static const String editRedo = '重做';
  static const String editCopy = '复制';
  static const String editPaste = '粘贴';
  static const String editCut = '剪切';
  static const String editDelete = '删除';
  static const String editSelectAll = '全选';

  // 注释工具
  static const String toolArrow = '箭头';
  static const String toolRect = '矩形';
  static const String toolCircle = '圆形';
  static const String toolLine = '直线';
  static const String toolText = '文本';
  static const String toolHighlight = '高亮';
  static const String toolBlur = '模糊';
  static const String toolCrop = '裁剪';

  // 设置
  static const String settingsTitle = '设置';
  static const String settingsLanguage = '语言';
  static const String settingsTheme = '主题';
  static const String settingsDarkMode = '深色模式';
  static const String settingsExportQuality = '导出质量';

  // 错误消息
  static const String errorLoadingImage = '无法加载图片';
  static const String errorSavingFile = '保存文件失败';
  static const String errorExporting = '导出失败';
  static const String errorGeneric = '出现错误，请重试';
}

/// 路由常量
class AppRoutes {
  AppRoutes._(); // 私有构造函数，防止实例化

  static const String splash = '/';
  static const String home = '/home';
  static const String editor = '/editor';
  static const String settings = '/settings';
  static const String about = '/about';
}

/// 资源路径常量
class AppAssets {
  AppAssets._(); // 私有构造函数，防止实例化

  // 图片
  static const String logoPath = 'assets/images/logo.png';
  static const String backgroundPath = 'assets/images/background.png';

  // 图标
  static const String iconsPath = 'assets/icons/';
}

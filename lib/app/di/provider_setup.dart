import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../themes/theme_provider.dart';
import '../../features/editor/presentation/providers/project_provider.dart';
import '../../features/editor/presentation/providers/tools_provider.dart';
import '../../features/editor/presentation/providers/settings_provider.dart';
import '../../features/hires_capture/presentation/providers/hires_capture_provider.dart';
import '../../features/annotation/presentation/providers/magnifier_provider.dart';

/// 全局Provider配置
List<SingleChildWidget> globalProviders = [
  ChangeNotifierProvider(create: (_) => ThemeProvider()),
  // 其他全局Provider...
];

/// 特性级Provider配置
List<SingleChildWidget> featureProviders = [
  ChangeNotifierProvider(create: (_) => ProjectProvider()),
  ChangeNotifierProvider(create: (_) => ToolsProvider()),
  ChangeNotifierProvider(create: (_) => SettingsProvider()),
  ChangeNotifierProvider(create: (_) => HiResCapureProvider()),
  ChangeNotifierProvider(create: (_) => MagnifierProvider()),
  // 其他特性级Provider...
];

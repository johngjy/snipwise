import 'package:flutter/material.dart';
import 'themes/app_theme.dart';

class SnipwiseApp extends StatelessWidget {
  const SnipwiseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snipwise',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // TODO: 添加路由配置
      // routes: AppRouter.routes,
      // initialRoute: Routes.home,
      home: const Scaffold(
        body: Center(
          child: Text('Snipwise - 开发中'),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

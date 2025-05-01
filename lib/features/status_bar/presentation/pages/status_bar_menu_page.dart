import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/status_bar_menu.dart';
import '../../application/status_bar_controller.dart';

/// 状态栏菜单页面 - 作为状态栏菜单的入口点
class StatusBarMenuPage extends StatelessWidget {
  const StatusBarMenuPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Material(
        color: Colors.transparent,
        child: Center(
          child: ChangeNotifierProvider<StatusBarController>(
            create: (_) => StatusBarController(),
            child: const StatusBarMenu(),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../application/core/editor_state_core.dart';
import '../../application/providers/state_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'delay_dropdown_menu.dart';

/// 新建按钮下拉菜单
class NewButtonMenu extends ConsumerWidget {
  /// 菜单关闭回调
  final VoidCallback onClose;

  const NewButtonMenu({
    Key? key,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMenuItem(
              context,
              '新建截图',
              PhosphorIcons.camera(PhosphorIconsStyle.light),
              () {
                onClose();
                Navigator.pushNamed(context, '/capture');
              },
            ),
            _buildMenuItem(
              context,
              '延时截图',
              PhosphorIcons.timer(PhosphorIconsStyle.light),
              () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: DelayDropdownMenu(
                      onDelaySelected: (duration) {
                        onClose();
                        Navigator.pushNamed(
                          context,
                          '/capture',
                          arguments: {'delay': duration},
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            _buildMenuItem(
              context,
              '从剪贴板导入',
              PhosphorIcons.clipboard(PhosphorIconsStyle.light),
              () async {
                onClose();
                // TODO: 实现从剪贴板导入功能
              },
            ),
            _buildMenuItem(
              context,
              '从文件导入',
              PhosphorIcons.image(PhosphorIconsStyle.light),
              () async {
                onClose();
                // TODO: 实现从文件导入功能
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: Colors.black87,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

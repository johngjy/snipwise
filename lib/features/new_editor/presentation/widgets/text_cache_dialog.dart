import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../application/providers/painter_providers.dart';
import '../../../../core/services/clipboard_service.dart';

/// 文本缓存对话框
/// 显示所有缓存的文本内容，支持复制和搜索
class TextCacheDialog extends ConsumerWidget {
  const TextCacheDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textCache = ref.watch(textCacheProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '文本内容',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    PhosphorIcons.x(PhosphorIconsStyle.light),
                    size: 20,
                  ),
                  onPressed: () {
                    ref.read(showTextCacheDialogProvider.notifier).state =
                        false;
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 文本内容列表
            Expanded(
              child: textCache.isEmpty
                  ? const Center(
                      child: Text(
                        '没有文本内容',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: textCache.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final text = textCache[index];
                        return ListTile(
                          title: Text(
                            text,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              PhosphorIcons.copySimple(
                                  PhosphorIconsStyle.light),
                              size: 18,
                            ),
                            onPressed: () {
                              _copyToClipboard(context, text);
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // 底部按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ref.read(textCacheProvider.notifier).clearAll();
                  },
                  child: const Text('清空'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ref.read(showTextCacheDialogProvider.notifier).state =
                        false;
                  },
                  child: const Text('关闭'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 复制文本到剪贴板
  Future<void> _copyToClipboard(BuildContext context, String text) async {
    try {
      final result = await ClipboardService.instance.copyText(text);

      if (!result) {
        await Clipboard.setData(ClipboardData(text: text));
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('已复制到剪贴板'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('复制失败: $e'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

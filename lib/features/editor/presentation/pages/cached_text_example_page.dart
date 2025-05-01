import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/services/cached_text_service.dart';

/// 缓存文本示例页面 - 展示缓存文本功能的用法
class CachedTextExamplePage extends ConsumerStatefulWidget {
  /// 构造函数
  const CachedTextExamplePage({Key? key}) : super(key: key);

  @override
  ConsumerState<CachedTextExamplePage> createState() =>
      _CachedTextExamplePageState();
}

class _CachedTextExamplePageState extends ConsumerState<CachedTextExamplePage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _sourceController =
      TextEditingController(text: '手动输入');

  @override
  void dispose() {
    _textController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  /// 添加文本到缓存
  void _addTextToCache() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final source = _sourceController.text.trim().isEmpty
        ? '手动输入'
        : _sourceController.text.trim();

    // 使用服务添加文本
    final cachedTextService = ref.read(cachedTextServiceProvider);
    cachedTextService.addText(ref, text, source);

    // 清空输入框
    _textController.clear();

    // 显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('文本已添加到缓存')),
    );
  }

  /// 显示缓存文本对话框
  void _showCachedTexts() {
    final cachedTextService = ref.read(cachedTextServiceProvider);
    cachedTextService.showCachedTextDialog(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    // 监听缓存文本列表变化
    final cachedTexts = ref.watch(cachedTextsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('缓存文本示例'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.text_badge_plus),
            onPressed: _showCachedTexts,
            tooltip: '查看缓存文本',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文本输入
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: '文本内容',
                hintText: '输入要缓存的文本',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // 来源输入
            TextField(
              controller: _sourceController,
              decoration: const InputDecoration(
                labelText: '文本来源',
                hintText: '输入文本的来源',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // 添加按钮
            ElevatedButton.icon(
              onPressed: _addTextToCache,
              icon: const Icon(CupertinoIcons.add),
              label: const Text('添加到缓存'),
            ),

            const SizedBox(height: 24),

            // 缓存统计
            Text(
              '当前缓存文本数量: ${cachedTexts.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // 最新文本预览
            if (cachedTexts.isNotEmpty) ...[
              const Text(
                '最新缓存文本:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cachedTexts.last.content,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '来源: ${cachedTexts.last.source}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

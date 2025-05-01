import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../../domain/models/cached_text.dart';
import '../../domain/models/cached_text_types.dart';
import '../../application/services/cached_text_service.dart';

/// 缓存文本对话框 - 显示所有缓存的文本内容
class CachedTextDialog extends StatelessWidget {
  /// 缓存的文本列表
  final List<CachedText> texts;

  /// 关闭对话框回调
  final VoidCallback onClose;

  /// 清除所有缓存回调
  final VoidCallback onClearAll;

  /// 删除特定文本回调
  final Function(CachedText) onRemoveText;

  /// 当前过滤类型
  final CachedTextFilterType currentFilter;

  /// 当前排序类型
  final CachedTextSortType currentSortType;

  /// 过滤类型变化回调
  final Function(CachedTextFilterType) onFilterChanged;

  /// 排序类型变化回调
  final Function(CachedTextSortType) onSortTypeChanged;

  /// 构造函数
  const CachedTextDialog({
    Key? key,
    required this.texts,
    required this.onClose,
    required this.onClearAll,
    required this.onRemoveText,
    required this.currentFilter,
    required this.currentSortType,
    required this.onFilterChanged,
    required this.onSortTypeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Container(
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: 800,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 标题栏
              Row(
                children: [
                  const Text(
                    '文本缓存',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${texts.length} 条',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // 功能按钮区
                  if (texts.isNotEmpty) ...[
                    _buildActionButton(
                      context: context,
                      icon: CupertinoIcons.arrow_down_doc,
                      label: '导出',
                      onPressed: () => _exportTexts(context),
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context: context,
                      icon: CupertinoIcons.trash,
                      label: '清除全部',
                      color: Colors.red,
                      onPressed: () => _showClearConfirmation(context),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // 导入按钮
                  _buildActionButton(
                    context: context,
                    icon: CupertinoIcons.arrow_up_doc,
                    label: '导入',
                    onPressed: () => _importTexts(context),
                  ),

                  const SizedBox(width: 8),

                  // 关闭按钮
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onClose,
                    child: const Icon(CupertinoIcons.xmark),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 过滤和排序工具栏
              _buildFilterAndSortToolbar(context),

              const SizedBox(height: 16),

              // 搜索框
              Consumer(
                builder: (context, ref, _) {
                  return _SearchBar(
                    texts: texts,
                    dateFormat: dateFormat,
                    onRemoveText: onRemoveText,
                  );
                },
              ),

              const SizedBox(height: 16),

              // 内容列表
              Expanded(
                child: texts.isEmpty
                    ? _buildEmptyView()
                    : _buildTextList(texts, dateFormat),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建功能按钮
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.blue,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }

  /// 构建空列表视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无缓存文本',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '使用OCR识别或手动输入文本后，内容将自动缓存在这里',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建文本列表
  Widget _buildTextList(List<CachedText> texts, DateFormat dateFormat) {
    return ListView.separated(
      itemCount: texts.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        // 倒序显示，最新的在前面
        final text = texts[texts.length - 1 - index];
        return _TextItem(
          text: text,
          dateFormat: dateFormat,
          onRemove: () => onRemoveText(text),
        );
      },
    );
  }

  /// 显示清除确认对话框
  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('确定要清除所有缓存的文本吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onClearAll();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  /// 导出文本到文件
  Future<void> _exportTexts(BuildContext context) async {
    try {
      final jsonList = texts.map((text) => text.toJson()).toList();
      final jsonStr = json.encode(jsonList);
      final String fileName =
          'cached_texts_${DateTime.now().millisecondsSinceEpoch}.json';

      if (kIsWeb) {
        // Web平台不支持文件系统访问，显示一个对话框让用户复制内容
        await _showExportWebDialog(context, jsonStr);
      } else {
        // 桌面或移动平台使用FilePicker
        String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: '保存缓存文本',
          fileName: fileName,
          allowedExtensions: ['json'],
          type: FileType.custom,
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsString(jsonStr);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('成功导出 ${texts.length} 条文本')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  /// 显示Web导出对话框
  Future<void> _showExportWebDialog(
      BuildContext context, String jsonContent) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出数据'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('由于Web浏览器限制，请复制以下内容并保存到一个.json文件中:'),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(8),
                child: SelectableText(
                  jsonContent,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonContent));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('内容已复制到剪贴板')),
              );
            },
            child: const Text('复制到剪贴板'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 从文件导入文本
  Future<void> _importTexts(BuildContext context) async {
    if (kIsWeb) {
      await _showImportWebDialog(context);
      return;
    }

    try {
      // 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: '选择文本文件',
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (result != null) {
        String content = '';

        // 根据平台处理文件内容
        if (result.files.single.bytes != null) {
          // Web 平台或直接获取bytes的情况
          final bytes = result.files.single.bytes!;
          content = utf8.decode(bytes);
        } else if (result.files.single.path != null) {
          // 桌面或移动平台
          final file = File(result.files.single.path!);
          content = await file.readAsString();
        } else {
          throw Exception('无法读取文件内容');
        }

        await _processImportedContent(context, content);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  /// 显示Web导入对话框
  Future<void> _showImportWebDialog(BuildContext context) async {
    final TextEditingController controller = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入数据'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('请粘贴JSON格式的缓存文本数据:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '粘贴JSON数据...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final content = controller.text.trim();
              if (content.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入JSON数据')),
                );
                return;
              }

              Navigator.of(context).pop();
              await _processImportedContent(context, content);
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  /// 处理导入的内容
  Future<void> _processImportedContent(
      BuildContext context, String content) async {
    try {
      // 获取服务和引用
      final widgetRef = ProviderScope.containerOf(context) as WidgetRef;
      final service = widgetRef.read(cachedTextServiceProvider);

      // 导入文本
      await service.importTextsFromJson(widgetRef, content);

      // 显示成功消息
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('成功导入文本')),
        );
      }

      // 关闭对话框并重新打开以刷新
      if (context.mounted) {
        Navigator.of(context).pop();
        service.showCachedTextDialog(context, widgetRef);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  /// 构建过滤和排序工具栏
  Widget _buildFilterAndSortToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 过滤选择器
          const Text('筛选: ', style: TextStyle(fontSize: 14)),
          DropdownButton<CachedTextFilterType>(
            value: currentFilter,
            underline: const SizedBox(),
            items: CachedTextFilterType.values.map((filter) {
              String label = '未知';
              switch (filter) {
                case CachedTextFilterType.all:
                  label = '全部';
                  break;
                case CachedTextFilterType.ocrOnly:
                  label = 'OCR识别';
                  break;
                case CachedTextFilterType.manualOnly:
                  label = '手动输入';
                  break;
                case CachedTextFilterType.today:
                  label = '今天';
                  break;
                case CachedTextFilterType.yesterday:
                  label = '昨天';
                  break;
                case CachedTextFilterType.lastWeek:
                  label = '过去7天';
                  break;
              }
              return DropdownMenuItem<CachedTextFilterType>(
                value: filter,
                child: Text(label, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onFilterChanged(value);
              }
            },
          ),

          const Spacer(),

          // 排序选择器
          const Text('排序: ', style: TextStyle(fontSize: 14)),
          DropdownButton<CachedTextSortType>(
            value: currentSortType,
            underline: const SizedBox(),
            items: CachedTextSortType.values.map((sortType) {
              String label = '未知';
              switch (sortType) {
                case CachedTextSortType.dateDesc:
                  label = '时间 (新→旧)';
                  break;
                case CachedTextSortType.dateAsc:
                  label = '时间 (旧→新)';
                  break;
                case CachedTextSortType.lengthDesc:
                  label = '长度 (长→短)';
                  break;
                case CachedTextSortType.lengthAsc:
                  label = '长度 (短→长)';
                  break;
              }
              return DropdownMenuItem<CachedTextSortType>(
                value: sortType,
                child: Text(label, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                onSortTypeChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// 文本项组件
class _TextItem extends StatelessWidget {
  final CachedText text;
  final DateFormat dateFormat;
  final VoidCallback onRemove;

  const _TextItem({
    required this.text,
    required this.dateFormat,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        text.content,
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(
        '来源: ${text.source} - ${dateFormat.format(text.timestamp)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(CupertinoIcons.doc_on_clipboard, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: text.content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已复制到剪贴板')),
              );
            },
            tooltip: '复制文本',
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.trash, size: 20),
            onPressed: onRemove,
            tooltip: '删除',
          ),
        ],
      ),
    );
  }
}

/// 搜索栏组件
class _SearchBar extends StatefulWidget {
  final List<CachedText> texts;
  final DateFormat dateFormat;
  final Function(CachedText) onRemoveText;

  const _SearchBar({
    required this.texts,
    required this.dateFormat,
    required this.onRemoveText,
  });

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final TextEditingController _searchController = TextEditingController();
  List<CachedText> _filteredTexts = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredTexts = widget.texts;
    _searchController.addListener(_filterTexts);
  }

  @override
  void didUpdateWidget(covariant _SearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.texts != widget.texts) {
      _filterTexts();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTexts);
    _searchController.dispose();
    super.dispose();
  }

  void _filterTexts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (_isSearching) {
        _filteredTexts = widget.texts
            .where((text) =>
                text.content.toLowerCase().contains(query) ||
                text.source.toLowerCase().contains(query))
            .toList();
      } else {
        _filteredTexts = widget.texts;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 搜索输入框
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: '搜索文本内容或来源',
            prefixIcon: const Icon(CupertinoIcons.search),
            suffixIcon: _isSearching
                ? IconButton(
                    icon: const Icon(CupertinoIcons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),

        // 搜索结果提示
        if (_isSearching) ...[
          const SizedBox(height: 8),
          Text(
            '找到 ${_filteredTexts.length} 条匹配结果',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),

          // 搜索结果列表
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _filteredTexts.isEmpty
                ? const Center(child: Text('没有找到匹配的文本'))
                : ListView.separated(
                    itemCount: _filteredTexts.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final text = _filteredTexts[index];
                      return _TextItem(
                        text: text,
                        dateFormat: widget.dateFormat,
                        onRemove: () => widget.onRemoveText(text),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }
}

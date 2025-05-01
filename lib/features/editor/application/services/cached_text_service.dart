import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/cached_text.dart';
import '../../domain/models/cached_text_types.dart';
import '../../presentation/widgets/cached_text_dialog.dart';

/// 筛选器提供者
final textFilterProvider = StateProvider<CachedTextFilterType>(
  (ref) => CachedTextFilterType.all,
);

/// 排序方式提供者
final textSortProvider = StateProvider<CachedTextSortType>(
  (ref) => CachedTextSortType.dateDesc,
);

/// 缓存文本服务提供者
final cachedTextServiceProvider = Provider<CachedTextService>((ref) {
  return CachedTextService(ref);
});

/// 缓存文本列表提供者
final cachedTextsProvider =
    StateNotifierProvider<CachedTextsNotifier, List<CachedText>>((ref) {
  return CachedTextsNotifier(ref);
});

/// 过滤后的缓存文本列表提供者
final filteredCachedTextsProvider = Provider<List<CachedText>>((ref) {
  final texts = ref.watch(cachedTextsProvider);
  final filter = ref.watch(textFilterProvider);
  final sortType = ref.watch(textSortProvider);

  // 应用过滤器
  final filteredTexts = _filterTexts(texts, filter);

  // 应用排序
  return _sortTexts(filteredTexts, sortType);
});

/// 根据过滤器过滤文本
List<CachedText> _filterTexts(
    List<CachedText> texts, CachedTextFilterType filter) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final lastWeek = today.subtract(const Duration(days: 7));

  switch (filter) {
    case CachedTextFilterType.all:
      return texts;

    case CachedTextFilterType.ocrOnly:
      return texts
          .where((text) =>
              text.source.toLowerCase().contains('ocr') ||
              text.source.toLowerCase().contains('识别'))
          .toList();

    case CachedTextFilterType.manualOnly:
      return texts
          .where((text) =>
              text.source.toLowerCase().contains('手动') ||
              text.source.toLowerCase().contains('输入'))
          .toList();

    case CachedTextFilterType.today:
      return texts.where((text) {
        final date = DateTime(
            text.timestamp.year, text.timestamp.month, text.timestamp.day);
        return date.isAtSameMomentAs(today);
      }).toList();

    case CachedTextFilterType.yesterday:
      return texts.where((text) {
        final date = DateTime(
            text.timestamp.year, text.timestamp.month, text.timestamp.day);
        return date.isAtSameMomentAs(yesterday);
      }).toList();

    case CachedTextFilterType.lastWeek:
      return texts.where((text) {
        final date = DateTime(
            text.timestamp.year, text.timestamp.month, text.timestamp.day);
        return date.isAfter(lastWeek.subtract(const Duration(days: 1))) &&
            date.isBefore(today.add(const Duration(days: 1)));
      }).toList();
  }
}

/// 根据排序方式排序文本
List<CachedText> _sortTexts(
    List<CachedText> texts, CachedTextSortType sortType) {
  final sortedTexts = List<CachedText>.from(texts);

  switch (sortType) {
    case CachedTextSortType.dateDesc:
      sortedTexts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      break;

    case CachedTextSortType.dateAsc:
      sortedTexts.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      break;

    case CachedTextSortType.lengthDesc:
      sortedTexts.sort((a, b) => b.content.length.compareTo(a.content.length));
      break;

    case CachedTextSortType.lengthAsc:
      sortedTexts.sort((a, b) => a.content.length.compareTo(b.content.length));
      break;
  }

  return sortedTexts;
}

/// 缓存文本列表状态通知器
class CachedTextsNotifier extends StateNotifier<List<CachedText>> {
  final Ref _ref;
  static const String _storageKey = 'cached_texts';

  CachedTextsNotifier(this._ref) : super([]) {
    // 初始化时加载保存的文本
    _loadCachedTexts();
  }

  /// 从持久化存储加载文本
  Future<void> _loadCachedTexts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey);

      if (jsonList != null && jsonList.isNotEmpty) {
        final List<CachedText> loadedTexts = jsonList
            .map((jsonStr) => CachedText.fromJson(json.decode(jsonStr)))
            .toList();

        state = loadedTexts;
      }
    } catch (e) {
      debugPrint('加载缓存文本时出错: $e');
    }
  }

  /// 保存文本到持久化存储
  Future<void> _saveCachedTexts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((text) => json.encode(text.toJson())).toList();

      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      debugPrint('保存缓存文本时出错: $e');
    }
  }

  /// 添加文本到缓存
  void addText(String content, String source) {
    // 检查是否有重复文本
    if (state.any((text) => text.content == content)) {
      return; // 如果已存在相同内容，跳过
    }

    final newState = [
      ...state,
      CachedText(
        content: content,
        source: source,
        timestamp: DateTime.now(),
      ),
    ];

    state = newState;
    _saveCachedTexts();
  }

  /// 移除特定缓存文本
  void removeText(CachedText text) {
    final newState = state.where((t) => t != text).toList();
    state = newState;
    _saveCachedTexts();
  }

  /// 清除所有缓存文本
  void clearAll() {
    state = [];
    _saveCachedTexts();
  }

  /// 批量删除缓存文本
  void removeTexts(List<CachedText> textsToRemove) {
    if (textsToRemove.isEmpty) return;

    final newState =
        state.where((text) => !textsToRemove.contains(text)).toList();
    state = newState;
    _saveCachedTexts();
  }

  /// 清除特定时间段之前的缓存文本
  void clearBeforeDate(DateTime date) {
    final newState =
        state.where((text) => text.timestamp.isAfter(date)).toList();
    state = newState;
    _saveCachedTexts();
  }

  /// 更新缓存文本
  void updateText(CachedText oldText, String newContent, String newSource) {
    final index = state.indexOf(oldText);
    if (index == -1) return;

    final updatedText = CachedText(
      content: newContent,
      source: newSource,
      timestamp: oldText.timestamp,
    );

    final newState = List<CachedText>.from(state);
    newState[index] = updatedText;

    state = newState;
    _saveCachedTexts();
  }
}

/// 缓存文本服务
class CachedTextService {
  final Ref _ref;

  CachedTextService(this._ref);

  /// 显示缓存文本对话框
  void showCachedTextDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final textsNotifier = ref.read(cachedTextsProvider.notifier);
          final texts = ref.watch(filteredCachedTextsProvider);
          final filter = ref.watch(textFilterProvider);
          final sortType = ref.watch(textSortProvider);

          return CachedTextDialog(
            texts: texts,
            onClose: () => Navigator.of(context).pop(),
            onClearAll: textsNotifier.clearAll,
            onRemoveText: textsNotifier.removeText,
            currentFilter: filter,
            currentSortType: sortType,
            onFilterChanged: (newFilter) =>
                ref.read(textFilterProvider.notifier).state = newFilter,
            onSortTypeChanged: (newSortType) =>
                ref.read(textSortProvider.notifier).state = newSortType,
          );
        },
      ),
    );
  }

  /// 添加文本到缓存
  void addText(WidgetRef ref, String content, String source) {
    if (content.trim().isEmpty) return;
    ref.read(cachedTextsProvider.notifier).addText(content, source);
  }

  /// 获取所有缓存文本
  List<CachedText> getAllTexts(WidgetRef ref) {
    return ref.read(cachedTextsProvider);
  }

  /// 获取最新的缓存文本
  CachedText? getLatestText(WidgetRef ref) {
    final texts = ref.read(cachedTextsProvider);
    if (texts.isEmpty) return null;
    return texts.last;
  }

  /// 导出缓存文本为JSON字符串
  String exportTextsAsJson(WidgetRef ref) {
    final texts = ref.read(cachedTextsProvider);
    final List<Map<String, dynamic>> jsonList =
        texts.map((text) => text.toJson()).toList();
    return json.encode(jsonList);
  }

  /// 从JSON字符串导入缓存文本
  Future<void> importTextsFromJson(WidgetRef ref, String jsonString) async {
    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      final List<CachedText> texts = jsonList
          .map((json) => CachedText.fromJson(json as Map<String, dynamic>))
          .toList();

      // 替换现有文本
      final notifier = ref.read(cachedTextsProvider.notifier);
      notifier.clearAll();

      // 逐个添加，这样会自动保存
      for (final text in texts) {
        notifier.addText(text.content, text.source);
      }
    } catch (e) {
      debugPrint('导入缓存文本时出错: $e');
      rethrow;
    }
  }

  /// 清除特定日期之前的文本
  void clearBeforeDate(WidgetRef ref, DateTime date) {
    ref.read(cachedTextsProvider.notifier).clearBeforeDate(date);
  }

  /// 更新缓存文本
  void updateText(
      WidgetRef ref, CachedText oldText, String newContent, String newSource) {
    ref
        .read(cachedTextsProvider.notifier)
        .updateText(oldText, newContent, newSource);
  }

  /// 获取文本统计信息
  Map<String, dynamic> getTextStatistics(WidgetRef ref) {
    final texts = ref.read(cachedTextsProvider);

    if (texts.isEmpty) {
      return {
        'totalCount': 0,
        'totalCharacters': 0,
        'averageLength': 0,
        'longestText': null,
        'newestText': null,
        'oldestText': null,
        'sourcesCount': <String, int>{},
      };
    }

    // 计算总字符数
    final totalCharacters =
        texts.fold<int>(0, (sum, text) => sum + text.content.length);

    // 计算平均长度
    final averageLength = totalCharacters / texts.length;

    // 找出最长的文本
    final longestText =
        texts.reduce((a, b) => a.content.length > b.content.length ? a : b);

    // 按时间排序，找出最新和最旧的文本
    final sortedByTime = List<CachedText>.from(texts)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final oldestText = sortedByTime.first;
    final newestText = sortedByTime.last;

    // 统计各来源的数量
    final sourcesCount = <String, int>{};
    for (final text in texts) {
      sourcesCount[text.source] = (sourcesCount[text.source] ?? 0) + 1;
    }

    return {
      'totalCount': texts.length,
      'totalCharacters': totalCharacters,
      'averageLength': averageLength,
      'longestText': longestText,
      'newestText': newestText,
      'oldestText': oldestText,
      'sourcesCount': sourcesCount,
    };
  }
}

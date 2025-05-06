import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 文本缓存状态管理器
class TextCacheNotifier extends StateNotifier<List<String>> {
  TextCacheNotifier() : super([]);

  /// 添加文本到缓存
  void addText(String text) {
    state = [...state, text];
  }

  /// 从缓存中移除文本
  void removeText(String text) {
    state = state.where((t) => t != text).toList();
  }

  /// 清空所有缓存
  void clearAll() {
    state = [];
  }
}

/// 缓存文本排序类型枚举
enum CachedTextSortType {
  /// 按时间降序（最新的在前）
  newestFirst,
  
  /// 按时间升序（最旧的在前）
  oldestFirst,
  
  /// 按内容长度降序（最长的在前）
  longestFirst,
  
  /// 按内容长度升序（最短的在前）
  shortestFirst,
  
  /// 按来源排序
  bySource,
}

/// 缓存文本排序类型扩展
extension CachedTextSortTypeExtension on CachedTextSortType {
  /// 获取排序类型显示名称
  String get displayName {
    switch (this) {
      case CachedTextSortType.newestFirst:
        return '最新优先';
      case CachedTextSortType.oldestFirst:
        return '最早优先';
      case CachedTextSortType.longestFirst:
        return '最长优先';
      case CachedTextSortType.shortestFirst:
        return '最短优先';
      case CachedTextSortType.bySource:
        return '按来源';
    }
  }
}

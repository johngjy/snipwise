/// 缓存文本过滤类型枚举
enum CachedTextFilterType {
  /// 全部文本
  all,
  
  /// 今天添加的文本
  today,
  
  /// 本周添加的文本
  thisWeek,
  
  /// 本月添加的文本
  thisMonth,
  
  /// 自定义过滤条件
  custom,
}

/// 缓存文本过滤类型扩展
extension CachedTextFilterTypeExtension on CachedTextFilterType {
  /// 获取过滤类型显示名称
  String get displayName {
    switch (this) {
      case CachedTextFilterType.all:
        return '全部';
      case CachedTextFilterType.today:
        return '今天';
      case CachedTextFilterType.thisWeek:
        return '本周';
      case CachedTextFilterType.thisMonth:
        return '本月';
      case CachedTextFilterType.custom:
        return '自定义';
    }
  }
}

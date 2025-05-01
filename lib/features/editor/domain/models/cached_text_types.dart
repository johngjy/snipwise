/// 缓存文本类型筛选选项
enum CachedTextFilterType {
  /// 全部
  all,

  /// 只显示来自OCR的文本
  ocrOnly,

  /// 只显示手动输入的文本
  manualOnly,

  /// 今天的文本
  today,

  /// 昨天的文本
  yesterday,

  /// 过去七天的文本
  lastWeek,
}

/// 缓存文本排序选项
enum CachedTextSortType {
  /// 时间降序（最近的在前）
  dateDesc,

  /// 时间升序（最旧的在前）
  dateAsc,

  /// 内容长度降序（长的在前）
  lengthDesc,

  /// 内容长度升序（短的在前）
  lengthAsc,
}

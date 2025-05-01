import 'dart:convert';

/// 缓存文本模型 - 非Freezed实现
/// 临时替代方案，解决构建错误
/// 后期可以恢复使用Freezed实现

class CachedText {
  /// 文本内容
  final String content;

  /// 来源（例如：OCR, 手动输入）
  final String source;

  /// 创建时间戳
  final DateTime timestamp;

  /// 构造函数
  const CachedText({
    required this.content,
    required this.source,
    required this.timestamp,
  });

  /// 从JSON创建
  factory CachedText.fromJson(Map<String, dynamic> json) {
    return CachedText(
      content: json['content'] as String,
      source: json['source'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'source': source,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// 复制对象并修改属性
  CachedText copyWith({
    String? content,
    String? source,
    DateTime? timestamp,
  }) {
    return CachedText(
      content: content ?? this.content,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CachedText &&
        other.content == content &&
        other.source == source &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => content.hashCode ^ source.hashCode ^ timestamp.hashCode;
}

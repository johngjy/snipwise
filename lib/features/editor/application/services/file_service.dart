import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/services/clipboard_service.dart';
import '../providers/editor_providers.dart';

/// 文件服务类，处理文件相关操作，包括保存、复制、分享等
class FileService {
  static final FileService _instance = FileService._internal();

  factory FileService() => _instance;

  FileService._internal();

  final Logger _logger = Logger();

  /// 保存图片到下载目录
  Future<String> saveImage(Uint8List imageData,
      {String? name, String? extension}) async {
    if (imageData.isEmpty) {
      throw Exception('图像数据为空');
    }

    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('无法获取下载目录');
      }

      final fileName =
          name ?? 'screenshot_${DateTime.now().millisecondsSinceEpoch}';
      final fileExtension = extension ?? '.png';
      final filePath = '${directory.path}/$fileName$fileExtension';

      await File(filePath).writeAsBytes(imageData);
      _logger.d('图像已保存到: $filePath');

      return filePath;
    } catch (e, stackTrace) {
      _logger.e('保存图像失败', error: e, stackTrace: stackTrace);
      throw Exception('保存图像失败: $e');
    }
  }

  /// 从编辑器状态保存图片
  Future<String> saveImageFromEditorState(WidgetRef ref) async {
    final editorState = ref.read(editorStateProvider);
    final imageData = editorState.currentImageData;

    if (imageData == null || imageData.isEmpty) {
      throw Exception('当前没有可用的图像数据');
    }

    return saveImage(imageData);
  }

  /// 复制图片到剪贴板
  Future<bool> copyImageToClipboard(Uint8List imageData) async {
    if (imageData.isEmpty) {
      _logger.w('无可用的图像数据');
      return false;
    }

    try {
      final ClipboardService clipboardService = ClipboardService();
      final success = await clipboardService.copyImage(imageData);
      _logger.d('图像复制到剪贴板: $success');
      return success;
    } catch (e, stackTrace) {
      _logger.e('复制图像到剪贴板失败', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 从编辑器状态复制图片到剪贴板
  Future<bool> copyImageFromEditorState(WidgetRef ref) async {
    final editorState = ref.read(editorStateProvider);
    final imageData = editorState.currentImageData;

    if (imageData == null || imageData.isEmpty) {
      _logger.w('当前没有可用的图像数据');
      return false;
    }

    return copyImageToClipboard(imageData);
  }

  /// 分享图片
  Future<void> shareImage(Uint8List imageData,
      {String? subject, String? text}) async {
    if (imageData.isEmpty) {
      throw Exception('图像数据为空');
    }

    try {
      // 首先保存到临时目录
      final tempDir = await getTemporaryDirectory();
      final fileName = 'share_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';

      await File(filePath).writeAsBytes(imageData);
      _logger.d('分享图像临时保存到: $filePath');

      // 使用share_plus分享
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: subject ?? '分享截图',
          text: text ?? '来自Snipwise的截图',
        ),
      );

      _logger.d('分享结果: ${result.status}');
    } catch (e, stackTrace) {
      _logger.e('分享图像失败', error: e, stackTrace: stackTrace);
      throw Exception('分享图像失败: $e');
    }
  }

  /// 从编辑器状态分享图片
  Future<void> shareImageFromEditorState(WidgetRef ref,
      {String? subject, String? text}) async {
    final editorState = ref.read(editorStateProvider);
    final imageData = editorState.currentImageData;

    if (imageData == null || imageData.isEmpty) {
      _logger.w('当前没有可用的图像数据');
      throw Exception('当前没有可用的图像数据');
    }

    return shareImage(imageData, subject: subject, text: text);
  }

  /// 打开文件位置
  Future<bool> openFileLocation(String filePath) async {
    try {
      if (!File(filePath).existsSync()) {
        throw Exception('文件不存在');
      }

      // 获取目录路径
      final directory = File(filePath).parent.path;

      // 基于平台打开文件浏览器
      if (Platform.isMacOS) {
        await Process.run('open', [directory]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [directory]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [directory]);
      } else {
        // 尝试使用url_launcher
        final url = Uri.file(directory);
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          throw Exception('无法打开文件位置');
        }
      }

      _logger.d('已打开文件位置: $directory');
      return true;
    } catch (e, stackTrace) {
      _logger.e('打开文件位置失败', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 打开上次保存的文件位置
  Future<bool> openLastSavedFileLocation(WidgetRef ref) async {
    try {
      // 这里可以从某个状态获取上次保存的文件路径
      // 暂时先获取下载目录
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('无法获取下载目录');
      }

      return openFileLocation(directory.path);
    } catch (e, stackTrace) {
      _logger.e('打开上次保存的文件位置失败', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// 从本地文件加载图片
  Future<Uint8List> loadImageFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('文件不存在');
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('文件为空');
      }

      _logger.d('已从文件加载图像: $filePath, 大小: ${bytes.length}字节');
      return bytes;
    } catch (e, stackTrace) {
      _logger.e('从文件加载图像失败', error: e, stackTrace: stackTrace);
      throw Exception('加载图像失败: $e');
    }
  }
}

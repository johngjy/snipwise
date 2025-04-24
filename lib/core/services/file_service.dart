import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// 文件处理服务
class FileService {
  /// 选择图像文件
  Future<File?> pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path;
        if (path != null) {
          return File(path);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// 选择保存路径并保存文件
  Future<String?> saveFile(Uint8List data, String fileName,
      {String? extension}) async {
    try {
      // 移动平台使用应用文档目录
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/$fileName${extension != null ? '.$extension' : ''}';
        final file = File(path);
        await file.writeAsBytes(data);
        return path;
      }
      // 桌面平台使用文件选择器
      else if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final path = await FilePicker.platform.saveFile(
          dialogTitle: '保存文件',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: extension != null ? [extension] : null,
        );

        if (path != null) {
          final file = File(path);
          await file.writeAsBytes(data);
          return path;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error saving file: $e');
      return null;
    }
  }

  /// 从路径加载图像文件
  Future<Uint8List?> loadImageFromPath(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      debugPrint('Error loading image: $e');
      return null;
    }
  }

  /// 获取临时目录
  Future<Directory> getTemporaryDirectory() async {
    return await getTemporaryDirectory();
  }

  /// 判断文件是否存在
  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }
}

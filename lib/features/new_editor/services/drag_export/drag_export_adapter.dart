import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

enum ExportFormat { png, jpeg }

class DragExportAdapter {
  static final DragExportAdapter _instance = DragExportAdapter._internal();
  final logger = Logger();

  factory DragExportAdapter() {
    return _instance;
  }

  DragExportAdapter._internal();

  /// Platform is supported when the OS is macOS
  bool isPlatformSupported() {
    return Platform.isMacOS;
  }

  /// Starts a drag operation with the given image bytes
  Future<DragExportResult> startDrag({
    required Uint8List imageBytes,
    ExportFormat format = ExportFormat.png,
    int maxRetries = 3,
  }) async {
    if (!isPlatformSupported()) {
      logger.w('Platform not supported for drag export');
      return DragExportResult(
          success: false,
          errorMessage: 'Platform not supported for drag export');
    }

    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        logger.d('Starting drag export attempt ${retryCount + 1}');

        // Create temp file
        final tempFile = await _createTempFile(imageBytes, format);
        if (tempFile == null) {
          throw Exception('Failed to create temporary file');
        }

        logger.d('Temp file created at: ${tempFile.path}');

        // Start drag operation via platform channel
        final MethodChannel channel = MethodChannel('com.snipwise/drag_export');
        final bool result = await channel.invokeMethod('startDrag', {
          'filePath': tempFile.path,
        });

        logger.d('Drag operation result: $result');

        if (result) {
          _cleanupTempFile(tempFile);
          return DragExportResult(success: true);
        } else {
          _cleanupTempFile(tempFile);
          retryCount++;
          logger.w('Drag attempt ${retryCount} failed, retrying...');
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
          continue;
        }
      } catch (e, stackTrace) {
        logger.e('Error during drag operation: $e',
            error: e, stackTrace: stackTrace);
        retryCount++;
        if (retryCount >= maxRetries) {
          return DragExportResult(
              success: false,
              errorMessage:
                  'Failed after $maxRetries attempts: ${e.toString()}');
        }
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }

    return DragExportResult(
        success: false, errorMessage: 'Failed after $maxRetries attempts');
  }

  Future<File?> _createTempFile(
      Uint8List imageBytes, ExportFormat format) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final uuid = Uuid().v4();
      final extension = format == ExportFormat.png ? 'png' : 'jpg';
      final tempFile = File('${tempDir.path}/$uuid.$extension');

      // Write the image to file
      if (format == ExportFormat.jpeg) {
        // Convert to JPEG if needed
        final img.Image? image = img.decodeImage(imageBytes);
        if (image == null) {
          logger.e('Failed to decode image');
          return null;
        }
        final jpegData = img.encodeJpg(image, quality: 90);
        await tempFile.writeAsBytes(jpegData);
      } else {
        // Use PNG directly
        await tempFile.writeAsBytes(imageBytes);
      }

      return tempFile;
    } catch (e, stackTrace) {
      logger.e('Error creating temp file', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  void _cleanupTempFile(File file) {
    try {
      if (file.existsSync()) {
        file.deleteSync();
        logger.d('Temp file deleted: ${file.path}');
      }
    } catch (e) {
      logger.e('Error cleaning up temp file: $e');
    }
  }
}

class DragExportResult {
  final bool success;
  final String? errorMessage;

  DragExportResult({
    required this.success,
    this.errorMessage,
  });
}

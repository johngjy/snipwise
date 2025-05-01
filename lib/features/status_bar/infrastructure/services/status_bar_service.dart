import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

class StatusBarService {
  static final Logger _logger = Logger('StatusBarService');
  static const MethodChannel _channel =
      MethodChannel('com.snipwise.app/status_bar');

  /// Initializes the status bar menu
  Future<void> initialize() async {
    try {
      await _channel.invokeMethod('initializeStatusBar');
      _logger.info('Status bar initialized successfully');
    } catch (e) {
      _logger.severe('Failed to initialize status bar: $e');
      rethrow;
    }
  }

  /// Shows the status bar menu
  Future<void> showMenu() async {
    try {
      await _channel.invokeMethod('showStatusBarMenu');
      _logger.info('Status bar menu shown');
    } catch (e) {
      _logger.severe('Failed to show status bar menu: $e');
      rethrow;
    }
  }

  /// Hides the status bar menu
  Future<void> hideMenu() async {
    try {
      await _channel.invokeMethod('hideStatusBarMenu');
      _logger.info('Status bar menu hidden');
    } catch (e) {
      _logger.severe('Failed to hide status bar menu: $e');
      rethrow;
    }
  }

  /// Sets the status bar icon
  Future<void> setIcon(String iconPath) async {
    try {
      await _channel.invokeMethod('setStatusBarIcon', {'iconPath': iconPath});
      _logger.info('Status bar icon set to $iconPath');
    } catch (e) {
      _logger.severe('Failed to set status bar icon: $e');
      rethrow;
    }
  }

  /// Sets the status bar tooltip
  Future<void> setTooltip(String tooltip) async {
    try {
      await _channel.invokeMethod('setStatusBarTooltip', {'tooltip': tooltip});
      _logger.info('Status bar tooltip set to $tooltip');
    } catch (e) {
      _logger.severe('Failed to set status bar tooltip: $e');
      rethrow;
    }
  }

  /// Disposes the status bar
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod('disposeStatusBar');
      _logger.info('Status bar disposed');
    } catch (e) {
      _logger.severe('Failed to dispose status bar: $e');
      rethrow;
    }
  }
}

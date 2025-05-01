import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/services/status_bar_service.dart';

/// Provider for the StatusBarService
final statusBarServiceProvider = Provider<StatusBarService>((ref) {
  return StatusBarService();
});

/// Provider to initialize the status bar
final initializeStatusBarProvider = FutureProvider<void>((ref) async {
  final statusBarService = ref.read(statusBarServiceProvider);
  await statusBarService.initialize();
});

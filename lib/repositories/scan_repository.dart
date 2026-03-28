import 'dart:io';
import '../models/scan_result.dart';
import '../services/api_service.dart';

/// Scan Repository - Abstraction layer for scan operations

class ScanRepository {
  final ApiService _apiService;

  ScanRepository(this._apiService);

  /// Check if backend is healthy
  Future<bool> checkHealth() async {
    return await _apiService.checkHealth();
  }

  /// Scan an APK file
  Future<ScanResult> scanApkFile(
    File file, {
    Map<String, dynamic>? deviceInfo,
    void Function(int sent, int total)? onProgress,
    bool forceRescan = false,
  }) async {
    return await _apiService.scanApk(
      file,
      deviceInfo: deviceInfo,
      onProgress: onProgress,
      forceRescan: forceRescan,
    );
  }

  /// Clears server-side APK scan cache so the next upload is recomputed.
  Future<void> clearServerScanCache() async {
    await _apiService.clearServerScanCache();
  }

  /// Scan a Play Store app by package name or URL
  Future<ScanResult> scanPlayStoreApp(String input) async {
    // Determine if input is URL or package name
    if (_isPlayStoreUrl(input)) {
      return await _apiService.scanPlayStore(url: input);
    } else {
      return await _apiService.scanPlayStore(packageName: input);
    }
  }

  /// Check if input is a Play Store URL
  bool _isPlayStoreUrl(String input) {
    return input.contains('play.google.com');
  }

  /// Validate Play Store input
  static bool isValidInput(String input) {
    if (input.isEmpty) return false;

    // Check if it's a URL
    if (input.contains('play.google.com')) {
      return input.contains('id=') || input.contains('/details');
    }

    // Check if it's a valid package name (basic validation)
    // Package names should be like: com.example.app
    final packageRegex = RegExp(
      r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
    );
    return packageRegex.hasMatch(input);
  }
}

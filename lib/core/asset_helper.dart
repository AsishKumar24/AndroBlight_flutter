import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Asset Helper - Utilities for working with bundled assets

class AssetHelper {
  /// Copy a bundled asset to the app's temporary directory
  /// Returns the File object pointing to the copied file
  static Future<File> copyAssetToTemp(String assetPath, String fileName) async {
    // Get the temp directory
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    
    // Load asset data
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();
    
    // Write to temp file
    await tempFile.writeAsBytes(bytes);
    
    return tempFile;
  }
  
  /// Get the demo APK file
  static Future<File> getDemoApk() async {
    return await copyAssetToTemp('assets/demo.apk', 'demo.apk');
  }
}

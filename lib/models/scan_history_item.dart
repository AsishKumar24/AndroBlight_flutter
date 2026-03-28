import 'package:hive/hive.dart';

part 'scan_history_item.g.dart';

/// Scan History Item - Local Storage Model

@HiveType(typeId: 0)
class ScanHistoryItem extends HiveObject {
  @HiveField(0)
  final String scanType; // 'apk' or 'playstore'

  @HiveField(1)
  final String identifier; // file name or package/URL

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String label;

  @HiveField(4)
  final double confidence;

  @HiveField(5)
  final String? fileName; // For APK scans

  @HiveField(6)
  final int? fileSize; // For APK scans (in bytes)

  @HiveField(7)
  final bool verdictChanged; // True if background rescan changed the verdict

  ScanHistoryItem({
    required this.scanType,
    required this.identifier,
    required this.timestamp,
    required this.label,
    required this.confidence,
    this.fileName,
    this.fileSize,
    this.verdictChanged = false,
  });

  bool get isMalware => label.toLowerCase() == 'malware';
  bool get isBenign => label.toLowerCase() == 'benign';
  bool get isApkScan => scanType == 'apk';
  bool get isPlayStoreScan => scanType == 'playstore';

  /// Display name for the scan item
  String get displayName => fileName ?? identifier;

  /// Confidence as a percentage string (e.g., "87%")
  String get confidencePercent => '${(confidence * 100).round()}%';

  String get fileSizeFormatted {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024)
      return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

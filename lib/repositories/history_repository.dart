import '../models/scan_history_item.dart';
import '../models/scan_result.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// History Repository - Abstraction layer for scan history
/// Now supports cloud sync (merge local + remote records).

class HistoryRepository {
  final StorageService _storageService;
  final ApiService _apiService;

  /// Timestamp of last successful sync (ISO 8601)
  String? _lastSyncTimestamp;

  HistoryRepository(this._storageService, this._apiService);

  /// Get all scan history (local)
  List<ScanHistoryItem> getAllHistory() {
    return _storageService.getAllHistory();
  }

  /// Add APK scan result to history
  Future<void> addApkScanToHistory({
    required String fileName,
    required int fileSize,
    required ScanResult result,
  }) async {
    final item = ScanHistoryItem(
      scanType: 'apk',
      identifier: fileName,
      timestamp: DateTime.now(),
      label: result.label,
      confidence: result.confidence,
      fileName: fileName,
      fileSize: fileSize,
    );
    await _storageService.addToHistory(item);
  }

  /// Add Play Store scan result to history
  Future<void> addPlayStoreScanToHistory({
    required String identifier,
    required ScanResult result,
  }) async {
    final item = ScanHistoryItem(
      scanType: 'playstore',
      identifier: identifier,
      timestamp: DateTime.now(),
      label: result.label,
      confidence: result.confidence,
    );
    await _storageService.addToHistory(item);
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _storageService.clearHistory();
  }

  /// Delete specific item
  Future<void> deleteItem(ScanHistoryItem item) async {
    await _storageService.deleteHistoryItem(item);
  }

  /// Get history count
  int get historyCount => _storageService.historyCount;

  // ===========================================================================
  // Cloud Sync (Task 3.4)
  // ===========================================================================

  /// Sync local history with the cloud.
  /// 1. Push local records that the server may not have.
  /// 2. Pull remote records newer than the last sync timestamp.
  /// 3. Merge — avoid duplicates by checking identifiers + timestamps.
  ///
  /// Returns the number of new records pulled from the cloud.
  Future<SyncResult> syncWithCloud() async {
    if (!_apiService.isAuthenticated) {
      return SyncResult(pushed: 0, pulled: 0, error: 'Not authenticated');
    }

    int pushed = 0;
    int pulled = 0;

    try {
      // ── Step 1: Push local records to cloud ──
      final localItems = _storageService.getAllHistory();
      if (localItems.isNotEmpty) {
        final records = localItems.map((item) => {
          'scan_type': item.scanType,
          'identifier': item.identifier,
          'file_name': item.fileName,
          'file_size': item.fileSize,
          'label': item.label,
          'confidence': item.confidence,
          'file_hash': '${item.identifier}_${item.timestamp.millisecondsSinceEpoch}',
        }).toList();

        final pushResponse = await _apiService.pushSyncHistory(records);
        pushed = pushResponse['synced'] ?? 0;
      }

      // ── Step 2: Pull remote records ──
      final pullResponse = await _apiService.pullSyncHistory(
        since: _lastSyncTimestamp,
      );

      final remoteRecords = pullResponse['records'] as List<dynamic>? ?? [];

      // ── Step 3: Merge — add records we don't have locally ──
      final localIdentifiers = <String>{};
      for (final item in localItems) {
        localIdentifiers.add(
          '${item.identifier}_${item.scanType}',
        );
      }

      for (final record in remoteRecords) {
        final key = '${record['identifier']}_${record['scan_type']}';
        if (!localIdentifiers.contains(key)) {
          final newItem = ScanHistoryItem(
            scanType: record['scan_type'] ?? 'apk',
            identifier: record['identifier'] ?? 'unknown',
            timestamp: record['created_at'] != null
                ? DateTime.tryParse(record['created_at']) ?? DateTime.now()
                : DateTime.now(),
            label: record['label'] ?? 'Unknown',
            confidence: (record['confidence'] as num?)?.toDouble() ?? 0.0,
            fileName: record['file_name'],
            fileSize: record['file_size'],
          );
          await _storageService.addToHistory(newItem);
          pulled++;
        }
      }

      // Update sync timestamp
      _lastSyncTimestamp = pullResponse['sync_timestamp'] ??
          DateTime.now().toUtc().toIso8601String();

      return SyncResult(pushed: pushed, pulled: pulled);
    } catch (e) {
      return SyncResult(pushed: pushed, pulled: pulled, error: e.toString());
    }
  }
}

/// Result of a cloud sync operation
class SyncResult {
  final int pushed;
  final int pulled;
  final String? error;

  SyncResult({required this.pushed, required this.pulled, this.error});

  bool get hasError => error != null;
  bool get hasChanges => pushed > 0 || pulled > 0;
}

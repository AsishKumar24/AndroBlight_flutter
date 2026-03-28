import 'package:hive_flutter/hive_flutter.dart';
import '../models/scan_history_item.dart';

/// Storage Service - Hive Local Storage

class StorageService {
  static const String _historyBoxName = 'scan_history';
  late Box<ScanHistoryItem> _historyBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ScanHistoryItemAdapter());
    _historyBox = await Hive.openBox<ScanHistoryItem>(_historyBoxName);
  }

  /// Get all scan history items (newest first)
  List<ScanHistoryItem> getAllHistory() {
    final items = _historyBox.values.toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  /// Add a new scan to history
  Future<void> addToHistory(ScanHistoryItem item) async {
    await _historyBox.add(item);
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _historyBox.clear();
  }

  /// Delete a specific history item
  Future<void> deleteHistoryItem(ScanHistoryItem item) async {
    await item.delete();
  }

  /// Get history count
  int get historyCount => _historyBox.length;
}

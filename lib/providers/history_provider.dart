import 'package:flutter/foundation.dart';
import '../models/scan_history_item.dart';
import '../repositories/history_repository.dart';
import '../services/api_service.dart';

/// History Provider - Scan history state with search, filter, and sort support.
/// Implements tasks 3.6: searchQuery, selectedFilter, sortOrder, filteredHistory.

enum HistoryFilter { all, malware, benign, apk, playstore }

enum HistorySortOrder { newest, oldest, highestRisk }

class HistoryProvider extends ChangeNotifier {
  final HistoryRepository _historyRepository;
  final ApiService? _apiService;

  List<ScanHistoryItem> _history = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  int _pendingVerdictChanges = 0;

  // Search / Filter / Sort state (Task 3.6)
  String _searchQuery = '';
  HistoryFilter _selectedFilter = HistoryFilter.all;
  HistorySortOrder _sortOrder = HistorySortOrder.newest;

  // Sync feedback
  String? _syncMessage;
  bool? _syncSuccess;

  /// [apiService] is optional for backward-compat; needed for checkForUpdates().
  HistoryProvider(this._historyRepository, [this._apiService]);

  // ──── Getters ────
  List<ScanHistoryItem> get history => _history;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  bool get hasHistory => _history.isNotEmpty;
  int get historyCount => _history.length;
  int get pendingVerdictChanges => _pendingVerdictChanges;

  String get searchQuery => _searchQuery;
  HistoryFilter get selectedFilter => _selectedFilter;
  HistorySortOrder get sortOrder => _sortOrder;

  String? get syncMessage => _syncMessage;
  bool? get syncSuccess => _syncSuccess;

  /// Filtered + sorted history based on current search/filter/sort state
  List<ScanHistoryItem> get filteredHistory {
    List<ScanHistoryItem> result = List.from(_history);

    // 1. Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((item) {
        return item.displayName.toLowerCase().contains(query) ||
            item.identifier.toLowerCase().contains(query) ||
            (item.fileName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 2. Category filter
    switch (_selectedFilter) {
      case HistoryFilter.malware:
        result = result.where((item) => item.isMalware).toList();
        break;
      case HistoryFilter.benign:
        result = result.where((item) => item.isBenign).toList();
        break;
      case HistoryFilter.apk:
        result = result.where((item) => item.isApkScan).toList();
        break;
      case HistoryFilter.playstore:
        result = result.where((item) => item.isPlayStoreScan).toList();
        break;
      case HistoryFilter.all:
        break;
    }

    // 3. Sort
    switch (_sortOrder) {
      case HistorySortOrder.newest:
        result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case HistorySortOrder.oldest:
        result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case HistorySortOrder.highestRisk:
        // Malware first, then sort by confidence descending
        result.sort((a, b) {
          if (a.isMalware && !b.isMalware) return -1;
          if (!a.isMalware && b.isMalware) return 1;
          return b.confidence.compareTo(a.confidence);
        });
        break;
    }

    return result;
  }

  // ──── Setters ────

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(HistoryFilter filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSortOrder(HistorySortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedFilter = HistoryFilter.all;
    _sortOrder = HistorySortOrder.newest;
    notifyListeners();
  }

  void clearSyncMessage() {
    _syncMessage = null;
    _syncSuccess = null;
    notifyListeners();
  }

  // ──── Actions ────

  /// Load history from local storage
  void loadHistory() {
    _isLoading = true;
    notifyListeners();

    _history = _historyRepository.getAllHistory();
    _isLoading = false;
    notifyListeners();
  }

  /// Sync history with the cloud
  Future<void> syncWithCloud() async {
    _isSyncing = true;
    _syncMessage = null;
    _syncSuccess = null;
    notifyListeners();

    final result = await _historyRepository.syncWithCloud();

    if (result.hasError) {
      _syncMessage = result.error;
      _syncSuccess = false;
    } else if (result.hasChanges) {
      _syncMessage = 'Synced: ${result.pushed} pushed, ${result.pulled} pulled';
      _syncSuccess = true;
      // Reload local history to include newly pulled records
      _history = _historyRepository.getAllHistory();
    } else {
      _syncMessage = 'Already up to date';
      _syncSuccess = true;
    }

    _isSyncing = false;
    notifyListeners();
  }

  /// Clear all history
  Future<void> clearHistory() async {
    _isLoading = true;
    notifyListeners();

    await _historyRepository.clearHistory();
    _history = [];
    _isLoading = false;
    notifyListeners();
  }

  /// Delete specific item
  Future<void> deleteItem(ScanHistoryItem item) async {
    await _historyRepository.deleteItem(item);
    _history.remove(item);
    notifyListeners();
  }

  /// Refresh history
  void refresh() {
    loadHistory();
  }

  /// Poll /rescan/updates for verdict changes since [since].
  /// Updates local history items whose identifier matches a changed hash and
  /// increments [pendingVerdictChanges] for the badge in the UI.
  Future<void> checkForUpdates({String? since}) async {
    if (_apiService == null) return;

    try {
      final data = await _apiService.getRescanUpdates(since: since);
      final updates = data['updates'] as List<dynamic>? ?? [];
      if (updates.isEmpty) return;

      int changed = 0;
      for (final update in updates) {
        final identifier = update['identifier'] as String? ?? '';
        final newLabel = update['label'] as String? ?? '';
        if (identifier.isEmpty || newLabel.isEmpty) continue;

        for (var i = 0; i < _history.length; i++) {
          if (_history[i].identifier == identifier &&
              _history[i].label != newLabel) {
            // Replace with an updated copy flagging the verdict change
            final updated = ScanHistoryItem(
              scanType: _history[i].scanType,
              identifier: _history[i].identifier,
              timestamp: _history[i].timestamp,
              label: newLabel,
              confidence: _history[i].confidence,
              fileName: _history[i].fileName,
              fileSize: _history[i].fileSize,
              verdictChanged: true,
            );
            _history[i] = updated;
            changed++;
          }
        }
      }

      if (changed > 0) {
        _pendingVerdictChanges += changed;
        notifyListeners();
      }
    } catch (_) {
      // Silent fail — updates are best-effort
    }
  }

  /// Clear the pending verdict-changes counter (call after user dismisses notification).
  void clearVerdictChanges() {
    _pendingVerdictChanges = 0;
    notifyListeners();
  }
}

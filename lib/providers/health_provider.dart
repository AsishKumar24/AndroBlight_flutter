import 'package:flutter/foundation.dart';
import '../repositories/scan_repository.dart';

/// Health Provider - Backend health check state

enum HealthStatus { initial, checking, online, offline }

class HealthProvider extends ChangeNotifier {
  final ScanRepository _scanRepository;
  
  HealthStatus _status = HealthStatus.initial;
  String? _errorMessage;

  HealthProvider(this._scanRepository);

  HealthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _status == HealthStatus.online;
  bool get isChecking => _status == HealthStatus.checking;

  /// Check backend health - always tries real backend first
  /// Returns true if backend is online, false otherwise
  Future<bool> checkHealth() async {
    _status = HealthStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      final isHealthy = await _scanRepository.checkHealth();
      _status = isHealthy ? HealthStatus.online : HealthStatus.offline;
      if (!isHealthy) {
        _errorMessage = 'Backend offline - using demo mode';
      }
      notifyListeners();
      return isHealthy;
    } catch (e) {
      _status = HealthStatus.offline;
      _errorMessage = 'Backend offline - using demo mode';
      notifyListeners();
      return false;
    }
  }

  /// Reset to initial state
  void reset() {
    _status = HealthStatus.initial;
    _errorMessage = null;
    notifyListeners();
  }
}

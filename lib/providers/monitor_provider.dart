import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Monitor Provider
/// Manages state for the Installed App Monitoring feature (4D).

enum MonitorStatus { initial, loading, loaded, error }

class AppRiskResult {
  final String packageName;
  final String riskLevel;
  final String reason;
  final bool verified;

  const AppRiskResult({
    required this.packageName,
    required this.riskLevel,
    required this.reason,
    required this.verified,
  });

  factory AppRiskResult.fromJson(Map<String, dynamic> json) => AppRiskResult(
    packageName: json['package_name'] as String? ?? '',
    riskLevel: json['risk_level'] as String? ?? 'unknown',
    reason: json['reason'] as String? ?? '',
    verified: json['verified'] as bool? ?? false,
  );

  bool get isCritical => riskLevel == 'critical';
  bool get isHigh => riskLevel == 'high';
  bool get isLow => riskLevel == 'low';
}

class MonitorSummary {
  final int critical;
  final int high;
  final int low;
  final int unknown;

  const MonitorSummary({
    this.critical = 0,
    this.high = 0,
    this.low = 0,
    this.unknown = 0,
  });

  factory MonitorSummary.fromJson(Map<String, dynamic> json) => MonitorSummary(
    critical: json['critical'] as int? ?? 0,
    high: json['high'] as int? ?? 0,
    low: json['low'] as int? ?? 0,
    unknown: json['unknown'] as int? ?? 0,
  );

  int get totalRisky => critical + high;
}

class MonitorProvider extends ChangeNotifier {
  final ApiService _apiService;

  MonitorStatus _status = MonitorStatus.initial;
  List<AppRiskResult> _results = [];
  MonitorSummary? _summary;
  String? _errorMessage;

  MonitorProvider(this._apiService);

  MonitorStatus get status => _status;
  List<AppRiskResult> get results => _results;
  MonitorSummary? get summary => _summary;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == MonitorStatus.loading;
  bool get hasResults => _status == MonitorStatus.loaded;

  /// Submit list of installed package names for risk assessment
  Future<void> checkInstalledApps(List<String> packages) async {
    if (packages.isEmpty) return;

    _status = MonitorStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _apiService.checkInstalledApps(packages);
      _results = (data['results'] as List)
          .map((e) => AppRiskResult.fromJson(e as Map<String, dynamic>))
          .toList();
      _summary = data['summary'] != null
          ? MonitorSummary.fromJson(data['summary'] as Map<String, dynamic>)
          : null;
      _status = MonitorStatus.loaded;
    } catch (e) {
      _status = MonitorStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  void reset() {
    _status = MonitorStatus.initial;
    _results = [];
    _summary = null;
    _errorMessage = null;
    notifyListeners();
  }
}

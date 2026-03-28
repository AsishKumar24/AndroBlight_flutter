import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/scan_result.dart';
import '../repositories/scan_repository.dart';
import '../repositories/history_repository.dart';
import '../services/device_security_service.dart';

/// Scan Provider - APK and Play Store scan state
/// Now supports dynamic backend connectivity detection

enum ScanStatus { initial, scanning, success, error }

class ScanProvider extends ChangeNotifier {
  final ScanRepository _scanRepository;
  final HistoryRepository _historyRepository;
  final DeviceSecurityService _deviceSecurityService = DeviceSecurityService();

  ScanStatus _status = ScanStatus.initial;
  ScanResult? _result;
  String? _errorMessage;
  double _uploadProgress = 0.0;
  bool _isBackendOnline = false; // Track backend status

  // Device security state (4A)
  DeviceSecurityInfo? _deviceSecurity;
  bool _deviceSecurityChecked = false;

  // Current scan info
  String? _currentFileName;
  int? _currentFileSize;
  String? _currentPlayStoreInput;

  ScanProvider(this._scanRepository, this._historyRepository);

  // Getters
  ScanStatus get status => _status;
  ScanResult? get result => _result;
  String? get errorMessage => _errorMessage;
  double get uploadProgress => _uploadProgress;
  bool get isScanning => _status == ScanStatus.scanning;
  bool get hasResult => _status == ScanStatus.success && _result != null;
  bool get hasError => _status == ScanStatus.error;
  bool get isBackendOnline => _isBackendOnline;
  bool get isUsingDemoMode => !_isBackendOnline;

  // Device security getters (4A)
  DeviceSecurityInfo? get deviceSecurity => _deviceSecurity;
  bool get isDeviceRooted => _deviceSecurity?.isRooted ?? false;
  bool get deviceSecurityChecked => _deviceSecurityChecked;

  /// Explicit message for the loading overlay based on current mode
  String get scanningMessage {
    if (!_isBackendOnline) return 'Demo Mode: Simulating Deep Analysis...';
    if (_uploadProgress < 0.1) return 'Connecting to Security Cluster...';
    if (_uploadProgress < 0.9)
      return 'Uploading APK for Extraction (${(_uploadProgress * 100).round()}%)...';
    return 'Server Analysis: Extracting Manifest & Permissions...';
  }

  String? get currentFileName => _currentFileName;
  int? get currentFileSize => _currentFileSize;
  String? get currentPlayStoreInput => _currentPlayStoreInput;

  /// Update backend status (called from HealthProvider)
  void setBackendStatus(bool isOnline) {
    if (_isBackendOnline != isOnline) {
      _isBackendOnline = isOnline;
      notifyListeners();
    }
  }

  /// Check device root/security status (4A)
  Future<void> checkDeviceSecurity() async {
    if (_deviceSecurityChecked) return;
    _deviceSecurity = await _deviceSecurityService.checkDeviceSecurity();
    _deviceSecurityChecked = true;
    notifyListeners();
  }

  /// Generate mock scan result for demo mode
  ScanResult _generateMockResult({String? fileName, int? fileSize}) {
    final random = Random();
    final isMalware = random.nextBool();
    final confidence = 0.75 + (random.nextDouble() * 0.20); // 75-95%
    final riskScore = isMalware
        ? random.nextInt(40) +
              10 // 10-50 for malware
        : random.nextInt(25) + 70; // 70-95 for benign

    final name = fileName ?? 'whatsapp_v2.23.apk';
    final size = fileSize ?? 45240576;
    final sha =
        '5a2e${random.nextInt(1000000).toString().padLeft(6, '0')}f...fake...';

    return ScanResult(
      label: isMalware ? 'Malware' : 'Benign',
      confidence: confidence,
      overallScore: riskScore,
      threatLevel: isMalware ? 'high' : 'low',
      recommendations: isMalware
          ? [
              '⚠️ Do not install this application',
              '🚨 Potential SMS stealer activity',
              '🔒 Review sensitive permissions',
            ]
          : [
              '✅ This application appears safe to use',
              '🛡️ Certificate signed by trusted developer',
            ],
      metadata: ApkMetadata(
        fileName: name,
        fileSize: size,
        fileSizeReadable: '${(size / (1024 * 1024)).toStringAsFixed(1)} MB',
        sha256: sha,
        scanTimestamp: DateTime.now().toIso8601String(),
        packageName: 'com.android.sample.${random.nextInt(100)}',
        versionName: '1.2.0',
      ),
      permissionAnalysis: PermissionAnalysis(
        totalCount: random.nextInt(12) + 8,
        riskScore: isMalware ? random.nextInt(50) + 50 : random.nextInt(30),
        critical: isMalware
            ? [
                PermissionInfo(
                  permission: 'android.permission.READ_SMS',
                  description: 'Can read all your text messages',
                  risk: 'Extremely High',
                ),
                PermissionInfo(
                  permission: 'android.permission.RECEIVE_SMS',
                  description: 'Can intercept incoming messages',
                  risk: 'High',
                ),
              ]
            : [],
        high: [
          PermissionInfo(
            permission: 'android.permission.CAMERA',
            description: 'Can take photos and record videos',
            risk: 'High',
          ),
        ],
        medium: [
          PermissionInfo(
            permission: 'android.permission.INTERNET',
            description: 'Full network access',
            risk: 'Medium',
          ),
        ],
        suspiciousCombos: isMalware
            ? [
                SuspiciousCombo(
                  threat: 'SMS Exfiltration',
                  description:
                      'COMBINATION: READ_SMS + INTERNET allowing data theft',
                  permissions: ['READ_SMS', 'INTERNET'],
                ),
              ]
            : [],
      ),
      malwareFamily: isMalware
          ? MalwareFamily(
              family: 'Trojan',
              description:
                  'Hidden malicious code inside legitimate-looking app',
            )
          : null,
      certificate: CertificateInfo(
        signed: true,
        debugSigned: isMalware,
        fingerprint: 'SHA256: ${sha.substring(0, 16)}...',
      ),
    );
  }

  /// Scan an APK file
  /// [isSample] forces demo mode behavior for testing
  Future<void> scanApkFile(File file, {bool isSample = false}) async {
    _status = ScanStatus.scanning;
    _result = null;
    _errorMessage = null;
    _uploadProgress = 0.0;
    _currentFileName = file.path.split(Platform.pathSeparator).last;
    _currentFileSize = await file.length();
    notifyListeners();

    try {
      ScanResult result;

      if (!_isBackendOnline || isSample) {
        // Demo mode or forced sample
        for (int i = 0; i <= 100; i += 10) {
          await Future.delayed(const Duration(milliseconds: 100));
          _uploadProgress = i / 100;
          notifyListeners();
        }
        await Future.delayed(const Duration(milliseconds: 300));
        result = _generateMockResult(
          fileName: isSample ? 'sample_malware.apk' : _currentFileName,
          fileSize: isSample ? 15728640 : _currentFileSize,
        );
      } else {
        // Production mode - real API
        result = await _scanRepository.scanApkFile(
          file,
          deviceInfo: _deviceSecurity?.toMap(),
          onProgress: (sent, total) {
            _uploadProgress = sent / total;
            notifyListeners();
          },
        );
      }

      _result = result;
      _status = ScanStatus.success;
      notifyListeners();

      // Persist history — must not fail the scan or block navigation
      try {
        await _historyRepository.addApkScanToHistory(
          fileName: _currentFileName!,
          fileSize: _currentFileSize!,
          result: result,
        );
      } catch (e, st) {
        debugPrint('addApkScanToHistory failed: $e\n$st');
      }

      notifyListeners();
    } catch (e) {
      _status = ScanStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Scan a Play Store app
  Future<void> scanPlayStoreApp(String input) async {
    _status = ScanStatus.scanning;
    _result = null;
    _errorMessage = null;
    _currentPlayStoreInput = input;
    notifyListeners();

    try {
      ScanResult result;

      if (!_isBackendOnline) {
        // Demo mode
        await Future.delayed(const Duration(seconds: 2));
        result = _generateMockResult(fileName: input);
      } else {
        // Production mode
        result = await _scanRepository.scanPlayStoreApp(input);
      }

      _result = result;
      _status = ScanStatus.success;
      notifyListeners();

      try {
        await _historyRepository.addPlayStoreScanToHistory(
          identifier: input,
          result: result,
        );
      } catch (e, st) {
        debugPrint('addPlayStoreScanToHistory failed: $e\n$st');
      }

      notifyListeners();
    } catch (e) {
      _status = ScanStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Validate Play Store input
  bool isValidPlayStoreInput(String input) {
    return ScanRepository.isValidInput(input);
  }

  /// Reset state
  void reset() {
    _status = ScanStatus.initial;
    _result = null;
    _errorMessage = null;
    _uploadProgress = 0.0;
    _currentFileName = null;
    _currentFileSize = null;
    _currentPlayStoreInput = null;
    notifyListeners();
  }
}

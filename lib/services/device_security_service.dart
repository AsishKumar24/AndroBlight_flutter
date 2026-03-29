import 'package:flutter/services.dart';

/// Device Security Service
/// Detects root/jailbreak status on Android via a MethodChannel
/// to native Kotlin code.

class DeviceSecurityService {
  static const _channel = MethodChannel(
    'com.androblight.andro_blight/device_security',
  );

  /// Returns a map with root detection results.
  /// Falls back gracefully on non-Android platforms (web, desktop).
  Future<DeviceSecurityInfo> checkDeviceSecurity() async {
    try {
      final result = await _channel.invokeMethod<Map>('checkRootStatus');
      if (result == null) return DeviceSecurityInfo.unknown();

      return DeviceSecurityInfo(
        isRooted: result['is_rooted'] == true,
        deviceModel: result['device_model'] as String? ?? '',
        androidVersion: result['android_version'] as String? ?? '',
        rootIndicators: List<String>.from(
          result['root_indicators'] as List? ?? [],
        ),
      );
    } on MissingPluginException {
      // Running on a non-Android platform (web, desktop, iOS) — no root by definition
      return DeviceSecurityInfo.notApplicable();
    } on PlatformException {
      return DeviceSecurityInfo.unknown();
    }
  }

  /// Opens Settings → allow installing apps from this app (Android 8+).
  Future<void> openInstallPermissionSettings() async {
    try {
      await _channel.invokeMethod<void>('openInstallPermissionSettings');
    } on MissingPluginException {
      return;
    }
  }

  /// Starts the system installer for [apkPath]. Android only; requires
  /// [REQUEST_INSTALL_PACKAGES] and "install unknown apps" for this package.
  Future<InstallApkResult> installApk(String apkPath) async {
    try {
      await _channel.invokeMethod<bool>('installApk', {'path': apkPath});
      return InstallApkResult.success();
    } on MissingPluginException {
      return InstallApkResult.unsupported();
    } on PlatformException catch (e) {
      if (e.code == 'INSTALL_PERMISSION_REQUIRED') {
        return InstallApkResult.needsPermission(e.message);
      }
      if (e.code == 'NOT_FOUND') {
        return InstallApkResult.notFound(e.message);
      }
      return InstallApkResult.failed(e.message);
    }
  }
}

/// Outcome of [DeviceSecurityService.installApk].
class InstallApkResult {
  final bool ok;
  final bool needsInstallPermission;
  final bool unsupported;
  final String? message;

  const InstallApkResult._({
    required this.ok,
    this.needsInstallPermission = false,
    this.unsupported = false,
    this.message,
  });

  factory InstallApkResult.success() =>
      const InstallApkResult._(ok: true);

  factory InstallApkResult.unsupported() =>
      const InstallApkResult._(ok: false, unsupported: true);

  factory InstallApkResult.needsPermission(String? message) => InstallApkResult._(
        ok: false,
        needsInstallPermission: true,
        message: message,
      );

  factory InstallApkResult.notFound(String? message) => InstallApkResult._(
        ok: false,
        message: message ?? 'File not found',
      );

  factory InstallApkResult.failed(String? message) => InstallApkResult._(
        ok: false,
        message: message,
      );
}

class DeviceSecurityInfo {
  final bool isRooted;
  final bool isUnknown;
  final bool isNotApplicable;
  final String deviceModel;
  final String androidVersion;
  final List<String> rootIndicators;

  const DeviceSecurityInfo({
    required this.isRooted,
    this.isUnknown = false,
    this.isNotApplicable = false,
    this.deviceModel = '',
    this.androidVersion = '',
    this.rootIndicators = const [],
  });

  factory DeviceSecurityInfo.unknown() =>
      const DeviceSecurityInfo(isRooted: false, isUnknown: true);

  factory DeviceSecurityInfo.notApplicable() =>
      const DeviceSecurityInfo(isRooted: false, isNotApplicable: true);

  Map<String, dynamic> toMap() => {
    'is_rooted': isRooted,
    'device_model': deviceModel,
    'android_version': androidVersion,
  };

  String get statusLabel {
    if (isNotApplicable) return 'N/A';
    if (isUnknown) return 'Unknown';
    return isRooted ? 'Rooted' : 'Secure';
  }
}

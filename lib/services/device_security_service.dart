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

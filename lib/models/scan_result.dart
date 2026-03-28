/// Scan Result Model - Enhanced API Response
/// Handles the comprehensive response from the enhanced backend

/// Backend may send booleans as `true`/`false`, `0`/`1`, or numeric/string forms.
bool? _parseJsonBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is num) return value != 0;
  if (value is String) {
    final s = value.toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
  }
  return null;
}

bool _parseJsonBoolOrFalse(dynamic value) => _parseJsonBool(value) ?? false;

Map<String, dynamic>? _parseJsonMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

class ScanResult {
  final String label;
  final double confidence;
  final int? overallScore;
  final String? threatLevel;
  final List<String>? recommendations;
  final PermissionAnalysis? permissionAnalysis;
  final MalwareFamily? malwareFamily;
  final CertificateInfo? certificate;
  final ApkMetadata? metadata;
  final List<EngineResult>? multiEngineResults;

  ScanResult({
    required this.label,
    required this.confidence,
    this.overallScore,
    this.threatLevel,
    this.recommendations,
    this.permissionAnalysis,
    this.malwareFamily,
    this.certificate,
    this.metadata,
    this.multiEngineResults,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    // Handle both simple and enhanced response formats
    String label;
    double confidence;

    final mlMap = _parseJsonMap(json['ml_detection']);
    if (mlMap != null) {
      label = mlMap['label'] as String? ?? 'Unknown';
      confidence = (mlMap['confidence'] as num? ?? 0.0).toDouble();
    } else {
      label = json['label'] as String? ?? 'Unknown';
      confidence = (json['confidence'] as num? ?? 0.0).toDouble();
    }

    MalwareFamily? malwareFamily;
    final mf = mlMap != null ? mlMap['malware_family'] : null;
    final mfMap = _parseJsonMap(mf);
    if (mfMap != null) {
      malwareFamily = MalwareFamily.fromJson(mfMap);
    }

    List<EngineResult>? multiEngineResults;
    final mer = json['multi_engine_results'];
    if (mer is List) {
      multiEngineResults = mer
          .map<EngineResult?>((e) {
            final m = _parseJsonMap(e);
            return m == null ? null : EngineResult.fromJson(m);
          })
          .whereType<EngineResult>()
          .toList();
    }

    return ScanResult(
      label: label,
      confidence: confidence,
      overallScore: (json['overall_score'] as num?)?.toInt(),
      threatLevel: json['threat_level'] as String?,
      recommendations: json['recommendations'] != null
          ? (json['recommendations'] as List).map((e) => e.toString()).toList()
          : (json['recommendation'] != null
                ? (json['recommendation'] as List)
                      .map((e) => e.toString())
                      .toList()
                : null),
      permissionAnalysis: _parseJsonMap(json['permission_analysis']) != null
          ? PermissionAnalysis.fromJson(_parseJsonMap(json['permission_analysis'])!)
          : null,
      malwareFamily: malwareFamily,
      certificate: _parseJsonMap(json['certificate']) != null
          ? CertificateInfo.fromJson(_parseJsonMap(json['certificate'])!)
          : null,
      metadata: _parseJsonMap(json['metadata']) != null
          ? ApkMetadata.fromJson(_parseJsonMap(json['metadata'])!)
          : null,
      multiEngineResults: multiEngineResults,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'confidence': confidence,
      'overall_score': overallScore,
      'threat_level': threatLevel,
      'recommendations': recommendations,
      'metadata': metadata,
    };
  }

  bool get isMalware =>
      label.toLowerCase() == 'malware' ||
      label.toLowerCase() == 'suspicious';
  bool get isBenign =>
      label.toLowerCase() == 'benign' ||
      label.toLowerCase() == 'likely safe';

  int get confidencePercent => (confidence * 100).round();

  // Risk level based on overall score (0-100, where 100 is safest)
  // Thresholds aligned with backend (app_enhanced.py:767-774)
  String get riskLevel {
    if (overallScore == null) return threatLevel ?? 'unknown';
    if (overallScore! >= 70) return 'low';
    if (overallScore! >= 50) return 'medium';
    if (overallScore! >= 30) return 'high';
    return 'critical';
  }
}

/// APK / Play Store Metadata from enhanced backend
class ApkMetadata {
  final String? fileName;
  final String? sha256;
  final String? md5;
  final int? fileSize;
  final String? fileSizeReadable;
  final String? scanTimestamp;
  final String? mainActivity;
  final String? packageName;
  final String? versionName;

  // Play Store-specific fields
  final String? appName;
  final String? developer;
  final int? installs;
  final double? rating;
  final int? ratingCount;
  final String? iconUrl;
  final String? genre;
  final String? contentRating;
  final String? playStoreUrl;
  final bool? containsAds;
  final bool? inAppPurchases;

  ApkMetadata({
    this.fileName,
    this.sha256,
    this.md5,
    this.fileSize,
    this.fileSizeReadable,
    this.scanTimestamp,
    this.mainActivity,
    this.packageName,
    this.versionName,
    // Play Store
    this.appName,
    this.developer,
    this.installs,
    this.rating,
    this.ratingCount,
    this.iconUrl,
    this.genre,
    this.contentRating,
    this.playStoreUrl,
    this.containsAds,
    this.inAppPurchases,
  });

  factory ApkMetadata.fromJson(Map<String, dynamic> json) {
    return ApkMetadata(
      fileName: json['file_name'] as String?,
      sha256: json['sha256'] as String?,
      md5: json['md5'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      fileSizeReadable: json['file_size_readable'] as String?,
      scanTimestamp: json['scan_timestamp'] as String?,
      mainActivity: json['main_activity'] as String?,
      packageName: json['package_name'] as String?,
      versionName: json['version_name'] as String?,

      // Play Store
      appName: json['app_name'] as String?,
      developer: json['developer'] as String?,
      installs: (json['installs'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: (json['rating_count'] as num?)?.toInt(),
      iconUrl: json['icon_url'] as String?,
      genre: json['genre'] as String?,
      contentRating: json['content_rating'] as String?,
      playStoreUrl: json['play_store_url'] as String?,

      containsAds: _parseJsonBool(json['contains_ads']),
      inAppPurchases: _parseJsonBool(json['in_app_purchases']),
    );
  }

  /// Human-readable install count (e.g. "10M+", "500K+")
  String get installsFormatted {
    if (installs == null) return 'N/A';
    if (installs! >= 1000000000) return '${(installs! / 1000000000).toStringAsFixed(1)}B+';
    if (installs! >= 1000000) return '${(installs! / 1000000).toStringAsFixed(0)}M+';
    if (installs! >= 1000) return '${(installs! / 1000).toStringAsFixed(0)}K+';
    return '$installs+';
  }
}

/// Permission Analysis from enhanced backend
class PermissionAnalysis {
  final int totalCount;
  final int riskScore;
  final List<PermissionInfo> critical;
  final List<PermissionInfo> high;
  final List<PermissionInfo> medium;
  final List<SuspiciousCombo> suspiciousCombos;

  PermissionAnalysis({
    required this.totalCount,
    required this.riskScore,
    required this.critical,
    required this.high,
    required this.medium,
    required this.suspiciousCombos,
  });

  factory PermissionAnalysis.fromJson(Map<String, dynamic> json) {
    List<PermissionInfo> mapPermList(dynamic v) {
      if (v is! List) return [];
      return v
          .map((e) {
            final m = _parseJsonMap(e);
            return m == null ? null : PermissionInfo.fromJson(m);
          })
          .whereType<PermissionInfo>()
          .toList();
    }

    List<SuspiciousCombo> mapComboList(dynamic v) {
      if (v is! List) return [];
      return v
          .map((e) {
            final m = _parseJsonMap(e);
            return m == null ? null : SuspiciousCombo.fromJson(m);
          })
          .whereType<SuspiciousCombo>()
          .toList();
    }

    return PermissionAnalysis(
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      riskScore: (json['risk_score'] as num?)?.toInt() ?? 0,
      critical: mapPermList(json['critical']),
      high: mapPermList(json['high']),
      medium: mapPermList(json['medium']),
      suspiciousCombos: mapComboList(json['suspicious_combos']),
    );
  }

  int get dangerousCount => critical.length + high.length;
}

class PermissionInfo {
  final String permission;
  final String description;
  final String risk;

  PermissionInfo({
    required this.permission,
    required this.description,
    required this.risk,
  });

  factory PermissionInfo.fromJson(Map<String, dynamic> json) {
    return PermissionInfo(
      permission: json['permission'] as String? ?? '',
      description: json['description'] as String? ?? '',
      risk: json['risk'] as String? ?? '',
    );
  }
}

class SuspiciousCombo {
  final String threat;
  final String description;
  final List<String>? permissions;

  SuspiciousCombo({
    required this.threat,
    required this.description,
    this.permissions,
  });

  factory SuspiciousCombo.fromJson(Map<String, dynamic> json) {
    return SuspiciousCombo(
      threat: json['threat'] as String? ?? '',
      description: json['description'] as String? ?? '',
      permissions: (json['permissions'] as List?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}

class MalwareFamily {
  final String family;
  final String description;

  MalwareFamily({required this.family, required this.description});

  factory MalwareFamily.fromJson(Map<String, dynamic> json) {
    return MalwareFamily(
      family: json['family'] as String? ?? 'unknown',
      description: json['description'] as String? ?? '',
    );
  }
}

class CertificateInfo {
  final bool signed;
  final bool debugSigned;
  final String? fingerprint;

  CertificateInfo({
    required this.signed,
    required this.debugSigned,
    this.fingerprint,
  });

  factory CertificateInfo.fromJson(Map<String, dynamic> json) {
    return CertificateInfo(
      signed: _parseJsonBoolOrFalse(json['signed']),
      debugSigned: _parseJsonBoolOrFalse(json['debug_signed']),
      fingerprint: json['fingerprint_sha256'] as String?,
    );
  }
}

/// Multi-engine AV result (4C — Hybrid Analysis, MetaDefender, VirusTotal)
class EngineResult {
  final String engine;
  final bool found;
  final bool malicious;
  final String? verdict;
  final String? detectionRatio;
  final String? error;

  EngineResult({
    required this.engine,
    required this.found,
    required this.malicious,
    this.verdict,
    this.detectionRatio,
    this.error,
  });

  factory EngineResult.fromJson(Map<String, dynamic> json) {
    return EngineResult(
      engine: json['engine'] as String? ?? 'Unknown',
      found: _parseJsonBoolOrFalse(json['found']),
      malicious: _parseJsonBoolOrFalse(json['malicious']),
      verdict: json['verdict'] as String?,
      detectionRatio: json['detection_ratio'] as String?,
      error: json['error'] as String?,
    );
  }
}

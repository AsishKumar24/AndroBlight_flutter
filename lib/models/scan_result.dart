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

double _parseJsonDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is bool) return value ? 1.0 : 0.0;
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int? _parseJsonInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is bool) return value ? 1 : 0;
  if (value is String) return int.tryParse(value);
  return null;
}

List<String>? _parseRecommendationsList(Map<String, dynamic> json) {
  final recs = json['recommendations'];
  if (recs is List) {
    return recs.map((e) => e.toString()).toList();
  }
  final rec = json['recommendation'];
  if (rec is List) {
    return rec.map((e) => e.toString()).toList();
  }
  if (rec is String) {
    return [rec];
  }
  return null;
}

/// Parse [multi_engine_results] without failing the whole [ScanResult] on one bad row.
List<EngineResult>? _parseMultiEngineResultsList(dynamic mer) {
  if (mer is! List) return null;
  final out = <EngineResult>[];
  for (final e in mer) {
    final m = _parseJsonMap(e);
    if (m == null) continue;
    try {
      out.add(EngineResult.fromJson(m));
    } catch (_) {
      // Skip malformed engine entries (Dio may decode nested maps loosely).
    }
  }
  return out.isEmpty ? null : out;
}

/// Single row from backend [final_verdict.reasons].
class VerdictReason {
  final String code;
  final String label;
  final String detail;

  VerdictReason({
    required this.code,
    required this.label,
    required this.detail,
  });

  factory VerdictReason.fromJson(Map<String, dynamic> json) {
    return VerdictReason(
      code: json['code'] as String? ?? '',
      label: json['label'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
    );
  }
}

/// Primary AI signal from backend ([ml_risk_score] = normalized 0–100 before weighting).
class MlSignal {
  final String label;
  final double confidence;
  final String role;
  final String? note;
  /// Backend-normalized model predicted risk 0–100 (Malware/Suspicious/Benign mapping).
  final double? mlRiskScore;

  MlSignal({
    required this.label,
    required this.confidence,
    required this.role,
    this.note,
    this.mlRiskScore,
  });

  factory MlSignal.fromJson(Map<String, dynamic> json) {
    final raw = json['ml_risk_score'];
    return MlSignal(
      label: json['label'] as String? ?? 'Unknown',
      confidence: _parseJsonDouble(json['confidence']),
      role: json['role'] as String? ?? 'primary',
      note: json['note'] as String?,
      mlRiskScore: raw == null ? null : _parseJsonDouble(raw),
    );
  }

  int get confidencePercent => (confidence * 100).round();
}

/// Centralized aggregation from the backend (permissions, externals, rules, ML advisory).
class FinalVerdict {
  final String level;
  final int riskScore;
  final int safetyScore;
  final List<VerdictReason> reasons;
  final MlSignal mlSignal;

  FinalVerdict({
    required this.level,
    required this.riskScore,
    required this.safetyScore,
    required this.reasons,
    required this.mlSignal,
  });

  factory FinalVerdict.fromJson(Map<String, dynamic> json) {
    final raw = json['reasons'];
    final reasons = <VerdictReason>[];
    if (raw is List) {
      for (final e in raw) {
        final m = _parseJsonMap(e);
        if (m != null) {
          reasons.add(VerdictReason.fromJson(m));
        }
      }
    }
    final ms = _parseJsonMap(json['ml_signal']);
    return FinalVerdict(
      level: (json['level'] as String? ?? 'low').toLowerCase(),
      riskScore: _parseJsonInt(json['risk_score']) ?? 0,
      safetyScore: _parseJsonInt(json['safety_score']) ?? 0,
      reasons: reasons,
      mlSignal: ms != null
          ? MlSignal.fromJson(ms)
          : MlSignal(label: 'Unknown', confidence: 0, role: 'primary'),
    );
  }
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
  /// Raw `virustotal` object from API (fallback if [multiEngineResults] is empty).
  final Map<String, dynamic>? virustotalRaw;
  /// Backend: one-line combined verdict (ML + permissions + threat tier).
  final String? verdictSummary;
  /// Backend: which external engines are configured (`enabled` vs `not_configured`).
  final Map<String, String>? scannerStatus;
  /// Aggregated verdict (risk/safety, reasons, advisory ML). Prefer over raw [label].
  final FinalVerdict? finalVerdict;

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
    this.virustotalRaw,
    this.verdictSummary,
    this.scannerStatus,
    this.finalVerdict,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    // Handle both simple and enhanced response formats
    String label;
    double confidence;

    final mlMap = _parseJsonMap(json['ml_detection']);
    if (mlMap != null) {
      label = mlMap['label'] as String? ?? 'Unknown';
      confidence = _parseJsonDouble(mlMap['confidence']);
    } else {
      label = json['label'] as String? ?? 'Unknown';
      confidence = _parseJsonDouble(json['confidence']);
    }

    MalwareFamily? malwareFamily;
    final mf = mlMap != null ? mlMap['malware_family'] : null;
    final mfMap = _parseJsonMap(mf);
    if (mfMap != null) {
      malwareFamily = MalwareFamily.fromJson(mfMap);
    }

    final multiEngineResults = _parseMultiEngineResultsList(
      json['multi_engine_results'] ?? json['multiEngineResults'],
    );
    final virustotalRaw = _parseJsonMap(json['virustotal']);

    Map<String, String>? scannerStatus;
    final ss = json['scanner_status'];
    if (ss is Map) {
      scannerStatus = {
        for (final e in ss.entries)
          e.key.toString(): e.value.toString(),
      };
    }

    FinalVerdict? finalVerdict;
    final fvMap = _parseJsonMap(json['final_verdict']);
    if (fvMap != null) {
      try {
        finalVerdict = FinalVerdict.fromJson(fvMap);
      } catch (_) {
        finalVerdict = null;
      }
    }

    return ScanResult(
      label: label,
      confidence: confidence,
      overallScore: _parseJsonInt(json['overall_score']),
      threatLevel: json['threat_level'] as String?,
      recommendations: _parseRecommendationsList(json),
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
      virustotalRaw: virustotalRaw,
      verdictSummary: json['verdict_summary'] as String?,
      scannerStatus: scannerStatus,
      finalVerdict: finalVerdict,
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

  /// Rows for the Multi-engine UI: list from API, else a single row built from `virustotal`.
  List<EngineResult> get enginesForDisplay {
    if (multiEngineResults != null && multiEngineResults!.isNotEmpty) {
      return multiEngineResults!;
    }
    final vt = virustotalRaw;
    if (vt != null) {
      try {
        return [EngineResult.fromJson(vt)];
      } catch (_) {}
    }
    return [];
  }

  /// Effective tier: [finalVerdict] from API, else [threatLevel] / score bands.
  String get effectiveThreatLevel {
    final fv = finalVerdict?.level.toLowerCase().trim();
    if (fv != null &&
        fv.isNotEmpty &&
        const {'low', 'medium', 'high', 'critical'}.contains(fv)) {
      return fv;
    }
    return riskLevel;
  }

  /// Hero title: **final aggregated verdict** — never the raw ML label alone.
  String get displayHeadline {
    final tl = effectiveThreatLevel;
    switch (tl) {
      case 'critical':
        return 'CRITICAL RISK';
      case 'high':
        return 'HIGH RISK';
      case 'medium':
        return 'ELEVATED RISK';
      case 'low':
        return 'LOW RISK';
      default:
        return 'UNKNOWN RISK';
    }
  }

  /// Under hero: primary AI line (final tier still reflects weighted + overrides).
  String? get displayHeadlineSubtitle {
    if (finalVerdict != null) {
      final ms = finalVerdict!.mlSignal;
      final mrs = ms.mlRiskScore;
      if (mrs != null) {
        return 'Model predicted risk: ${mrs.round()}/100 · ${ms.label} (${ms.confidencePercent}% model confidence) · combined with supporting signals';
      }
      return 'AI: ${ms.label} (${ms.confidencePercent}% model confidence)';
    }
    final tl = effectiveThreatLevel;
    if (tl == 'unknown') return null;
    return 'AI: ${label.toUpperCase()} (${confidencePercent}% confidence)';
  }

  /// Prefer backend `threat_level` (merged). Fallback to score bands.
  String get riskLevel {
    final tl = threatLevel?.toLowerCase().trim();
    if (tl != null &&
        tl.isNotEmpty &&
        const {'low', 'medium', 'high', 'critical'}.contains(tl)) {
      return tl;
    }
    if (overallScore == null) return 'unknown';
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
  final List<PermissionInfo> low;
  final List<PermissionInfo> unknown;
  final List<SuspiciousCombo> suspiciousCombos;

  PermissionAnalysis({
    required this.totalCount,
    required this.riskScore,
    required this.critical,
    required this.high,
    required this.medium,
    required this.low,
    required this.unknown,
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
      low: mapPermList(json['low']),
      unknown: mapPermList(json['unknown']),
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
      permission: json['permission']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      risk: json['risk']?.toString() ?? '',
    );
  }
}

class SuspiciousCombo {
  final String threat;
  final String description;
  final List<String>? permissions;
  /// True when this row comes from a user-defined [ThreatRule] on the server.
  final bool customRule;
  final String? ruleName;

  SuspiciousCombo({
    required this.threat,
    required this.description,
    this.permissions,
    this.customRule = false,
    this.ruleName,
  });

  factory SuspiciousCombo.fromJson(Map<String, dynamic> json) {
    return SuspiciousCombo(
      threat: json['threat'] as String? ?? '',
      description: json['description'] as String? ?? '',
      permissions: (json['permissions'] as List?)
          ?.map((e) => e.toString())
          .toList(),
      customRule: _parseJsonBool(json['custom_rule']) ?? false,
      ruleName: json['rule_name'] as String?,
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
    final dr = json['detection_ratio'];
    final eng = json['engine'];
    return EngineResult(
      engine: eng == null ? 'Unknown' : eng.toString(),
      found: _parseJsonBoolOrFalse(json['found']),
      malicious: _parseJsonBoolOrFalse(json['malicious']),
      verdict: json['verdict']?.toString(),
      detectionRatio: dr == null ? null : dr.toString(),
      error: json['error']?.toString(),
    );
  }
}

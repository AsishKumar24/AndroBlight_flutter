import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/scan_result.dart';
import '../services/device_security_service.dart';
import 'home_screen.dart';

/// Result — scan analysis (lavender page, brand app bar, soft cards).

class ResultScreen extends StatelessWidget {
  final ScanResult result;
  final String scanType;
  final String identifier;

  /// Local path to the scanned APK (APK flow only). Used to open the system installer
  /// when the model verdict is benign.
  final String? apkLocalPath;

  const ResultScreen({
    super.key,
    required this.result,
    required this.scanType,
    required this.identifier,
    this.apkLocalPath,
  });

  String? _resolvePlayPackage() {
    final p = result.metadata?.packageName?.trim();
    if (p != null && p.isNotEmpty) return p;
    final re = RegExp(r'[?&]id=([^&]+)');
    final m = re.firstMatch(identifier);
    return m?.group(1);
  }

  List<Widget> _benignInstallActions(BuildContext context, Responsive r) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return [];
    }
    if (!result.isBenign) return [];

    if (scanType == 'APK Scan' &&
        apkLocalPath != null &&
        apkLocalPath!.isNotEmpty) {
      return [
        _buildSectionHeader(context, r, 'Install', Icons.install_mobile_rounded),
        Text(
          'If you trust this file, you can install it. A benign scan is not a guarantee of safety.',
          style: TextStyle(
            fontSize: r.sp(12),
            color: AppTheme.textSecondary,
            height: 1.35,
          ),
        ),
        SizedBox(height: r.spacingMD),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleInstallApk(context),
            icon: const Icon(Icons.install_mobile_rounded),
            label: const Text('Install this APK'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: r.spacingMD + 2),
              backgroundColor: AppTheme.benignGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        SizedBox(height: r.spacingLG),
      ];
    }

    if (scanType == 'Play Store') {
      final pkg = _resolvePlayPackage();
      if (pkg == null || pkg.isEmpty) return [];
      return [
        _buildSectionHeader(context, r, 'Get app', Icons.shopping_bag_rounded),
        Text(
          'Open Google Play to install or update this app.',
          style: TextStyle(
            fontSize: r.sp(12),
            color: AppTheme.textSecondary,
            height: 1.35,
          ),
        ),
        SizedBox(height: r.spacingMD),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleOpenPlayInstall(context, pkg),
            icon: const Icon(Icons.shopping_bag_rounded),
            label: const Text('Open in Play Store'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: r.spacingMD + 2),
              backgroundColor: AppTheme.brand,
              foregroundColor: AppTheme.onBrand,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        SizedBox(height: r.spacingLG),
      ];
    }

    return [];
  }

  Future<void> _handleInstallApk(BuildContext context) async {
    final path = apkLocalPath;
    if (path == null || path.isEmpty) return;
    final svc = DeviceSecurityService();
    final installResult = await svc.installApk(path);
    if (!context.mounted) return;
    if (installResult.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening system installer…')),
      );
      return;
    }
    if (installResult.needsInstallPermission) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Allow installs'),
          content: const Text(
            'Android needs permission for AndroBlight to install APKs. '
            'Open Settings, allow installation from this app, then try again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (go == true && context.mounted) {
        await svc.openInstallPermissionSettings();
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          installResult.message ?? 'Could not start install',
        ),
      ),
    );
  }

  Future<void> _handleOpenPlayInstall(
    BuildContext context,
    String packageName,
  ) async {
    final market = Uri.parse('market://details?id=$packageName');
    final https = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );
    try {
      if (await canLaunchUrl(market)) {
        await launchUrl(market, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(https)) {
        await launchUrl(https, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Play Store')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  /// Icon + color per line — backend sends emojis; avoid one green check for every row.
  (IconData, Color) _recommendationVisual(String rec) {
    final lower = rec.toLowerCase();
    if (rec.contains('🚨') ||
        rec.contains('🔴') ||
        lower.contains('do not install') ||
        lower.contains('high risk —')) {
      return (Icons.gpp_bad_rounded, AppTheme.malwareRed);
    }
    if (rec.contains('🧪') || lower.contains('ml model classified')) {
      return (Icons.biotech_rounded, AppTheme.warningAmber);
    }
    if (rec.contains('✅') || lower.contains('lower risk')) {
      return (Icons.check_circle_rounded, AppTheme.benignGreen);
    }
    if (lower.contains('elevated risk') || lower.contains('review all permissions')) {
      return (Icons.warning_amber_rounded, AppTheme.warningAmber);
    }
    return (Icons.chevron_right_rounded, AppTheme.textSecondary);
  }

  /// Hero foregrounds the **ML model** (not the combined tier).
  IconData _mlHeroIcon(ScanResult r) {
    final l = r.label.toLowerCase();
    if (l == 'malware') return Icons.psychology_rounded;
    if (l == 'suspicious') return Icons.warning_amber_rounded;
    return Icons.smart_toy_rounded;
  }

  Color _mlHeroAccent(ScanResult r) {
    final l = r.label.toLowerCase();
    if (l == 'malware') return const Color(0xFFFFB4B4);
    if (l == 'suspicious') return const Color(0xFFFFE082);
    return const Color(0xFFC8F7C5);
  }

  String _mlHeroTitle(ScanResult r) => r.label.toUpperCase();

  String _mlHeroSubtitle(ScanResult r) {
    final ms = r.finalVerdict?.mlSignal;
    final parts = <String>['${r.confidencePercent}% model confidence'];
    if (ms?.mlRiskScore != null) {
      parts.add('Model predicted risk ${ms!.mlRiskScore!.round()}/100');
    }
    return parts.join(' · ');
  }

  // Final combined tier / safety / risk line (hidden — model is the showcase).
  // String _combinedAssessmentLine(ScanResult r) {
  //   final safety = r.overallScore ?? (r.isMalware ? 15 : 95);
  //   final risk = r.finalVerdict?.riskScore ?? _fallbackRiskScore(r);
  //   return '${r.displayHeadline} · Safety $safety/100 · Combined risk $risk/100';
  // }

  bool _isMlRecommendation(String rec) {
    final lower = rec.toLowerCase();
    return lower.contains('ml model') ||
        lower.contains('model classified') ||
        lower.contains('heuristic') ||
        lower.contains('image model') ||
        lower.contains('🧪') ||
        rec.contains('🧪') ||
        lower.contains('ai risk assessment') ||
        lower.contains('your model');
  }

  /// Same messaging as the model — no permission/tier lines that weaken the ML story.
  List<String> _modelOnlyGuidanceLines() {
    final out = <String>[
      '${result.label} — ${result.confidencePercent}% confidence (model output).',
    ];
    final mrs = result.finalVerdict?.mlSignal.mlRiskScore;
    if (mrs != null) {
      out.add('Model predicted risk: ${mrs.round()}/100');
    }
    _appendCustomThreatRuleGuidance(out);
    if (result.recommendations != null) {
      for (final rec in result.recommendations!) {
        if (_isMlRecommendation(rec)) {
          out.add(rec);
        }
      }
    }
    return out;
  }

  /// Custom rules from [final_verdict.reasons] or [permission_analysis.suspicious_combos].
  void _appendCustomThreatRuleGuidance(List<String> out) {
    final fv = result.finalVerdict;
    final fromReasons = fv?.reasons
            .where((r) => r.code == 'CUSTOM_RULE')
            .toList() ??
        [];
    if (fromReasons.isNotEmpty) {
      for (final vr in fromReasons) {
        out.add(
          '🚨 ${vr.label}: ${vr.detail} '
          'You should not install this app based on your custom rule.',
        );
      }
      return;
    }
    final pa = result.permissionAnalysis;
    if (pa == null) return;
    for (final c in pa.suspiciousCombos) {
      if (!c.customRule) continue;
      final name = (c.ruleName != null && c.ruleName!.trim().isNotEmpty)
          ? c.ruleName!.trim()
          : 'Custom rule';
      final detail = c.description.isNotEmpty ? c.description : c.threat;
      out.add(
        '🚨 Threat rule "$name" matched: $detail. '
        'You should not install this app based on your custom rule.',
      );
    }
  }

  List<Widget> _buildRecommendationSections(BuildContext context, Responsive r) {
    final lines = _modelOnlyGuidanceLines();
    return [
      _buildSectionHeader(
          context, r, 'Combined guidance', Icons.psychology_rounded),
      _buildRecommendationListCard(context, r, lines),
      SizedBox(height: r.spacingLG),
    ];
  }

  Widget _buildRecommendationListCard(
    BuildContext context,
    Responsive r,
    List<String> recs,
  ) {
    return Container(
      padding: EdgeInsets.all(r.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.r20(context)),
        border: Border.all(color: AppTheme.brand.withAlpha(28)),
        boxShadow: UiShadows.card(blur: 16, y: 6),
      ),
      child: Column(
        children: recs
            .map(
              (rec) {
                final vis = _recommendationVisual(rec);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(vis.$1, size: 20, color: vis.$2),
                      SizedBox(width: r.spacingSM),
                      Expanded(
                        child: Text(
                          rec,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: r.sp(13),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
            .toList(),
      ),
    );
  }

  void _shareResult() {
    final text =
        'AndroBlight Scan Report\n'
        'File: ${result.metadata?.fileName ?? identifier}\n'
        'ML model: ${result.label} (${result.confidencePercent}% confidence)\n'
        // 'Combined: $tl · Safety ${result.overallScore?.toString() ?? "—"}/100 · Risk ${result.finalVerdict?.riskScore ?? _fallbackRiskScore(result)}/100\n'
        'Scan result powered by AndroBlight Security Engine.';
    SharePlus.instance.share(ShareParams(text: text));
  }

  void _downloadReport() async {
    final sha = result.metadata?.sha256;
    if (sha == null) return;

    final url = Uri.parse('${ApiConfig.baseUrl}/report/$sha');

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8F7FF),
                  AppTheme.pageBackground,
                ],
              ),
            ),
          ),
          Positioned(
            bottom: AppScale.verticalScale(context, 80),
            right: -AppScale.scale(context, 60),
            child: IgnorePointer(
              child: Container(
                width: AppScale.scale(context, 200),
                height: AppScale.scale(context, 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.brand.withAlpha(14),
                ),
              ),
            ),
          ),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 268,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.brand,
                foregroundColor: AppTheme.onBrand,
                iconTheme: const IconThemeData(color: AppTheme.onBrand),
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    onPressed: _shareResult,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.brand,
                          AppTheme.brandDark,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'ML MODEL',
                              style: TextStyle(
                                fontSize: r.sp(11),
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onBrand.withAlpha(200),
                                letterSpacing: 2.2,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: _mlHeroAccent(result).withAlpha(46),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.onBrand.withAlpha(90),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _mlHeroIcon(result),
                                size: 56,
                                color: AppTheme.onBrand,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              scanType,
                              style: TextStyle(
                                fontSize: r.sp(12),
                                fontWeight: FontWeight.w600,
                                color: AppTheme.onBrand.withAlpha(220),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _mlHeroTitle(result),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: r.sp(28),
                                fontWeight: FontWeight.w900,
                                color: AppTheme.onBrand,
                                letterSpacing: 1.0,
                                height: 1.05,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                _mlHeroSubtitle(result),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: r.sp(13),
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                  color: AppTheme.onBrand.withAlpha(245),
                                ),
                              ),
                            ),
                            // Final tier / safety / combined risk (hidden — model-first UI).
                            // const SizedBox(height: 10),
                            // Padding(
                            //   padding:
                            //       const EdgeInsets.symmetric(horizontal: 14),
                            //   child: Text(
                            //     _combinedAssessmentLine(result),
                            //     textAlign: TextAlign.center,
                            //     style: TextStyle(
                            //       fontSize: r.sp(10),
                            //       fontWeight: FontWeight.w600,
                            //       height: 1.35,
                            //       color: AppTheme.onBrand.withAlpha(200),
                            //       letterSpacing: 0.15,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.spacingMD,
                    r.spacingMD,
                    r.spacingMD,
                    r.spacingXL,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Model confidence',
                              '${result.confidencePercent}%',
                              AppTheme.brand,
                              r,
                              subtitle: 'ML output',
                            ),
                          ),
                          SizedBox(width: r.spacingMD),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Model Predicted risk',
                              result.finalVerdict?.mlSignal.mlRiskScore != null
                                  ? '${result.finalVerdict!.mlSignal.mlRiskScore!.round()}/100'
                                  : '—',
                              _mlHeroAccent(result),
                              r,
                              subtitle: 'From your ML model',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: r.spacingSM),
                      _buildScoreBreakdownTrigger(context, r),

                      // Safety / combined risk stats (commented — model stats above are the focus).
                      // SizedBox(height: r.spacingMD),
                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: _buildStatCard(
                      //         context,
                      //         'Safety score',
                      //         '${result.overallScore ?? (result.isMalware ? 15 : 95)}/100',
                      //         AppTheme.brand,
                      //         r,
                      //         subtitle: 'Combined assessment',
                      //       ),
                      //     ),
                      //     SizedBox(width: r.spacingMD),
                      //     Expanded(
                      //       child: _buildStatCard(
                      //         context,
                      //         'Combined risk',
                      //         '${result.finalVerdict?.riskScore ?? _fallbackRiskScore(result)}/100',
                      //         riskColor,
                      //         r,
                      //         subtitle: 'ML + supporting signals',
                      //       ),
                      //     ),
                      //   ],
                      // ),

                      // if (_supportingReasons(result).isNotEmpty) ...[
                      //   SizedBox(height: r.spacingMD),
                      //   _buildSupportingSignalsCard(
                      //       context, r, _supportingReasons(result)),
                      // ],

                      // if (result.verdictSummary != null &&
                      //     result.verdictSummary!.trim().isNotEmpty) ...[
                      //   SizedBox(height: r.spacingMD),
                      //   _buildVerdictSummaryCard(context, r, result.verdictSummary!),
                      // ],

                      if (result.scannerStatus != null &&
                          result.scannerStatus!.isNotEmpty) ...[
                        SizedBox(height: r.spacingMD),
                        _buildScannerStatusChips(context, r, result.scannerStatus!),
                      ],

                      SizedBox(height: r.spacingLG),

                      if (result.malwareFamily != null) ...[
                        _buildSectionHeader(context, r, 'Threat analysis',
                            Icons.biotech_rounded),
                        _buildAnalysisCard(
                          context: context,
                          title: 'Category: ${result.malwareFamily!.family}',
                          content: result.malwareFamily!.description,
                          color: AppTheme.malwareRed,
                          r: r,
                        ),
                        SizedBox(height: r.spacingLG),
                      ],

                      ..._buildRecommendationSections(context, r),

                      if (result.enginesForDisplay.isNotEmpty) ...[
                        _buildSectionHeader(context, r, 'Multi-engine verdicts',
                            Icons.shield_rounded),
                        _buildMultiEngineSection(
                            result.enginesForDisplay, r, context),
                        SizedBox(height: r.spacingLG),
                      ],

                      if (result.permissionAnalysis != null) ...[
                        _buildSectionHeader(context, r, 'Permission analysis',
                            Icons.lock_rounded),
                        _buildPermissionSummary(
                            result.permissionAnalysis!, r, context),
                        SizedBox(height: r.spacingLG),
                      ],

                      _buildSectionHeader(
                          context, r, 'Technical metadata', Icons.info_rounded),
                      _buildMetadataTable(result, r, context),

                      SizedBox(height: r.spacingLG + 8),

                      ..._benignInstallActions(context, r),

                      if (result.metadata?.sha256 != null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _downloadReport,
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Download PDF report'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: r.spacingMD,
                                horizontal: r.spacingMD,
                              ),
                              foregroundColor: AppTheme.brand,
                              side: const BorderSide(
                                  color: AppTheme.brand, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),

                      if (result.metadata?.sha256 != null)
                        SizedBox(height: r.spacingMD),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
                            (_) => false,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: r.spacingMD + 2,
                            ),
                            backgroundColor: AppTheme.brand,
                            foregroundColor: AppTheme.onBrand,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Back to home',
                            style: TextStyle(
                              fontSize: r.sp(16),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    Color color,
    Responsive r, {
    String? subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(r.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.r20(context)),
        border: Border.all(color: color.withAlpha(45)),
        boxShadow: UiShadows.card(blur: 18, y: 8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: r.sp(11),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: r.spacingSM),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: r.sp(22),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            SizedBox(height: r.spacingXS),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: r.sp(9),
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    Responsive r,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: r.spacingSM),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.brand.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppTheme.brand),
          ),
          SizedBox(width: r.spacingSM),
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: r.sp(17),
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard({
    required BuildContext context,
    required String title,
    required String content,
    required Color color,
    required Responsive r,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.spacingMD),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(AppRadius.r20(context)),
        border: Border.all(color: color.withAlpha(72)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: r.sp(15),
            ),
          ),
          SizedBox(height: r.spacingXS),
          Text(
            content,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: r.sp(13),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerStatusChips(
    BuildContext context,
    Responsive r,
    Map<String, String> status,
  ) {
    String labelFor(String k) {
      switch (k) {
        case 'virustotal':
          return 'VirusTotal';
        case 'hybrid_analysis':
          return 'Hybrid Analysis';
        case 'metadefender':
          return 'MetaDefender';
        default:
          return k;
      }
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: status.entries.map((e) {
        final on = e.value == 'enabled';
        return Chip(
          avatar: Icon(
            on ? Icons.link_rounded : Icons.link_off_rounded,
            size: 16,
            color: on ? AppTheme.benignGreen : AppTheme.textMuted,
          ),
          label: Text(
            '${labelFor(e.key)}: ${on ? 'linked' : 'not configured'}',
            style: TextStyle(
              fontSize: r.sp(11),
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          backgroundColor: AppTheme.surfaceLight,
          side: BorderSide(color: AppTheme.brand.withAlpha(24)),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionSummary(
    PermissionAnalysis analysis,
    Responsive r,
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.all(r.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.r20(context)),
        border: Border.all(color: AppTheme.brand.withAlpha(24)),
        boxShadow: UiShadows.card(blur: 14, y: 6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: r.spacingSM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
                SizedBox(width: r.spacingSM),
                Expanded(
                  child: Text(
                    'Custom rules apply when the server analyzes this APK. '
                    'If you added or changed rules after this scan, run Scan APK '
                    'again and enable Cache & rescan so patterns update.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: r.sp(11),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildPermissionRow(
            'Total permissions',
            analysis.totalCount.toString(),
            AppTheme.textSecondary,
            r,
          ),
          _buildPermissionRow(
            'Critical risk',
            analysis.critical.length.toString(),
            AppTheme.malwareRed,
            r,
          ),
          _buildPermissionRow(
            'High risk',
            analysis.high.length.toString(),
            AppTheme.warningAmber,
            r,
          ),
          _buildPermissionRow(
            'Unreviewed / unknown',
            analysis.unknown.length.toString(),
            AppTheme.textMuted,
            r,
          ),
          if (analysis.suspiciousCombos.isNotEmpty) ...[
            Divider(
              color: AppTheme.textMuted.withAlpha(40),
              height: 24,
            ),
            ...analysis.suspiciousCombos.map(
              (combo) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: AppTheme.warningAmber,
                    ),
                    SizedBox(width: r.spacingSM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pattern: ${combo.threat}',
                            style: TextStyle(
                              color: AppTheme.warningAmber,
                              fontSize: r.sp(12),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (combo.description.isNotEmpty)
                            Text(
                              combo.description,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: r.sp(11),
                                height: 1.35,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (analysis.critical.isNotEmpty ||
              analysis.high.isNotEmpty ||
              analysis.medium.isNotEmpty ||
              analysis.low.isNotEmpty ||
              analysis.unknown.isNotEmpty) ...[
            Divider(
              color: AppTheme.textMuted.withAlpha(40),
              height: 28,
            ),
            Text(
              'Details',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: r.sp(11),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            SizedBox(height: r.spacingSM),
            _buildPermissionTierExpansion(
              context,
              r,
              'Critical',
              analysis.critical,
              AppTheme.malwareRed,
              0,
            ),
            _buildPermissionTierExpansion(
              context,
              r,
              'High',
              analysis.high,
              AppTheme.warningAmber,
              1,
            ),
            _buildPermissionTierExpansion(
              context,
              r,
              'Medium',
              analysis.medium,
              AppTheme.textSecondary,
              2,
            ),
            _buildPermissionTierExpansion(
              context,
              r,
              'Low',
              analysis.low,
              AppTheme.textMuted,
              3,
            ),
            _buildPermissionTierExpansion(
              context,
              r,
              'Unknown / not in catalog',
              analysis.unknown,
              AppTheme.textMuted,
              4,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionTierExpansion(
    BuildContext context,
    Responsive r,
    String title,
    List<PermissionInfo> items,
    Color accent,
    int tierIndex,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
        key: ValueKey<int>(tierIndex),
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.only(bottom: r.spacingSM),
        initiallyExpanded: title == 'Critical' && items.length <= 6,
        title: Row(
          children: [
            Icon(Icons.label_important_outline, size: 18, color: accent),
            SizedBox(width: r.spacingSM),
            Text(
              '$title (${items.length})',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: r.sp(13),
              ),
            ),
          ],
        ),
        children: items
            .map(
              (p) => Padding(
                padding: EdgeInsets.only(bottom: r.spacingMD),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        p.permission,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: r.sp(12),
                        ),
                      ),
                      if (p.description.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          p.description,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: r.sp(12),
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (p.risk.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Text(
                          p.risk,
                          style: TextStyle(
                            color: accent,
                            fontSize: r.sp(11),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
            .toList(),
    );
  }

  Widget _buildPermissionRow(
    String label,
    String value,
    Color valueColor,
    Responsive r,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: r.sp(12),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w800,
              fontSize: r.sp(14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataTable(
    ScanResult result,
    Responsive r,
    BuildContext context,
  ) {
    final meta = result.metadata;
    final isPlayStore = meta?.appName != null || meta?.developer != null;

    return Container(
      padding: EdgeInsets.all(r.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.r20(context)),
        border: Border.all(color: AppTheme.brand.withAlpha(24)),
        boxShadow: UiShadows.card(blur: 14, y: 6),
      ),
      child: Column(
        children: [
          if (isPlayStore) ...[
            if (meta?.appName != null)
              _buildMetaRow('App name', meta!.appName!),
            if (meta?.developer != null)
              _buildMetaRow('Developer', meta!.developer!),
            if (meta?.installs != null)
              _buildMetaRow('Installs', meta!.installsFormatted),
            if (meta?.rating != null)
              _buildMetaRow(
                'Rating',
                '${meta!.rating!.toStringAsFixed(1)} ★'
                '${meta.ratingCount != null ? " (${meta.ratingCount})" : ""}',
              ),
            if (meta?.genre != null) _buildMetaRow('Category', meta!.genre!),
            if (meta?.contentRating != null)
              _buildMetaRow('Content', meta!.contentRating!),
            if (meta?.containsAds != null)
              _buildMetaRow(
                'Contains ads',
                meta!.containsAds! ? 'Yes' : 'No',
                color: meta.containsAds!
                    ? AppTheme.warningAmber
                    : AppTheme.benignGreen,
              ),
            Divider(
              color: AppTheme.textMuted.withAlpha(40),
              height: 20,
            ),
          ],
          _buildMetaRow('Package', meta?.packageName ?? identifier),
          _buildMetaRow('Version', meta?.versionName ?? 'N/A'),
          if (!isPlayStore)
            _buildMetaRow('File name', meta?.fileName ?? identifier),
          if (!isPlayStore)
            _buildMetaRow('Size', meta?.fileSizeReadable ?? 'N/A'),
          _buildMetaRow(
            'SHA256',
            (meta?.sha256 != null && meta!.sha256!.length > 12)
                ? '${meta.sha256!.substring(0, 12)}...'
                : meta?.sha256 ?? 'N/A',
          ),
          if (result.certificate != null)
            _buildMetaRow(
              'Signed',
              result.certificate!.signed ? 'Yes (trusted)' : 'No',
              color: result.certificate!.signed
                  ? AppTheme.benignGreen
                  : AppTheme.malwareRed,
            ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(
    String label,
    String value, {
    Color color = AppTheme.textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiEngineSection(
    List<EngineResult> engines,
    Responsive r,
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.all(r.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.r20(context)),
        border: Border.all(color: AppTheme.brand.withAlpha(24)),
        boxShadow: UiShadows.card(blur: 14, y: 6),
      ),
      child: Column(
        children: engines.map((engine) {
          late Color statusColor;
          late String statusText;
          late IconData statusIcon;

          if (engine.error != null) {
            statusColor = AppTheme.textMuted;
            statusText = 'Error';
            statusIcon = Icons.error_outline_rounded;
          } else if (!engine.found) {
            statusColor = AppTheme.textMuted;
            statusText = 'Not found';
            statusIcon = Icons.search_off_rounded;
          } else if (engine.malicious) {
            statusColor = AppTheme.malwareRed;
            statusText = engine.detectionRatio ?? engine.verdict ?? 'Malicious';
            statusIcon = Icons.dangerous_outlined;
          } else {
            statusColor = AppTheme.benignGreen;
            statusText = engine.verdict ?? 'Clean';
            statusIcon = Icons.verified_rounded;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(statusIcon, size: 20, color: statusColor),
                SizedBox(width: r.spacingSM),
                Expanded(
                  child: Text(
                    engine.engine,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: r.sp(13),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: r.sp(12),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _openScoreBreakdownDashboard(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ScoreBreakdownSheet(result: result),
    );
  }

  Widget _buildScoreBreakdownTrigger(BuildContext context, Responsive r) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openScoreBreakdownDashboard(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: r.spacingMD,
            vertical: r.spacingSM + 4,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.brand.withAlpha(40)),
            boxShadow: UiShadows.card(blur: 10, y: 4),
          ),
          child: Row(
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                color: AppTheme.brand,
                size: r.sp(22),
              ),
              SizedBox(width: r.spacingSM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Score breakdown & how it differs',
                      style: TextStyle(
                        fontSize: r.sp(13),
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Tap for combined risk, safety, model vs supporting signals',
                      style: TextStyle(
                        fontSize: r.sp(10),
                        color: AppTheme.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashboard-style sheet: formula, model vs combined, delta, factors, user choice.
class _ScoreBreakdownSheet extends StatelessWidget {
  final ScanResult result;

  const _ScoreBreakdownSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final fv = result.finalVerdict;
    final model = fv?.mlSignal.mlRiskScore;
    final combined = fv?.riskScore;
    final safety = fv?.safetyScore ?? result.overallScore;
    int? delta;
    if (model != null && combined != null) {
      delta = combined - model.round();
    }

    final maxH = MediaQuery.of(context).size.height * 0.88;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: AppTheme.pageBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: maxH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: r.spacingSM),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withAlpha(90),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(r.spacingMD, 0, r.spacingSM, r.spacingSM),
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: AppTheme.brand, size: r.sp(24)),
                    SizedBox(width: r.spacingSM),
                    Expanded(
                      child: Text(
                        'Risk score dashboard',
                        style: TextStyle(
                          fontSize: r.sp(18),
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    r.spacingMD,
                    0,
                    r.spacingMD,
                    r.spacingLG + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fv == null)
                        Padding(
                          padding: EdgeInsets.only(bottom: r.spacingMD),
                          child: Text(
                            'Reconnect to the latest server scan to load full breakdown '
                            '(model vs combined scores). Showing model output from this result only.',
                            style: TextStyle(
                              fontSize: r.sp(12),
                              height: 1.4,
                              color: AppTheme.warningAmber,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Text(
                        'How scores are calculated',
                        style: TextStyle(
                          fontSize: r.sp(13),
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: r.spacingXS),
                      Text(
                        'Final combined risk on the server blends your ML output with supporting analysis: '
                        'approximately 40% × model predicted risk + 60% × supporting risk '
                        '(permissions, unknown permissions, external engines, custom rules, device context). '
                        'Strong external detections or other floors can still raise the risk tier.',
                        style: TextStyle(
                          fontSize: r.sp(12),
                          height: 1.45,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      SizedBox(height: r.spacingMD),
                      _ScoreDashTile(
                        r: r,
                        icon: Icons.smart_toy_outlined,
                        title: 'Model predicted risk',
                        value: model != null ? '${model.round()}/100' : '—',
                        caption:
                            'From your classifier label + confidence (normalized 0–100), before blending.',
                      ),
                      SizedBox(height: r.spacingSM),
                      _ScoreDashTile(
                        r: r,
                        icon: Icons.merge_type_rounded,
                        title: 'Combined risk',
                        value: combined != null ? '$combined/100' : '—',
                        caption: 'After blending with supporting signals.',
                      ),
                      SizedBox(height: r.spacingSM),
                      _ScoreDashTile(
                        r: r,
                        icon: Icons.shield_outlined,
                        title: 'Safety score',
                        value: safety != null ? '$safety/100' : '—',
                        caption: 'Higher = safer (derived from combined risk on the server).',
                      ),
                      if (delta != null) ...[
                        SizedBox(height: r.spacingMD),
                        Text(
                          'Difference vs model',
                          style: TextStyle(
                            fontSize: r.sp(13),
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: r.spacingXS),
                        Text(
                          'Combined risk − model predicted risk = ${delta >= 0 ? '+' : ''}$delta. '
                          'Positive means supporting signals raised risk above the model alone; '
                          'negative means they lowered it.',
                          style: TextStyle(
                            fontSize: r.sp(12),
                            height: 1.45,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      if (fv != null && fv.reasons.isNotEmpty) ...[
                        SizedBox(height: r.spacingMD),
                        Text(
                          'Supporting signal factors',
                          style: TextStyle(
                            fontSize: r.sp(13),
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: r.spacingXS),
                        ...fv.reasons
                            .where((x) =>
                                x.code != 'ML_PRIMARY' && x.code != 'AGGREGATE')
                            .take(12)
                            .map(
                              (row) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '• ${row.label}: ${row.detail}',
                                  style: TextStyle(
                                    fontSize: r.sp(11),
                                    height: 1.35,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                      ],
                      SizedBox(height: r.spacingMD),
                      Container(
                        padding: EdgeInsets.all(r.spacingMD),
                        decoration: BoxDecoration(
                          color: AppTheme.brand.withAlpha(26),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.brand.withAlpha(55)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: AppTheme.brand,
                              size: 22,
                            ),
                            SizedBox(width: r.spacingSM),
                            Expanded(
                              child: Text(
                                'What you trust is your choice. This panel explains how the app combines '
                                'the model with other signals; you may weight the model more—or lean on '
                                'permissions and external scans. The app does not make the install decision for you.',
                                style: TextStyle(
                                  fontSize: r.sp(12),
                                  height: 1.45,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreDashTile extends StatelessWidget {
  final Responsive r;
  final IconData icon;
  final String title;
  final String value;
  final String caption;

  const _ScoreDashTile({
    required this.r,
    required this.icon,
    required this.title,
    required this.value,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(r.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.r20(context)),
        border: Border.all(color: AppTheme.brand.withAlpha(28)),
        boxShadow: UiShadows.card(blur: 10, y: 4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.brand, size: r.sp(22)),
          SizedBox(width: r.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: r.sp(12),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMuted,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: r.sp(22),
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  caption,
                  style: TextStyle(
                    fontSize: r.sp(10),
                    height: 1.35,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

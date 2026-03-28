import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../models/scan_result.dart';
import 'home_screen.dart';

/// Result — scan analysis (lavender page, brand app bar, soft cards).

class ResultScreen extends StatelessWidget {
  final ScanResult result;
  final String scanType;
  final String identifier;

  const ResultScreen({
    super.key,
    required this.result,
    required this.scanType,
    required this.identifier,
  });

  Color _getRiskColor() {
    final level = result.riskLevel.toLowerCase();
    if (level == 'low') return AppTheme.benignGreen;
    if (level == 'medium') return AppTheme.warningAmber;
    if (level == 'high') return AppTheme.malwareRed;
    if (level == 'critical') return const Color(0xFFB91C1C);
    return result.isMalware ? AppTheme.malwareRed : AppTheme.benignGreen;
  }

  void _shareResult() {
    final text =
        'AndroBlight Scan Report\n'
        'File: ${result.metadata?.fileName ?? identifier}\n'
        'Label: ${result.label}\n'
        'Confidence: ${result.confidencePercent}%\n'
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
    final riskColor = _getRiskColor();

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
                expandedHeight: 220,
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
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.onBrand.withAlpha(35),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                result.isMalware
                                    ? Icons.security_update_warning_rounded
                                    : Icons.verified_rounded,
                                size: 52,
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
                              result.label.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: r.sp(26),
                                fontWeight: FontWeight.w800,
                                color: AppTheme.onBrand,
                                letterSpacing: 1.2,
                              ),
                            ),
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
                              'Safety score',
                              '${result.overallScore ?? (result.isMalware ? 15 : 95)}/100',
                              AppTheme.brand,
                              r,
                            ),
                          ),
                          SizedBox(width: r.spacingMD),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              'Confidence',
                              '${result.confidencePercent}%',
                              riskColor,
                              r,
                            ),
                          ),
                        ],
                      ),

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

                      if (result.recommendations != null &&
                          result.recommendations!.isNotEmpty) ...[
                        _buildSectionHeader(context, r, 'Recommendations',
                            Icons.tips_and_updates_rounded),
                        Container(
                          padding: EdgeInsets.all(r.spacingMD),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius:
                                BorderRadius.circular(AppRadius.r20(context)),
                            border: Border.all(
                              color: AppTheme.brand.withAlpha(28),
                            ),
                            boxShadow: UiShadows.card(blur: 16, y: 6),
                          ),
                          child: Column(
                            children: result.recommendations!
                                .map(
                                  (rec) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          size: 20,
                                          color: riskColor,
                                        ),
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
                                  ),
                                )
                                .toList(),
                          ),
                        ),
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

                      if (result.multiEngineResults != null &&
                          result.multiEngineResults!.isNotEmpty) ...[
                        SizedBox(height: r.spacingLG),
                        _buildSectionHeader(context, r, 'Multi-engine verdicts',
                            Icons.shield_rounded),
                        _buildMultiEngineSection(
                            result.multiEngineResults!, r, context),
                      ],

                      SizedBox(height: r.spacingLG + 8),

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
    Responsive r,
  ) {
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
        children: [
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
          if (analysis.suspiciousCombos.isNotEmpty) ...[
            Divider(
              color: AppTheme.textMuted.withAlpha(40),
              height: 24,
            ),
            ...analysis.suspiciousCombos.map(
              (combo) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: AppTheme.warningAmber,
                    ),
                    SizedBox(width: r.spacingSM),
                    Expanded(
                      child: Text(
                        'Suspicious: ${combo.threat}',
                        style: TextStyle(
                          color: AppTheme.warningAmber,
                          fontSize: r.sp(12),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
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
}

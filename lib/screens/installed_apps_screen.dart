import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/monitor_provider.dart';

/// Installed apps monitor — native package list → backend risk assessment.

class InstalledAppsScreen extends StatefulWidget {
  const InstalledAppsScreen({super.key});

  @override
  State<InstalledAppsScreen> createState() => _InstalledAppsScreenState();
}

class _InstalledAppsScreenState extends State<InstalledAppsScreen> {
  static const _appsChannel = MethodChannel(
    'com.androblight.andro_blight/device_security',
  );

  List<String>? _installedPackages;
  bool _loadingPackages = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    setState(() {
      _loadingPackages = true;
      _loadError = null;
    });

    try {
      final result = await _appsChannel.invokeMethod<List>(
        'getInstalledPackages',
      );
      setState(() {
        _installedPackages = result?.map((e) => e.toString()).toList() ?? [];
        _loadingPackages = false;
      });
    } on MissingPluginException {
      setState(() {
        _installedPackages = _demoPackages;
        _loadingPackages = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _loadError = e.message;
        _loadingPackages = false;
      });
    }
  }

  Future<void> _scanPackages() async {
    if (_installedPackages == null || _installedPackages!.isEmpty) return;
    await context.read<MonitorProvider>().checkInstalledApps(
          _installedPackages!,
        );
  }

  Widget _pageBackground(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8F7FF),
                AppTheme.primaryLight,
                AppTheme.pageBackground,
              ],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -AppScale.verticalScale(context, 40),
          right: -AppScale.scale(context, 30),
          child: _glowOrb(AppScale.scale(context, 200), AppTheme.brand.withAlpha(18)),
        ),
        Positioned(
          bottom: AppScale.verticalScale(context, 100),
          left: -AppScale.scale(context, 50),
          child: _glowOrb(AppScale.scale(context, 170), AppTheme.brandDark.withAlpha(14)),
        ),
      ],
    );
  }

  Widget _glowOrb(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.pageBackground,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Scan my phone',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: r.sp(18),
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _pageBackground(context),
          Positioned.fill(
            child: Consumer<MonitorProvider>(
              builder: (context, provider, _) {
                if (_loadingPackages) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.brand),
                        SizedBox(height: r.spacingMD),
                        Text(
                          'Reading installed apps…',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: r.sp(14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_loadError != null) {
                  return Center(
                    child: Padding(
                      padding: r.screenPadding,
                      child: Container(
                        padding: EdgeInsets.all(r.spacingLG),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(AppRadius.r20(context)),
                          border: Border.all(color: AppTheme.malwareRed.withAlpha(50)),
                          boxShadow: UiShadows.card(blur: 16, y: 8),
                        ),
                        child: Text(
                          _loadError!,
                          style: TextStyle(
                            color: AppTheme.malwareRed,
                            fontSize: r.sp(14),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }

                if (provider.status == MonitorStatus.loading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.brand),
                        SizedBox(height: r.spacingMD),
                        Text(
                          'Analysing installed apps…',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: r.sp(14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (provider.status == MonitorStatus.error) {
                  return Center(
                    child: Padding(
                      padding: r.screenPadding,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.malwareRed,
                            size: 52,
                          ),
                          SizedBox(height: r.spacingMD),
                          Text(
                            provider.errorMessage ?? 'Unknown error',
                            style: TextStyle(
                              color: AppTheme.malwareRed,
                              fontSize: r.sp(14),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: r.spacingLG),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _scanPackages,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brand,
                                foregroundColor: AppTheme.onBrand,
                                padding: EdgeInsets.symmetric(vertical: r.spacingMD),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Retry'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (provider.status == MonitorStatus.initial) {
                  return _buildInitialState(r);
                }

                return _buildResults(provider, r);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(Responsive r) {
    final count = _installedPackages?.length ?? 0;
    return SingleChildScrollView(
      padding: r.screenPadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: r.spacingXL),
              Container(
                width: r.adaptive(small: 100.0, medium: 108.0),
                height: r.adaptive(small: 100.0, medium: 108.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppTheme.brand, AppTheme.brandDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.brand.withAlpha(70),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.smartphone_rounded,
                  size: r.adaptive(small: 48.0, medium: 52.0),
                  color: AppTheme.onBrand,
                ),
              ),
              SizedBox(height: r.spacingLG),
              Text(
                'Scan your phone',
                style: TextStyle(
                  fontSize: r.sp(24),
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: r.spacingSM),
              Text(
                'Found $count apps (Play & APK installs).\n'
                'Send them to the engine for risk scoring.',
                style: TextStyle(
                  fontSize: r.sp(14),
                  color: AppTheme.textSecondary,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: r.spacingXL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _scanPackages,
                  icon: const Icon(Icons.security_rounded),
                  label: const Text('Analyse all apps'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brand,
                    foregroundColor: AppTheme.onBrand,
                    padding: EdgeInsets.symmetric(vertical: r.spacingMD + 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              SizedBox(height: r.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(MonitorProvider provider, Responsive r) {
    final summary = provider.summary;
    return Column(
      children: [
        if (summary != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: r.spacingMD,
              horizontal: r.spacingSM,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.brand, AppTheme.brandDark],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brand.withAlpha(60),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryChip('Critical', summary.critical, AppTheme.malwareRed),
                _summaryChip('High', summary.high, AppTheme.warningAmber),
                _summaryChip(
                  'Unknown',
                  summary.unknown,
                  AppTheme.onBrand.withAlpha(210),
                ),
                _summaryChip('Safe', summary.low, AppTheme.benignGreen),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(r.spacingMD),
            itemCount: provider.results.length,
            itemBuilder: (context, index) {
              final item = provider.results[index];
              final color = _riskColor(item.riskLevel);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.r17(context)),
                    border: item.isCritical || item.isHigh
                        ? Border.all(color: color.withAlpha(90))
                        : Border.all(color: AppTheme.textMuted.withAlpha(35)),
                    boxShadow: UiShadows.card(blur: 12, y: 4),
                  ),
                  child: Row(
                    children: [
                      Icon(_riskIcon(item.riskLevel), color: color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.packageName,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: r.sp(13),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.reason,
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: r.sp(11),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlpha(28),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withAlpha(80)),
                        ),
                        child: Text(
                          item.riskLevel.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: r.sp(10),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(r.spacingMD, 8, r.spacingMD, r.spacingMD),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.read<MonitorProvider>().reset();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.brand,
                side: const BorderSide(color: AppTheme.brand, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: r.spacingMD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Scan again'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.onBrand.withAlpha(200),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'critical':
        return AppTheme.malwareRed;
      case 'high':
        return AppTheme.warningAmber;
      case 'low':
        return AppTheme.benignGreen;
      default:
        return AppTheme.textMuted;
    }
  }

  IconData _riskIcon(String level) {
    switch (level) {
      case 'critical':
        return Icons.dangerous_outlined;
      case 'high':
        return Icons.warning_amber_rounded;
      case 'low':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static const _demoPackages = [
    'com.whatsapp',
    'com.instagram.android',
    'com.google.android.gm',
    'com.facebook.orca',
    'com.spotify.music',
    'com.netflix.mediaclient',
    'com.amazon.mShop.android.shopping',
    'com.example.bankingapp',
    'com.android.system.update',
  ];
}

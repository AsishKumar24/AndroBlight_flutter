import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/scan_provider.dart';
import '../widgets/loading_overlay.dart';
import 'result_screen.dart';

/// Scan APK — pick a file, run analysis (light lavender chrome).

class ScanApkScreen extends StatefulWidget {
  const ScanApkScreen({super.key});

  @override
  State<ScanApkScreen> createState() => _ScanApkScreenState();
}

class _ScanApkScreenState extends State<ScanApkScreen> {
  File? _selectedFile;
  /// POST `force_rescan=true` — bypass server `scan_cache.json` for this upload.
  bool _forceRescan = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['apk'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file picker: $e'),
            backgroundColor: AppTheme.malwareRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleScan({bool isSample = false}) async {
    if (!isSample && _selectedFile == null) return;

    final provider = context.read<ScanProvider>();

    if (isSample) {
      await provider.scanApkFile(File('sample_malware.apk'), isSample: true);
    } else {
      await provider.scanApkFile(
        _selectedFile!,
        forceRescan: _forceRescan,
      );
    }

    if (!mounted) return;

    final scan = context.read<ScanProvider>();
    final result = scan.result;
    if (result != null && scan.status == ScanStatus.success) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            result: result,
            scanType: 'APK Scan',
            identifier: scan.currentFileName ?? 'Selected File',
            apkLocalPath: _selectedFile?.path,
          ),
        ),
      );
    } else if (scan.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(scan.errorMessage ?? 'Scan failed'),
          backgroundColor: AppTheme.malwareRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _confirmClearServerCache() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear server scan cache?'),
        content: const Text(
          'This removes cached results on the backend for all files. '
          'The next scan of any APK will run a full analysis again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ScanProvider>().clearServerScanCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Server scan cache cleared'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not clear cache: $e'),
          backgroundColor: AppTheme.malwareRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;
    final provider = context.watch<ScanProvider>();

    return LoadingOverlay(
      isLoading: provider.isScanning,
      message: provider.scanningMessage,
      progress: provider.uploadProgress,
      child: Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(
          title: const Text('Scan APK'),
          backgroundColor: AppTheme.pageBackground,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Stack(
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
              child: _glowOrb(
                AppScale.scale(context, 200),
                AppTheme.brand.withAlpha(20),
              ),
            ),
            Positioned(
              bottom: AppScale.verticalScale(context, 120),
              left: -AppScale.scale(context, 50),
              child: _glowOrb(
                AppScale.scale(context, 170),
                AppTheme.brandDark.withAlpha(14),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: r.screenPadding,
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: r.spacingSM),
                        _buildHero(r),
                        SizedBox(height: r.spacingLG + 8),
                        _buildPickerCard(r, provider),
                        SizedBox(height: r.spacingLG),
                        _buildPrimaryButton(r, provider),
                        SizedBox(height: r.spacingMD),
                        _buildSampleButton(r, provider),
                        SizedBox(height: r.spacingLG),
                        _buildAdvancedScanOptions(r, provider),
                        SizedBox(height: r.spacingLG),
                        _buildBackendPill(r, provider),
                        SizedBox(height: r.spacingLG),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildHero(Responsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.brand, AppTheme.brandDark],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.brand.withAlpha(80),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.android_rounded,
            size: r.adaptive(small: 40.0, medium: 44.0),
            color: AppTheme.onBrand,
          ),
        ),
        SizedBox(height: r.spacingMD),
        Text(
          'Upload an APK',
          style: TextStyle(
            fontSize: r.sp(26),
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: r.spacingXS),
        Text(
          'We extract permissions, signatures, and run the detection engine on your file.',
          style: TextStyle(
            fontSize: r.sp(14),
            color: AppTheme.textSecondary,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPickerCard(Responsive r, ScanProvider provider) {
    final hasFile = _selectedFile != null;
    final borderColor =
        hasFile ? AppTheme.brand : AppTheme.textMuted.withAlpha(55);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: provider.isScanning ? null : _pickFile,
        borderRadius: BorderRadius.circular(AppRadius.r28(context)),
        child: Ink(
          padding: EdgeInsets.symmetric(
            vertical: r.spacingLG + 4,
            horizontal: r.spacingMD,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.r28(context)),
            border: Border.all(color: borderColor, width: hasFile ? 2 : 1.5),
            boxShadow: UiShadows.card(blur: 22, y: 10),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hasFile
                      ? AppTheme.brand.withAlpha(28)
                      : AppTheme.surfaceDark,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasFile
                      ? Icons.insert_drive_file_rounded
                      : Icons.cloud_upload_rounded,
                  size: 40,
                  color: hasFile ? AppTheme.brand : AppTheme.textMuted,
                ),
              ),
              SizedBox(height: r.spacingMD),
              Text(
                hasFile
                    ? _selectedFile!.path.split(Platform.pathSeparator).last
                    : 'Tap to choose an APK',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      hasFile ? AppTheme.textPrimary : AppTheme.textSecondary,
                  fontSize: r.sp(15),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              if (!hasFile) ...[
                SizedBox(height: r.spacingXS),
                Text(
                  '.apk from storage or downloads',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: r.sp(12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(Responsive r, ScanProvider provider) {
    return SizedBox(
      height: r.adaptive(small: 52.0, medium: 56.0),
      child: ElevatedButton(
        onPressed: (_selectedFile == null || provider.isScanning)
            ? null
            : () => _handleScan(),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brand,
          foregroundColor: AppTheme.onBrand,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow_rounded, size: r.sp(22)),
            SizedBox(width: r.spacingXS),
            Text(
              'Start scan',
              style: TextStyle(
                fontSize: r.sp(16),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedScanOptions(Responsive r, ScanProvider provider) {
    return Material(
      color: AppTheme.surfaceLight,
      borderRadius: BorderRadius.circular(AppRadius.r20(context)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: EdgeInsets.symmetric(
            horizontal: r.spacingMD,
            vertical: r.spacingXS,
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            r.spacingSM,
            0,
            r.spacingSM,
            r.spacingMD,
          ),
          title: Row(
            children: [
              Icon(Icons.tune_rounded, size: r.sp(20), color: AppTheme.brand),
              SizedBox(width: r.spacingSM),
              Text(
                'Cache & rescan',
                style: TextStyle(
                  fontSize: r.sp(15),
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          subtitle: Text(
            'Avoid stale results when testing',
            style: TextStyle(
              fontSize: r.sp(12),
              color: AppTheme.textMuted,
            ),
          ),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _forceRescan,
              onChanged: provider.isScanning
                  ? null
                  : (v) => setState(() => _forceRescan = v),
              title: Text(
                'Force new scan',
                style: TextStyle(
                  fontSize: r.sp(14),
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              subtitle: Text(
                'Skip server cache for this file only (same APK, fresh analysis)',
                style: TextStyle(
                  fontSize: r.sp(11),
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
              activeThumbColor: AppTheme.brand,
            ),
            SizedBox(height: r.spacingSM),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: provider.isScanning ? null : _confirmClearServerCache,
                icon: Icon(Icons.delete_sweep_outlined, size: r.sp(18)),
                label: Text(
                  'Clear all server cache',
                  style: TextStyle(
                    fontSize: r.sp(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: BorderSide(color: AppTheme.textMuted.withAlpha(100)),
                  padding: EdgeInsets.symmetric(
                    vertical: r.spacingSM + 2,
                    horizontal: r.spacingMD,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleButton(Responsive r, ScanProvider provider) {
    return OutlinedButton.icon(
      onPressed: provider.isScanning ? null : () => _handleScan(isSample: true),
      icon: Icon(Icons.science_outlined, size: r.sp(18)),
      label: Text(
        'Try sample (demo)',
        style: TextStyle(
          fontSize: r.sp(14),
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.warningAmber,
        side: BorderSide(color: AppTheme.warningAmber.withAlpha(180)),
        padding: EdgeInsets.symmetric(
          vertical: r.spacingSM + 2,
          horizontal: r.spacingMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildBackendPill(Responsive r, ScanProvider provider) {
    final startupOffline = !provider.isBackendOnline;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: r.spacingMD,
        vertical: r.spacingSM,
      ),
      decoration: BoxDecoration(
        color: startupOffline
            ? AppTheme.warningAmber.withAlpha(22)
            : AppTheme.benignGreen.withAlpha(22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: startupOffline
              ? AppTheme.warningAmber.withAlpha(70)
              : AppTheme.benignGreen.withAlpha(70),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            startupOffline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
            size: 18,
            color: startupOffline ? AppTheme.warningAmber : AppTheme.benignGreen,
          ),
          SizedBox(width: r.spacingSM),
          Flexible(
            child: Text(
              startupOffline
                  ? 'Could not verify server at launch — scans still use your configured API'
                  : 'Connected to live engine',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: startupOffline ? AppTheme.warningAmber : AppTheme.benignGreen,
                fontSize: r.sp(12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

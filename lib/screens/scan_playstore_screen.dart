import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/scan_provider.dart';
import 'result_screen.dart';

/// Play Store scan — backend metadata via google-play-scraper.

class ScanPlaystoreScreen extends StatefulWidget {
  const ScanPlaystoreScreen({super.key});

  @override
  State<ScanPlaystoreScreen> createState() => _ScanPlaystoreScreenState();
}

class _ScanPlaystoreScreenState extends State<ScanPlaystoreScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  String? _errorText;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const _examples = [
    ('WhatsApp', 'Icons.chat', 'com.whatsapp'),
    ('Instagram', 'Icons.photo', 'com.instagram.android'),
    ('Telegram', 'Icons.send', 'org.telegram.messenger'),
    ('TikTok', 'Icons.music_note', 'com.zhiliaoapp.musically'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool _isValidInput(String input) {
    if (RegExp(r'^[a-z][a-z0-9_.]*\.[a-z][a-z0-9_.]*$').hasMatch(input)) {
      return true;
    }
    if (input.contains('play.google.com') && input.contains('id=')) {
      return true;
    }
    return false;
  }

  Future<void> _scanApp() async {
    final input = _controller.text.trim();

    if (input.isEmpty) {
      setState(() => _errorText = 'Enter a URL or package name');
      return;
    }
    if (!_isValidInput(input)) {
      setState(() => _errorText = 'Invalid Play Store URL or package name');
      return;
    }

    setState(() => _errorText = null);
    final scanProvider = context.read<ScanProvider>();
    await scanProvider.scanPlayStoreApp(input);

    if (!mounted) return;

    if (scanProvider.hasResult) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            result: scanProvider.result!,
            scanType: 'Play Store',
            identifier: input,
          ),
        ),
      );
    } else if (scanProvider.hasError) {
      _showError(scanProvider.errorMessage ?? 'An error occurred');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.onBrand, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppTheme.malwareRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      _controller.text = text;
      setState(() => _errorText = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: _buildAppBar(r),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildPageBackground(context),
          Consumer<ScanProvider>(
            builder: (context, provider, _) {
              if (provider.isScanning) {
                return _buildScanningOverlay(context, r);
              }
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: r.screenPadding,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: r.spacingSM),
                        _buildHeader(r),
                        SizedBox(height: r.spacingLG),
                        _buildInputCard(r, provider),
                        SizedBox(height: r.spacingMD),
                        _buildQuickFill(r),
                        SizedBox(height: r.spacingLG),
                        _buildInfoBanner(r),
                        SizedBox(height: r.spacingXL),
                        _buildScanButton(r, provider),
                        SizedBox(height: r.spacingLG),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageBackground(BuildContext context) {
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
          top: -AppScale.verticalScale(context, 50),
          right: -AppScale.scale(context, 40),
          child: _glowOrb(
            AppScale.scale(context, 210),
            AppTheme.brand.withAlpha(20),
          ),
        ),
        Positioned(
          bottom: AppScale.verticalScale(context, 100),
          left: -AppScale.scale(context, 55),
          child: _glowOrb(
            AppScale.scale(context, 180),
            AppTheme.brandDark.withAlpha(15),
          ),
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

  PreferredSizeWidget _buildAppBar(Responsive r) {
    return AppBar(
      backgroundColor: AppTheme.pageBackground,
      foregroundColor: AppTheme.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        'Play Store',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: r.sp(18),
          letterSpacing: -0.3,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        color: AppTheme.textPrimary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        Consumer<ScanProvider>(
          builder: (_, p, _) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: p.isBackendOnline
                        ? AppTheme.benignGreen.withAlpha(22)
                        : AppTheme.malwareRed.withAlpha(22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: p.isBackendOnline
                          ? AppTheme.benignGreen.withAlpha(70)
                          : AppTheme.malwareRed.withAlpha(70),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.isBackendOnline
                              ? AppTheme.benignGreen
                              : AppTheme.malwareRed,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        p.isBackendOnline ? 'Live' : 'Demo',
                        style: TextStyle(
                          color: p.isBackendOnline
                              ? AppTheme.benignGreen
                              : AppTheme.malwareRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader(Responsive r) {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: r.adaptive(small: 76.0, medium: 84.0),
            height: r.adaptive(small: 76.0, medium: 84.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.brand, AppTheme.brandDark],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.brand.withAlpha(85),
                  blurRadius: 22,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront_rounded,
              size: 40,
              color: AppTheme.onBrand,
            ),
          ),
        ),
        SizedBox(height: r.spacingMD),
        Text(
          'Play Store analysis',
          style: TextStyle(
            fontSize: r.sp(24),
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: r.spacingXS),
        Text(
          'Permissions, installs, rating & trust signals from the listing — '
          'no APK download.',
          style: TextStyle(
            fontSize: r.sp(13),
            color: AppTheme.textSecondary,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: r.spacingMD),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.brand.withAlpha(26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.brand.withAlpha(45)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt_rounded, size: 16, color: AppTheme.brandDark),
              const SizedBox(width: 6),
              Text(
                'Scan · Analyse · Protect',
                style: TextStyle(
                  fontSize: r.sp(11),
                  fontWeight: FontWeight.w700,
                  color: AppTheme.brandDark,
                  letterSpacing: 0.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard(Responsive r, ScanProvider provider) {
    return Container(
      padding: EdgeInsets.all(r.spacingMD + 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.r28(context)),
        border: Border.all(color: AppTheme.brand.withAlpha(28)),
        boxShadow: UiShadows.card(blur: 22, y: 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search_rounded, size: 18, color: AppTheme.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Package name or Play Store URL',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: r.sp(13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: r.spacingMD),

          TextFormField(
            controller: _controller,
            style: TextStyle(color: AppTheme.textPrimary, fontSize: r.sp(15)),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (_) => _scanApp(),
            onChanged: (_) => setState(() => _errorText = null),
            decoration: InputDecoration(
              hintText: 'com.example.app  or  play.google.com/store/...',
              hintStyle: TextStyle(
                color: AppTheme.textMuted,
                fontSize: r.sp(13),
              ),
              prefixIcon:
                  const Icon(Icons.link_rounded, color: AppTheme.brand),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_controller.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 20),
                      color: AppTheme.textMuted,
                      onPressed: () {
                        _controller.clear();
                        setState(() => _errorText = null);
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.content_paste_rounded, size: 20),
                    color: AppTheme.brand,
                    tooltip: 'Paste from clipboard',
                    onPressed: _pasteFromClipboard,
                  ),
                ],
              ),
              errorText: _errorText,
              filled: true,
              fillColor: AppTheme.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.textMuted.withAlpha(45)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.brand, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppTheme.malwareRed, width: 1.5),
              ),
            ),
          ),

          if (!provider.isBackendOnline) ...[
            SizedBox(height: r.spacingMD),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withAlpha(24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warningAmber.withAlpha(65)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 18,
                    color: AppTheme.warningAmber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Backend offline — demo mode active',
                      style: TextStyle(
                        color: AppTheme.warningAmber,
                        fontSize: r.sp(12),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickFill(Responsive r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on_rounded, size: 16, color: AppTheme.brand),
            const SizedBox(width: 6),
            Text(
              'Quick examples — tap to fill',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: r.sp(12),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        SizedBox(height: r.spacingSM),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _examples.map((ex) {
            final (name, _, pkg) = ex;
            return Material(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: () {
                  _controller.text = pkg;
                  setState(() => _errorText = null);
                },
                borderRadius: BorderRadius.circular(22),
                splashColor: AppTheme.brand.withAlpha(40),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppTheme.brand.withAlpha(70)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brand.withAlpha(18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.android_rounded,
                          size: 15, color: AppTheme.brand),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: r.sp(13),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(Responsive r) {
    final items = [
      (Icons.shield_rounded, 'Permissions', 'Declared in the listing'),
      (Icons.groups_rounded, 'Install count', 'Popularity signal'),
      (Icons.star_rounded, 'Rating', 'Community trust'),
      (Icons.storefront_rounded, 'Developer', 'Publisher info'),
    ];

    return Container(
      padding: EdgeInsets.all(r.spacingMD + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r20(context)),
        border: Border.all(color: AppTheme.brand.withAlpha(35)),
        boxShadow: UiShadows.card(blur: 18, y: 8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceLight,
            Color.lerp(AppTheme.surfaceLight, AppTheme.brand, 0.08)!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What we analyse',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: r.sp(14),
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: r.spacingMD),
          ...items.map((item) {
            final (icon, title, sub) = item;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withAlpha(28),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: AppTheme.brand),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: r.sp(13),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          sub,
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: r.sp(11),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          SizedBox(height: r.spacingXS),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'No APK upload — analysis uses Play Store metadata and '
                  'permission risk scoring.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: r.sp(10),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton(Responsive r, ScanProvider provider) {
    return SizedBox(
      height: r.adaptive(small: 52.0, medium: 56.0),
      child: ElevatedButton(
        onPressed: provider.isScanning ? null : _scanApp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.brand,
          foregroundColor: AppTheme.onBrand,
          disabledBackgroundColor: AppTheme.textMuted.withAlpha(60),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.manage_search_rounded,
              size: r.adaptive(small: 22.0, medium: 24.0),
            ),
            const SizedBox(width: 10),
            Text(
              'Analyse app',
              style: TextStyle(
                fontSize: r.sp(16),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningOverlay(BuildContext context, Responsive r) {
    final steps = [
      'Connecting to Play Store...',
      'Fetching app metadata...',
      'Retrieving declared permissions...',
      'Running permission risk analysis...',
      'Calculating trust score...',
    ];

    return SafeArea(
      child: Padding(
        padding: r.screenPadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: r.adaptive(small: 88.0, medium: 96.0),
                    height: r.adaptive(small: 88.0, medium: 96.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.brand, AppTheme.brandDark],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brand.withAlpha(95),
                          blurRadius: 28,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.travel_explore_rounded,
                      size: 44,
                      color: AppTheme.onBrand,
                    ),
                  ),
                ),
                SizedBox(height: r.spacingLG),
                Text(
                  'Analysing Play Store app',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: r.sp(19),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: r.spacingSM),
                Text(
                  _controller.text.trim(),
                  style: TextStyle(
                    color: AppTheme.brand,
                    fontSize: r.sp(13),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: r.spacingLG),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 5,
                    backgroundColor: AppTheme.surfaceDark,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppTheme.brand),
                  ),
                ),
                SizedBox(height: r.spacingLG),
                ...steps.map((label) => _buildStepItem(label, r)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String label, Responsive r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.brand.withAlpha(200),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: r.sp(12),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

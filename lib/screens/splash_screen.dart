import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/health_provider.dart';
import '../providers/scan_provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Splash — health check, brand moment, Njagani-style light purple chrome.

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  static const _logoAsset = 'assets/app_logo.png';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 700), () {
      _checkHealth();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkHealth() async {
    final healthProvider = context.read<HealthProvider>();
    final scanProvider = context.read<ScanProvider>();

    final isOnline = await healthProvider.checkHealth();

    scanProvider.setBackendStatus(isOnline);

    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 450));
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        final isLoggedIn = authProvider.isAuthenticated;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                isLoggedIn ? const HomeScreen() : const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 480),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
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
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -AppScale.verticalScale(context, 60),
            right: -AppScale.scale(context, 40),
            child: _glowOrb(
              AppScale.scale(context, 220),
              AppTheme.brand.withAlpha(22),
            ),
          ),
          Positioned(
            bottom: AppScale.verticalScale(context, 80),
            left: -AppScale.scale(context, 50),
            child: _glowOrb(
              AppScale.scale(context, 180),
              AppTheme.brandDark.withAlpha(18),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: r.availableHeight,
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: r.spacingMD,
                            vertical: r.spacingLG,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLogoCard(r),
                              SizedBox(height: r.spacingLG + 4),
                              Text(
                                'AndroBlight',
                                style: TextStyle(
                                  fontSize: r.sp(34),
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: r.spacingSM),
                              Text(
                                'Android Malware Detector',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: r.sp(15),
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                  height: 1.35,
                                ),
                              ),
                              SizedBox(height: r.spacingXS),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.brand.withAlpha(28),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.brand.withAlpha(50),
                                  ),
                                ),
                                child: Text(
                                  'Scan · Analyse · Protect',
                                  style: TextStyle(
                                    fontSize: r.sp(12),
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.brandDark,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              SizedBox(height: r.spacingXL + 8),
                              Consumer<HealthProvider>(
                                builder: (context, provider, _) {
                                  return _buildStatusIndicator(provider, r);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(double size, Color color) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLogoCard(Responsive r) {
    final side = r.adaptive(small: 132.0, medium: 152.0, large: 168.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.r32(context)),
        boxShadow: UiShadows.card(blur: 28, y: 12),
        border: Border.all(
          color: AppTheme.brand.withAlpha(40),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.r28(context)),
        child: Image.asset(
          _logoAsset,
          width: side,
          height: side,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _fallbackLogoGlyph(r, side);
          },
        ),
      ),
    );
  }

  /// Vector-style fallback if asset is missing.
  Widget _fallbackLogoGlyph(Responsive r, double side) {
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.brand, AppTheme.brandDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withAlpha(100),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(
        Icons.shield_rounded,
        size: side * 0.48,
        color: AppTheme.onBrand,
      ),
    );
  }

  Widget _buildStatusIndicator(HealthProvider provider, Responsive r) {
    switch (provider.status) {
      case HealthStatus.initial:
      case HealthStatus.checking:
        return Column(
          children: [
            SizedBox(
              width: r.adaptive(small: 36.0, medium: 42.0),
              height: r.adaptive(small: 36.0, medium: 42.0),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brand),
              ),
            ),
            SizedBox(height: r.spacingMD),
            Text(
              'Connecting to server…',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: r.sp(13),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case HealthStatus.offline:
        return Column(
          children: [
            Container(
              padding: EdgeInsets.all(r.spacingMD),
              decoration: BoxDecoration(
                color: AppTheme.malwareRed.withAlpha(36),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.malwareRed.withAlpha(80),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: r.adaptive(small: 38.0, medium: 44.0),
                    color: AppTheme.malwareRed,
                  ),
                  SizedBox(height: r.spacingSM),
                  Text(
                    'Server offline',
                    style: TextStyle(
                      color: AppTheme.malwareRed,
                      fontSize: r.sp(16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (provider.errorMessage != null) ...[
                    SizedBox(height: r.spacingXS),
                    Text(
                      provider.errorMessage!,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: r.sp(11),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: r.spacingMD),
            ElevatedButton.icon(
              onPressed: _checkHealth,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brand,
                foregroundColor: AppTheme.onBrand,
              ),
            ),
          ],
        );
      case HealthStatus.online:
        return Column(
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: r.adaptive(small: 38.0, medium: 44.0),
              color: AppTheme.benignGreen,
            ),
            SizedBox(height: r.spacingSM),
            Text(
              'Connected',
              style: TextStyle(
                color: AppTheme.benignGreen,
                fontSize: r.sp(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
    }
  }
}

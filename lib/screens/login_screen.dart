import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'totp_verify_screen.dart';

/// Login — light lavender shell, brand card, shared with register styling.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const _logoAsset = 'assets/app_logo.png';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (authProvider.isTwoFaPending) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TotpVerifyScreen(email: _emailController.text.trim()),
        ),
      );
      return;
    }

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
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
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -AppScale.verticalScale(context, 50),
            right: -AppScale.scale(context, 30),
            child: _glowOrb(
              AppScale.scale(context, 200),
              AppTheme.brand.withAlpha(20),
            ),
          ),
          Positioned(
            bottom: AppScale.verticalScale(context, 100),
            left: -AppScale.scale(context, 40),
            child: _glowOrb(
              AppScale.scale(context, 160),
              AppTheme.brandDark.withAlpha(16),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: r.screenPadding,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLogo(r),
                          SizedBox(height: r.spacingLG + 8),
                          _buildLoginCard(r),
                          SizedBox(height: r.spacingLG),
                          _buildRegisterLink(r),
                          SizedBox(height: r.spacingSM),
                          _buildSkipButton(r),
                        ],
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
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  Widget _buildLogo(Responsive r) {
    final side = r.adaptive(small: 96.0, medium: 108.0, large: 112.0);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.r32(context)),
            boxShadow: UiShadows.card(blur: 26, y: 12),
            border: Border.all(color: AppTheme.brand.withAlpha(38)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r28(context)),
            child: Image.asset(
              _logoAsset,
              width: side,
              height: side,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _fallbackLogoGlyph(r, side),
            ),
          ),
        ),
        SizedBox(height: r.spacingMD),
        Text(
          'AndroBlight',
          style: TextStyle(
            fontSize: r.sp(30),
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: r.spacingXS),
        Text(
          'Secure your Android world',
          style: TextStyle(
            fontSize: r.sp(14),
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: r.spacingSM),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.brand.withAlpha(26),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.brand.withAlpha(45)),
          ),
          child: Text(
            'Scan · Analyse · Protect',
            style: TextStyle(
              fontSize: r.sp(11),
              fontWeight: FontWeight.w600,
              color: AppTheme.brandDark,
              letterSpacing: 0.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackLogoGlyph(Responsive r, double side) {
    return Container(
      width: side,
      height: side,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.brand, AppTheme.brandDark],
        ),
      ),
      child: Icon(
        Icons.shield_rounded,
        size: side * 0.45,
        color: AppTheme.onBrand,
      ),
    );
  }

  Widget _buildLoginCard(Responsive r) {
    return Container(
      padding: EdgeInsets.all(r.spacingLG + 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.r28(context)),
        border: Border.all(color: AppTheme.brand.withAlpha(32)),
        boxShadow: UiShadows.card(blur: 28, y: 14),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: TextStyle(
                fontSize: r.sp(22),
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: r.spacingXS),
            Text(
              'Sign in to sync your scan history across devices',
              style: TextStyle(
                fontSize: r.sp(13),
                color: AppTheme.textSecondary,
                height: 1.35,
              ),
            ),
            SizedBox(height: r.spacingLG),

            Consumer<AuthProvider>(
              builder: (context, provider, _) {
                if (provider.errorMessage != null) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: r.spacingSM),
                    child: Container(
                      padding: EdgeInsets.all(r.spacingSM + 2),
                      decoration: BoxDecoration(
                        color: AppTheme.malwareRed.withAlpha(22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.malwareRed.withAlpha(55),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.malwareRed,
                            size: r.sp(20),
                          ),
                          SizedBox(width: r.spacingSM),
                          Expanded(
                            child: Text(
                              provider.errorMessage!,
                              style: TextStyle(
                                color: AppTheme.malwareRed,
                                fontSize: r.sp(13),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: r.sp(15)),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceDark,
                labelText: 'Email',
                labelStyle: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: r.sp(13),
                ),
                prefixIcon: const Icon(
                  Icons.alternate_email_rounded,
                  color: AppTheme.brand,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.textMuted.withAlpha(40)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.brand, width: 2),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: r.spacingMD),

            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: r.sp(15)),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.surfaceDark,
                labelText: 'Password',
                labelStyle: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: r.sp(13),
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppTheme.brand,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.textMuted.withAlpha(40)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.brand, width: 2),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            SizedBox(height: r.spacingLG + 4),

            Consumer<AuthProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  height: r.adaptive(small: 52.0, medium: 56.0),
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brand,
                      foregroundColor: AppTheme.onBrand,
                      elevation: 0,
                      shadowColor: AppTheme.brand.withAlpha(100),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppTheme.onBrand,
                            ),
                          )
                        : Text(
                            'Sign in',
                            style: TextStyle(
                              fontSize: r.sp(16),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink(Responsive r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: r.sp(14),
          ),
        ),
        TextButton(
          onPressed: () {
            context.read<AuthProvider>().clearError();
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.brand,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            'Sign up',
            style: TextStyle(
              fontSize: r.sp(14),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton(Responsive r) {
    return TextButton.icon(
      onPressed: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      },
      icon: Icon(
        Icons.arrow_forward_rounded,
        size: r.sp(16),
        color: AppTheme.textMuted,
      ),
      label: Text(
        'Continue without account',
        style: TextStyle(
          color: AppTheme.textMuted,
          fontSize: r.sp(13),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

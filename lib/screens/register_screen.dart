import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

/// Register — matches login shell (lavender, brand card, logo).

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  static const _logoAsset = 'assets/app_logo.png';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
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
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: AppTheme.surfaceDark,
      labelText: label,
      labelStyle: TextStyle(
        color: AppTheme.textMuted,
        fontSize: context.responsive.sp(13),
      ),
      prefixIcon: Icon(icon, color: AppTheme.brand),
      suffixIcon: suffix,
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
    );
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
            top: -AppScale.verticalScale(context, 40),
            right: -AppScale.scale(context, 20),
            child: _glowOrb(
              AppScale.scale(context, 190),
              AppTheme.brand.withAlpha(18),
            ),
          ),
          Positioned(
            bottom: AppScale.verticalScale(context, 120),
            left: -AppScale.scale(context, 50),
            child: _glowOrb(
              AppScale.scale(context, 150),
              AppTheme.brandDark.withAlpha(14),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Material(
                              color: AppTheme.surfaceLight,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: AppTheme.brand.withAlpha(30),
                                ),
                              ),
                              child: IconButton(
                                onPressed: () {
                                  context.read<AuthProvider>().clearError();
                                  Navigator.of(context).pop();
                                },
                                icon: const Icon(Icons.arrow_back_rounded),
                                color: AppTheme.textPrimary,
                                tooltip: 'Back',
                              ),
                            ),
                          ),
                          SizedBox(height: r.spacingMD),
                          _buildLogo(r),
                          SizedBox(height: r.spacingLG),
                          _buildRegisterCard(r),
                          SizedBox(height: r.spacingLG),
                          _buildLoginLink(r),
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
    final side = r.adaptive(small: 80.0, medium: 92.0, large: 96.0);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(AppRadius.r28(context)),
            boxShadow: UiShadows.card(blur: 22, y: 10),
            border: Border.all(color: AppTheme.brand.withAlpha(35)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.r20(context)),
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
          'Create account',
          style: TextStyle(
            fontSize: r.sp(26),
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.35,
          ),
        ),
        SizedBox(height: r.spacingXS),
        Text(
          'Join AndroBlight to sync scans and stay protected',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: r.sp(14),
            color: AppTheme.textSecondary,
            height: 1.4,
            fontWeight: FontWeight.w500,
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
        Icons.person_add_rounded,
        size: side * 0.42,
        color: AppTheme.onBrand,
      ),
    );
  }

  Widget _buildRegisterCard(Responsive r) {
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
              'Your details',
              style: TextStyle(
                fontSize: r.sp(18),
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: r.spacingXS),
            Text(
              'We only use this to sign you in and label your scans.',
              style: TextStyle(
                fontSize: r.sp(12),
                color: AppTheme.textMuted,
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
              controller: _nameController,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: r.sp(15),
              ),
              decoration: _fieldDecoration(
                label: 'Display name (optional)',
                icon: Icons.badge_outlined,
              ),
            ),
            SizedBox(height: r.spacingMD),

            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: r.sp(15),
              ),
              decoration: _fieldDecoration(
                label: 'Email',
                icon: Icons.alternate_email_rounded,
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
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: r.sp(15),
              ),
              decoration: _fieldDecoration(
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Minimum 6 characters';
                return null;
              },
            ),
            SizedBox(height: r.spacingMD),

            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: r.sp(15),
              ),
              decoration: _fieldDecoration(
                label: 'Confirm password',
                icon: Icons.lock_person_outlined,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.textMuted,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v != _passwordController.text) {
                  return 'Passwords do not match';
                }
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
                    onPressed: provider.isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brand,
                      foregroundColor: AppTheme.onBrand,
                      elevation: 0,
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
                            'Create account',
                            style: TextStyle(
                              fontSize: r.sp(16),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.25,
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

  Widget _buildLoginLink(Responsive r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: r.sp(14),
          ),
        ),
        TextButton(
          onPressed: () {
            context.read<AuthProvider>().clearError();
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.brand,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            'Sign in',
            style: TextStyle(
              fontSize: r.sp(14),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

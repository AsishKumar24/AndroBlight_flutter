import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

/// TOTP verify — second step after `2fa_required` (same API flow as before).

class TotpVerifyScreen extends StatefulWidget {
  final String email;

  const TotpVerifyScreen({super.key, required this.email});

  @override
  State<TotpVerifyScreen> createState() => _TotpVerifyScreenState();
}

class _TotpVerifyScreenState extends State<TotpVerifyScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter the 6-digit code'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.completeTwoFaLogin(otp);

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
      backgroundColor: AppTheme.pageBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _pageBackground(context),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: r.screenPadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: r.adaptive(small: 80.0, medium: 88.0),
                        height: r.adaptive(small: 80.0, medium: 88.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppTheme.brand, AppTheme.brandDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.brand.withAlpha(90),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.pin_rounded,
                          size: r.adaptive(small: 40.0, medium: 44.0),
                          color: AppTheme.onBrand,
                        ),
                      ),
                      SizedBox(height: r.spacingMD),
                      Text(
                        'Two-factor auth',
                        style: TextStyle(
                          fontSize: r.sp(26),
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      SizedBox(height: r.spacingXS),
                      Text(
                        widget.email,
                        style: TextStyle(
                          fontSize: r.sp(13),
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: r.spacingLG + 8),
                      Container(
                        padding: EdgeInsets.all(r.spacingLG),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(AppRadius.r28(context)),
                          border: Border.all(color: AppTheme.brand.withAlpha(32)),
                          boxShadow: UiShadows.card(blur: 24, y: 12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verification required',
                              style: TextStyle(
                                fontSize: r.sp(18),
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: r.spacingXS),
                            Text(
                              'Enter the 6-digit code from your authenticator app.',
                              style: TextStyle(
                                fontSize: r.sp(13),
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: r.spacingLG),
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                if (auth.errorMessage != null) {
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
                                        children: [
                                          Icon(
                                            Icons.error_outline_rounded,
                                            color: AppTheme.malwareRed,
                                            size: r.sp(20),
                                          ),
                                          SizedBox(width: r.spacingSM),
                                          Expanded(
                                            child: Text(
                                              auth.errorMessage!,
                                              style: TextStyle(
                                                color: AppTheme.malwareRed,
                                                fontSize: r.sp(13),
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
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              autofocus: true,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: r.sp(28),
                                letterSpacing: 10,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppTheme.surfaceDark,
                                labelText: 'Authentication code',
                                labelStyle: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: r.sp(13),
                                ),
                                prefixIcon: const Icon(
                                  Icons.password_rounded,
                                  color: AppTheme.brand,
                                ),
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppTheme.textMuted.withAlpha(45),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppTheme.brand,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: r.spacingLG),
                            Consumer<AuthProvider>(
                              builder: (context, auth, _) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: r.adaptive(small: 52.0, medium: 56.0),
                                  child: ElevatedButton(
                                    onPressed: auth.isLoading ? null : _verify,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.brand,
                                      foregroundColor: AppTheme.onBrand,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: auth.isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: AppTheme.onBrand,
                                            ),
                                          )
                                        : Text(
                                            'Verify & sign in',
                                            style: TextStyle(
                                              fontSize: r.sp(16),
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: r.spacingMD),
                      TextButton.icon(
                        onPressed: () {
                          context.read<AuthProvider>().cancelTwoFa();
                          Navigator.of(context).pop();
                        },
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: r.sp(18),
                          color: AppTheme.textMuted,
                        ),
                        label: Text(
                          'Back to login',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: r.sp(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
          top: -AppScale.verticalScale(context, 50),
          right: -AppScale.scale(context, 30),
          child: IgnorePointer(
            child: Container(
              width: AppScale.scale(context, 200),
              height: AppScale.scale(context, 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brand.withAlpha(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

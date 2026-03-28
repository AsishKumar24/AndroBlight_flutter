import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/totp_provider.dart';

/// 2FA setup — QR + confirm OTP (same provider calls as before).

class TwoFaSetupScreen extends StatefulWidget {
  const TwoFaSetupScreen({super.key});

  @override
  State<TwoFaSetupScreen> createState() => _TwoFaSetupScreenState();
}

class _TwoFaSetupScreenState extends State<TwoFaSetupScreen> {
  final _otpController = TextEditingController();
  bool _confirmMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TotpProvider>().setupTwoFa();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a 6-digit code'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final success = await context.read<TotpProvider>().confirmTwoFa(otp);

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Two-factor authentication enabled'),
          backgroundColor: AppTheme.benignGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
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
          bottom: AppScale.verticalScale(context, 100),
          left: -AppScale.scale(context, 40),
          child: IgnorePointer(
            child: Container(
              width: AppScale.scale(context, 180),
              height: AppScale.scale(context, 180),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.brand.withAlpha(16),
              ),
            ),
          ),
        ),
      ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            context.read<TotpProvider>().reset();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Two-factor auth',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: r.sp(18),
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _pageBackground(context),
          Consumer<TotpProvider>(
            builder: (context, totp, _) {
              if (totp.isLoading) {
                return Center(
                  child: CircularProgressIndicator(color: AppTheme.brand),
                );
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
                        _buildStepIndicator(r),
                        SizedBox(height: r.spacingLG),
                        if (!_confirmMode)
                          _buildQrStep(r, totp)
                        else
                          _buildConfirmStep(r, totp),
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

  Widget _buildStepIndicator(Responsive r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepDot(1, !_confirmMode, r),
        Container(
          width: 44,
          height: 3,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: _confirmMode ? AppTheme.brand : AppTheme.textMuted.withAlpha(60),
          ),
        ),
        _stepDot(2, _confirmMode, r),
      ],
    );
  }

  Widget _stepDot(int n, bool active, Responsive r) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active
            ? const LinearGradient(
                colors: [AppTheme.brand, AppTheme.brandDark],
              )
            : null,
        color: active ? null : AppTheme.surfaceDark,
        border: Border.all(
          color: active ? AppTheme.brand : AppTheme.textMuted.withAlpha(80),
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppTheme.brand.withAlpha(60),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          '$n',
          style: TextStyle(
            color: active ? AppTheme.onBrand : AppTheme.textMuted,
            fontSize: r.sp(14),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildQrStep(Responsive r, TotpProvider totp) {
    final uri = totp.otpauthUri;
    final secret = totp.secret;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Scan with your authenticator',
          style: TextStyle(
            fontSize: r.sp(18),
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: r.spacingSM),
        Text(
          'Google Authenticator, Authy, or any TOTP app.',
          style: TextStyle(
            fontSize: r.sp(13),
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: r.spacingLG),

        if (uri != null)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.r20(context)),
              border: Border.all(color: AppTheme.brand.withAlpha(35)),
              boxShadow: UiShadows.card(blur: 20, y: 10),
            ),
            child: QrImageView(
              data: uri,
              version: QrVersions.auto,
              size: r.adaptive(small: 200.0, medium: 240.0),
              backgroundColor: Colors.white,
            ),
          ),
        SizedBox(height: r.spacingLG),

        Text(
          'Or enter manually',
          style: TextStyle(
            fontSize: r.sp(13),
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: r.spacingSM),
        if (secret != null)
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: secret));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Secret copied'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.brand.withAlpha(45)),
                boxShadow: UiShadows.card(blur: 10, y: 4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _formatSecret(secret),
                      style: TextStyle(
                        fontSize: r.sp(13),
                        color: AppTheme.brandDark,
                        fontFamily: 'monospace',
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.copy_rounded, color: AppTheme.brand, size: 20),
                ],
              ),
            ),
          ),
        SizedBox(height: r.spacingXL),

        SizedBox(
          width: double.infinity,
          height: r.adaptive(small: 52.0, medium: 56.0),
          child: ElevatedButton(
            onPressed: () => setState(() => _confirmMode = true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brand,
              foregroundColor: AppTheme.onBrand,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'I\'ve scanned it — next',
              style: TextStyle(
                fontSize: r.sp(16),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep(Responsive r, TotpProvider totp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm setup',
          style: TextStyle(
            fontSize: r.sp(18),
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: r.spacingSM),
        Text(
          'Enter the 6-digit code from your app to activate 2FA.',
          style: TextStyle(
            fontSize: r.sp(13),
            color: AppTheme.textSecondary,
            height: 1.45,
          ),
        ),
        SizedBox(height: r.spacingLG),

        if (totp.errorMessage != null)
          Padding(
            padding: EdgeInsets.only(bottom: r.spacingSM),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(r.spacingSM + 2),
              decoration: BoxDecoration(
                color: AppTheme.malwareRed.withAlpha(22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.malwareRed.withAlpha(55)),
              ),
              child: Text(
                totp.errorMessage!,
                style: TextStyle(
                  color: AppTheme.malwareRed,
                  fontSize: r.sp(13),
                ),
              ),
            ),
          ),

        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: r.sp(24),
            letterSpacing: 8,
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
            counterText: '',
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
          ),
        ),
        SizedBox(height: r.spacingLG),

        SizedBox(
          width: double.infinity,
          height: r.adaptive(small: 52.0, medium: 56.0),
          child: ElevatedButton(
            onPressed: totp.isLoading ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brand,
              foregroundColor: AppTheme.onBrand,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: totp.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppTheme.onBrand,
                    ),
                  )
                : Text(
                    'Activate 2FA',
                    style: TextStyle(
                      fontSize: r.sp(16),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        SizedBox(height: r.spacingMD),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _confirmMode = false),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: r.sp(18),
              color: AppTheme.textMuted,
            ),
            label: Text(
              'Back to QR',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: r.sp(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatSecret(String secret) {
    final buf = StringBuffer();
    for (int i = 0; i < secret.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(secret[i]);
    }
    return buf.toString();
  }
}

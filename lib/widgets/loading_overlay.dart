import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../core/app_styling_tokens.dart';
import '../core/theme.dart';

/// Full-screen loading layer — used by APK scan (and anywhere else that wraps content).
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final double? progress;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.progress,
  });

  bool get _hasDeterminateProgress =>
      progress != null && progress! > 0 && progress! < 1.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: AbsorbPointer(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    alignment: Alignment.center,
                    color: AppTheme.textPrimary.withAlpha(35),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: Material(
                          color: AppTheme.surfaceLight,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppRadius.r28(context)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 28,
                            ),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.r28(context)),
                              border: Border.all(
                                color: AppTheme.brand.withAlpha(45),
                              ),
                              boxShadow: UiShadows.card(blur: 32, y: 18),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.brand,
                                        AppTheme.brandDark,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.brand.withAlpha(80),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      value: _hasDeterminateProgress
                                          ? progress
                                          : null,
                                      strokeWidth: 3,
                                      backgroundColor:
                                          AppTheme.onBrand.withAlpha(100),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppTheme.onBrand,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  'Analysing APK',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (message != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    message!,
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      height: 1.45,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (progress != null) ...[
                                  const SizedBox(height: 20),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: _hasDeterminateProgress
                                          ? progress
                                          : null,
                                      minHeight: 8,
                                      backgroundColor: AppTheme.surfaceDark,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        AppTheme.brand,
                                      ),
                                    ),
                                  ),
                                  if (_hasDeterminateProgress) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '${(progress! * 100).round()}% uploaded',
                                      style: TextStyle(
                                        color: AppTheme.brandDark,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
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
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Loading Overlay Widget - Wraps a child and shows a loading screen on top
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.45),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      value: progress,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentCyan),
                      backgroundColor: Colors.white10,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      message!,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (progress != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${(progress! * 100).round()}%',
                      style: const TextStyle(
                        color: AppTheme.accentCyan,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

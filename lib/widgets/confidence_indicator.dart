import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../core/theme.dart';

/// Confidence Indicator Widget - Animated circular gauge

class ConfidenceIndicator extends StatefulWidget {
  final double confidence; // 0.0 to 1.0
  final bool isMalware;
  final double size;

  const ConfidenceIndicator({
    super.key,
    required this.confidence,
    required this.isMalware,
    this.size = 180,
  });

  @override
  State<ConfidenceIndicator> createState() => _ConfidenceIndicatorState();
}

class _ConfidenceIndicatorState extends State<ConfidenceIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.confidence).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isMalware ? AppTheme.malwareRed : AppTheme.benignGreen;
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background circle
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceLight,
                ),
              ),
              // Progress arc
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _CircularProgressPainter(
                  progress: _animation.value,
                  color: color,
                  strokeWidth: 12,
                ),
              ),
              // Center content
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_animation.value * 100).round()}%',
                    style: TextStyle(
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    'Confidence',
                    style: TextStyle(
                      fontSize: widget.size * 0.08,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = AppTheme.surfaceDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

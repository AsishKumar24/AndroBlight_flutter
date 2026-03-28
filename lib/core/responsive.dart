import 'package:flutter/material.dart';

/// Responsive Helper - Adapts UI to any screen size
/// 
/// Usage:
/// ```dart
/// // In build method:
/// final responsive = Responsive(context);
/// 
/// // Use responsive values:
/// SizedBox(height: responsive.hp(5)) // 5% of screen height
/// Text(style: TextStyle(fontSize: responsive.sp(16)))
/// ```

class Responsive {
  final BuildContext context;
  late final double _screenWidth;
  late final double _screenHeight;
  late final double _safeAreaTop;
  late final double _safeAreaBottom;
  late final bool _isSmallScreen;
  late final bool _isMediumScreen;
  late final bool _isLargeScreen;

  Responsive(this.context) {
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width;
    _screenHeight = mediaQuery.size.height;
    _safeAreaTop = mediaQuery.padding.top;
    _safeAreaBottom = mediaQuery.padding.bottom;
    
    // Screen size categories
    _isSmallScreen = _screenHeight < 700;
    _isMediumScreen = _screenHeight >= 700 && _screenHeight < 900;
    _isLargeScreen = _screenHeight >= 900;
  }

  // Screen dimensions
  double get screenWidth => _screenWidth;
  double get screenHeight => _screenHeight;
  double get safeAreaTop => _safeAreaTop;
  double get safeAreaBottom => _safeAreaBottom;
  
  // Available height (minus safe areas)
  double get availableHeight => _screenHeight - _safeAreaTop - _safeAreaBottom;
  
  // Screen size checks
  bool get isSmallScreen => _isSmallScreen;
  bool get isMediumScreen => _isMediumScreen;
  bool get isLargeScreen => _isLargeScreen;

  /// Width percentage (0-100)
  double wp(double percentage) => _screenWidth * (percentage / 100);
  
  /// Height percentage (0-100)
  double hp(double percentage) => _screenHeight * (percentage / 100);
  
  /// Scaled pixel for fonts (based on screen width)
  double sp(double size) {
    // Base width is 375 (iPhone SE/small phone)
    final scaleFactor = _screenWidth / 375;
    return size * scaleFactor.clamp(0.8, 1.3);
  }
  
  /// Adaptive value based on screen size
  T adaptive<T>({
    required T small,
    T? medium,
    T? large,
  }) {
    if (_isLargeScreen) return large ?? medium ?? small;
    if (_isMediumScreen) return medium ?? small;
    return small;
  }
  
  /// Responsive padding
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
    horizontal: adaptive(small: 16.0, medium: 20.0, large: 24.0),
    vertical: adaptive(small: 12.0, medium: 16.0, large: 20.0),
  );
  
  /// Responsive spacing
  double get spacingXS => adaptive(small: 4.0, medium: 6.0, large: 8.0);
  double get spacingSM => adaptive(small: 8.0, medium: 12.0, large: 16.0);
  double get spacingMD => adaptive(small: 16.0, medium: 20.0, large: 24.0);
  double get spacingLG => adaptive(small: 24.0, medium: 32.0, large: 40.0);
  double get spacingXL => adaptive(small: 32.0, medium: 48.0, large: 60.0);
}

/// Extension to easily access Responsive from BuildContext
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
}

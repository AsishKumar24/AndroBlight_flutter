import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Baselines aligned with RN `guideLineBaseWidth` / `guideLineBaseHeight`.
const double _guideW = 375;
const double _guideH = 812;

/// Port of React Native `scale` / `verticalScale` using logical pixels.
abstract final class AppScale {
  static double _short(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    return math.min(s.width, s.height);
  }

  static double _long(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    return math.max(s.width, s.height);
  }

  /// Horizontal-ish scale: `(shortDimension / 375) * size`
  static double scale(BuildContext context, double size) =>
      (_short(context) / _guideW) * size;

  /// Vertical-ish scale: `(longDimension / 812) * size`
  static double verticalScale(BuildContext context, double size) =>
      (_long(context) / _guideH) * size;
}

/// RN `colors` — use alongside or instead of [AppTheme] as needed.
abstract final class AppColors {
  static const Color primary = Color(0xFFA3E635);
  static const Color primaryDark = Color(0xFF0369A1);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFE5E5E5);
  static const Color textLighter = Color(0xFFD4D4D4);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color rose = Color(0xFFEF4444);
  static const Color green = Color(0xFF16A34A);
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral350 = Color(0xFFCCCCCC);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF070707);
}

/// `SpacingX` — horizontal spacing via [AppScale.scale].
abstract final class SpacingX {
  static double s3(BuildContext c) => AppScale.scale(c, 3);
  static double s5(BuildContext c) => AppScale.scale(c, 5);
  static double s7(BuildContext c) => AppScale.scale(c, 7);
  static double s10(BuildContext c) => AppScale.scale(c, 10);
  static double s12(BuildContext c) => AppScale.scale(c, 12);
  static double s15(BuildContext c) => AppScale.scale(c, 15);
  static double s20(BuildContext c) => AppScale.scale(c, 20);
  static double s25(BuildContext c) => AppScale.scale(c, 25);
  static double s30(BuildContext c) => AppScale.scale(c, 30);
  static double s35(BuildContext c) => AppScale.scale(c, 35);
  static double s40(BuildContext c) => AppScale.scale(c, 40);
  static double s45(BuildContext c) => AppScale.scale(c, 45);
  static double s50(BuildContext c) => AppScale.scale(c, 50);
}

/// `SpacingY` — vertical spacing via [AppScale.verticalScale].
abstract final class SpacingY {
  static double s7(BuildContext c) => AppScale.verticalScale(c, 7);
  static double s10(BuildContext c) => AppScale.verticalScale(c, 10);
  static double s12(BuildContext c) => AppScale.verticalScale(c, 12);
  static double s15(BuildContext c) => AppScale.verticalScale(c, 15);
  static double s17(BuildContext c) => AppScale.verticalScale(c, 17);
  static double s20(BuildContext c) => AppScale.verticalScale(c, 20);
  static double s25(BuildContext c) => AppScale.verticalScale(c, 25);
  static double s30(BuildContext c) => AppScale.verticalScale(c, 30);
  static double s35(BuildContext c) => AppScale.verticalScale(c, 35);
  static double s40(BuildContext c) => AppScale.verticalScale(c, 40);
  static double s45(BuildContext c) => AppScale.verticalScale(c, 45);
  static double s50(BuildContext c) => AppScale.verticalScale(c, 50);
  static double s55(BuildContext c) => AppScale.verticalScale(c, 55);
  static double s60(BuildContext c) => AppScale.verticalScale(c, 60);
}

/// `radius` — RN used [verticalScale] for corner radii; same here.
abstract final class AppRadius {
  static double r3(BuildContext c) => AppScale.verticalScale(c, 3);
  static double r6(BuildContext c) => AppScale.verticalScale(c, 6);
  static double r10(BuildContext c) => AppScale.verticalScale(c, 10);
  static double r12(BuildContext c) => AppScale.verticalScale(c, 12);
  static double r15(BuildContext c) => AppScale.verticalScale(c, 15);
  static double r17(BuildContext c) => AppScale.verticalScale(c, 17);
  static double r20(BuildContext c) => AppScale.verticalScale(c, 20);
  static double r28(BuildContext c) => AppScale.verticalScale(c, 28);
  static double r30(BuildContext c) => AppScale.verticalScale(c, 30);
  static double r32(BuildContext c) => AppScale.verticalScale(c, 32);
}

/// Soft floating-card shadows (light UI).
abstract final class UiShadows {
  static List<BoxShadow> card({double blur = 24, double y = 10}) => [
        BoxShadow(
          color: const Color(0xFF8B5CF6).withOpacity(0.07),
          blurRadius: blur,
          offset: Offset(0, y),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

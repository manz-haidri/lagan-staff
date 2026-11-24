import 'package:flutter/material.dart';

class AppDimensions {
  // Component Heights
  static const double buttonHeight = 52.0;
  static const double buttonHeightSmall = 40.0;
  static const double inputFieldHeight = 54.0;
  static const double topAppBarHeight = 56.0;
  static const double bottomNavBarHeight = 64.0;

  // Border Radii
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusPill = 999.0;

  static const BorderRadius roundedSmall = BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius roundedMedium = BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius roundedLarge = BorderRadius.all(Radius.circular(radiusLarge));
  static const BorderRadius roundedPill = BorderRadius.all(Radius.circular(radiusPill));

  // Icon Sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXLarge = 32.0;
  static const double iconHero = 48.0;
}

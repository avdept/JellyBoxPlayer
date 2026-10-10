import 'package:flutter/material.dart';

abstract final class TvTokens {
  static const double pagePaddingH = 40;
  static const double pagePaddingV = 28;

  static const double railCollapsedWidth = 64;
  static const double railExpandedWidth = 216;

  static const double cardWidth = 148;
  static const double cardGap = 18;
  static const double libraryCardWidth = 280;
  static const double libraryCardHeight = 158;

  static const double miniPlayerHeight = 72;

  static const double focusScale = 1.07;
  static const Duration focusDuration = Duration(milliseconds: 160);
  static const Curve focusCurve = Curves.easeOutCubic;
  static const Duration longSelect = Duration(milliseconds: 450);

  static const Color focusRing = Colors.white;
  static const Color surface = Color(0xFF1C1518);
  static const Color surfaceRaised = Color(0xFF2B1D23);
  static const Color railBackground = Color(0xFF471F27);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(10));
  static const BorderRadius panelRadius = BorderRadius.all(
    Radius.circular(14),
  );

  static const TextStyle title = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(fontSize: 14, height: 1.3);
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: Colors.white70,
  );

  static List<BoxShadow> glow({double alpha = 0.35}) => [
    BoxShadow(
      color: Colors.white.withValues(alpha: alpha),
      blurRadius: 18,
      spreadRadius: 1,
    ),
  ];
}

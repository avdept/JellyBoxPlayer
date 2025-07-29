import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';

abstract class Themes {
  static final red = ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.dark,
    fontFamily: FontFamily.gilroy,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFD2F2F),
      onPrimary: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.black,
    cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
      primaryColor: Colors.white,
      primaryContrastingColor: Color(0xFFFD2F2F),
      barBackgroundColor: Color(0xFF471F27),
      scaffoldBackgroundColor: Colors.black,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.black87,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 4,
      overlayColor: Colors.transparent,
      thumbColor: Colors.white,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 16),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF471F27),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF471F27),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xFF471F27),
    ),
    chipTheme: ChipThemeData(
      labelPadding: const EdgeInsets.symmetric(horizontal: 11),
      backgroundColor: const Color(0xFF362A30),
      selectedColor: const Color(0xFF0066FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

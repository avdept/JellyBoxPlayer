import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/presentation/themes/app_colors.dart';

export 'app_colors.dart';

abstract class Themes {
  static const tooltipDelay = Duration(milliseconds: 350);

  static const tooltipPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 6,
  );

  static const tooltipTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 13,
    height: 1.2,
  );

  static BoxDecoration tooltipDecoration(BuildContext context) =>
      _tooltipBox(AppColors.from(context).surface);

  static BoxDecoration _tooltipBox(Color color) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(6),
    boxShadow: const [
      BoxShadow(
        color: Colors.black54,
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  static final Map<(ColorTheme, AppFont, bool), ThemeData> _cache = {};

  static ThemeData of(
    ColorTheme theme, {
    AppFont font = AppFont.gilroy,
    bool tv = false,
  }) => _cache.putIfAbsent((theme, font, tv), () {
    final colors = AppColors.of(theme);
    final base = _build(colors, fontFamily(font));
    return tv ? _tv(base, colors) : base;
  });

  static String fontFamily(AppFont font) => switch (font) {
    AppFont.gilroy => FontFamily.gilroy,
    AppFont.inter => FontFamily.inter,
    AppFont.onest => FontFamily.onest,
    AppFont.montserrat => FontFamily.montserrat,
    AppFont.archivo => FontFamily.archivo,
  };

  static ThemeData _build(AppColors colors, String font) => ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.dark,
    fontFamily: font,
    colorScheme: ColorScheme.dark(
      primary: colors.primary,
      onPrimary: Colors.white,
    ),
    extensions: [colors],
    scaffoldBackgroundColor: Colors.black,
    cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
      primaryColor: Colors.white,
      primaryContrastingColor: colors.primary,
      barBackgroundColor: colors.panel,
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
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colors.panel,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colors.panel,
    ),
    chipTheme: ChipThemeData(
      labelPadding: const EdgeInsets.symmetric(horizontal: 11),
      backgroundColor: colors.chip,
      selectedColor: colors.accent,
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
    tooltipTheme: TooltipThemeData(
      decoration: _tooltipBox(colors.surface),
      textStyle: tooltipTextStyle,
      padding: tooltipPadding,
      waitDuration: tooltipDelay,
    ),
  );

  static ThemeData _tv(ThemeData base, AppColors colors) => base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF121212),
    visualDensity: VisualDensity.standard,
    focusColor: Colors.white24,
    splashFactory: NoSplash.splashFactory,
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      contentTextStyle: const TextStyle(fontSize: 16, color: Colors.white),
    ),
    textButtonTheme: TextButtonThemeData(
      style:
          TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? Colors.white
                  : Colors.white10,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? Colors.black
                  : Colors.white,
            ),
          ),
    ),
  );
}

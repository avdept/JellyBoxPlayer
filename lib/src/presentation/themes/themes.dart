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

  static const _tooltipText = TextStyle(fontSize: 13, height: 1.2);

  static TextStyle tooltipTextStyle(BuildContext context) =>
      _tooltipText.copyWith(color: AppColors.from(context).text);

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

  static ThemeData _build(AppColors colors, String font) {
    final light = colors.isLight;
    final background = light ? colors.surface : Colors.black;
    final base = ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      brightness: colors.brightness,
      fontFamily: font,
      colorScheme: light
          ? ColorScheme.light(
              primary: colors.primary,
              onPrimary: colors.text,
              surface: colors.surfaceRaised,
              onSurface: colors.text,
            )
          : ColorScheme.dark(
              primary: colors.primary,
              onPrimary: Colors.white,
            ),
      extensions: [colors],
      scaffoldBackgroundColor: background,
      iconTheme: light ? IconThemeData(color: colors.text) : null,
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        primaryColor: colors.text,
        primaryContrastingColor: colors.primary,
        barBackgroundColor: colors.panel,
        scaffoldBackgroundColor: background,
        textTheme: light
            ? CupertinoTextThemeData(primaryColor: colors.text)
            : null,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Colors.black87,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        overlayColor: Colors.transparent,
        thumbColor: light ? colors.text : Colors.white,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStatePropertyAll(colors.onPrimaryFill),
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
          foregroundColor: colors.text,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: _tooltipBox(colors.surface),
        textStyle: _tooltipText.copyWith(color: colors.text),
        padding: tooltipPadding,
        waitDuration: tooltipDelay,
      ),
    );
    if (!light) return base;
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: colors.text,
        displayColor: colors.text,
      ),
    );
  }

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

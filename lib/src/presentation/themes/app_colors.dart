import 'package:flutter/material.dart';
import 'package:jplayer/src/core/enums/enums.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.accent,
    required this.panel,
    required this.surface,
    required this.surfaceRaised,
    required this.chip,
    required this.indicator,
  });

  factory AppColors.of(ColorTheme theme) => switch (theme) {
    ColorTheme.oxblood => oxblood,
    ColorTheme.midnightBrass => midnightBrass,
    ColorTheme.champagne => champagne,
    ColorTheme.racingGreen => racingGreen,
    ColorTheme.copperNoir => copperNoir,
    ColorTheme.plumVelvet => plumVelvet,
    ColorTheme.inkAndIce => inkAndIce,
    ColorTheme.original => original,
  };

  static AppColors from(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? oxblood;

  static const oxblood = AppColors(
    primary: Color(0xFFC9505C),
    accent: Color(0xFF8C2D39),
    panel: Color(0xFF2A1418),
    surface: Color(0xFF161012),
    surfaceRaised: Color(0xFF21171A),
    chip: Color(0xFF2F2023),
    indicator: Color(0xFF3B1A20),
  );

  static const midnightBrass = AppColors(
    primary: Color(0xFFC9A86A),
    accent: Color(0xFF2C4876),
    panel: Color(0xFF141A28),
    surface: Color(0xFF0D1119),
    surfaceRaised: Color(0xFF161C29),
    chip: Color(0xFF212A3B),
    indicator: Color(0xFF2A2416),
  );

  static const champagne = AppColors(
    primary: Color(0xFFD6C2A1),
    accent: Color(0xFF7A6448),
    panel: Color(0xFF1D1D1F),
    surface: Color(0xFF121213),
    surfaceRaised: Color(0xFF1A1A1C),
    chip: Color(0xFF2A2A2C),
    indicator: Color(0xFF2A251D),
  );

  static const racingGreen = AppColors(
    primary: Color(0xFF86BC9E),
    accent: Color(0xFF1F5C45),
    panel: Color(0xFF11201A),
    surface: Color(0xFF0C1310),
    surfaceRaised: Color(0xFF141E19),
    chip: Color(0xFF1E2B24),
    indicator: Color(0xFF183026),
  );

  static const copperNoir = AppColors(
    primary: Color(0xFFD08A5B),
    accent: Color(0xFF8A4A2C),
    panel: Color(0xFF21160F),
    surface: Color(0xFF120E0B),
    surfaceRaised: Color(0xFF1C1612),
    chip: Color(0xFF2B211A),
    indicator: Color(0xFF33200F),
  );

  static const plumVelvet = AppColors(
    primary: Color(0xFFB896D8),
    accent: Color(0xFF5B3B84),
    panel: Color(0xFF1F1629),
    surface: Color(0xFF120E17),
    surfaceRaised: Color(0xFF1B1522),
    chip: Color(0xFF2A2233),
    indicator: Color(0xFF2B1E3B),
  );

  static const inkAndIce = AppColors(
    primary: Color(0xFF9CC1E0),
    accent: Color(0xFF2F5D8A),
    panel: Color(0xFF101821),
    surface: Color(0xFF0A0F15),
    surfaceRaised: Color(0xFF131B25),
    chip: Color(0xFF1E2833),
    indicator: Color(0xFF16283A),
  );

  static const original = AppColors(
    primary: Color(0xFFFD2F2F),
    accent: Color(0xFF0066FF),
    panel: Color(0xFF471F27),
    surface: Color(0xFF1C1518),
    surfaceRaised: Color(0xFF2B1D23),
    chip: Color(0xFF362A30),
    indicator: Color(0xFF341010),
  );

  final Color primary;
  final Color accent;
  final Color panel;
  final Color surface;
  final Color surfaceRaised;
  final Color chip;
  final Color indicator;

  Color get onPrimaryFill =>
      ThemeData.estimateBrightnessForColor(primary) == Brightness.light
      ? const Color(0xFF141414)
      : Colors.white;

  @override
  AppColors copyWith({
    Color? primary,
    Color? accent,
    Color? panel,
    Color? surface,
    Color? surfaceRaised,
    Color? chip,
    Color? indicator,
  }) => AppColors(
    primary: primary ?? this.primary,
    accent: accent ?? this.accent,
    panel: panel ?? this.panel,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    chip: chip ?? this.chip,
    indicator: indicator ?? this.indicator,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      indicator: Color.lerp(indicator, other.indicator, t)!,
    );
  }
}

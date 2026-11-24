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
    this.brightness = Brightness.dark,
    this.text = Colors.white,
    this.sheet = const Color(0xFF212121),
    this.sheetAlt = const Color(0xFF424242),
    this.banner = const Color(0xFF383A3F),
    this.card = const Color(0xFF2A2A2E),
    this.field = fieldFill,
    this.onField = onFieldFill,
    this.muted = const Color(0xFF9E9E9E),
    this.scrim = const Color(0x59000000),
    this.onScrim = const Color(0xFFFFFFFF),
    this.track = const Color(0xFFE0E0E0),
    this.trackBuffered = const Color(0xFFFFFFFF),
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
    ColorTheme.leica => leica,
    ColorTheme.classicBlue => classicBlue,
    ColorTheme.hermes => hermes,
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

  static const leica = AppColors(
    primary: Color(0xFFE2001A),
    accent: Color(0xFF141414),
    panel: Color(0xFFFFFFFF),
    surface: Color(0xFFF4F4F5),
    surfaceRaised: Color(0xFFFFFFFF),
    chip: Color(0xFFE6E6E8),
    indicator: Color(0xFFFBDBDF),
    brightness: Brightness.light,
    text: Color(0xFF141414),
    sheet: Color(0xFFFFFFFF),
    sheetAlt: Color(0xFFFFFFFF),
    banner: Color(0xFFE6E6E8),
    card: Color(0xFFFFFFFF),
    field: Color(0xFFE6E6E8),
    onField: Color(0xFF141414),
    muted: Color(0xFF8A8A8E),
    track: Color(0x26141414),
    trackBuffered: Color(0x73141414),
  );

  static const classicBlue = AppColors(
    primary: Color(0xFF0F4C81),
    accent: Color(0xFF0F4C81),
    panel: Color(0xFFEEF0F3),
    surface: Color(0xFFF7F8FA),
    surfaceRaised: Color(0xFFFFFFFF),
    chip: Color(0xFFE3E6EA),
    indicator: Color(0xFFCFD9E3),
    brightness: Brightness.light,
    text: Color(0xFF14202C),
    sheet: Color(0xFFFFFFFF),
    sheetAlt: Color(0xFFFFFFFF),
    banner: Color(0xFFE3E6EA),
    card: Color(0xFFFFFFFF),
    field: Color(0xFFE3E6EA),
    onField: Color(0xFF14202C),
    muted: Color(0xFF8A9199),
    track: Color(0x2614202C),
    trackBuffered: Color(0x7314202C),
  );

  static const hermes = AppColors(
    primary: Color(0xFFB84A16),
    accent: Color(0xFFE8601C),
    panel: Color(0xFFEDE3D2),
    surface: Color(0xFFF6F0E6),
    surfaceRaised: Color(0xFFFBF7F0),
    chip: Color(0xFFE9DFCE),
    indicator: Color(0xFFE6CEB8),
    brightness: Brightness.light,
    text: Color(0xFF3B2416),
    sheet: Color(0xFFFBF7F0),
    sheetAlt: Color(0xFFFBF7F0),
    banner: Color(0xFFE9DFCE),
    card: Color(0xFFFBF7F0),
    field: Color(0xFFE9DFCE),
    onField: Color(0xFF3B2416),
    muted: Color(0xFF9A8878),
    track: Color(0x263B2416),
    trackBuffered: Color(0x733B2416),
  );

  final Color primary;
  final Color accent;
  final Color panel;
  final Color surface;
  final Color surfaceRaised;
  final Color chip;
  final Color indicator;
  final Brightness brightness;
  final Color text;
  final Color sheet;
  final Color sheetAlt;
  final Color banner;
  final Color card;
  final Color field;
  final Color onField;
  final Color muted;
  final Color scrim;
  final Color onScrim;
  final Color track;
  final Color trackBuffered;

  bool get isLight => brightness == Brightness.light;

  Color get artist => isLight ? text : primary;

  Color coverTint(Color cover) => isLight
      ? Color.lerp(surface, cover, 0.35)!
      : Color.lerp(Colors.black, cover, 0.5)!;

  static const fieldFill = Color(0xFFEEEEEE);
  static const onFieldFill = Color(0xDD000000);
  static const onFieldHint = Color(0x8A000000);

  static const _darkText = Color(0xFF141414);

  Color get onPrimaryFill => readableOn(primary);

  Color get onAccent => readableOn(accent);

  Color get secondaryText => text.withValues(alpha: isLight ? 0.7 : 0.51);

  Color subtle(double alpha) =>
      text.withValues(alpha: isLight ? alpha * 0.5 : alpha);

  static Color readableOn(Color fill) {
    final luminance = fill.computeLuminance();
    final onWhite = 1.05 / (luminance + 0.05);
    final onDark = (luminance + 0.05) / (_darkText.computeLuminance() + 0.05);
    return onDark > onWhite ? _darkText : Colors.white;
  }

  Color get tint => Color.alphaBlend(primary.withValues(alpha: 0.18), panel);

  @override
  AppColors copyWith({
    Color? primary,
    Color? accent,
    Color? panel,
    Color? surface,
    Color? surfaceRaised,
    Color? chip,
    Color? indicator,
    Brightness? brightness,
    Color? text,
    Color? sheet,
    Color? sheetAlt,
    Color? banner,
    Color? card,
    Color? field,
    Color? onField,
    Color? muted,
    Color? scrim,
    Color? onScrim,
    Color? track,
    Color? trackBuffered,
  }) => AppColors(
    primary: primary ?? this.primary,
    accent: accent ?? this.accent,
    panel: panel ?? this.panel,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    chip: chip ?? this.chip,
    indicator: indicator ?? this.indicator,
    brightness: brightness ?? this.brightness,
    text: text ?? this.text,
    sheet: sheet ?? this.sheet,
    sheetAlt: sheetAlt ?? this.sheetAlt,
    banner: banner ?? this.banner,
    card: card ?? this.card,
    field: field ?? this.field,
    onField: onField ?? this.onField,
    muted: muted ?? this.muted,
    scrim: scrim ?? this.scrim,
    onScrim: onScrim ?? this.onScrim,
    track: track ?? this.track,
    trackBuffered: trackBuffered ?? this.trackBuffered,
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
      brightness: t < 0.5 ? brightness : other.brightness,
      text: Color.lerp(text, other.text, t)!,
      sheet: Color.lerp(sheet, other.sheet, t)!,
      sheetAlt: Color.lerp(sheetAlt, other.sheetAlt, t)!,
      banner: Color.lerp(banner, other.banner, t)!,
      card: Color.lerp(card, other.card, t)!,
      field: Color.lerp(field, other.field, t)!,
      onField: Color.lerp(onField, other.onField, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      onScrim: Color.lerp(onScrim, other.onScrim, t)!,
      track: Color.lerp(track, other.track, t)!,
      trackBuffered: Color.lerp(trackBuffered, other.trackBuffered, t)!,
    );
  }
}

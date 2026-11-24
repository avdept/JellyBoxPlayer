import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final theme in ColorTheme.values) {
    group(theme.name, () {
      final colors = AppColors.of(theme);

      test('text on a primary fill is readable', () {
        expect(
          _contrast(colors.onPrimaryFill, colors.primary),
          greaterThanOrEqualTo(4),
        );
      });

      test('text on the accent is readable', () {
        expect(
          _contrast(colors.onAccent, colors.accent),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('text on the tint is readable', () {
        expect(
          _contrast(colors.text, colors.tint),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('text on the background and panels is readable', () {
        for (final surface in [
          colors.surface,
          colors.surfaceRaised,
          colors.panel,
          colors.chip,
        ]) {
          expect(_contrast(colors.text, surface), greaterThanOrEqualTo(4.5));
        }
      });

      test('secondary text on the background is readable', () {
        final background = colors.isLight ? colors.surface : colors.panel;
        expect(
          _contrast(
            Color.alphaBlend(colors.secondaryText, background),
            background,
          ),
          greaterThanOrEqualTo(4.5),
        );
      });

      test('primary text on the background is readable', () {
        expect(
          _contrast(
            colors.primary,
            colors.isLight ? colors.surface : colors.panel,
          ),
          greaterThanOrEqualTo(3),
        );
      });

      test('primary icons on the tint stand out', () {
        expect(
          _contrast(colors.primary, colors.tint),
          greaterThanOrEqualTo(3),
        );
      });
    });
  }
}

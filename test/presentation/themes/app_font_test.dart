import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/presentation/themes/themes.dart';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  for (final font in AppFont.values) {
    test('- $font is bundled with every weight the app uses', () {
      final family = Themes.fontFamily(font);
      final block = RegExp(
        '- family: $family\\n((?:        .*\\n|      fonts:\\n)+)',
      ).firstMatch(pubspec);

      expect(block, isNotNull, reason: '$family missing from pubspec.yaml');
      final assets = RegExp(
        r'asset: (\S+)\n\s+weight: (\d+)',
      ).allMatches(block!.group(1)!).toList();
      final weights = {for (final a in assets) int.parse(a.group(2)!)};

      expect(weights, containsAll([400, 500, 600, 700]));
      for (final a in assets) {
        expect(File(a.group(1)!).existsSync(), isTrue, reason: a.group(1));
      }
    });
  }
}

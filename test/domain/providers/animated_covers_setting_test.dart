import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/shared_preferences_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/animated_cover_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/providers/network_type_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider_container.dart';

class _FixedNetwork extends NetworkTypeNotifier {
  _FixedNetwork(NetworkType type) : super(hasCellular: false) {
    state = type;
  }
}

void main() {
  Future<AppSettingsNotifier> notifierWith(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    return AppSettingsNotifier(await SharedPreferences.getInstance());
  }

  group('animatedCoversProvider', () {
    test('- defaults to always', () async {
      final notifier = await notifierWith({});
      final container = createProviderContainer(
        overrides: [appSettingsProvider.overrideWith((_) => notifier)],
      );

      expect(container.read(animatedCoversProvider), AnimatedCovers.always);
    });

    test('- maps the legacy checkbox to Wi-Fi only', () async {
      final notifier = await notifierWith({
        'app_settings': jsonEncode({'animated_covers': true}),
      });
      final container = createProviderContainer(
        overrides: [appSettingsProvider.overrideWith((_) => notifier)],
      );

      expect(container.read(animatedCoversProvider), AnimatedCovers.wifi);
    });

    test('- reads the stored choice', () async {
      final notifier = await notifierWith({
        'app_settings': jsonEncode({'animated_covers': 'never'}),
      });
      final container = createProviderContainer(
        overrides: [appSettingsProvider.overrideWith((_) => notifier)],
      );

      expect(container.read(animatedCoversProvider), AnimatedCovers.never);
    });
  });

  group('animatedCoversAllowedProvider', () {
    bool allowedFor(AnimatedCovers choice, NetworkType network) =>
        createProviderContainer(
          overrides: [
            animatedCoversProvider.overrideWithValue(choice),
            networkTypeProvider.overrideWith((_) => _FixedNetwork(network)),
          ],
        ).read(animatedCoversAllowedProvider);

    test('- always plays on any network', () {
      expect(allowedFor(AnimatedCovers.always, NetworkType.cellular), isTrue);
      expect(allowedFor(AnimatedCovers.always, NetworkType.wifi), isTrue);
    });

    test('- wifi plays on Wi-Fi only', () {
      expect(allowedFor(AnimatedCovers.wifi, NetworkType.wifi), isTrue);
      expect(allowedFor(AnimatedCovers.wifi, NetworkType.cellular), isFalse);
    });

    test('- never blocks everywhere', () {
      expect(allowedFor(AnimatedCovers.never, NetworkType.wifi), isFalse);
      expect(allowedFor(AnimatedCovers.never, NetworkType.cellular), isFalse);
    });
  });

  group('desktopAnimatedCoverProvider', () {
    final cover = Uri.parse('https://example.com/cover.m3u8');
    const album = LibraryItem(
      id: 'a1',
      name: 'Album',
      kind: ItemKind.album,
      albumArtist: 'Artist',
    );

    Future<Uri?> lookup({required bool desktop}) => createProviderContainer(
      overrides: [
        settingProvider(
          AppSetting.desktopAnimatedCovers,
        ).overrideWithValue(desktop),
        animatedCoversProvider.overrideWithValue(AnimatedCovers.never),
        animatedCoverSearchProvider.overrideWith((_, _) async => cover),
      ],
    ).read(desktopAnimatedCoverProvider(album).future);

    test('- ignores the mobile choice when enabled', () async {
      expect(await lookup(desktop: true), cover);
    });

    test('- returns nothing when disabled', () async {
      expect(await lookup(desktop: false), isNull);
    });
  });
}

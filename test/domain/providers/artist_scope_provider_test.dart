import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/artist_scope_provider.dart';

import '../../provider_container.dart';

void main() {
  ProviderContainer containerWith({
    required Set<ArtistScope> supported,
    ArtistScope? selected,
  }) => createProviderContainer(
    overrides: [
      serverCapabilitiesProvider.overrideWithValue(
        MediaServerCapabilities(artistScopes: supported),
      ),
      if (selected != null)
        artistBrowseScopeProvider.overrideWithValue(selected),
    ],
  );

  group('effectiveArtistScopeProvider', () {
    test('- honours the stored scope when the server supports it', () {
      final container = containerWith(
        supported: {ArtistScope.albumArtists, ArtistScope.allArtists},
        selected: ArtistScope.allArtists,
      );

      expect(
        container.read(effectiveArtistScopeProvider),
        ArtistScope.allArtists,
      );
    });

    test('- falls back to a supported scope on a server without it', () {
      final container = containerWith(
        supported: {ArtistScope.albumArtists},
        selected: ArtistScope.allArtists,
      );

      expect(
        container.read(effectiveArtistScopeProvider),
        ArtistScope.albumArtists,
      );
    });

    test('- defaults to album artists when nothing is advertised', () {
      final container = containerWith(
        supported: const {},
        selected: ArtistScope.allArtists,
      );

      expect(
        container.read(effectiveArtistScopeProvider),
        ArtistScope.albumArtists,
      );
    });

    test('- browses the unfiltered artist list by default', () {
      final container = containerWith(
        supported: {ArtistScope.albumArtists, ArtistScope.allArtists},
      );

      expect(
        container.read(effectiveArtistScopeProvider),
        ArtistScope.allArtists,
      );
    });
  });
}

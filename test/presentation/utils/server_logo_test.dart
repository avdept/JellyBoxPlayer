import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/backend/server_type.dart';
import 'package:jplayer/src/presentation/utils/server_logo.dart';

void main() {
  group('serverLogoAsset', () {
    test('- badges a Navidrome server with its own logo', () {
      expect(
        serverLogoAsset(ServerType.subsonic, productName: 'navidrome'),
        SvgPictures.navidromeLogo,
      );
    });

    test('- keeps the Navidrome logo when its Jellyfin api is the '
        'one in use', () {
      expect(
        serverLogoAsset(ServerType.jellyfin, productName: 'navidrome'),
        SvgPictures.navidromeLogo,
      );
    });

    test('- badges a real Jellyfin server with the Jellyfin logo', () {
      expect(
        serverLogoAsset(ServerType.jellyfin, productName: 'Jellyfin Server'),
        SvgPictures.jellyfinLogo,
      );
    });

    test('- falls back to the plain Subsonic logo for an unknown '
        'flavour', () {
      expect(
        serverLogoAsset(ServerType.subsonic, productName: 'gonic'),
        SvgPictures.subsonicLogo,
      );
    });

    test('- falls back to the server type when no product is known', () {
      expect(serverLogoAsset(ServerType.emby), SvgPictures.embyLogo);
    });
  });
}

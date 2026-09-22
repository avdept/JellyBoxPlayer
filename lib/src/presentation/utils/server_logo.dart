import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/backend/server_type.dart';

const _flavourLogos = <String, String>{
  'navidrome': SvgPictures.navidromeLogo,
};

String serverLogoAsset(ServerType serverType, {String? productName}) {
  final flavour = productName?.trim().toLowerCase() ?? '';
  for (final entry in _flavourLogos.entries) {
    if (flavour.startsWith(entry.key)) return entry.value;
  }

  switch (serverType) {
    case ServerType.jellyfin:
      return SvgPictures.jellyfinLogo;
    case ServerType.emby:
      return SvgPictures.embyLogo;
    case ServerType.subsonic:
      return SvgPictures.subsonicLogo;
  }
}

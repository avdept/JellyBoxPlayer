import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class ServerLogoPicture extends StatefulWidget {
  const ServerLogoPicture({required this.asset, this.size, super.key});

  final String asset;
  final double? size;

  @override
  State<ServerLogoPicture> createState() => _ServerLogoPictureState();
}

class _ServerLogoPictureState extends State<ServerLogoPicture>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logo = SvgPicture.asset(
      widget.asset,
      width: widget.size,
      height: widget.size,
    );
    final spinning = widget.asset == SvgPictures.navidromeLogo;
    if (spinning && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!spinning && _spin.isAnimating) {
      _spin.stop();
    }
    if (!spinning) return logo;
    return RotationTransition(turns: _spin, child: logo);
  }
}

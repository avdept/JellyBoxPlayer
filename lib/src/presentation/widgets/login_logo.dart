import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/services/server_probe_service.dart';

class LoginLogo extends StatefulWidget {
  const LoginLogo({
    this.serverType,
    this.size = 160,
    this.pairedSize = 100,
    this.overlapFraction = 0.5,
    super.key,
  });

  final ServerType? serverType;
  final double size;
  final double pairedSize;
  final double overlapFraction;

  @override
  State<LoginLogo> createState() => _LoginLogoState();
}

class _LoginLogoState extends State<LoginLogo> {
  static const _duration = Duration(milliseconds: 520);
  static const _badgeEntryOffset = 28.0;
  static const _badgeFadeStart = 0.25;

  ServerType? _lastServerType;

  @override
  void initState() {
    super.initState();
    _lastServerType = widget.serverType;
  }

  @override
  void didUpdateWidget(LoginLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.serverType != null) _lastServerType = widget.serverType;
  }

  double get _overlap => widget.pairedSize * widget.overlapFraction;

  double get _pairExtent => widget.pairedSize * 2 - _overlap;

  double get _boxSize => max(widget.size, _pairExtent);

  @override
  Widget build(BuildContext context) {
    final inset = (_boxSize - _pairExtent) / 2;
    final idleOffset = (_boxSize - widget.size) / 2;
    final logoFrom = Rect.fromLTWH(
      idleOffset,
      idleOffset,
      widget.size,
      widget.size,
    );
    final logoTo = Rect.fromLTWH(
      inset,
      inset,
      widget.pairedSize,
      widget.pairedSize,
    );
    final badgeStart = inset + widget.pairedSize - _overlap;
    final badgeTo = Rect.fromLTWH(
      badgeStart,
      badgeStart,
      widget.pairedSize,
      widget.pairedSize,
    );
    final badgeFrom = badgeTo.translate(_badgeEntryOffset, _badgeEntryOffset);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: widget.serverType == null ? 0 : 1),
      duration: _duration,
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => SizedBox.square(
        dimension: _boxSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fromRect(
              rect: Rect.lerp(logoFrom, logoTo, progress)!,
              child: _logo(SvgPictures.jellyboxLogo),
            ),
            Positioned.fromRect(
              rect: Rect.lerp(badgeFrom, badgeTo, progress)!,
              child: Opacity(
                opacity: _badgeOpacity(progress),
                child: _serverBadge(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _badgeOpacity(double progress) =>
      ((progress - _badgeFadeStart) / (1 - _badgeFadeStart)).clamp(0.0, 1.0);

  Widget _serverBadge() {
    final serverType = _lastServerType;
    if (serverType == null) return const SizedBox.shrink();
    return _logo(_badgeAsset(serverType));
  }

  String _badgeAsset(ServerType serverType) => switch (serverType) {
    ServerType.jellyfin => SvgPictures.jellyfinLogo,
    ServerType.emby => SvgPictures.embyLogo,
  };

  Widget _logo(String asset) => SvgPicture.asset(asset);
}

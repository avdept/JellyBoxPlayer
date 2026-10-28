import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:optional_features/catalog.dart';
import 'package:jplayer/src/presentation/widgets/album_view.dart';
import 'package:jplayer/src/presentation/widgets/catalog_actions.dart';
import 'package:jplayer/src/presentation/widgets/catalog_source_badge.dart';

class CatalogAlbumCard extends StatefulWidget {
  const CatalogAlbumCard({
    required this.album,
    this.onTap,
    this.subtitle,
    this.muted = false,
    super.key,
  });

  final CatalogAlbum album;
  final VoidCallback? onTap;
  final String? subtitle;
  final bool muted;

  @override
  State<CatalogAlbumCard> createState() => _CatalogAlbumCardState();
}

class _CatalogAlbumCardState extends State<CatalogAlbumCard> {
  static const _identity = <double>[
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  static const _greyscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final subtitle =
        widget.subtitle ?? widget.album.releaseDate?.year.toString() ?? '';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.04 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: CatalogContextMenuRegion(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AlbumView.coverTextSpacing,
            children: [
              Flexible(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: widget.muted ? _mutedCover() : _cover(),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.album.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      color: Color.fromARGB(130, 255, 255, 255),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cover() {
    final cover = widget.album.coverUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: cover == null
          ? Image.asset(Images.album, fit: BoxFit.cover)
          : Image(
              image: CachedNetworkImageProvider(cover),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset(Images.album, fit: BoxFit.cover),
            ),
    );
  }

  Widget _mutedCover() => Stack(
    fit: StackFit.expand,
    children: [
      TweenAnimationBuilder<double>(
        tween: Tween(end: _hovered ? 1 : 0),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: _cover(),
        builder: (context, colour, child) => ColorFiltered(
          colorFilter: ColorFilter.matrix([
            for (var i = 0; i < _identity.length; i++)
              _greyscale[i] + (_identity[i] - _greyscale[i]) * colour,
          ]),
          child: child,
        ),
      ),
      Positioned(
        top: 8,
        right: 8,
        child: CatalogSourceBadge(source: widget.album.source, size: 24),
      ),
    ],
  );
}

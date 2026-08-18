import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

class AlbumView extends ConsumerStatefulWidget {
  const AlbumView({
    required this.album,
    this.onTap,
    this.onPlayPressed,
    this.optionsBuilder,
    this.mainTextStyle,
    this.subTextStyle,
    this.showArtist = true,
    this.subtitle,
    this.trailing,
    this.alignTextStart = false,
    this.coverOverride,
    super.key,
  });

  static const coverTextSpacing = 6.0;

  final LibraryItem album;
  final bool showArtist;
  final void Function(LibraryItem)? onTap;
  final Future<void> Function(LibraryItem)? onPlayPressed;
  final List<PopupMenuEntry<void>> Function(BuildContext)? optionsBuilder;
  final TextStyle? mainTextStyle;
  final TextStyle? subTextStyle;

  final String? subtitle;

  final Widget? trailing;
  final bool alignTextStart;

  final Widget? coverOverride;

  @override
  ConsumerState<AlbumView> createState() => _AlbumViewState();
}

class _AlbumViewState extends ConsumerState<AlbumView> {
  var _isHovered = false;
  var _isPlayHovered = false;
  var _isPlayLoading = false;

  ImageProvider get _libraryImage {
    final downloadedCover = DownloadPaths.coverFile(widget.album.id);
    if (downloadedCover != null) return FileImage(downloadedCover);

    final tag = widget.album.images.primary;
    if (tag == null) return const AssetImage(Images.album);

    return CachedNetworkImageProvider(
      ref.read(imageServiceProvider).imagePath(tagId: tag, id: widget.album.id),
    );
  }

  String get _subtitleText =>
      widget.subtitle ??
      (widget.showArtist ? (widget.album.albumArtist ?? '') : '');

  Future<void> _onPlayPressed() async {
    final onPlayPressed = widget.onPlayPressed;
    if (onPlayPressed == null || _isPlayLoading) return;
    setState(() => _isPlayLoading = true);
    try {
      await onPlayPressed(widget.album);
    } finally {
      if (mounted) setState(() => _isPlayLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isTablet = deviceType == DeviceScreenType.tablet;

    final card = GestureDetector(
      onTap: (widget.onTap != null)
          ? () => widget.onTap!.call(widget.album)
          : null,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: widget.alignTextStart
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        spacing: AlbumView.coverTextSpacing,
        children: [
          Flexible(
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.coverOverride ??
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: _libraryImage,
                          ),
                        ),
                      ),
                  if (widget.optionsBuilder != null)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: PopupMenuButton<void>(
                        icon: const Icon(Icons.more_vert),
                        tooltip: 'More',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black45,
                        ),
                        itemBuilder: widget.optionsBuilder!,
                      ),
                    ),
                  if (widget.onPlayPressed != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _playButton(isTablet ? 48 : 40),
                    ),
                ],
              ),
            ),
          ),
          if (widget.trailing != null)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: widget.alignTextStart
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _titleText(isTablet: isTablet),
                      _subtitleWidget(isTablet: isTablet),
                    ],
                  ),
                ),
                widget.trailing!,
              ],
            )
          else
            Column(
              crossAxisAlignment: widget.alignTextStart
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _titleText(isTablet: isTablet),
                _subtitleWidget(isTablet: isTablet),
              ],
            ),
        ],
      ),
    );

    if (widget.onPlayPressed == null) return card;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPlayHovered = false;
      }),
      child: card,
    );
  }

  Widget _titleText({required bool isTablet}) => Text(
    widget.album.name,
    style: TextStyle(
      fontSize: isTablet ? 24 : 16,
      fontWeight: FontWeight.w500,
      height: 1.2,
      overflow: TextOverflow.ellipsis,
    ).merge(widget.mainTextStyle),
    maxLines: 1,
  );

  Widget _subtitleWidget({required bool isTablet}) => Text(
    _subtitleText,
    style: TextStyle(
      fontSize: isTablet ? 22 : 14,
      fontWeight: FontWeight.w400,
      height: 1.2,
      color: const Color.fromARGB(130, 255, 255, 255),
      overflow: TextOverflow.ellipsis,
    ).merge(widget.subTextStyle),
    maxLines: 1,
  );

  Widget _playButton(double size) {
    final isVisible = _isHovered || _isPlayLoading;

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: MouseRegion(
          onEnter: (_) => setState(() => _isPlayHovered = true),
          onExit: (_) => setState(() => _isPlayHovered = false),
          child: AnimatedScale(
            scale: _isPlayHovered ? 1.15 : 1,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: SizedBox.square(
              dimension: size,
              child: MaterialButton(
                onPressed: _isPlayLoading ? null : _onPlayPressed,
                color: const Color(0xFF0066FF),
                disabledColor: const Color(0xFF0066FF),
                shape: const CircleBorder(),
                padding: EdgeInsets.zero,
                elevation: _isPlayHovered ? 8 : 4,
                child: _isPlayLoading
                    ? SizedBox.square(
                        dimension: size * 0.4,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.play_arrow_outlined,
                        size: size * 0.65,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

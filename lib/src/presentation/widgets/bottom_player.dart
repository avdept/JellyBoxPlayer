import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/entypo_icons.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/player_bar_provider.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';
import 'package:jplayer/src/presentation/widgets/marquee_text.dart';
import 'package:jplayer/src/presentation/widgets/position_slider.dart';
import 'package:jplayer/src/presentation/widgets/remaining_duration.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:jplayer/src/presentation/widgets/volume_control.dart';
import 'package:responsive_builder/responsive_builder.dart';

const _sheetHorizontalPadding = 30.0;

class BottomPlayer extends ConsumerStatefulWidget {
  const BottomPlayer({super.key});

  @override
  ConsumerState<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends ConsumerState<BottomPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final _imageProvider = ValueNotifier<ImageProvider?>(null);
  final _dynamicColors = ValueNotifier<ColorScheme?>(null);
  final _isPlaying = ValueNotifier<bool>(false);
  final _queueShown = ValueNotifier<bool>(false);
  late ThemeData _theme;
  late MaterialLocalizations _localizations;
  late EdgeInsets _viewPadding;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isDesktop;
  late bool _isLandscape;

  Future<void> _onExpand() {
    if (_isMobile && _isLandscape) return Future<void>.value();
    final route = ModalSheetRoute<void>(
      builder: (context) => SafeArea(
        top: false,
        minimum: EdgeInsets.only(
          top: _isMobile ? 0 : 20,
          bottom: _isMobile ? 20 : 60,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 518),
          child: ValueListenableBuilder(
            valueListenable: _dynamicColors,
            builder: (context, colorScheme, child) => Theme(
              data: Theme.of(context).copyWith(colorScheme: colorScheme),
              child: Consumer(
                builder: (context, ref, _) {
                  final coveredByLandscapePlayer =
                      _isMobile &&
                      MediaQuery.orientationOf(context) ==
                          Orientation.landscape;
                  if (coveredByLandscapePlayer ||
                      !ref.watch(barHasQueueProvider)) {
                    return const SizedBox.shrink();
                  }
                  final currentSong = ref.watch(barMediaItemProvider);
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      _sheetHeader(context),
                      Expanded(
                        child: ValueListenableBuilder<bool>(
                          valueListenable: _queueShown,
                          builder: (context, showQueue, _) => FlipPanel(
                            side: showQueue ? FlipSide.right : FlipSide.front,
                            front: Column(
                              children: [
                                Expanded(child: _artworkArea()),
                                _sheetDetails(context, currentSong),
                              ],
                            ),
                            right: const NowPlayingQueueView(),
                          ),
                        ),
                      ),
                      _extraControls(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      containerBuilder: (context, animation, child) => LayoutBuilder(
        builder: (context, constraints) => ValueListenableBuilder(
          valueListenable: _dynamicColors,
          builder: (context, colorScheme, child) => BottomSheet(
            animationController: _animationController,
            onClosing: () {},
            enableDrag: false,
            showDragHandle: false,
            backgroundColor: colorScheme?.background,
            constraints: BoxConstraints(
              maxHeight: constraints.maxHeight * 0.92,
              minWidth: constraints.maxWidth,
            ),
            builder: (context) => child!,
          ),
          child: child,
        ),
      ),
      bounce: true,
      expanded: true,
      barrierLabel: _localizations.modalBarrierDismissLabel,
      duration: const Duration(milliseconds: 300),
    );
    return Navigator.of(
      context,
      rootNavigator: true,
    ).push(route).whenComplete(_onSheetClosed);
  }

  void _onSheetClosed() {
    _queueShown.value = false;
    if (mounted) ref.read(lyricsVisibleProvider.notifier).state = false;
  }

  Widget _artworkArea() => Consumer(
    builder: (context, ref, child) => AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: ref.watch(lyricsShownProvider)
          ? const Padding(
              key: ValueKey('lyrics'),
              padding: EdgeInsets.symmetric(
                horizontal: _sheetHorizontalPadding,
              ),
              child: LyricsView(),
            )
          : child,
    ),
    child: ValueListenableBuilder<bool>(
      key: const ValueKey('artwork'),
      valueListenable: _isPlaying,
      builder: (context, isPlaying, child) => SwipeableArtwork(
        queue: ref.watch(barMediaQueueProvider),
        currentIndex: ref.watch(barQueueIndexProvider),
        borderRadius: _isMobile ? 12 : 16,
        artworkBuilder: _artwork,
        horizontalPadding: _sheetHorizontalPadding,
        scale: isPlaying ? 1 : 0.82,
      ),
    ),
  );

  Widget _sheetHeader(BuildContext context) => SizedBox(
    height: kMinInteractiveDimension,
    child: Center(
      child: Container(
        width: 113,
        height: 10,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    ),
  );

  Widget _queueButton() => ValueListenableBuilder<bool>(
    valueListenable: _queueShown,
    builder: (context, isShown, _) => IconButton(
      onPressed: () => _queueShown.value = !isShown,
      color: _theme.colorScheme.onPrimary,
      iconSize: _isMobile ? 26 : 24,
      tooltip: isShown ? 'Hide queue' : 'Queue',
      icon: const Icon(Icons.queue_music),
      selectedIcon: Icon(
        Icons.queue_music,
        color: _theme.colorScheme.primary,
      ),
      isSelected: isShown,
    ),
  );

  Widget _sheetDetails(BuildContext context, MediaItem? currentSong) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: _sheetHorizontalPadding),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: _isMobile ? 24 : 32),
        Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentSong?.title ?? '',
                    style: TextStyle(
                      fontSize: _isMobile ? 24 : 32,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  ClickableWidget(
                    onPressed: currentSong?.extras?['artistId'] != null
                        ? () async {
                            final artistId =
                                currentSong!.extras!['artistId'] as String;
                            final item = await ref
                                .read(mediaServerClientProvider)
                                .getItem(artistId, kind: ItemKind.artist);
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            context.goNamed(
                              Routes.artist.name,
                              extra: {'artist': item},
                            );
                          }
                        : null,
                    textStyle: TextStyle(
                      fontSize: _isMobile ? 16 : 20,
                      height: 1.2,
                      color: _theme.colorScheme.primary,
                    ),
                    child: Text(
                      currentSong?.artist ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Consumer(
              builder: (context, ref, _) {
                final isLoaded = ref.watch(barSongProvider) != null;
                if (!isLoaded) return const SizedBox.shrink();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    _moreButton(currentSong),
                  ],
                );
              },
            ),
          ],
        ),
        SizedBox(height: _isMobile ? 12 : 20),
        const PositionSlider.bar(),
        PositionLabels.bar(fontSize: _isMobile ? 12 : 13),
        SizedBox(height: _isMobile ? 8 : 12),
        AudioQualityBadge.heard(currentSong?.extras),
        SizedBox(height: _isMobile ? 12 : 24),
        IconTheme.merge(
          data: IconThemeData(size: _isMobile ? 40 : 44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _secondaryControl(_randomQueueButton()),
              _prevTrackButton(),
              SizedBox.square(
                dimension: 72,
                child: _playPauseButton(),
              ),
              _nextTrackButton(),
              _secondaryControl(_repeatTrackButton()),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _extraControls() => Padding(
    padding: EdgeInsets.only(
      left: _sheetHorizontalPadding,
      right: _sheetHorizontalPadding,
      top: _isMobile ? 24 : 32,
    ),
    child: IconTheme.merge(
      data: IconThemeData(size: _isMobile ? 26 : 24),
      child: Consumer(
        builder: (context, ref, _) {
          final playingElsewhere = ref.watch(playingElsewhereProvider);
          return Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _playbackTargetButton(showsDeviceName: true),
                ),
              ),
              _lyricsButton(),
              if (!_isMobile && !playingElsewhere) _downloadTrackButton(),
              _likeTrackButton(),
              _queueButton(),
            ],
          );
        },
      ),
    ),
  );

  Future<void> _onImageProviderChanged() async {
    final imageProvider = _imageProvider.value;

    if (imageProvider == null || !mounted) return;
    try {
      final colors = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: _theme.brightness,
      );
      if (mounted) _dynamicColors.value = colors;
    } on Object {
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = BottomSheet.createAnimationController(this);
    _imageProvider.addListener(_onImageProviderChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _imageProvider.value = const AssetImage(Images.songSample),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
    _localizations = MaterialLocalizations.of(context);
    _viewPadding = MediaQuery.viewPaddingOf(context);
    _screenSize = MediaQuery.sizeOf(context);

    _isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    final deviceType = getDeviceType(_screenSize);
    _isMobile = deviceType == DeviceScreenType.mobile;
    _isDesktop = deviceType == DeviceScreenType.desktop;
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(barPlayingProvider);
    if (_isPlaying.value != isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _isPlaying.value = isPlaying;
      });
    }
    return Consumer(
      builder: (context, ref, _) {
        final playingElsewhere = ref.watch(playingElsewhereProvider);
        final isEmpty = !ref.watch(barHasQueueProvider);
        final device = _isDesktop ? null : ref.watch(activeDeviceProvider);
        final currentSong = ref.watch(barMediaItemProvider);
        final image = ref
            .read(imageServiceProvider)
            .artworkImage(currentSong?.artUri);
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _imageProvider.value = image,
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
              child: isEmpty
                  ? const SizedBox(width: double.infinity)
                  : Container(
                      height: (_isMobile ? 69 : 92) + _viewPadding.bottom,
                      color: _theme.bottomSheetTheme.backgroundColor
                          ?.withOpacity(0.75),
                      padding: EdgeInsets.only(bottom: _viewPadding.bottom),
                      child: SimpleListTile(
                        onTap: !_isDesktop ? _onExpand : null,
                        padding: const EdgeInsets.only(right: 8),
                        leading: AspectRatio(
                          aspectRatio: 1,
                          child: _isDesktop
                              ? MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _goToCurrentAlbum,
                                    onSecondaryTapUp: (details) =>
                                        _showArtworkMenu(
                                          details.globalPosition,
                                        ),
                                    child: _artwork(currentSong),
                                  ),
                                )
                              : _artwork(currentSong),
                        ),
                        title: device != null
                            ? MarqueeText(
                                [
                                  if (currentSong?.artist?.isNotEmpty ?? false)
                                    currentSong!.artist!,
                                  currentSong?.title ?? '',
                                ].join(' — '),
                                bounce: true,
                                style: TextStyle(
                                  fontSize: _isMobile ? 16 : 22,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      currentSong?.title ?? '',
                                      style: TextStyle(
                                        fontSize: _isMobile ? 18 : 24,
                                        fontWeight: FontWeight.w500,
                                        height: 1.2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (_isDesktop) const SizedBox(width: 8),
                                  if (_isDesktop)
                                    AudioQualityBadge.heard(
                                      currentSong?.extras,
                                    ),
                                ],
                              ),
                        subtitle: device != null
                            ? _deviceLine(device)
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: ClickableWidget(
                                  onPressed:
                                      (_isDesktop &&
                                          currentSong?.extras?['artistId'] !=
                                              null)
                                      ? () async {
                                          final artistId =
                                              currentSong!.extras!['artistId']
                                                  as String;
                                          final item = await ref
                                              .read(mediaServerClientProvider)
                                              .getItem(
                                                artistId,
                                                kind: ItemKind.artist,
                                              );
                                          if (!context.mounted) return;
                                          context.goNamed(
                                            Routes.artist.name,
                                            extra: {'artist': item},
                                          );
                                        }
                                      : null,
                                  textStyle: TextStyle(
                                    fontSize: _isMobile ? 12 : 18,
                                    height: 1.2,
                                  ),
                                  child: Text(
                                    currentSong?.artist ?? '',
                                  ),
                                ),
                              ),
                        // Text(
                        //   currentSong?.displayDescription ?? '',
                        //   style: TextStyle(
                        //     fontSize: _isMobile ? 12 : 18,
                        //     height: 1.2,
                        //   ),
                        // ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (_isDesktop) const RemainingDuration(),
                            if (_isDesktop) _randomQueueButton(),
                            _prevTrackButton(),
                            SizedBox.square(
                              dimension: 45,
                              child: _playPauseButton(),
                            ),
                            _nextTrackButton(),
                            if (_isDesktop) _repeatTrackButton(),
                            if (_isDesktop) _lyricsButton(),
                            if (_isDesktop) const VolumeControl(size: 44),
                            if (_isDesktop) _playbackTargetButton(size: 44),
                            if (_isDesktop) _queueSidebarButton(),
                            if (!_isMobile && !playingElsewhere)
                              _studioModeButton(),
                          ],
                        ),
                        leadingToTitle: 15,
                      ),
                    ),
            ),
            if (!isEmpty)
              ValueListenableBuilder(
                valueListenable: _dynamicColors,
                builder: (context, colorScheme, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: colorScheme,
                  ),
                  child: const Positioned(
                    left: -25,
                    top: -22,
                    right: -25,
                    child: PositionSlider.bar(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _imageProvider.dispose();
    _dynamicColors.dispose();
    _isPlaying.dispose();
    _queueShown.dispose();
    super.dispose();
  }

  Widget _artwork(MediaItem? currentSong) {
    return SizedBox.expand(
      key: ValueKey(currentSong?.id),
      child: Image(
        image: ref.read(imageServiceProvider).artworkImage(currentSong?.artUri),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset(Images.album, fit: BoxFit.cover),
      ),
    );
  }

  Widget _moreButton(MediaItem? currentSong) => IconButton(
    onPressed: () => _onMorePressed(currentSong),
    color: _theme.colorScheme.onPrimary,
    iconSize: _isMobile ? 26 : 24,
    icon: const Icon(Icons.more_vert),
  );

  LibraryItem? get _currentQueueSong => ref.read(barSongProvider);

  Future<void> _onLikeCurrent(LibraryItem song) async {
    final saved = await ref.read(barControlsProvider).toggleFavourite(song);
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This action needs a connection')),
      );
    }
  }

  Future<void> _onMorePressed(MediaItem? currentSong) async {
    final song = _currentQueueSong;
    if (song == null) return;
    final actions = contextMenuActions(
      context,
      ref,
      song,
      scope: ContextMenuScope.nowPlaying,
      onLike: _onLikeCurrent,
    );
    await showContextMenuSheet(context, actions: actions);
  }

  void _showArtworkMenu(Offset position) {
    final song = _currentQueueSong;
    if (song == null) return;
    showContextMenu(
      context,
      position: position,
      actions: contextMenuActions(
        context,
        ref,
        song,
        scope: ContextMenuScope.nowPlaying,
        onLike: _onLikeCurrent,
      ),
    );
  }

  Future<void> _goToCurrentAlbum() async {
    final albumId = _currentQueueSong?.albumId;
    if (albumId == null) return;
    final item = await ref
        .read(mediaServerClientProvider)
        .getItem(albumId, kind: ItemKind.album);
    if (!mounted) return;
    ref.read(currentAlbumProvider.notifier).setAlbum(item);
    context.goNamed(Routes.album.name, extra: {'album': item});
  }

  Widget _deviceLine(ActiveDevice device) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Icon(
          device.icon,
          size: _isMobile ? 17 : 21,
          color: _theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            device.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _isMobile ? 14 : 20,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: _theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _playPauseButton() => PlayPauseButton(
    onPressed: ref.read(barControlsProvider).togglePlay,
    background: _theme.colorScheme.onPrimary,
    foreground: _theme.scaffoldBackgroundColor,
    stateNotifier: _isPlaying,
  );

  Widget _prevTrackButton() => IconButton(
    onPressed: ref.read(barControlsProvider).previous,
    color: _theme.colorScheme.onPrimary,
    icon: const Icon(Entypo.fast_backward),
  );

  Widget _nextTrackButton() => IconButton(
    onPressed: ref.read(barControlsProvider).next,
    color: _theme.colorScheme.onPrimary,
    icon: const Icon(Entypo.fast_forward),
  );

  Widget _queueSidebarButton() => Consumer(
    builder: (context, ref, _) {
      final isShown = ref.watch(queueSidebarVisibleProvider);
      return SizedBox.square(
        dimension: 44,
        child: IconButton(
          onPressed: () =>
              ref.read(queueSidebarVisibleProvider.notifier).state = !isShown,
          color: _theme.colorScheme.onPrimary,
          padding: EdgeInsets.zero,
          iconSize: 24,
          tooltip: isShown ? 'Hide queue' : 'Queue',
          icon: const Icon(Icons.queue_music),
          selectedIcon: Icon(
            Icons.queue_music,
            color: _theme.colorScheme.primary,
          ),
          isSelected: isShown,
        ),
      );
    },
  );

  Widget _studioModeButton() => IconButton(
    onPressed: () {
      ref.read(lyricsVisibleProvider.notifier).state = false;
      ref.read(studioModeVisibleProvider.notifier).state = true;
    },
    color: _theme.colorScheme.onPrimary,
    tooltip: 'Studio mode',
    icon: const Icon(Icons.fullscreen),
  );

  Widget _secondaryControl(Widget child) => IconTheme.merge(
    data: IconThemeData(size: _isMobile ? 20 : 24),
    child: child,
  );

  Widget _randomQueueButton() => Consumer(
    builder: (context, ref, child) {
      final enabled = ref.watch(barShuffleProvider);
      return IconButton(
        onPressed: () =>
            ref.read(barControlsProvider).setShuffle(enabled: !enabled),
        icon: Icon(
          JPlayer.mix,
          color: _theme.colorScheme.onPrimary,
        ),
        selectedIcon: Icon(
          JPlayer.mix,
          color: _theme.colorScheme.primary,
        ),
        isSelected: enabled,
      );
    },
  );

  Widget _repeatTrackButton() => Consumer(
    builder: (context, ref, _) {
      final mode = ref.watch(barRepeatProvider);
      return IconButton(
        onPressed: () => ref
            .read(barControlsProvider)
            .setRepeat(mode == LoopMode.all ? LoopMode.off : LoopMode.all),
        icon: Icon(
          JPlayer.repeat,
          color: _theme.colorScheme.onPrimary,
        ),
        selectedIcon: Icon(
          JPlayer.repeat,
          color: _theme.colorScheme.primary,
        ),
        isSelected: mode == LoopMode.all,
      );
    },
  );

  Widget _playbackTargetButton({
    double? size,
    bool showsDeviceName = false,
  }) => PlaybackTargetButton(
    size: size,
    color: _theme.colorScheme.onPrimary,
    activeColor: _theme.colorScheme.primary,
    showsDeviceName: showsDeviceName,
  );

  Widget _lyricsButton() => Consumer(
    builder: (context, ref, _) {
      final hasLyrics = ref.watch(currentSongHasLyricsProvider);
      final isShown = ref.watch(lyricsShownProvider);

      return IconButton(
        onPressed: hasLyrics
            ? () {
                _queueShown.value = false;
                ref.read(lyricsVisibleProvider.notifier).state = !isShown;
              }
            : null,
        color: _theme.colorScheme.onPrimary,
        disabledColor: _theme.colorScheme.onPrimary.withOpacity(0.3),
        tooltip: hasLyrics ? 'Lyrics' : 'No lyrics for this track',
        icon: const Icon(Icons.lyrics_outlined),
        selectedIcon: Icon(
          Icons.lyrics,
          color: _theme.colorScheme.primary,
        ),
        isSelected: isShown,
      );
    },
  );

  Widget _downloadTrackButton() => Consumer(
    builder: (context, ref, _) {
      final playback = ref.watch(playbackProvider);
      final currentSong = playback.currentMediaIndex != null
          ? playback.songs.elementAtOrNull(playback.currentMediaIndex!)
          : null;

      if (currentSong == null) return const SizedBox.shrink();

      final isDownloaded = ref
          .watch(isSongDownloadedProvider(currentSong))
          .valueOrNull;
      final currentTask = ref
          .watch(downloadServiceProvider)
          .getTask(currentSong.id);

      if (isDownloaded == true) {
        return Icon(Icons.check_circle, color: Colors.green);
      }

      if (currentTask != null) {
        return ValueListenableBuilder<DownloadStatus>(
          valueListenable: currentTask.status,
          builder: (context, status, _) {
            if (!currentTask.isDownloadingNow) {
              return IconButton(
                onPressed: () => ref
                    .read(downloadManagerProvider.notifier)
                    .downloadSong(currentSong),
                color: _theme.colorScheme.onPrimary,
                icon: const Icon(JPlayer.download),
              );
            }
            return SizedBox.square(
              dimension: _isMobile ? 28 : 24,
              child: ValueListenableBuilder<double?>(
                valueListenable: currentTask.progress,
                builder: (context, progress, _) => CircularProgressIndicator(
                  value: progress,
                  color: _theme.colorScheme.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        );
      }

      return IconButton(
        onPressed: () => ref
            .read(downloadManagerProvider.notifier)
            .downloadSong(currentSong),
        color: _theme.colorScheme.onPrimary,
        icon: const Icon(JPlayer.download),
      );
    },
  );

  Widget _likeTrackButton() => Consumer(
    builder: (context, ref, _) {
      final song = ref.watch(barSongProvider);
      return IconButton(
        onPressed: song == null ? null : () => _onLikeCurrent(song),
        icon: Icon(
          CupertinoIcons.heart,
          color: _theme.colorScheme.onPrimary,
        ),
        selectedIcon: Icon(
          CupertinoIcons.heart_fill,
          color: _theme.colorScheme.primary,
        ),
        isSelected: song?.userData.isFavorite ?? false,
      );
    },
  );
}

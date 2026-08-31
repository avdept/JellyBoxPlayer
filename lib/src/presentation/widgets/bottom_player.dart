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
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';
import 'package:jplayer/src/presentation/widgets/position_slider.dart';
import 'package:jplayer/src/presentation/widgets/remaining_duration.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:native_route_picker/native_route_picker.dart';
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
  final _likeTrack = ValueNotifier<bool>(false);
  late ThemeData _theme;
  late MaterialLocalizations _localizations;
  late EdgeInsets _viewPadding;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isDesktop;

  Future<void> _onExpand() => Navigator.of(context, rootNavigator: true)
      .push(
        ModalSheetRoute<void>(
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
                  child: StreamBuilder<SequenceState?>(
                    stream: ref.read(playerProvider).sequenceStateStream,
                    builder: (context, snapshot) {
                      if (snapshot.data?.sequence.isEmpty ?? true) {
                        return const SizedBox.shrink();
                      }
                      final currentSong =
                          snapshot.data?.currentSource?.tag as MediaItem?;
                      return Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, child) =>
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: ref.watch(lyricsShownProvider)
                                        ? const Padding(
                                            key: ValueKey('lyrics'),
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                                  _sheetHorizontalPadding,
                                            ),
                                            child: LyricsView(),
                                          )
                                        : child,
                                  ),
                              child: ValueListenableBuilder<bool>(
                                key: const ValueKey('artwork'),
                                valueListenable: _isPlaying,
                                builder: (context, isPlaying, child) =>
                                    SwipeableArtwork(
                                      sequenceState: snapshot.data!,
                                      borderRadius: _isMobile ? 12 : 16,
                                      artworkBuilder: _artwork,
                                      horizontalPadding:
                                          _sheetHorizontalPadding,
                                      scale: isPlaying ? 1 : 0.82,
                                    ),
                              ),
                            ),
                          ),
                          _sheetDetails(context, currentSong),
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
                showDragHandle: true,
                dragHandleSize: const Size(113, 10),
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
        ),
      )
      .whenComplete(_onSheetClosed);

  void _onSheetClosed() {
    if (mounted) ref.read(lyricsVisibleProvider.notifier).state = false;
  }

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
                                .getItem(artistId);
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
                final playback = ref.watch(playbackProvider);
                final index = playback.currentMediaIndex;
                final isLoaded =
                    index != null &&
                    playback.songs.elementAtOrNull(index) != null;
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
        const PositionSlider(),
        PositionLabels(fontSize: _isMobile ? 12 : 13),
        SizedBox(height: _isMobile ? 8 : 12),
        AudioQualityBadge(
          codec: currentSong?.extras?['codec'] as String?,
          bitRate: currentSong?.extras?['bitRate'] as int?,
          sampleRate: currentSong?.extras?['sampleRate'] as int?,
        ),
        SizedBox(height: _isMobile ? 12 : 24),
        IconTheme.merge(
          data: IconThemeData(size: _isMobile ? 40 : 44),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _prevTrackButton(),
              SizedBox(width: _isMobile ? 32 : 24),
              SizedBox.square(
                dimension: 72,
                child: _playPauseButton(),
              ),
              SizedBox(width: _isMobile ? 32 : 24),
              _nextTrackButton(),
            ],
          ),
        ),
        SizedBox(height: _isMobile ? 24 : 32),
        IconTheme.merge(
          data: IconThemeData(size: _isMobile ? 26 : 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _randomQueueButton(),
              _repeatTrackButton(),
              if (NativeRoutePicker.isSupported) _outputRouteButton(),
              _lyricsButton(),
              _downloadTrackButton(),
              _likeTrackButton(),
            ],
          ),
        ),
      ],
    ),
  );

  Future<void> _onImageProviderChanged() async {
    final imageProvider = _imageProvider.value;

    if (imageProvider != null && mounted) {
      _dynamicColors.value = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: _theme.brightness,
      );
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

    final deviceType = getDeviceType(_screenSize);
    _isMobile = deviceType == DeviceScreenType.mobile;
    _isDesktop = deviceType == DeviceScreenType.desktop;
  }

  @override
  Widget build(BuildContext context) {
    final playBackProvider = ref.watch(playbackProvider);

    final isPlaying = playBackProvider.status == PlaybackStatus.playing;
    if (_isPlaying.value != isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _isPlaying.value = isPlaying;
      });
    }
    return StreamBuilder<SequenceState?>(
      stream: ref.read(playerProvider).sequenceStateStream,
      builder: (context, snapshot) {
        final isEmpty = snapshot.data?.sequence.isEmpty ?? true;
        final currentSong = snapshot.data?.currentSource?.tag as MediaItem?;
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
                          child: _artwork(currentSong),
                        ),
                        title: Row(
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
                              AudioQualityBadge(
                                codec: currentSong?.extras?['codec'] as String?,
                                bitRate:
                                    currentSong?.extras?['bitRate'] as int?,
                                sampleRate:
                                    currentSong?.extras?['sampleRate'] as int?,
                              ),
                          ],
                        ),
                        subtitle: Align(
                          alignment: Alignment.centerLeft,
                          child: ClickableWidget(
                            onPressed:
                                (_isDesktop &&
                                    currentSong?.extras?['artistId'] != null)
                                ? () async {
                                    final artistId =
                                        currentSong!.extras!['artistId']
                                            as String;
                                    final item = await ref
                                        .read(mediaServerClientProvider)
                                        .getItem(artistId);
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
                            if (_isDesktop) const RandomQueueButton(),
                            _prevTrackButton(),
                            SizedBox.square(
                              dimension: 45,
                              child: _playPauseButton(),
                            ),
                            _nextTrackButton(),
                            if (_isDesktop) _repeatTrackButton(),
                            if (_isDesktop) _lyricsButton(),
                            if (_isDesktop) const VolumeControl(size: 44),
                            if (_isDesktop && NativeRoutePicker.isSupported)
                              _outputRouteButton(size: 44),
                            if (!_isMobile) _studioModeButton(),
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
                    child: PositionSlider(),
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
    _likeTrack.dispose();
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
    icon: const Icon(JPlayer.more_horizontal),
  );

  Future<void> _onMorePressed(MediaItem? currentSong) async {
    final playback = ref.read(playbackProvider);
    final index = playback.currentMediaIndex;
    final song = index != null ? playback.songs.elementAtOrNull(index) : null;
    if (song == null) return;
    final artistId = currentSong?.extras?['artistId'] as String?;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.text_badge_plus),
              title: const Text('Add to playlist'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _addToPlaylist(song);
              },
            ),
            if (artistId != null)
              ListTile(
                leading: const Icon(CupertinoIcons.person),
                title: const Text('Go to artist'),
                onTap: () => _goToArtist(sheetContext, artistId),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToPlaylist(LibraryItem song) async {
    final playlist = await showPlaylistPicker(context, isDesktop: _isDesktop);
    if (playlist == null) return;

    await ref
        .read(mediaServerClientProvider)
        .addPlaylistItems(playlistId: playlist.id, itemIds: [song.id]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully added item to playlist')),
    );
  }

  Future<void> _goToArtist(BuildContext sheetContext, String artistId) async {
    final item = await ref.read(mediaServerClientProvider).getItem(artistId);
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    if (!mounted) return;
    Navigator.of(context).pop();
    context.goNamed(Routes.artist.name, extra: {'artist': item});
  }

  Widget _playPauseButton() => PlayPauseButton(
    onPressed: () => _isPlaying.value
        ? ref.read(playbackProvider.notifier).pause()
        : ref.read(playbackProvider.notifier).resume(),
    background: _theme.colorScheme.onPrimary,
    foreground: _theme.scaffoldBackgroundColor,
    stateNotifier: _isPlaying,
  );

  Widget _prevTrackButton() => IconButton(
    onPressed: ref.read(playbackProvider.notifier).prev,
    color: _theme.colorScheme.onPrimary,
    icon: const Icon(Entypo.fast_backward),
  );

  Widget _nextTrackButton() => IconButton(
    onPressed: ref.read(playbackProvider.notifier).next,
    color: _theme.colorScheme.onPrimary,
    icon: const Icon(Entypo.fast_forward),
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

  Widget _randomQueueButton() => StreamBuilder<bool?>(
    stream: ref.read(playerProvider).shuffleModeEnabledStream,
    builder: (context, snapshot) {
      return IconButton(
        onPressed: () => ref
            .read(playerProvider)
            .setShuffleModeEnabled(!(snapshot.data ?? false)),
        icon: Icon(
          JPlayer.mix,
          color: _theme.colorScheme.onPrimary,
        ),
        selectedIcon: Icon(
          JPlayer.mix,
          color: _theme.colorScheme.primary,
        ),
        isSelected: snapshot.data ?? false,
      );
    },
  );

  Widget _repeatTrackButton() => StreamBuilder<LoopMode>(
    stream: ref.read(playerProvider).loopModeStream,
    builder: (context, snapshot) {
      return IconButton(
        onPressed: () => ref
            .read(playerProvider)
            .setLoopMode(
              snapshot.data == LoopMode.all ? LoopMode.off : LoopMode.all,
            ),
        icon: Icon(
          JPlayer.repeat,
          color: _theme.colorScheme.onPrimary,
        ),
        selectedIcon: Icon(
          JPlayer.repeat,
          color: _theme.colorScheme.primary,
        ),
        isSelected: snapshot.data == LoopMode.all,
      );
    },
  );

  Widget _outputRouteButton({double? size}) => RoutePickerButton(
    size: size ?? (_isMobile ? 40 : 36),
    color: _theme.colorScheme.onPrimary,
    activeColor: _theme.colorScheme.primary,
  );

  Widget _lyricsButton() => Consumer(
    builder: (context, ref, _) {
      final playback = ref.watch(playbackProvider);
      final index = playback.currentMediaIndex;
      final currentSong = index != null
          ? playback.songs.elementAtOrNull(index)
          : null;
      final hasLyrics = currentSong?.hasLyrics ?? false;
      final isShown = ref.watch(lyricsShownProvider);

      return IconButton(
        onPressed: hasLyrics
            ? () => ref.read(lyricsVisibleProvider.notifier).state = !isShown
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

  Widget _likeTrackButton() => ValueListenableBuilder(
    valueListenable: _likeTrack,
    builder: (context, isLiked, child) => IconButton(
      onPressed: () => _likeTrack.value = !isLiked,
      icon: Icon(
        CupertinoIcons.heart,
        color: _theme.colorScheme.onPrimary,
      ),
      selectedIcon: Icon(
        CupertinoIcons.heart_fill,
        color: _theme.colorScheme.primary,
      ),
      isSelected: isLiked,
    ),
  );
}

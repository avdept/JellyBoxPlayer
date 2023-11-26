import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/entypo_icons.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/dto/songs/songs_dto.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/presentation/widgets/position_slider.dart';
import 'package:jplayer/src/presentation/widgets/random_queue_button.dart';
import 'package:jplayer/src/presentation/widgets/remaining_duration.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:responsive_builder/responsive_builder.dart';

class BottomPlayer extends ConsumerStatefulWidget {
  const BottomPlayer({super.key});

  @override
  ConsumerState<BottomPlayer> createState() => _BottomPlayerState();
}

class _BottomPlayerState extends ConsumerState<BottomPlayer> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final _imageProvider = ValueNotifier<ImageProvider?>(null);
  final _dynamicColors = ValueNotifier<ColorScheme?>(null);
  final _playProgress = ValueNotifier<double>(0.6);
  final _isPlaying = ValueNotifier<bool>(false);
  final _randomQueue = ValueNotifier<bool>(false);
  final _repeatTrack = ValueNotifier<bool>(false);
  final _likeTrack = ValueNotifier<bool>(false);
  SongDTO? currentSong;
  late ThemeData _theme;
  late MaterialLocalizations _localizations;
  late EdgeInsets _viewPadding;
  late Size _screenSize;
  late bool _isMobile;
  late bool _isDesktop;

  Future<void> _onExpand(MediaItem? currentSong) => Navigator.of(context, rootNavigator: true).push(
        ModalSheetRoute(
          builder: (context) => SafeArea(
            top: false,
            minimum: EdgeInsets.only(
              left: 30,
              top: _isMobile ? 0 : 20,
              right: 30,
              bottom: _isMobile ? 20 : 60,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 518),
              child: ValueListenableBuilder(
                valueListenable: _dynamicColors,
                builder: (context, colorScheme, child) => Theme(
                  data: Theme.of(context).copyWith(colorScheme: colorScheme),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 444),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: ValueListenableBuilder(
                                  valueListenable: _imageProvider,
                                  builder: (context, image, child) => (image == null)
                                      ? const SizedBox.shrink()
                                      : Image(
                                          image: currentSong?.artUri != null
                                              ? NetworkImage(currentSong!.artUri.toString())
                                              : const AssetImage(Images.album) as ImageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                            ),
                            SizedBox(height: _isMobile ? 6 : 18),
                            IconTheme(
                              data: _theme.iconTheme.copyWith(
                                size: _isMobile ? 28 : 24,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  // _openListButton(),
                                  _randomQueueButton(),
                                  _repeatTrackButton(),
                                  _downloadTrackButton(),
                                  _likeTrackButton(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: _isMobile ? 30 : 26),
                      Text(
                        currentSong?.title ?? '',
                        style: TextStyle(
                          fontSize: _isMobile ? 30 : 40,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                      Text(
                        currentSong?.artist ?? '',
                        style: TextStyle(
                          fontSize: _isMobile ? 18 : 24,
                          height: 1.2,
                        ),
                      ),
                      // SizedBox(height: _isMobile ? 17 : 0),
                      // Text(
                      //   'FLAC 44.1Khz/1080Kbps',
                      //   style: TextStyle(
                      //     fontSize: _isMobile ? 14 : 18,
                      //     color: colorScheme?.onPrimary,
                      //     height: 1.2,
                      //   ),
                      // ),
                      SizedBox(height: _isMobile ? 15 : 21),
                      const PositionSlider(),
                      SizedBox(height: _isMobile ? 23 : 56),
                      IconTheme(
                        data: _theme.iconTheme.copyWith(
                          size: _isMobile ? 37 : 46,
                        ),
                        child: Wrap(
                          spacing: _isMobile ? 40 : 24,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _prevTrackButton(),
                            SizedBox.square(
                              dimension: _isMobile ? 68 : 84,
                              child: _playPauseButton(),
                            ),
                            _nextTrackButton(),
                          ],
                        ),
                      ),
                    ],
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
          expanded: false,
          barrierLabel: _localizations.modalBarrierDismissLabel,
          duration: const Duration(milliseconds: 300),
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

    _isPlaying.value = playBackProvider.status == PlaybackStatus.playing;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        StreamBuilder<SequenceState?>(
          stream: ref.read(playerProvider).sequenceStateStream,
          builder: (context, snapshot) {
            if (snapshot.data?.sequence.isEmpty ?? true) return Container();
            final currentSong = snapshot.data?.sequence[snapshot.data!.currentIndex].tag as MediaItem?;
            final image = currentSong?.artUri != null ? NetworkImage(currentSong!.artUri.toString()) : const AssetImage(Images.emptyItem) as ImageProvider;
            _imageProvider.value = image;
            return Container(
              height: (_isMobile ? 69 : 92) + _viewPadding.bottom,
              color: _theme.bottomSheetTheme.backgroundColor?.withOpacity(0.75),
              padding: EdgeInsets.only(bottom: _viewPadding.bottom),
              child: GestureDetector(
                onTap: !_isDesktop ? () => _onExpand(currentSong) : null,
                behavior: HitTestBehavior.opaque,
                child: SimpleListTile(
                  padding: const EdgeInsets.only(right: 8),
                  leading: AspectRatio(
                    aspectRatio: 1,
                    child: Image(
                      image: image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    currentSong?.title ?? '',
                    style: TextStyle(
                      fontSize: _isMobile ? 18 : 24,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  subtitle: Text(
                    currentSong?.artist ?? '',
                    style: TextStyle(
                      fontSize: _isMobile ? 10 : 18,
                      height: 1.2,
                    ),
                  ),
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
                    ],
                  ),
                  leadingToTitle: 15,
                ),
              ),
            );
          },
        ),
        ValueListenableBuilder(
          valueListenable: _dynamicColors,
          builder: (context, colorScheme, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: colorScheme,
            ),
            child: const Positioned(left: -25, top: -22, right: -25, child: PositionSlider()),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _imageProvider.dispose();
    _dynamicColors.dispose();
    _playProgress.dispose();
    _isPlaying.dispose();
    _randomQueue.dispose();
    _repeatTrack.dispose();
    _likeTrack.dispose();
    super.dispose();
  }

  Widget _playPauseButton() => PlayPauseButton(
        onPressed: () => _isPlaying.value ? ref.read(playbackProvider.notifier).pause() : ref.read(playbackProvider.notifier).resume(),
        background: _theme.colorScheme.onPrimary,
        foreground: _theme.scaffoldBackgroundColor,
        stateNotifier: _isPlaying,
      );

  Widget _prevTrackButton() => IconButton(
        onPressed: () => ref.read(playbackProvider.notifier).prev(),
        color: _theme.colorScheme.onPrimary,
        icon: const Icon(Entypo.fast_backward),
      );

  Widget _nextTrackButton() => IconButton(
        onPressed: () => ref.read(playbackProvider.notifier).next(),
        color: _theme.colorScheme.onPrimary,
        icon: const Icon(Entypo.fast_forward),
      );

  Widget _openListButton() => IconButton(
        onPressed: () {},
        color: _theme.colorScheme.onPrimary,
        icon: const Icon(CupertinoIcons.list_bullet),
      );

  Widget _randomQueueButton() => StreamBuilder<bool?>(
        stream: ref.read(playerProvider).shuffleModeEnabledStream,
        builder: (context, snapshot) {
          return IconButton(
            onPressed: () => ref.read(playerProvider).setShuffleModeEnabled(snapshot.data == null ? !snapshot.data! : true),
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
            onPressed: () => ref.read(playerProvider).setLoopMode(snapshot.data == LoopMode.all ? LoopMode.off : LoopMode.all),
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

  Widget _downloadTrackButton() => IconButton(
        onPressed: () {},
        color: _theme.colorScheme.onPrimary,
        icon: const Icon(JPlayer.download),
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

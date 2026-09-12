import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/entypo_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/now_playing_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/audio_quality_badge.dart';
import 'package:jplayer/src/presentation/widgets/aurora_background.dart';
import 'package:jplayer/src/presentation/widgets/flip_panel.dart';
import 'package:jplayer/src/presentation/widgets/keep_screen_awake.dart';
import 'package:jplayer/src/presentation/widgets/lyrics_overlay.dart';
import 'package:jplayer/src/presentation/widgets/now_playing_queue_view.dart';
import 'package:jplayer/src/presentation/widgets/play_pause_button.dart';
import 'package:jplayer/src/presentation/widgets/position_labels.dart';
import 'package:jplayer/src/presentation/widgets/position_slider.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

const List<DeviceOrientation> _portraitOrientations = [
  DeviceOrientation.portraitUp,
];
const List<DeviceOrientation> _phoneOrientations = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];
const List<DeviceOrientation> _systemOrientations = [];

bool get supportsLandscapePlayer =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

bool isPhoneSize(Size size) => DeviceType.fromScreenSize(size).isMobile;

enum _Panel { player, lyrics, queue }

const double _artworkInset = 14;
const double _pausedArtworkScale = 0.92;
const double _tapTargetOverhang = 12;
const double _dimmedPanelButtons = 0.45;

class LandscapePlayerScope extends ConsumerStatefulWidget {
  const LandscapePlayerScope({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<LandscapePlayerScope> createState() =>
      _LandscapePlayerScopeState();
}

class _LandscapePlayerScopeState extends ConsumerState<LandscapePlayerScope> {
  List<DeviceOrientation>? _appliedOrientations;

  void _applyOrientations(List<DeviceOrientation> orientations) {
    if (identical(_appliedOrientations, orientations)) return;
    _appliedOrientations = orientations;
    unawaited(SystemChrome.setPreferredOrientations(orientations));
  }

  @override
  Widget build(BuildContext context) {
    if (!isPhoneSize(MediaQuery.sizeOf(context))) {
      _applyOrientations(_systemOrientations);
      return widget.child;
    }

    final hasSong = ref.watch(
      nowPlayingProvider.select((song) => song != null),
    );
    _applyOrientations(hasSong ? _phoneOrientations : _portraitOrientations);

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (hasSong && isLandscape)
          const Positioned.fill(child: LandscapePlayer()),
      ],
    );
  }
}

class LandscapePlayer extends StatelessWidget {
  const LandscapePlayer({super.key});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
    builder: (context, opacity, child) =>
        Opacity(opacity: opacity, child: child),
    child: HeroControllerScope.none(
      child: Navigator(
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) =>
              const _LandscapePlayerView(),
        ),
      ),
    ),
  );
}

class _LandscapePlayerView extends ConsumerStatefulWidget {
  const _LandscapePlayerView();

  @override
  ConsumerState<_LandscapePlayerView> createState() =>
      _LandscapePlayerViewState();
}

class _LandscapePlayerViewState extends ConsumerState<_LandscapePlayerView> {
  final _isPlaying = ValueNotifier<bool>(false);
  late ThemeData _theme;
  _Panel _panel = _Panel.player;

  @override
  void initState() {
    super.initState();
    _isPlaying.value = ref.read(playbackProvider).status.isPlaying;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _theme = Theme.of(context);
  }

  @override
  void dispose() {
    _isPlaying.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(
      playbackProvider.select((state) => state.status.isPlaying),
      (_, isPlaying) => _isPlaying.value = isPlaying,
    );

    final colorScheme =
        ref.watch(artworkSchemeProvider).valueOrNull ?? _theme.colorScheme;
    final song = ref.watch(nowPlayingProvider);

    return Theme(
      data: _theme.copyWith(colorScheme: colorScheme),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(gradient: _background(colorScheme)),
          ),
          const AuroraBackground(),
          const KeepScreenAwake(),
          Material(
            type: MaterialType.transparency,
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _artwork(song),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: _artworkInset,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) => Center(
                          child: SizedBox(
                            height:
                                constraints.maxHeight * _pausedArtworkScale +
                                _tapTargetOverhang * 2,
                            child: _details(song, colorScheme),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Gradient _background(ColorScheme colorScheme) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(colorScheme.primaryContainer, colorScheme.primary, 0.25)!,
      colorScheme.primaryContainer,
      Color.lerp(colorScheme.tertiaryContainer, colorScheme.surface, 0.35)!,
    ],
  );

  Widget _artwork(MediaItem? song) => ValueListenableBuilder<bool>(
    valueListenable: _isPlaying,
    builder: (context, isPlaying, child) => AnimatedScale(
      scale: isPlaying ? 1 : _pausedArtworkScale,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      child: child,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: _artworkInset),
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              key: ValueKey(song?.id),
              image: ref.watch(imageServiceProvider).artworkImage(song?.artUri),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset(Images.album, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    ),
  );

  Color get _foreground => _theme.colorScheme.onPrimary;

  void _showPanel(_Panel panel) =>
      setState(() => _panel = _panel == panel ? _Panel.player : panel);

  Widget _details(MediaItem? song, ColorScheme colorScheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: FlipPanel(
          side: switch (_panel) {
            _Panel.player => FlipSide.front,
            _Panel.lyrics => FlipSide.left,
            _Panel.queue => FlipSide.right,
          },
          front: _nowPlayingFace(song, colorScheme),
          left: const LyricsView(padding: EdgeInsets.symmetric(vertical: 8)),
          right: const NowPlayingQueueView(
            padding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
      _panelButtons(),
    ],
  );

  Widget _nowPlayingFace(MediaItem? song, ColorScheme colorScheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              song?.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: _foreground,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _likeButton(),
        ],
      ),
      Text(
        song?.artist ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 15,
          height: 1.2,
          color: _foreground.withValues(alpha: 0.75),
        ),
      ),
      Expanded(child: Center(child: _transport(song, colorScheme))),
    ],
  );

  Widget _transport(MediaItem? song, ColorScheme colorScheme) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const PositionSlider(),
      PositionLabels(
        fontSize: 12,
        middle: AudioQualityBadge(
          codec: song?.extras?['codec'] as String?,
          bitRate: song?.extras?['bitRate'] as int?,
          sampleRate: song?.extras?['sampleRate'] as int?,
          textColor: _foreground,
        ),
      ),
      const SizedBox(height: 12),
      IconTheme.merge(
        data: const IconThemeData(size: 34),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _prevTrackButton(),
            const SizedBox(width: 20),
            SizedBox.square(
              dimension: 68,
              child: _playPauseButton(colorScheme),
            ),
            const SizedBox(width: 20),
            _nextTrackButton(),
          ],
        ),
      ),
    ],
  );

  Widget _panelButtons() => AnimatedOpacity(
    opacity: _panel == _Panel.lyrics ? _dimmedPanelButtons : 1,
    duration: const Duration(milliseconds: 200),
    child: IconTheme.merge(
      data: const IconThemeData(size: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_lyricsButton(), _queueButton()],
      ),
    ),
  );

  Widget _lyricsButton() => Consumer(
    builder: (context, ref, _) {
      final hasLyrics = ref.watch(
        currentSongProvider.select((song) => song?.hasLyrics ?? false),
      );
      return IconButton(
        onPressed: hasLyrics ? () => _showPanel(_Panel.lyrics) : null,
        color: _foreground,
        disabledColor: _foreground.withValues(alpha: 0.3),
        tooltip: hasLyrics ? 'Lyrics' : 'No lyrics for this track',
        icon: const Icon(Icons.lyrics_outlined),
        selectedIcon: Icon(Icons.lyrics, color: _theme.colorScheme.primary),
        isSelected: _panel == _Panel.lyrics,
      );
    },
  );

  Widget _queueButton() => IconButton(
    onPressed: () => _showPanel(_Panel.queue),
    color: _foreground,
    tooltip: _panel == _Panel.queue ? 'Hide queue' : 'Queue',
    icon: const Icon(Icons.queue_music),
    selectedIcon: Icon(
      Icons.queue_music,
      color: _theme.colorScheme.primary,
    ),
    isSelected: _panel == _Panel.queue,
  );

  Widget _likeButton() => Consumer(
    builder: (context, ref, _) {
      final song = ref.watch(currentSongProvider);
      if (song == null) return const SizedBox.shrink();
      final isOffline = ref.watch(isOfflineProvider);

      return IconButton(
        onPressed: isOffline ? null : () => _toggleFavourite(song),
        iconSize: 26,
        disabledColor: _foreground.withValues(alpha: 0.3),
        icon: Icon(CupertinoIcons.heart, color: _foreground),
        selectedIcon: Icon(
          CupertinoIcons.heart_fill,
          color: _theme.colorScheme.primary,
        ),
        isSelected: song.userData.isFavorite,
      );
    },
  );

  Future<void> _toggleFavourite(LibraryItem song) async {
    final favourite = !song.userData.isFavorite;
    try {
      await ref
          .read(mediaServerClientProvider)
          .setFavorite(song.id, favorite: favourite);
    } on Object {
      return;
    }
    if (!mounted) return;
    ref.invalidate(favouriteSongsProvider);
    ref
        .read(playbackProvider.notifier)
        .updateSong(
          song.copyWith(
            userData: song.userData.copyWith(isFavorite: favourite),
          ),
        );
  }

  Widget _playPauseButton(ColorScheme colorScheme) => PlayPauseButton(
    onPressed: ref.read(playbackProvider.notifier).playPause,
    background: _foreground,
    foreground: colorScheme.primaryContainer,
    stateNotifier: _isPlaying,
  );

  Widget _prevTrackButton() => IconButton(
    onPressed: ref.read(playbackProvider.notifier).prev,
    color: _foreground,
    icon: const Icon(Entypo.fast_backward),
  );

  Widget _nextTrackButton() => IconButton(
    onPressed: ref.read(playbackProvider.notifier).next,
    color: _foreground,
    icon: const Icon(Entypo.fast_forward),
  );
}

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/entypo_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/widgets/play_pause_button.dart';
import 'package:jplayer/src/presentation/widgets/position_labels.dart';
import 'package:jplayer/src/presentation/widgets/position_slider.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:window_manager/window_manager.dart';

class StudioMode extends ConsumerWidget {
  const StudioMode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<bool>(
      playbackProvider.select(
        (state) => state.status == PlaybackStatus.stopped,
      ),
      (_, stopped) {
        if (stopped) {
          ref.read(studioModeVisibleProvider.notifier).state = false;
        }
      },
    );
    final isShown = ref.watch(studioModeShownProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: isShown
          ? const _StudioModeView(key: ValueKey(true))
          : const SizedBox.expand(key: ValueKey(false)),
    );
  }
}

class _StudioModeView extends ConsumerStatefulWidget {
  const _StudioModeView({super.key});

  @override
  ConsumerState<_StudioModeView> createState() => _StudioModeViewState();
}

class _StudioModeViewState extends ConsumerState<_StudioModeView> {
  static const double _playingSpeed = 1 / 90;
  static const double _pausedSpeed = 1 / 450;
  static const double _speedRampSeconds = 1.5;
  static const _phaseInterval = Duration(milliseconds: 66);
  static const int _blurTargetSize = 512;
  static const double _blurSigma = 16;

  static Future<ui.FragmentProgram>? _auroraProgramFuture;

  static Future<ui.FragmentProgram> _auroraProgram() =>
      _auroraProgramFuture ??= ui.FragmentProgram.fromAsset(
        'shaders/studio_aurora.frag',
      );

  final _isPlaying = ValueNotifier<bool>(false);
  final _backgroundPhase = ValueNotifier<double>(0);
  final _phaseWatch = Stopwatch();
  Timer? _phaseTimer;
  MediaItem? _currentSong;
  String? _displayedSongId;
  String? _pendingSongId;
  ImageProvider _coverImage = const AssetImage(Images.album);
  ui.FragmentShader? _auroraShader;
  ui.Image? _blurredArt;
  double _backgroundSpeed = _pausedSpeed;
  Timer? _hideTimer;
  bool _controlsVisible = true;
  int _activePointers = 0;
  bool _didEnterWindowFullscreen = false;

  @override
  void initState() {
    super.initState();
    unawaited(_enterWindowFullscreen());
    final playing = ref.read(playbackProvider).status == PlaybackStatus.playing;
    _isPlaying.value = playing;
    _backgroundSpeed = playing ? _playingSpeed : _pausedSpeed;
    if (ref.read(settingProvider(AppSetting.studioModeAnimation))) {
      _phaseWatch.start();
      _phaseTimer = Timer.periodic(_phaseInterval, _onPhaseTick);
    }
    ref.listenManual(nowPlayingProvider, (_, song) => _onNowPlaying(song));
    _currentSong = ref.read(nowPlayingProvider);
    ref.listenManual(
      playbackProvider.select(
        (state) => state.status == PlaybackStatus.playing,
      ),
      (_, playing) => _isPlaying.value = playing,
    );
    _pokeControls();
  }

  Future<void> _enterWindowFullscreen() async {
    if (!supportsWindowFullscreen) return;
    if (!ref.read(settingProvider(AppSetting.studioModeFullscreen))) return;
    if (await windowManager.isFullScreen()) return;
    _didEnterWindowFullscreen = true;
    await windowManager.setFullScreen(true);
  }

  void _onNowPlaying(MediaItem? song) {
    if (!mounted) return;
    if (song?.id != _currentSong?.id) {
      setState(() => _currentSong = song);
    }
    if (song?.id == _displayedSongId && _auroraShader != null) return;
    _prepareArtwork(song);
  }

  void _prepareArtwork(MediaItem? song) {
    final id = song?.id;
    _pendingSongId = id;
    final imageService = ref.read(imageServiceProvider);
    final cover = imageService.artworkImage(song?.artUri, size: 1024);
    final background = imageService.artworkImage(song?.artUri);
    unawaited(() async {
      await precacheImage(cover, context);
      ui.FragmentShader? shader;
      ui.Image? blurred;
      try {
        final program = await _auroraProgram();
        blurred = await _blurArtwork(background);
        shader = program.fragmentShader()..setImageSampler(0, blurred);
      } on Object catch (error) {
        dev.log('Failed to build aurora shader', error: error);
        shader?.dispose();
        blurred?.dispose();
        shader = null;
        blurred = null;
      }
      if (!mounted || _pendingSongId != id) {
        shader?.dispose();
        blurred?.dispose();
        return;
      }
      final outgoingShader = _auroraShader;
      final outgoingArt = _blurredArt;
      setState(() {
        _displayedSongId = id;
        _coverImage = cover;
        _auroraShader = shader;
        _blurredArt = blurred;
      });
      Timer(const Duration(milliseconds: 900), () {
        outgoingShader?.dispose();
        outgoingArt?.dispose();
      });
    }());
  }

  Future<ui.Image> _blurArtwork(ImageProvider provider) async {
    final completer = Completer<ImageInfo>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        completer.complete(info);
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        completer.completeError(error, stackTrace);
      },
    );
    stream.addListener(listener);
    final sourceInfo = await completer.future;
    try {
      final source = sourceInfo.image;
      const targetRect = Rect.fromLTWH(
        0,
        0,
        _blurTargetSize * 1.0,
        _blurTargetSize * 1.0,
      );
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawImageRect(
        source,
        Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
        targetRect,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: _blurSigma,
            sigmaY: _blurSigma,
            tileMode: ui.TileMode.clamp,
          ),
      );
      final picture = recorder.endRecording();
      final blurred = await picture.toImage(_blurTargetSize, _blurTargetSize);
      picture.dispose();
      return blurred;
    } finally {
      sourceInfo.dispose();
    }
  }

  void _onPhaseTick(Timer timer) {
    final dt = _phaseWatch.elapsedMicroseconds / 1e6;
    _phaseWatch.reset();
    final target = _isPlaying.value ? _playingSpeed : _pausedSpeed;
    _backgroundSpeed +=
        (target - _backgroundSpeed) * (1 - exp(-dt / _speedRampSeconds));
    _backgroundPhase.value =
        (_backgroundPhase.value + dt * _backgroundSpeed) % 1;
  }

  void _pokeControls() {
    _hideTimer?.cancel();
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _hideTimer = Timer(const Duration(seconds: 5), _hideControls);
  }

  void _hideControls() {
    if (_activePointers > 0) {
      _hideTimer = Timer(const Duration(seconds: 5), _hideControls);
      return;
    }
    if (mounted) setState(() => _controlsVisible = false);
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;
    _pokeControls();
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers = max(0, _activePointers - 1);
    _pokeControls();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = max(0, _activePointers - 1);
    _pokeControls();
  }

  void _close() {
    ref.read(studioModeVisibleProvider.notifier).state = false;
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: MouseRegion(
          onHover: (_) => _pokeControls(),
          cursor: _controlsVisible
              ? MouseCursor.defer
              : SystemMouseCursors.none,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerDown,
            onPointerMove: (_) => _pokeControls(),
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  child: KeyedSubtree(
                    key: ValueKey(_displayedSongId),
                    child: _animatedBackground(),
                  ),
                ),
                RepaintBoundary(
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final coverSize = min(
                          min(
                            constraints.maxHeight * 0.5,
                            constraints.maxWidth * 0.7,
                          ),
                          480,
                        ).toDouble();
                        return Stack(
                          children: [
                            Center(child: _centeredCover(coverSize)),
                            Positioned(
                              top: (constraints.maxHeight + coverSize) / 2 + 20,
                              left: 0,
                              right: 0,
                              child: _fadeWithControls(
                                Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 480,
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: _controls(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _fadeWithControls(
                    IconButton(
                      onPressed: _close,
                      color: Colors.white,
                      tooltip: 'Exit studio mode',
                      icon: const Icon(Icons.fullscreen_exit),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _animatedBackground() {
    final shader = _auroraShader;
    if (shader == null) return const SizedBox.expand();
    return SizedBox.expand(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _AuroraPainter(shader: shader, phase: _backgroundPhase),
        ),
      ),
    );
  }

  Widget _centeredCover(double size) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 500),
    child: ClipRRect(
      key: ValueKey(_displayedSongId),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox.square(
        dimension: size,
        child: Image(
          image: _coverImage,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              Image.asset(Images.album, fit: BoxFit.cover),
        ),
      ),
    ),
  );

  Widget _fadeWithControls(Widget child) => AnimatedOpacity(
    opacity: _controlsVisible ? 1 : 0,
    duration: const Duration(milliseconds: 200),
    child: IgnorePointer(ignoring: !_controlsVisible, child: child),
  );

  Widget _controls() {
    final artworkScheme = ref.watch(artworkSchemeProvider).valueOrNull;
    return Theme(
      data: Theme.of(context).copyWith(colorScheme: artworkScheme),
      child: _controlsColumn(),
    );
  }

  Widget _controlsColumn() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        _currentSong?.title ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        _currentSong?.artist ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 14,
          height: 1.2,
        ),
      ),
      const SizedBox(height: 8),
      const PositionSlider(),
      const PositionLabels(fontSize: 12),
      const SizedBox(height: 8),
      IconTheme.merge(
        data: const IconThemeData(size: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: ref.read(playbackProvider.notifier).prev,
              color: Colors.white,
              icon: const Icon(Entypo.fast_backward),
            ),
            const SizedBox(width: 16),
            SizedBox.square(
              dimension: 52,
              child: PlayPauseButton(
                onPressed: () => _isPlaying.value
                    ? ref.read(playbackProvider.notifier).pause()
                    : ref.read(playbackProvider.notifier).resume(),
                background: Colors.white,
                foreground: Colors.black,
                stateNotifier: _isPlaying,
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: ref.read(playbackProvider.notifier).next,
              color: Colors.white,
              icon: const Icon(Entypo.fast_forward),
            ),
          ],
        ),
      ),
    ],
  );

  @override
  void dispose() {
    if (_didEnterWindowFullscreen) {
      unawaited(windowManager.setFullScreen(false));
    }
    _hideTimer?.cancel();
    _phaseTimer?.cancel();
    _backgroundPhase.dispose();
    _auroraShader?.dispose();
    _blurredArt?.dispose();
    _isPlaying.dispose();
    super.dispose();
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required this.shader, required this.phase})
    : super(repaint: phase);

  final ui.FragmentShader shader;
  final ValueListenable<double> phase;

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, phase.value);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.shader != shader;
}

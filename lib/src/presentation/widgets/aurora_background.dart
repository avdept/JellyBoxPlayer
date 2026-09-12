import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/now_playing_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

const int auroraBlurTargetSize = 512;
const double auroraBlurSigma = 16;

Future<ui.FragmentProgram>? _auroraProgramFuture;

Future<ui.FragmentProgram> auroraProgram() =>
    _auroraProgramFuture ??= ui.FragmentProgram.fromAsset(
      'shaders/studio_aurora.frag',
    );

Future<ui.Image> blurArtwork(
  ImageProvider provider, {
  int size = auroraBlurTargetSize,
  double sigma = auroraBlurSigma,
}) async {
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
    final targetRect = Rect.fromLTWH(0, 0, size * 1.0, size * 1.0);
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      source,
      Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
      targetRect,
      Paint()
        ..imageFilter = ui.ImageFilter.blur(
          sigmaX: sigma,
          sigmaY: sigma,
          tileMode: ui.TileMode.clamp,
        ),
    );
    final picture = recorder.endRecording();
    final blurred = await picture.toImage(size, size);
    picture.dispose();
    return blurred;
  } finally {
    sourceInfo.dispose();
  }
}

class AuroraPainter extends CustomPainter {
  AuroraPainter({required this.shader, required this.phase})
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
  bool shouldRepaint(covariant AuroraPainter oldDelegate) =>
      oldDelegate.shader != shader;
}

class AuroraBackground extends ConsumerStatefulWidget {
  const AuroraBackground({this.animate = true, super.key});

  final bool animate;

  @override
  ConsumerState<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends ConsumerState<AuroraBackground> {
  static const double _playingSpeed = 1 / 90;
  static const double _pausedSpeed = 1 / 450;
  static const double _speedRampSeconds = 1.5;
  static const _phaseInterval = Duration(milliseconds: 66);
  static const _crossfade = Duration(milliseconds: 800);

  final _phase = ValueNotifier<double>(0);
  final _phaseWatch = Stopwatch();
  Timer? _phaseTimer;
  ui.FragmentShader? _shader;
  ui.Image? _blurredArt;
  String? _displayedSongId;
  String? _pendingSongId;
  double _speed = _pausedSpeed;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _isPlaying = ref.read(playbackProvider).status.isPlaying;
    _speed = _isPlaying ? _playingSpeed : _pausedSpeed;
    if (widget.animate) {
      _phaseWatch.start();
      _phaseTimer = Timer.periodic(_phaseInterval, _onPhaseTick);
    }
    ref.listenManual(
      playbackProvider.select((state) => state.status.isPlaying),
      (_, playing) => _isPlaying = playing,
    );
    ref.listenManual(nowPlayingProvider, (_, song) => _prepareArtwork(song));
    unawaited(_prepareArtwork(ref.read(nowPlayingProvider)));
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _phase.dispose();
    _shader?.dispose();
    _blurredArt?.dispose();
    super.dispose();
  }

  void _onPhaseTick(Timer timer) {
    final dt = _phaseWatch.elapsedMicroseconds / 1e6;
    _phaseWatch.reset();
    final target = _isPlaying ? _playingSpeed : _pausedSpeed;
    _speed += (target - _speed) * (1 - exp(-dt / _speedRampSeconds));
    _phase.value = (_phase.value + dt * _speed) % 1;
  }

  Future<void> _prepareArtwork(MediaItem? song) async {
    final id = song?.id;
    if (id == _displayedSongId && _shader != null) return;
    _pendingSongId = id;

    final artUri = song?.artUri;
    ui.FragmentShader? shader;
    ui.Image? blurred;
    if (artUri != null) {
      final artwork = ref.read(imageServiceProvider).artworkImage(artUri);
      try {
        final program = await auroraProgram();
        blurred = await blurArtwork(artwork);
        shader = program.fragmentShader()..setImageSampler(0, blurred);
      } on Object catch (error) {
        dev.log('Failed to build aurora shader', error: error);
        shader?.dispose();
        blurred?.dispose();
        shader = null;
        blurred = null;
      }
    }

    if (!mounted || _pendingSongId != id) {
      shader?.dispose();
      blurred?.dispose();
      return;
    }

    final outgoingShader = _shader;
    final outgoingArt = _blurredArt;
    setState(() {
      _displayedSongId = id;
      _shader = shader;
      _blurredArt = blurred;
    });
    if (outgoingShader == null && outgoingArt == null) return;
    Timer(_crossfade + const Duration(milliseconds: 100), () {
      outgoingShader?.dispose();
      outgoingArt?.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    return AnimatedSwitcher(
      duration: _crossfade,
      child: KeyedSubtree(
        key: ValueKey(_displayedSongId),
        child: shader == null
            ? const SizedBox.expand()
            : SizedBox.expand(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: AuroraPainter(shader: shader, phase: _phase),
                  ),
                ),
              ),
      ),
    );
  }
}

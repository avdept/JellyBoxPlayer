import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:jplayer/src/core/animated_artwork/hls_variant_resolver.dart';
import 'package:video_player/video_player.dart';

const _maxTargetWidth = 1080;

class AnimatedCoverVideo extends StatefulWidget {
  const AnimatedCoverVideo({
    required this.url,
    this.maxWidth,
    this.onReady,
    super.key,
  });

  final Uri url;

  final double? maxWidth;

  final ValueChanged<Uri>? onReady;

  @override
  State<AnimatedCoverVideo> createState() => _AnimatedCoverVideoState();
}

class _AnimatedCoverVideoState extends State<AnimatedCoverVideo>
    with WidgetsBindingObserver {
  static final _resolver = HlsVariantResolver();

  VideoPlayerController? _controller;
  var _ready = false;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_start());
    });
  }

  @override
  void didUpdateWidget(AnimatedCoverVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.maxWidth != widget.maxWidth) {
      final previous = _controller;
      _ready = false;
      _controller = null;
      unawaited(previous?.dispose());
      unawaited(_start());
    }
  }

  static VideoPlayerController _controllerFor(Uri url) =>
      VideoPlayerController.networkUrl(
        url,
        videoPlayerOptions: Platform.isAndroid
            ? VideoPlayerOptions(mixWithOthers: true)
            : null,
      );

  int _targetWidth() {
    final logical = widget.maxWidth ?? MediaQuery.sizeOf(context).longestSide;
    final pixels = logical * MediaQuery.devicePixelRatioOf(context);
    return pixels.round().clamp(1, _maxTargetWidth);
  }

  Future<void> _start() async {
    final generation = ++_generation;
    final url = widget.url;
    VideoPlayerController? controller;
    try {
      final source = await _resolver.resolve(url, targetWidth: _targetWidth());
      if (_stale(generation)) return;
      controller = _controllerFor(source);
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
    } on Object catch (error) {
      debugPrint('[AnimatedCover] could not play $url: $error');
      if (_stale(generation)) unawaited(controller?.dispose());
      return;
    }
    if (_stale(generation)) {
      unawaited(controller.dispose());
      return;
    }
    setState(() => _ready = true);
    widget.onReady?.call(url);
  }

  bool _stale(int generation) => !mounted || generation != _generation;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (!_ready || controller == null) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(controller.play());
    } else {
      unawaited(controller.pause());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final size = _ready && controller != null
        ? controller.value.size
        : Size.zero;
    return AnimatedOpacity(
      opacity: _ready ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      child: _ready && controller != null
          ? FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: VideoPlayer(controller),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}

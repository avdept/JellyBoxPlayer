import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class AnimatedCoverVideo extends StatefulWidget {
  const AnimatedCoverVideo({required this.url, super.key});

  final Uri url;

  @override
  State<AnimatedCoverVideo> createState() => _AnimatedCoverVideoState();
}

class _AnimatedCoverVideoState extends State<AnimatedCoverVideo>
    with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = _controllerFor(widget.url);
    unawaited(_start());
  }

  @override
  void didUpdateWidget(AnimatedCoverVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      final previous = _controller;
      _ready = false;
      _controller = _controllerFor(widget.url);
      unawaited(previous.dispose());
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

  Future<void> _start() async {
    final controller = _controller;
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
    } on Object catch (error) {
      debugPrint('[AnimatedCover] could not play ${widget.url}: $error');
      return;
    }
    if (mounted && identical(controller, _controller)) {
      setState(() => _ready = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ready) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_controller.play());
    } else {
      unawaited(_controller.pause());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = _ready ? _controller.value.size : Size.zero;
    return AnimatedOpacity(
      opacity: _ready ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      child: _ready
          ? FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: VideoPlayer(_controller),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}

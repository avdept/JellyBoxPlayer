import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/window/shutdown_hooks.dart';
import 'package:video_player/video_player.dart';

abstract class PreviewAudio {
  ValueListenable<double> get progress;

  Future<void> play(Uri url, {required VoidCallback onDone});

  Future<void> stop();

  void dispose();
}

class VideoPlayerPreviewAudio implements PreviewAudio {
  final _progress = ValueNotifier<double>(0);
  VideoPlayerController? _controller;
  var _generation = 0;

  @override
  ValueListenable<double> get progress => _progress;

  @override
  Future<void> play(Uri url, {required VoidCallback onDone}) async {
    await stop();
    final generation = ++_generation;
    final controller = VideoPlayerController.networkUrl(
      url,
      videoPlayerOptions: Platform.isAndroid
          ? VideoPlayerOptions(mixWithOthers: true)
          : null,
    );
    _controller = controller;
    ShutdownHooks.instance.add(controller, controller.dispose);
    var finished = false;
    controller.addListener(() {
      if (generation != _generation) return;
      final value = controller.value;
      final total = value.duration.inMilliseconds;
      _progress.value = total == 0
          ? 0
          : (value.position.inMilliseconds / total).clamp(0, 1).toDouble();
      if (!finished && (value.isCompleted || value.hasError)) {
        finished = true;
        onDone();
      }
    });
    await controller.initialize();
    if (generation != _generation) return;
    await controller.play();
  }

  @override
  Future<void> stop() async {
    _generation++;
    _progress.value = 0;
    final controller = _release();
    await controller?.dispose();
  }

  @override
  void dispose() {
    _generation++;
    _release()?.dispose().ignore();
    _progress.dispose();
  }

  VideoPlayerController? _release() {
    final controller = _controller;
    _controller = null;
    if (controller != null) ShutdownHooks.instance.remove(controller);
    return controller;
  }
}

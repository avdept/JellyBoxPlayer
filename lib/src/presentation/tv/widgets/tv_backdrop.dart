import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class TvBackdrop extends StatefulWidget {
  const TvBackdrop({required this.image, super.key});

  final ImageProvider image;

  static const int width = 192;
  static const int height = 108;
  static const double sigma = 14;
  static const Color dim = Color(0x99000000);

  static final _cache = <ImageProvider, Future<ui.Image>>{};
  static const _cacheSize = 4;

  static Future<ui.Image> of(ImageProvider image) {
    final cached = _cache.remove(image);
    if (cached != null) {
      _cache[image] = cached;
      return cached;
    }
    final future = _resolve(image).then(render);
    _cache[image] = future;
    if (_cache.length > _cacheSize) _cache.remove(_cache.keys.first)?.ignore();
    unawaited(
      future.then<void>(
        (_) {},
        onError: (Object _) => _cache.remove(image)?.ignore(),
      ),
    );
    return future;
  }

  static Future<ui.Image> render(ui.Image source) {
    const size = Size(width * 1.0, height * 1.0);
    final bounds = Offset.zero & size;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(bounds, Paint()..color = Colors.black)
      ..saveLayer(
        bounds.inflate(sigma * 3),
        Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      );
    final sourceSize = Size(source.width * 1.0, source.height * 1.0);
    final fitted = applyBoxFit(BoxFit.cover, sourceSize, size);
    canvas
      ..drawImageRect(
        source,
        Alignment.center.inscribe(fitted.source, Offset.zero & sourceSize),
        Alignment.center
            .inscribe(fitted.destination, bounds)
            .inflate(sigma * 3),
        Paint()..filterQuality = FilterQuality.low,
      )
      ..restore()
      ..drawRect(bounds, Paint()..color = dim)
      ..drawRect(
        bounds,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0x99000000), Colors.black],
            stops: [0, 0.5, 1],
          ).createShader(bounds),
      );
    return recorder.endRecording().toImage(width, height);
  }

  static Future<ui.Image> _resolve(ImageProvider image) {
    final completer = Completer<ui.Image>();
    final stream = image.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(info.image);
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  @override
  State<TvBackdrop> createState() => _TvBackdropState();
}

class _TvBackdropState extends State<TvBackdrop> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(TvBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != oldWidget.image) _load();
  }

  void _load() {
    final image = widget.image;
    unawaited(
      TvBackdrop.of(image).then(
        (rendered) {
          if (mounted && widget.image == image) {
            setState(() => _image = rendered);
          }
        },
        onError: (Object _) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ColoredBox(
      color: Colors.black,
      child: RawImage(
        image: _image,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      ),
    ),
  );
}

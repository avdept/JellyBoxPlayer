import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

class SmoothPosition extends StatefulWidget {
  const SmoothPosition({
    required this.position,
    required this.duration,
    required this.playing,
    required this.builder,
    this.stopwatch,
    super.key,
  });

  static const snapThreshold = Duration(seconds: 1);
  static const maxExtrapolation = Duration(milliseconds: 1500);
  static const minSettle = Duration(milliseconds: 400);
  static const minTick = Duration(milliseconds: 16);
  static const maxTick = Duration(milliseconds: 250);

  final Duration position;
  final Duration duration;
  final bool playing;
  final Widget Function(BuildContext context, Duration position) builder;
  final Stopwatch? stopwatch;

  @override
  State<SmoothPosition> createState() => _SmoothPositionState();
}

class _SmoothPositionState extends State<SmoothPosition> {
  late final _sinceReport = widget.stopwatch ?? Stopwatch();
  Duration _lag = Duration.zero;
  Duration _settle = SmoothPosition.minSettle;
  double _pixels = 0;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _sinceReport.start();
  }

  @override
  void didUpdateWidget(SmoothPosition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.position == oldWidget.position &&
        widget.playing == oldWidget.playing &&
        widget.duration == oldWidget.duration) {
      return;
    }
    final shown = _positionFor(oldWidget);
    final error = shown - widget.position;
    final continues =
        widget.playing &&
        oldWidget.playing &&
        widget.duration == oldWidget.duration &&
        error.abs() < SmoothPosition.snapThreshold;
    _lag = continues ? error : Duration.zero;
    _settle = Duration(
      microseconds: max(
        SmoothPosition.minSettle.inMicroseconds,
        _lag.inMicroseconds.abs() * 2,
      ),
    );
    _sinceReport
      ..reset()
      ..start();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Duration _positionFor(SmoothPosition widget) {
    if (!widget.playing) return widget.position;
    final elapsed = _sinceReport.elapsed;
    final extrapolated = elapsed < SmoothPosition.maxExtrapolation
        ? elapsed
        : SmoothPosition.maxExtrapolation;
    final remaining = 1 - elapsed.inMicroseconds / _settle.inMicroseconds;
    final lag = remaining > 0 ? _lag * remaining : Duration.zero;
    final position = widget.position + extrapolated + lag;
    if (position < Duration.zero) return Duration.zero;
    if (widget.duration > Duration.zero && position > widget.duration) {
      return widget.duration;
    }
    return position;
  }

  void _scheduleTick() {
    _tick?.cancel();
    _tick = null;
    final durationUs = widget.duration.inMicroseconds;
    if (!widget.playing || durationUs <= 0 || _pixels <= 0) return;
    final perPixel = Duration(microseconds: durationUs ~/ _pixels);
    final interval = perPixel < SmoothPosition.minTick
        ? SmoothPosition.minTick
        : perPixel > SmoothPosition.maxTick
        ? SmoothPosition.maxTick
        : perPixel;
    _tick = Timer(interval, () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0;
      _pixels = width * MediaQuery.devicePixelRatioOf(context);
      _scheduleTick();
      return widget.builder(context, _positionFor(widget));
    },
  );
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VinylPullToRefresh extends StatefulWidget {
  const VinylPullToRefresh({
    required this.onRefresh,
    required this.indicatorHeight,
    required this.child,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final double indicatorHeight;
  final Widget child;

  @override
  State<VinylPullToRefresh> createState() => _VinylPullToRefreshState();
}

class _VinylPullToRefreshState extends State<VinylPullToRefresh>
    with TickerProviderStateMixin {
  static const _revolution = Duration(milliseconds: 1800);

  late final _slide = AnimationController.unbounded(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  late final _spin = AnimationController(vsync: this, duration: _revolution);
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _pulse = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.12), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1), weight: 1),
  ]).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut));

  var _pull = 0.0;
  var _dragging = false;
  var _refreshing = false;

  _VinylGeometry get _geometry =>
      _VinylGeometry((widget.indicatorHeight * 0.17).clamp(22.0, 36.0));

  bool get _armed => _pull >= _geometry.armDistance;

  bool _onNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    if (notification.metrics.axis != Axis.horizontal) return false;

    switch (notification) {
      case ScrollStartNotification(dragDetails: _?):
        _dragging = true;
        _setPull(0);
      case ScrollUpdateNotification(:final dragDetails, :final metrics):
        if (!_dragging) break;
        if (dragDetails == null) {
          _release();
          break;
        }
        final overshoot = metrics.minScrollExtent - metrics.pixels;
        _setPull(overshoot > 0 ? overshoot : 0);
      case OverscrollNotification(
        dragDetails: _?,
        :final overscroll,
        :final metrics,
      ):
        if (!_dragging || overscroll >= 0) break;
        final stretched = (_pull / metrics.viewportDimension).clamp(0.0, 1.0);
        _setPull(_pull - overscroll * 0.52 * pow(1 - stretched, 2));
      case ScrollEndNotification():
        if (_dragging) _release();
      default:
        break;
    }
    return false;
  }

  void _setPull(double value) {
    if (_refreshing) return;
    final wasArmed = _armed;
    _pull = value;
    _slide.value = min(_pull, _geometry.armDistance);
    if (!wasArmed && _armed) {
      _pop.forward(from: 0);
      unawaited(HapticFeedback.selectionClick());
    }
  }

  void _release() {
    _dragging = false;
    if (_refreshing) return;
    final armed = _armed;
    _pull = 0;
    if (armed) {
      unawaited(_refresh());
    } else {
      _slide.animateTo(0, curve: Curves.easeIn);
    }
  }

  Future<void> _refresh() async {
    _refreshing = true;
    _slide.animateTo(_geometry.armDistance, curve: Curves.easeOut);
    _spin.repeat();
    try {
      await widget.onRefresh();
    } on Object catch (_) {
    } finally {
      if (mounted) {
        _spin.stop();
        _refreshing = false;
        _slide.animateTo(
          0,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _spin.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onNotification,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            height: widget.indicatorHeight,
            child: IgnorePointer(
              child: ClipRect(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_slide, _spin, _pop]),
                    builder: (context, _) => CustomPaint(
                      painter: _scene(Theme.of(context).colorScheme),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _SleevePainter? _scene(ColorScheme colors) {
    final pulled = _slide.value;
    if (pulled <= 0) return null;

    return _SleevePainter(
      pulled: pulled,
      spin: _spin.value * 2 * pi,
      pop: _pulse.value,
      geometry: _geometry,
      label: colors.primary,
      hole: colors.surface,
    );
  }
}

class _VinylGeometry {
  const _VinylGeometry(this.radius);

  final double radius;

  double get side => radius * 2.16;

  double get sleeveReveal => side * 0.75;

  double get recordTravel => side / 2 + radius * 0.8;

  double get armDistance => sleeveReveal + recordTravel;
}

class _SleevePainter extends CustomPainter {
  const _SleevePainter({
    required this.pulled,
    required this.spin,
    required this.pop,
    required this.geometry,
    required this.label,
    required this.hole,
  });

  final double pulled;
  final double spin;
  final double pop;
  final _VinylGeometry geometry;
  final Color label;
  final Color hole;

  double get radius => geometry.radius;

  @override
  void paint(Canvas canvas, Size size) {
    final side = geometry.side;
    final shown = min(pulled, geometry.sleeveReveal);
    final travel = geometry.recordTravel;
    final recordOffset = (pulled - geometry.sleeveReveal).clamp(0.0, travel);

    final sleeve = Rect.fromLTWH(
      shown - side,
      (size.height - side) / 2,
      side,
      side,
    );
    final recordCenter = sleeve.center.translate(recordOffset, 0);
    final tilt = -0.08 * (1 - shown / geometry.sleeveReveal);

    canvas
      ..save()
      ..translate(sleeve.center.dx, sleeve.center.dy)
      ..rotate(tilt)
      ..translate(-sleeve.center.dx, -sleeve.center.dy);

    _paintShadow(canvas, sleeve);
    if (recordOffset > 0) {
      _paintRecord(
        canvas,
        center: recordCenter,
        radius: radius * (recordOffset == travel ? pop : 1),
        angle: recordOffset / radius * 0.6 + spin,
      );
      _paintEdgeShadow(canvas, sleeve, recordCenter);
    }
    _paintSleeve(canvas, sleeve);
    _paintBarShadow(canvas, sleeve);

    canvas.restore();
  }

  void _paintShadow(Canvas canvas, Rect sleeve) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        sleeve.shift(Offset(0, radius * 0.1)),
        Radius.circular(radius * 0.08),
      ),
      Paint()
        ..color = Colors.black54
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18),
    );
  }

  void _paintRecord(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double angle,
  }) {
    final disc = Rect.fromCircle(center: center, radius: radius);
    final labelRadius = radius * 0.38;
    final labelRect = Rect.fromCircle(center: Offset.zero, radius: labelRadius);
    final groove = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.5, radius * 0.015);

    canvas
      ..drawCircle(
        center.translate(0, radius * 0.08),
        radius,
        Paint()
          ..color = Colors.black45
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.12),
      )
      ..drawCircle(
        center,
        radius,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0xFF2A2A2A), Color(0xFF0E0E0E)],
          ).createShader(disc),
      );
    for (var r = radius * 0.46; r < radius * 0.96; r += radius * 0.055) {
      groove.color = Colors.white.withValues(alpha: 0.05 + 0.04 * (r / radius));
      canvas.drawCircle(center, r, groove);
    }
    canvas
      ..drawCircle(
        center,
        radius,
        Paint()
          ..shader = SweepGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.16),
              Colors.transparent,
              Colors.transparent,
              Colors.white.withValues(alpha: 0.16),
              Colors.transparent,
            ],
            stops: const [0.05, 0.13, 0.21, 0.55, 0.63, 0.71],
          ).createShader(disc),
      )
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(angle)
      ..drawCircle(Offset.zero, labelRadius, Paint()..color = label)
      ..drawArc(
        labelRect,
        0,
        pi,
        true,
        Paint()..color = Color.lerp(label, Colors.black, 0.25)!,
      )
      ..drawCircle(
        Offset(labelRadius * 0.62, 0),
        labelRadius * 0.12,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      )
      ..restore()
      ..drawCircle(center, max(1.5, radius * 0.06), Paint()..color = hole);
  }

  void _paintEdgeShadow(Canvas canvas, Rect sleeve, Offset recordCenter) {
    final width = radius * 0.35;
    final strip = Rect.fromLTWH(
      sleeve.right,
      sleeve.top,
      width,
      sleeve.height,
    );
    canvas
      ..save()
      ..clipPath(
        Path()..addOval(Rect.fromCircle(center: recordCenter, radius: radius)),
      )
      ..drawRect(
        strip,
        Paint()
          ..shader = LinearGradient(
            colors: [Colors.black.withValues(alpha: 0.55), Colors.transparent],
          ).createShader(strip),
      )
      ..restore();
  }

  void _paintSleeve(Canvas canvas, Rect sleeve) {
    final corner = Radius.circular(radius * 0.08);
    final body = RRect.fromRectAndRadius(sleeve, corner);
    final base = Color.lerp(label, Colors.black, 0.45)!;
    final ringWear = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.05
      ..color = Colors.white.withValues(alpha: 0.1);
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.75, radius * 0.03);

    canvas
      ..drawRRect(
        body,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(base, Colors.white, 0.18)!,
              base,
              Color.lerp(base, Colors.black, 0.3)!,
            ],
            stops: const [0, 0.55, 1],
          ).createShader(sleeve),
      )
      ..save()
      ..clipRRect(body)
      ..drawCircle(sleeve.center, radius * 0.9, ringWear)
      ..drawCircle(sleeve.center, radius * 0.38, ringWear)
      ..drawRect(
        Rect.fromLTWH(
          sleeve.left,
          sleeve.top,
          sleeve.width,
          sleeve.height * 0.5,
        ),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.1),
              Colors.transparent,
            ],
          ).createShader(sleeve),
      )
      ..restore()
      ..drawRRect(
        body,
        edge..color = Colors.white.withValues(alpha: 0.12),
      )
      ..drawLine(
        sleeve.topRight.translate(-edge.strokeWidth, radius * 0.06),
        sleeve.bottomRight.translate(-edge.strokeWidth, -radius * 0.06),
        Paint()
          ..strokeWidth = edge.strokeWidth * 1.6
          ..color = Colors.black.withValues(alpha: 0.45),
      );
  }

  void _paintBarShadow(Canvas canvas, Rect sleeve) {
    final strip = Rect.fromLTWH(0, sleeve.top, radius * 0.3, sleeve.height);
    canvas
      ..save()
      ..clipRRect(
        RRect.fromRectAndRadius(sleeve, Radius.circular(radius * 0.08)),
      )
      ..drawRect(
        strip,
        Paint()
          ..shader = LinearGradient(
            colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
          ).createShader(strip),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_SleevePainter oldDelegate) =>
      pulled != oldDelegate.pulled ||
      spin != oldDelegate.spin ||
      pop != oldDelegate.pop ||
      radius != oldDelegate.radius ||
      label != oldDelegate.label ||
      hole != oldDelegate.hole;
}

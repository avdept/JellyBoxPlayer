import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/device_volume_provider.dart';
import 'package:jplayer/src/domain/providers/volume_keys_provider.dart';
import 'package:jplayer/src/presentation/widgets/playback_target_picker.dart';

enum HudSide { left, right }

const _pillWidth = 45.0;
const _pillSpan = 250.0;
const _pillRadius = 22.5;
const _innerPad = 9.0;
const _edgeInset = 6.0;
const _filletTail = 35.0;
const _housingBlack = Color(0xFF000000);
const _trackCharcoal = Color(0xFF2C2C2E);
const _fillWhite = Color(0xFFFFFFFF);
const _onFill = Color(0xFF6E6E73);
const _onTrack = Color(0xFFFFFFFF);
const _showDuration = Duration(milliseconds: 260);
const _hideDuration = Duration(milliseconds: 180);
const _fillDuration = Duration(milliseconds: 220);
const _topFraction = 0.18;

class VolumeHud extends ConsumerStatefulWidget {
  const VolumeHud({this.side, super.key});

  final HudSide? side;

  static HudSide get platformSide =>
      Platform.isIOS ? HudSide.left : HudSide.right;

  @override
  ConsumerState<VolumeHud> createState() => _VolumeHudState();
}

class _VolumeHudState extends ConsumerState<VolumeHud> {
  HudSide get _side => widget.side ?? VolumeHud.platformSide;

  _PillGeometry get _geometry => _PillGeometry(side: _side);

  void _setLevel(double level, {required bool settle}) {
    ref.read(volumeKeysProvider.notifier).show();
    unawaited(
      ref.read(deviceVolumeProvider.notifier).setLevel(level, settle: settle),
    );
  }

  void _onTapUp(TapUpDetails details) {
    final geometry = _geometry;
    if (geometry.inIconZone(details.localPosition)) {
      ref.read(volumeKeysProvider.notifier).show();
      unawaited(ref.read(deviceVolumeProvider.notifier).toggleMute());
      return;
    }
    _setLevel(geometry.levelAt(details.localPosition), settle: true);
  }

  @override
  Widget build(BuildContext context) {
    final visible = ref.watch(volumeKeysProvider);
    final device = ref.watch(activeDeviceProvider);
    final volume = ref.watch(deviceVolumeProvider);
    final side = _side;
    final geometry = _geometry;
    final media = MediaQuery.of(context);
    final top = math.max(
      media.padding.top + 24,
      media.size.height * _topFraction,
    );

    return IgnorePointer(
      ignoring: !visible,
      child: Align(
        alignment: side == HudSide.right
            ? Alignment.topRight
            : Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.only(top: top),
          child: AnimatedSlide(
            offset: visible
                ? Offset.zero
                : Offset(side == HudSide.right ? 1 : -1, 0),
            duration: visible ? _showDuration : _hideDuration,
            curve: visible ? Curves.easeOutCubic : Curves.fastOutSlowIn,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _onTapUp,
              onVerticalDragUpdate: (details) => _setLevel(
                geometry.levelAt(details.localPosition),
                settle: false,
              ),
              onVerticalDragEnd: (_) => _setLevel(
                ref.read(deviceVolumeProvider).level,
                settle: true,
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: volume.effectiveLevel),
                duration: _fillDuration,
                curve: Curves.easeOutCubic,
                builder: (_, level, _) => CustomPaint(
                  size: geometry.size,
                  painter: _EdgePillPainter(
                    geometry: geometry,
                    level: level,
                    icon: volume.isSilent
                        ? Icons.volume_off_rounded
                        : device?.icon ?? Icons.speaker,
                    counter: '${(volume.effectiveLevel * 100).round()}',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillGeometry {
  const _PillGeometry({required this.side});

  final HudSide side;

  double get housingThickness => _pillWidth + _innerPad + _edgeInset;

  Size get size => Size(housingThickness, _pillSpan + 2 * (_innerPad + _filletTail));

  double get housingTop => _filletTail;

  double get housingBottom => size.height - _filletTail;

  Rect get track {
    final top = housingTop + _innerPad;
    final bottom = housingBottom - _innerPad;
    return side == HudSide.right
        ? Rect.fromLTRB(_innerPad, top, size.width - _edgeInset, bottom)
        : Rect.fromLTRB(_edgeInset, top, size.width - _innerPad, bottom);
  }

  double get iconSize => (_pillWidth * 0.54).clamp(16.0, 40.0);

  double get counterSize => (_pillWidth * 0.32).clamp(10.0, 20.0);

  double get iconZone => _pillWidth.clamp(50.0, 70.0);

  Offset get iconCenter =>
      Offset(track.center.dx, track.bottom - math.min(_pillWidth * 0.5, 38));

  Offset get counterCenter =>
      Offset(track.center.dx, track.top + math.min(_pillWidth * 0.5, 38));

  bool inIconZone(Offset position) =>
      position.dy >= track.bottom - iconZone && position.dy <= track.bottom;

  double levelAt(Offset position) =>
      ((track.bottom - position.dy) / track.height).clamp(0.0, 1.0);

  double get edgeX => side == HudSide.right ? size.width : 0;

  double get innerX => side == HudSide.right ? 0 : size.width;

  Path housing() {
    final radius = Radius.circular(
      math.min(_pillRadius + _innerPad, housingThickness / 2),
    );
    final body = Rect.fromLTRB(0, housingTop, size.width, housingBottom);
    final rounded = side == HudSide.right
        ? RRect.fromRectAndCorners(body, topLeft: radius, bottomLeft: radius)
        : RRect.fromRectAndCorners(body, topRight: radius, bottomRight: radius);
    final tangent = housingThickness * 0.36;
    final filletX = side == HudSide.right ? edgeX - tangent : edgeX + tangent;

    return Path()
      ..addRRect(rounded)
      ..moveTo(edgeX, housingTop - _filletTail)
      ..quadraticBezierTo(edgeX, housingTop, filletX, housingTop)
      ..lineTo(edgeX, housingTop)
      ..close()
      ..moveTo(edgeX, housingBottom + _filletTail)
      ..quadraticBezierTo(edgeX, housingBottom, filletX, housingBottom)
      ..lineTo(edgeX, housingBottom)
      ..close();
  }
}

class _EdgePillPainter extends CustomPainter {
  _EdgePillPainter({
    required this.geometry,
    required this.level,
    required this.icon,
    required this.counter,
  });

  final _PillGeometry geometry;
  final double level;
  final IconData icon;
  final String counter;

  @override
  void paint(Canvas canvas, Size size) {
    final track = geometry.track;
    final pill = RRect.fromRectAndRadius(
      track,
      const Radius.circular(_pillRadius),
    );
    final fill = Rect.fromLTRB(
      track.left,
      track.bottom - track.height * level,
      track.right,
      track.bottom,
    );
    final unfilled = Rect.fromLTRB(track.left, track.top, track.right, fill.top);

    canvas
      ..drawPath(geometry.housing(), Paint()..color = _housingBlack)
      ..drawRRect(pill, Paint()..color = _trackCharcoal)
      ..save()
      ..clipRRect(pill)
      ..drawRect(fill, Paint()..color = _fillWhite)
      ..restore();

    _drawGlyphs(canvas, clip: unfilled, color: _onTrack);
    _drawGlyphs(canvas, clip: fill, color: _onFill);
  }

  void _drawGlyphs(Canvas canvas, {required Rect clip, required Color color}) {
    if (clip.isEmpty) return;
    canvas
      ..save()
      ..clipRect(clip);
    _drawText(
      canvas,
      String.fromCharCode(icon.codePoint),
      center: geometry.iconCenter,
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: geometry.iconSize,
        color: color,
      ),
    );
    _drawText(
      canvas,
      counter,
      center: geometry.counterCenter,
      style: TextStyle(
        fontSize: geometry.counterSize,
        fontWeight: FontWeight.w700,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    canvas.restore();
  }

  void _drawText(
    Canvas canvas,
    String text, {
    required Offset center,
    required TextStyle style,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_EdgePillPainter old) =>
      old.level != level ||
      old.icon != icon ||
      old.counter != counter ||
      old.geometry.side != geometry.side;
}

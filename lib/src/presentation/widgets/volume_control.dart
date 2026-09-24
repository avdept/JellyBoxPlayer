import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/volume_provider.dart';
import 'package:optional_features/jellybox_cloud.dart';

const _buttonSize = 44.0;
const _sliderLength = 150.0;
const _sliderPadding = 14.0;
const _hideDelay = Duration(milliseconds: 150);
const _wheelSettleDelay = Duration(milliseconds: 100);
const _wheelLevelPerPixel = 0.0004;
const _remoteSendInterval = Duration(milliseconds: 150);
const _remoteHold = Duration(seconds: 2);

class VolumeControl extends ConsumerStatefulWidget {
  const VolumeControl({this.size = _buttonSize, this.color, super.key});

  final double size;
  final Color? color;

  @override
  ConsumerState<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends ConsumerState<VolumeControl> {
  final _portalController = OverlayPortalController();
  final _link = LayerLink();
  Timer? _hideTimer;
  Timer? _wheelTimer;
  Timer? _remoteSendTimer;
  Timer? _remoteHoldTimer;
  bool _expanded = false;
  double? _remoteLevel;
  double? _remotePending;
  double _lastRemoteAudible = 0.5;

  bool get _remote => ref.read(playingElsewhereProvider);

  double get _level => _remote
      ? _remoteLevel ?? ref.read(remoteSessionProvider)?.doc.volume ?? 1
      : ref.read(volumeProvider).level;

  VolumeState _watchVolume() {
    if (!ref.watch(playingElsewhereProvider)) return ref.watch(volumeProvider);
    final reported = ref.watch(
      remoteSessionProvider.select((remote) => remote?.doc.volume ?? 1),
    );
    return VolumeState(level: _remoteLevel ?? reported);
  }

  void _setLevel(double value, {bool settle = true}) {
    if (!_remote) {
      unawaited(
        ref.read(volumeProvider.notifier).setLevel(value, persist: settle),
      );
      return;
    }
    final level = value.clamp(0.0, 1.0);
    if (level > 0) _lastRemoteAudible = level;
    setState(() => _remoteLevel = level);
    _remotePending = level;
    if (settle) {
      _remoteSendTimer?.cancel();
      _remoteSendTimer = null;
      _flushRemote();
    } else {
      _remoteSendTimer ??= Timer(_remoteSendInterval, () {
        _remoteSendTimer = null;
        _flushRemote();
      });
    }
    _remoteHoldTimer?.cancel();
    _remoteHoldTimer = Timer(_remoteHold, () {
      if (mounted) setState(() => _remoteLevel = null);
    });
  }

  void _flushRemote() {
    final level = _remotePending;
    if (level == null || !mounted) return;
    _remotePending = null;
    unawaited(
      ref
          .read(cloudProvider.notifier)
          .sendCommand(PlayerCommand.volume, value: level),
    );
  }

  void _toggleMute() {
    if (!_remote) {
      unawaited(ref.read(volumeProvider.notifier).toggleMute());
      return;
    }
    _setLevel(_level > 0 ? 0 : _lastRemoteAudible);
  }

  void _show() {
    _hideTimer?.cancel();
    if (_expanded) return;
    setState(() => _expanded = true);
    _portalController.show();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideDelay, () {
      if (!mounted || !_expanded) return;
      setState(() => _expanded = false);
      _portalController.hide();
    });
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final delta = -event.scrollDelta.dy * _wheelLevelPerPixel;
    if (delta == 0) return;
    _setLevel(_level + delta, settle: false);
    _wheelTimer?.cancel();
    _wheelTimer = Timer(_wheelSettleDelay, () {
      if (mounted) _setLevel(_level);
    });
  }

  IconData _iconFor(VolumeState volume) {
    if (volume.isSilent) return Icons.volume_off_rounded;
    if (volume.effectiveLevel < 0.34) return Icons.volume_mute_rounded;
    if (volume.effectiveLevel < 0.67) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _wheelTimer?.cancel();
    _remoteSendTimer?.cancel();
    _remoteHoldTimer?.cancel();
    super.dispose();
  }

  Color _tint(ThemeData theme) => widget.color ?? theme.colorScheme.onPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final volume = _watchVolume();

    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: (context) => Align(
        alignment: Alignment.topLeft,
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomCenter,
          followerAnchor: Alignment.bottomCenter,
          child: _capsule(theme, volume),
        ),
      ),
      child: CompositedTransformTarget(
        link: _link,
        child: MouseRegion(
          onEnter: (_) => _show(),
          onExit: (_) => _scheduleHide(),
          child: Opacity(
            opacity: _expanded ? 0 : 1,
            child: _muteButton(theme, volume),
          ),
        ),
      ),
    );
  }

  Widget _capsule(ThemeData theme, VolumeState volume) => MouseRegion(
    onEnter: (_) => _show(),
    onExit: (_) => _scheduleHide(),
    child: Listener(
      onPointerSignal: _onPointerSignal,
      child: SizedBox(
        width: widget.size,
        height: _sliderLength + widget.size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: ColoredBox(
              color: Colors.black.withOpacity(0.35),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: _sliderPadding),
                      child: _slider(theme, volume),
                    ),
                  ),
                  _muteButton(theme, volume),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _slider(ThemeData theme, VolumeState volume) => RotatedBox(
    quarterTurns: 3,
    child: SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: _tint(theme),
        inactiveTrackColor: _tint(theme).withOpacity(0.25),
        thumbColor: _tint(theme),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      child: Slider(
        value: volume.effectiveLevel,
        onChanged: (value) => _setLevel(value, settle: false),
        onChangeEnd: _setLevel,
      ),
    ),
  );

  Widget _muteButton(ThemeData theme, VolumeState volume) => IconButton(
    onPressed: _toggleMute,
    padding: EdgeInsets.zero,
    constraints: BoxConstraints.tightFor(
      width: widget.size,
      height: widget.size,
    ),
    color: _tint(theme),
    iconSize: widget.size * 0.55,
    icon: Icon(_iconFor(volume)),
  );
}

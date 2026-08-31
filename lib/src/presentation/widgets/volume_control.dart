import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/volume_provider.dart';

const _buttonSize = 44.0;
const _sliderLength = 150.0;
const _sliderPadding = 14.0;
const _hideDelay = Duration(milliseconds: 150);

class VolumeControl extends ConsumerStatefulWidget {
  const VolumeControl({this.size = _buttonSize, super.key});

  final double size;

  @override
  ConsumerState<VolumeControl> createState() => _VolumeControlState();
}

class _VolumeControlState extends ConsumerState<VolumeControl> {
  final _portalController = OverlayPortalController();
  final _link = LayerLink();
  Timer? _hideTimer;
  bool _expanded = false;

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

  IconData _iconFor(VolumeState volume) {
    if (volume.isSilent) return Icons.volume_off_rounded;
    if (volume.effectiveLevel < 0.34) return Icons.volume_mute_rounded;
    if (volume.effectiveLevel < 0.67) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final volume = ref.watch(volumeProvider);

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
  );

  Widget _slider(ThemeData theme, VolumeState volume) => RotatedBox(
    quarterTurns: 3,
    child: SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: theme.colorScheme.onPrimary,
        inactiveTrackColor: theme.colorScheme.onPrimary.withOpacity(0.25),
        thumbColor: theme.colorScheme.onPrimary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      ),
      child: Slider(
        value: volume.effectiveLevel,
        onChanged: (value) =>
            ref.read(volumeProvider.notifier).setLevel(value, persist: false),
        onChangeEnd: ref.read(volumeProvider.notifier).setLevel,
      ),
    ),
  );

  Widget _muteButton(ThemeData theme, VolumeState volume) => IconButton(
    onPressed: ref.read(volumeProvider.notifier).toggleMute,
    padding: EdgeInsets.zero,
    constraints: BoxConstraints.tightFor(
      width: widget.size,
      height: widget.size,
    ),
    color: theme.colorScheme.onPrimary,
    iconSize: widget.size * 0.55,
    icon: Icon(_iconFor(volume)),
  );
}

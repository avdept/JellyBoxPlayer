import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/playback/output_controller.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_focusable.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_link_dialog.dart';
import 'package:jplayer/src/presentation/widgets/playback_target_picker.dart';
import 'package:optional_features/jellybox_cloud.dart';

class TvPlayOnDialog extends ConsumerStatefulWidget {
  const TvPlayOnDialog({super.key});

  static Future<void> show(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => const TvPlayOnDialog(),
  );

  @override
  ConsumerState<TvPlayOnDialog> createState() => _TvPlayOnDialogState();
}

class _TvPlayOnDialogState extends ConsumerState<TvPlayOnDialog> {
  String? _failed;

  OutputController get _outputs => ref.read(outputControllerProvider);

  void _playHere() {
    unawaited(_outputs.playHere());
    Navigator.of(context).pop();
  }

  Future<void> _handOffTo(ConductorDevice device) async {
    setState(() => _failed = null);
    final taken = await _outputs.handOffTo(device);
    if (!mounted) return;
    if (taken) {
      Navigator.of(context).pop();
    } else {
      setState(() => _failed = device.id);
    }
  }

  Future<void> _connect() async {
    Navigator.of(context).pop();
    await TvLinkDialog.show(context);
  }

  bool _onAnotherServer(ConductorDevice device) =>
      ref.read(cloudProvider.notifier).sameBackend(device) == false;

  String _subtitle(ConductorDevice device, CloudState cloud) {
    if (cloud.handingOffTo == device.id) {
      return device.isOnline ? 'Connecting…' : 'Waking up…';
    }
    if (_failed == device.id) return cloud.error ?? 'Could not take over';
    if (device.isRenderer && !ref.watch(remoteSessionOursProvider)) {
      return 'Playing on a different server';
    }
    if (_onAnotherServer(device)) return 'Connected to a different server';
    if (device.isRenderer) return 'Playing';
    return device.isOnline ? 'Your device' : 'Asleep';
  }

  @override
  Widget build(BuildContext context) {
    final cloud = ref.watch(cloudProvider);
    final elsewhere = ref.watch(remoteRendererProvider);
    final onThisTv = elsewhere == null;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Play on',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              _DeviceRow(
                icon: Icons.tv_rounded,
                title: 'This TV',
                subtitle: onThisTv ? 'Playing' : null,
                selected: onThisTv,
                autofocus: onThisTv,
                onSelect: onThisTv ? null : _playHere,
              ),
              if (ref.watch(cloudAvailableProvider) && cloud.account == null)
                _DeviceRow(
                  icon: Icons.cloud_off_outlined,
                  title: 'Jellybox Link not connected',
                  subtitle: 'Connect to play on your other devices',
                  onSelect: () => unawaited(_connect()),
                ),
              for (final device in cloud.targets)
                _DeviceRow(
                  icon: conductorDeviceIcon(device.platform),
                  title: device.name,
                  subtitle: _subtitle(device, cloud),
                  selected: device.id == elsewhere?.id,
                  busy: cloud.handingOffTo == device.id,
                  autofocus: device.id == elsewhere?.id,
                  onSelect:
                      device.isRenderer ||
                          cloud.handingOffTo != null ||
                          _onAnotherServer(device)
                      ? null
                      : () => unawaited(_handOffTo(device)),
                ),
              if (cloud.account != null && cloud.targets.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 4, 14, 8),
                  child: Text(
                    'No other devices are signed in to Jellybox Link.',
                    style: TvTokens.caption,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.busy = false,
    this.autofocus = false,
    this.onSelect,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool busy;
  final bool autofocus;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final enabled = onSelect != null;
    return TvFocusable(
      enabled: enabled,
      autofocus: autofocus,
      scrollOnFocus: false,
      onSelect: onSelect,
      debugLabel: 'play-on:$title',
      builder: (context, focused) => AnimatedContainer(
        duration: TvTokens.focusDuration,
        curve: TvTokens.focusCurve,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: focused ? TvTokens.listFocus(context) : Colors.transparent,
          borderRadius: TvTokens.cardRadius,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? accent
                  : (enabled ? Colors.white : Colors.white38),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: enabled || selected
                          ? Colors.white
                          : Colors.white54,
                    ),
                  ),
                  if (subtitle case final subtitle?)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TvTokens.caption,
                    ),
                ],
              ),
            ),
            if (busy)
              const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (selected)
              Icon(Icons.check_rounded, size: 18, color: accent),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/playback/upnp_playback_target.dart';
import 'package:jplayer/src/domain/providers/upnp_renderers_provider.dart';
import 'package:jplayer/src/presentation/widgets/anchored_dropdown.dart';

const _menuWidth = 320.0;
const _menuMaxHeight = 360.0;

class PlaybackTargetButton extends ConsumerStatefulWidget {
  const PlaybackTargetButton({
    super.key,
    this.size,
    this.color,
    this.activeColor,
  });

  final double? size;
  final Color? color;
  final Color? activeColor;

  @override
  ConsumerState<PlaybackTargetButton> createState() =>
      _PlaybackTargetButtonState();
}

class _PlaybackTargetButtonState extends ConsumerState<PlaybackTargetButton> {
  final _dropdown = AnchoredDropdownController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = ref.watch(playbackTargetProvider);
    final casting = target.kind != PlaybackTargetKind.local;

    final idleColor = widget.color ?? theme.colorScheme.onPrimary;
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;

    final box = widget.size;
    final glyph = box == null ? IconTheme.of(context).size ?? 24 : box * 0.55;
    final narrow = MediaQuery.sizeOf(context).width < 600;

    return AnchoredDropdown(
      controller: _dropdown,
      direction: DropDirection.up,
      alignment: narrow ? DropAlignment.center : DropAlignment.end,
      menuBuilder: (context) => PlaybackTargetMenu(onDone: _dropdown.close),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            tooltip: casting ? 'Playing on ${target.name}' : 'Play on a device',
            padding: box == null ? null : EdgeInsets.zero,
            constraints: box == null
                ? null
                : BoxConstraints.tightFor(width: box, height: box),
            iconSize: glyph,
            icon: Icon(
              casting ? Icons.cast_connected : Icons.cast,
              color: casting ? activeColor : idleColor,
            ),
            onPressed: _dropdown.toggle,
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: _BetaBadge(
                scale: glyph / 24,
                background: activeColor,
                foreground: idleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BetaBadge extends StatelessWidget {
  const _BetaBadge({
    required this.scale,
    required this.background,
    required this.foreground,
  });

  final double scale;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final fontSize = 9 * scale;
    final letterSpacing = 0.4 * scale;
    final padding = 4 * scale;

    return Container(
      height: fontSize + 4 * scale,
      alignment: Alignment.center,
      padding: EdgeInsets.only(
        left: padding + letterSpacing / 2,
        right: padding,
        top: fontSize * 0.2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4 * scale),
      ),
      child: Text(
        'BETA',
        textAlign: TextAlign.center,
        strutStyle: StrutStyle(
          fontSize: fontSize,
          height: 1,
          forceStrutHeight: true,
        ),
        style: TextStyle(
          fontSize: fontSize,
          height: 1,
          letterSpacing: letterSpacing,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }
}

class PlaybackTargetMenu extends ConsumerStatefulWidget {
  const PlaybackTargetMenu({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  ConsumerState<PlaybackTargetMenu> createState() => _PlaybackTargetMenuState();
}

class _PlaybackTargetMenuState extends ConsumerState<PlaybackTargetMenu> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(upnpRenderersProvider.notifier).refresh());
    });
  }

  void _selectLocal() {
    ref.read(playbackTargetProvider.notifier).useLocal();
    widget.onDone();
  }

  void _selectRenderer(UpnpRenderer renderer) {
    ref
        .read(playbackTargetProvider.notifier)
        .select(UpnpPlaybackTarget(renderer));
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = ref.watch(playbackTargetProvider);
    final discovery = ref.watch(upnpRenderersProvider);
    final width = math.min(_menuWidth, MediaQuery.sizeOf(context).width - 24);

    return Material(
      color: Colors.grey[900],
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: width,
          minWidth: width,
          maxHeight: _menuMaxHeight,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, right: 8),
                child: Row(
                  children: [
                    Text('Play on', style: theme.textTheme.titleSmall),
                    const Spacer(),
                    if (discovery.scanning)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      IconButton(
                        tooltip: 'Scan again',
                        iconSize: 18,
                        icon: const Icon(Icons.refresh),
                        onPressed: () =>
                            ref.read(upnpRenderersProvider.notifier).refresh(),
                      ),
                  ],
                ),
              ),
              _TargetTile(
                icon: _thisDeviceIcon,
                title: 'This device',
                selected: active.kind == PlaybackTargetKind.local,
                onTap: _selectLocal,
              ),
              for (final renderer in discovery.renderers)
                _TargetTile(
                  icon: rendererIcon(renderer),
                  title: renderer.name,
                  subtitle: renderer.model,
                  selected: active.id == renderer.id,
                  onTap: () => _selectRenderer(renderer),
                ),
              if (discovery.renderers.isEmpty && !discovery.scanning)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    'No DLNA devices found on this network.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData get _thisDeviceIcon {
    if (Platform.isIOS) return Icons.phone_iphone;
    if (Platform.isAndroid) return Icons.smartphone;
    return Icons.laptop_mac;
  }
}

IconData rendererIcon(UpnpRenderer renderer) {
  final haystack = [
    renderer.name,
    renderer.model ?? '',
    renderer.device.deviceType,
  ].join(' ').toLowerCase();

  if (haystack.contains('tv') ||
      haystack.contains('display') ||
      haystack.contains('screen') ||
      haystack.contains('bravia') ||
      haystack.contains('roku')) {
    return Icons.tv;
  }
  if (haystack.contains('receiver') ||
      haystack.contains('amplifier') ||
      haystack.contains('denon') ||
      haystack.contains('yamaha') ||
      haystack.contains('marantz')) {
    return Icons.settings_input_component;
  }
  return Icons.speaker;
}

class _TargetTile extends StatelessWidget {
  const _TargetTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = selected ? theme.colorScheme.primary : null;

    return ListTile(
      dense: true,
      leading: Icon(icon, color: tint, size: 20),
      title: Text(title, style: TextStyle(color: tint)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
      trailing: selected
          ? Icon(Icons.check, size: 18, color: theme.colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

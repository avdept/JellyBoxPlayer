import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:optional_features/jellybox_cloud.dart';
import 'package:jplayer/src/domain/playback/control_point_host_provider.dart';
import 'package:jplayer/src/domain/playback/output_controller.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/playback/upnp_playback_target.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/output_route_provider.dart';
import 'package:jplayer/src/domain/providers/upnp_renderers_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/adaptive_dialog_action.dart';
import 'package:jplayer/src/presentation/widgets/anchored_dropdown.dart';
import 'package:jplayer/src/presentation/widgets/frosted_panel.dart';
import 'package:jplayer/src/presentation/widgets/jellybox_cloud_settings.dart';
import 'package:jplayer/src/presentation/widgets/marquee_text.dart';
import 'package:jplayer/src/presentation/widgets/volume_control.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:jplayer/src/providers/diagnostics_provider.dart';
import 'package:native_route_picker/native_route_picker.dart';
import 'package:optional_features/upnp_quirks.dart';

const _menuWidth = 320.0;
const _menuMaxHeight = 360.0;

typedef ActiveDevice = ({String name, IconData icon});

final activeDeviceProvider = Provider<ActiveDevice?>((ref) {
  final elsewhere = ref.watch(remoteRendererProvider);
  if (elsewhere != null) {
    return (
      name: elsewhere.name,
      icon: conductorDeviceIcon(elsewhere.platform),
    );
  }
  final target = ref.watch(playbackTargetProvider);
  if (target.kind == PlaybackTargetKind.local) {
    final route = ref.watch(externalOutputRouteProvider);
    return route == null
        ? null
        : (name: route.name, icon: outputRouteIcon(route.kind));
  }
  return (
    name: target.name,
    icon: target is UpnpPlaybackTarget
        ? rendererIcon(target.renderer)
        : Icons.speaker,
  );
});

class PlaybackTargetButton extends ConsumerStatefulWidget {
  const PlaybackTargetButton({
    super.key,
    this.size,
    this.color,
    this.activeColor,
    this.showsDeviceName = false,
  });

  final double? size;
  final Color? color;
  final Color? activeColor;
  final bool showsDeviceName;

  @override
  ConsumerState<PlaybackTargetButton> createState() =>
      _PlaybackTargetButtonState();
}

class PlaybackTargetMenuAnchor extends StatefulWidget {
  const PlaybackTargetMenuAnchor({required this.builder, super.key});

  final Widget Function(VoidCallback open) builder;

  @override
  State<PlaybackTargetMenuAnchor> createState() =>
      _PlaybackTargetMenuAnchorState();
}

class _PlaybackTargetMenuAnchorState extends State<PlaybackTargetMenuAnchor> {
  final _dropdown = AnchoredDropdownController();

  void _open() {
    final isDesktop = DeviceType.fromScreenSize(
      MediaQuery.sizeOf(context),
    ).isDesktop;
    if (isDesktop) {
      _dropdown.toggle();
    } else {
      unawaited(PlaybackTargetMenu.showSheet(context));
    }
  }

  @override
  Widget build(BuildContext context) => AnchoredDropdown(
    controller: _dropdown,
    direction: DropDirection.up,
    menuBuilder: (context) => PlaybackTargetMenu(onDone: _dropdown.close),
    child: widget.builder(_open),
  );
}

class _PlaybackTargetButtonState extends ConsumerState<PlaybackTargetButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = ref.watch(playbackTargetProvider);
    final casting = target.kind != PlaybackTargetKind.local;

    final idleColor = widget.color ?? theme.colorScheme.onPrimary;
    final activeColor = widget.activeColor ?? theme.colorScheme.primary;

    final box = widget.size;
    final glyph = box == null ? IconTheme.of(context).size ?? 24 : box * 0.55;

    final device = ref.watch(activeDeviceProvider);

    return PlaybackTargetMenuAnchor(
      builder: (open) => widget.showsDeviceName && device != null
          ? _deviceName(theme, device.name, device.icon, activeColor, open)
          : _icon(
              casting: casting,
              target: target,
              box: box,
              glyph: glyph,
              idleColor: idleColor,
              activeColor: activeColor,
              open: open,
            ),
    );
  }

  Widget _deviceName(
    ThemeData theme,
    String name,
    IconData icon,
    Color color,
    VoidCallback open,
  ) => Semantics(
    button: true,
    label: 'Playing on $name. Choose a device',
    child: InkWell(
      onTap: open,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: MarqueeText(
                  name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _icon({
    required bool casting,
    required PlaybackTarget target,
    required double? box,
    required double glyph,
    required Color idleColor,
    required Color activeColor,
    required VoidCallback open,
  }) => Stack(
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
        onPressed: open,
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
  );
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
  const PlaybackTargetMenu({
    required this.onDone,
    this.inSheet = false,
    super.key,
  });

  final VoidCallback onDone;
  final bool inSheet;

  static Future<void> showSheet(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (sheetContext) => PlaybackTargetMenu(
          inSheet: true,
          onDone: () => Navigator.of(sheetContext).pop(),
        ),
      );

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

  OutputController get _outputs => ref.read(outputControllerProvider);

  void _selectLocal() {
    unawaited(_outputs.playHere());
    widget.onDone();
  }

  void _connectCloud() {
    final navigator = Navigator.of(context, rootNavigator: true);
    widget.onDone();
    unawaited(connectJellyboxCloud(navigator.context));
  }

  void _handOffTo(ConductorDevice device) {
    unawaited(_outputs.handOffTo(device));
    widget.onDone();
  }

  void _selectRenderer(UpnpRenderer renderer) {
    unawaited(_outputs.playOn(UpnpPlaybackTarget(renderer)));
    widget.onDone();
  }

  Future<void> _shareDevices(List<UpnpRenderer> renderers) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final diagnostics = ref.read(diagnosticsProvider);
    final payload = deviceReportPayload(renderers);

    widget.onDone();
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => _ShareDevicesDialog(count: renderers.length),
    );
    if (confirmed != true) return;

    await diagnostics.report(upnpDeviceReportMessage, data: payload);
    messenger?.showSnackBar(
      const SnackBar(content: Text('Device list sent. Thank you!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = ref.watch(playbackTargetProvider);
    final discovery = ref.watch(upnpRenderersProvider);
    final conductor = ref.watch(cloudProvider);
    final host = ref.watch(controlPointHostProvider);
    final width = math.min(_menuWidth, MediaQuery.sizeOf(context).width - 24);
    final elsewhere = ref.watch(remoteRendererProvider);
    final onThisDevice =
        active.kind == PlaybackTargetKind.local && elsewhere == null;
    final route = onThisDevice ? ref.watch(externalOutputRouteProvider) : null;
    final localSelected = onThisDevice && route == null;

    final list = SingleChildScrollView(
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
                IconButton(
                  tooltip: 'Share this device list with the developer',
                  iconSize: 18,
                  icon: const Icon(Icons.upload),
                  onPressed: discovery.scanning || discovery.renderers.isEmpty
                      ? null
                      : () => _shareDevices(discovery.renderers),
                ),
              ],
            ),
          ),
          _TargetTile(
            icon: _thisDeviceIcon,
            title: 'This device',
            selected: localSelected,
            onTap: _selectLocal,
          ),
          if (ref.watch(cloudAvailableProvider) && conductor.account == null)
            _TargetTile(
              icon: Icons.cloud_off_outlined,
              title: 'Continuity not available',
              subtitle: 'Tap to connect',
              selected: false,
              onTap: _connectCloud,
            ),
          for (final device in conductor.targets) ...[
            _TargetTile(
              icon: conductorDeviceIcon(device.platform),
              title: device.name,
              subtitle: device.isRenderer ? 'Playing' : 'Your device',
              selected: device.id == elsewhere?.id,
              onTap: device.isRenderer ? null : () => _handOffTo(device),
            ),
            if (device.id == elsewhere?.id) _volume,
          ],
          for (final renderer in discovery.renderers) ...[
            _rendererTile(
              renderer,
              selected: elsewhere == null && active.id == renderer.id,
              host: host,
            ),
            if (elsewhere == null && active.id == renderer.id) _volume,
          ],
          if (discovery.renderers.isEmpty &&
              conductor.targets.isEmpty &&
              !discovery.scanning)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                'No DLNA devices found on this network.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          if (NativeRoutePicker.isSupported) ...[
            Builder(
              builder: (row) => _TargetTile(
                icon: route == null
                    ? Icons.airplay
                    : outputRouteIcon(route.kind),
                title: 'AirPlay & Bluetooth',
                subtitle: route?.name,
                selected: route != null,
                onTap: () => _showSystemOutputs(row),
              ),
            ),
            if (route != null) _volume,
          ],
        ],
      ),
    );

    final palette = ref.watch(artworkSchemeProvider).valueOrNull;

    if (widget.inSheet) {
      return FrostedPanel(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.7,
            ),
            child: list,
          ),
        ),
      );
    }

    return Theme(
      data: palette == null ? theme : theme.copyWith(colorScheme: palette),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x80000000),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: FrostedPanel(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width,
              minWidth: width,
              maxHeight: _menuMaxHeight,
            ),
            child: list,
          ),
        ),
      ),
    );
  }

  void _showSystemOutputs(BuildContext row) {
    final box = row.findRenderObject() as RenderBox?;
    final anchor = box?.localToGlobal(box.size.center(Offset.zero));
    if (ref.read(playingElsewhereProvider)) unawaited(_outputs.playHere());
    widget.onDone();
    unawaited(NativeRoutePicker.showOutputSwitcher(anchor: anchor));
  }

  Widget get _volume => const DeviceVolumeSlider(
    padding: EdgeInsets.only(left: 12, right: 16, bottom: 4),
  );

  Widget _rendererTile(
    UpnpRenderer renderer, {
    required bool selected,
    required ControlPointHost host,
  }) {
    final blocked = castingBlockedReason(
      deviceHoldsQueue: renderer.holdsQueue,
      host: host,
    );

    return _TargetTile(
      icon: rendererIcon(renderer),
      title: renderer.name,
      subtitle: blocked ?? [renderer.host, ?renderer.model].join(' · '),
      selected: selected,
      onTap: blocked == null ? () => _selectRenderer(renderer) : null,
    );
  }

  IconData get _thisDeviceIcon {
    if (Platform.isIOS) return Icons.phone_iphone;
    if (Platform.isAndroid) return Icons.smartphone;
    return Icons.laptop_mac;
  }
}

IconData conductorDeviceIcon(String platform) => switch (platform) {
  'ios' => Icons.phone_iphone,
  'android' => Icons.phone_android,
  'macos' => Icons.laptop_mac,
  'windows' => Icons.laptop_windows,
  'linux' => Icons.computer,
  _ => Icons.devices_other,
};

IconData outputRouteIcon(OutputRouteKind kind) => switch (kind) {
  OutputRouteKind.airPlay => Icons.airplay,
  OutputRouteKind.bluetooth => Icons.bluetooth_audio,
  OutputRouteKind.wired => Icons.headphones,
  OutputRouteKind.car => Icons.directions_car,
  OutputRouteKind.builtIn || OutputRouteKind.other => Icons.speaker,
};

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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onTap == null;
    final tint = disabled
        ? theme.disabledColor
        : (selected ? theme.colorScheme.primary : null);

    return ListTile(
      dense: true,
      enabled: !disabled,
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

const upnpDeviceReportMessage = 'upnp device report';

Map<String, Object?> deviceReportPayload(List<UpnpRenderer> renderers) => {
  'devices': [
    for (final renderer in renderers) _reportEntry(renderer),
  ],
};

Map<String, Object?> _reportEntry(UpnpRenderer renderer) {
  final fingerprint = renderer.fingerprint;
  return {
    'manufacturer': fingerprint.manufacturer,
    'modelName': fingerprint.modelName,
    'modelNumber': fingerprint.modelNumber,
    'deviceType': fingerprint.deviceType,
    'hasFriendlyName': fingerprint.friendlyName != null,
    'hasRoomName': renderer.device.roomName != null,
    'services': {
      for (final service in fingerprint.services) service: true,
    },
    'actions': {for (final action in fingerprint.actions) action: true},
    'sinkMimeTypes': {
      for (final mimeType in fingerprint.sinkMimeTypes) mimeType: true,
    },
    'queue': renderer.queueKind.name,
    'queueDriven': renderer.holdsQueue,
    'quirks': renderer.quirks.toJson(),
    'rules': rulesFor(fingerprint).map((rule) => rule.name).toList(),
  };
}

class _ShareDevicesDialog extends StatelessWidget {
  const _ShareDevicesDialog({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => AlertDialog.adaptive(
    title: const Text('Share what JellyBox found?'),
    content: Text(
      count == 1
          ? 'Send the details of the DLNA device on your network? It stays '
                'private and is only used to build proper support for '
                'different manufacturers.'
          : 'Send the details of the $count DLNA devices on your network? It '
                'stays private and is only used to build proper support for '
                'different manufacturers.',
    ),
    actions: [
      AdaptiveDialogAction(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Not now'),
      ),
      AdaptiveDialogAction(
        onPressed: () => Navigator.pop(context, true),
        isDefaultAction: true,
        child: const Text('Share'),
      ),
    ],
  );
}

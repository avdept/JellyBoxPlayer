import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/conductor/conductor_models.dart';
import 'package:jplayer/src/domain/providers/conductor_provider.dart';

class ConductorDevicesSheet extends ConsumerWidget {
  const ConductorDevicesSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const ConductorDevicesSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conductorProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Play on', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(_statusLine(state), style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),

            if (state.error case final error?) ...[
              Text(error, style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 12),
            ],

            if (!state.isConnected)
              ListTile(
                leading: const Icon(Icons.cloud_off),
                title: const Text('Not connected to a conductor'),
                subtitle: const Text('Set its address in Settings'),
                onTap: () => Navigator.of(context).pop(),
              )
            else if (state.devices.isEmpty)
              const ListTile(
                leading: Icon(Icons.hourglass_empty),
                title: Text('Looking for devices...'),
              )
            else
              for (final device in state.devices)
                _DeviceTile(
                  device: device,
                  onTap: () => _onTap(context, ref, device),
                ),

            if (state.lastHandoffMs case final ms?) ...[
              const SizedBox(height: 12),
              Text(
                'Last handoff took ${ms}ms',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    ConductorDevice device,
  ) async {
    final notifier = ref.read(conductorProvider.notifier);
    Navigator.of(context).pop();

    if (device.isSelf) {
      await notifier.claimHere();
    } else {
      await notifier.handoffTo(device.id);
    }
  }

  String _statusLine(ConductorUiState state) => switch (state.status) {
    ConductorStatus.off => 'Conductor off',
    ConductorStatus.connecting => 'Connecting...',
    ConductorStatus.reconnecting => 'Reconnecting...',
    ConductorStatus.error => 'Connection problem',
    ConductorStatus.listening => 'Playing on another device',
    ConductorStatus.rendering => 'Playing here',
  };
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onTap});

  final ConductorDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(_iconFor(device.platform)),
      title: Text(device.isSelf ? '${device.name} (this device)' : device.name),
      subtitle: device.isRenderer ? const Text('Playing') : null,
      trailing: device.isRenderer
          ? Icon(Icons.volume_up, color: theme.colorScheme.primary)
          : null,
      enabled: !device.isRenderer,
      onTap: onTap,
    );
  }

  IconData _iconFor(String platform) => switch (platform) {
    'ios' => Icons.phone_iphone,
    'android' => Icons.phone_android,
    'macos' => Icons.laptop_mac,
    'windows' => Icons.laptop_windows,
    'linux' => Icons.computer,
    _ => Icons.devices_other,
  };
}

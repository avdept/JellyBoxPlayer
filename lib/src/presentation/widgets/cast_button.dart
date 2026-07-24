import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/cast_provider.dart';

class CastButton extends ConsumerWidget {
  const CastButton({
    super.key,
    this.size = 24,
    this.color,
    this.activeColor,
  });

  final double size;
  final Color? color;
  final Color? activeColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cast = ref.read(castControllerProvider);
    final idle = color ?? IconTheme.of(context).color;
    final active = activeColor ?? Theme.of(context).colorScheme.primary;

    return StreamBuilder<GoogleCastSession?>(
      stream: cast.sessionStream,
      builder: (context, snapshot) {
        final connected = snapshot.data?.connectionState ==
            GoogleCastConnectState.connected;
        return IconButton(
          iconSize: size,
          color: connected ? active : idle,
          tooltip: 'Cast',
          icon: Icon(connected ? Icons.cast_connected : Icons.cast),
          onPressed: () => showCastDevicesSheet(context, ref),
        );
      },
    );
  }
}

Future<void> showCastDevicesSheet(BuildContext context, WidgetRef ref) async {
  final cast = ref.read(castControllerProvider);
  cast.startDiscovery();
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.grey[900],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: StreamBuilder<GoogleCastSession?>(
        stream: cast.sessionStream,
        builder: (context, sessionSnap) {
          final connected = sessionSnap.data?.connectionState ==
              GoogleCastConnectState.connected;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Cast to',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              if (connected)
                ListTile(
                  leading: const Icon(Icons.cast_connected),
                  title: Text(
                    sessionSnap.data?.device?.friendlyName ?? 'Connected',
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      await cast.disconnect();
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Stop'),
                  ),
                )
              else
                StreamBuilder<List<GoogleCastDevice>>(
                  stream: cast.devicesStream,
                  builder: (context, devSnap) {
                    final devices = devSnap.data ?? const <GoogleCastDevice>[];
                    if (devices.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Searching for devices…'),
                          ],
                        ),
                      );
                    }
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final device in devices)
                          ListTile(
                            leading: const Icon(Icons.cast),
                            title: Text(device.friendlyName),
                            subtitle: device.modelName != null
                                ? Text(device.modelName!)
                                : null,
                            onTap: () async {
                              await cast.connectAndCast(device);
                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                          ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 8),
            ],
          );
        },
      ),
    ),
  );
  cast.stopDiscovery();
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/presentation/widgets/continuity_intro.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/jellybox_cloud_connect_form.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/server_addresses_provider.dart';

Future<void> connectJellyboxCloud(BuildContext context) async {
  final signedIn = await showFormModal<bool>(
    context,
    builder: (context) => const JellyboxCloudConnectForm(),
  );
  if (signedIn == true && context.mounted) {
    await ContinuityIntro.show(context);
  }
}

class JellyboxCloudSettings extends ConsumerWidget {
  const JellyboxCloudSettings({super.key});

  static final ButtonStyle _buttonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(cloudProvider).account;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => unawaited(connectJellyboxCloud(context)),
          style: _buttonStyle,
          icon: Icon(account == null ? Icons.cloud_outlined : Icons.cloud_done),
          label: Text(
            account == null ? 'Connect' : 'Connected as ${account.email}',
          ),
        ),
        const _ServerConnectionRow(),
      ],
    );
  }
}

class _ServerConnectionRow extends ConsumerWidget {
  const _ServerConnectionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(serverConnectionProvider);
    final addresses = ref.watch(serverAddressesProvider);
    final hasTunnel = addresses?.relay != null;
    final tunnelUp = ref.watch(relayReachableProvider);
    final muted = Theme.of(
      context,
    ).colorScheme.onPrimary.withValues(alpha: 0.5);

    final (icon, label) = switch (connection) {
      ServerConnection.direct => (Icons.lan_outlined, 'Direct'),
      ServerConnection.tunnel => (Icons.vpn_lock_outlined, 'Tunnel'),
      ServerConnection.offline => (Icons.cloud_off_outlined, 'Offline'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [Icon(icon, size: 18), Text('Connection: $label')],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 2),
            child: Text(
              switch ((hasTunnel, tunnelUp)) {
                (false, _) => switch (addresses?.relayDenied) {
                  'plan_full' =>
                    "This server's Jellybox Cloud plan has no free seat for "
                        'your user. Ask the owner to make room.',
                  'no_password' =>
                    'Remote access needs a password on your Jellyfin user.',
                  _ => 'No remote access address for this server yet.',
                },
                (true, false) =>
                  'Remote access is set up, but the tunnel '
                      'is not answering.',
                _ => 'Remote access is set up and the tunnel is ready.',
              },
              style: TextStyle(fontSize: 12, height: 1.3, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

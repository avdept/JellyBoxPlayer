import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:jplayer/src/config/constants.dart';
import 'package:jplayer/src/data/backend/server_type.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/presentation/widgets/continuity_intro.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/jellybox_cloud_connect_form.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/current_server_type_provider.dart';
import 'package:jplayer/src/providers/server_addresses_provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
            account == null
                ? S.of(context).connect
                : S.of(context).connectedAs(account.email),
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
    final notSetUp =
        !hasTunnel &&
        addresses?.relayDenied == null &&
        ref.watch(currentServerTypeProvider) == ServerType.jellyfin;
    final muted = Theme.of(
      context,
    ).colorScheme.onPrimary.withValues(alpha: 0.5);

    final (icon, label) = switch (connection) {
      ServerConnection.direct => (Icons.lan_outlined, S.of(context).direct),
      ServerConnection.remote => (
        Icons.public_outlined,
        S.of(context).remoteAddress,
      ),
      ServerConnection.tunnel => (
        Icons.vpn_lock_outlined,
        S.of(context).tunnel,
      ),
      ServerConnection.offline => (
        Icons.cloud_off_outlined,
        S.of(context).offline,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(icon, size: 18),
              Text(S.of(context).connectionStatus(label)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 2),
            child: Text(
              switch ((hasTunnel, tunnelUp)) {
                (false, _) => switch (addresses?.relayDenied) {
                  'plan_full' => S.of(context).relayPlanFull,
                  'no_password' => S.of(context).relayNoPassword,
                  _ => S.of(context).relayNotSetUp,
                },
                (true, false) => S.of(context).tunnelNotAnswering,
                _ => S.of(context).tunnelReady,
              },
              style: TextStyle(fontSize: 12, height: 1.3, color: muted),
            ),
          ),
          if (notSetUp)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 4),
              child: InkWell(
                onTap: () => unawaited(
                  launchUrl(
                    Uri.parse(jellyfinRelayPluginUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                child: Text(
                  S.of(context).setUpRelayPlugin,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

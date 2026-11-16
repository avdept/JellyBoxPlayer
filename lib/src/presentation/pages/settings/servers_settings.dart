import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/presentation/pages/settings/settings_controls.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/accounts_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';

class ServersSettings extends ConsumerWidget {
  const ServersSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        const SettingsGroupHeader('Accounts'),
        const ServerAccountList(),
        const SettingsGroupHeader('Addresses'),
        const ServerAddressSettings(),
        if (!device.isDesktop) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: ref.read(authProvider.notifier).logout,
            style: settingsButtonStyle(),
            icon: const Icon(JPlayer.log_out),
            label: Text(
              ref.watch(accountsProvider).length > 1
                  ? 'Log out of all servers'
                  : 'Log out',
            ),
          ),
        ],
      ],
    );
  }
}

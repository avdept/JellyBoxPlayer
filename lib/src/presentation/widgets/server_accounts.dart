import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/backend/server_type.dart';
import 'package:jplayer/src/data/services/server_data_cleaner.dart';
import 'package:jplayer/src/data/storages/account_store.dart';
import 'package:jplayer/src/presentation/pages/queue_cache_page.dart';
import 'package:jplayer/src/presentation/utils/server_logo.dart';
import 'package:jplayer/src/presentation/widgets/adaptive_dialog_action.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/providers/accounts_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';

Future<void> showServerSwitcher(BuildContext context) => showFormModal<void>(
  context,
  builder: (context) =>
      const ServerAccountList(removable: false, inSheet: true),
);

class ServerAccountList extends ConsumerWidget {
  const ServerAccountList({
    this.removable = true,
    this.inSheet = false,
    this.showAdd = true,
    this.onSelect,
    super.key,
  });

  final bool removable;
  final bool inSheet;
  final bool showAdd;
  final ValueChanged<ServerAccount>? onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final activeId = ref.watch(currentServerIdProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        for (final account in accounts)
          _AccountRow(
            account: account,
            active: account.serverId == activeId,
            onSelect: () => _select(context, ref, account),
            onRemove: removable
                ? () => confirmRemoveAccount(context, ref, account)
                : null,
          ),
        if (showAdd)
          TextButton.icon(
            onPressed: () => _add(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add server'),
          ),
      ],
    );
  }

  void _add(BuildContext context) {
    final router = GoRouter.of(context);
    if (inSheet) Navigator.of(context).pop();
    unawaited(router.push(Routes.addServer.path));
  }

  void _select(BuildContext context, WidgetRef ref, ServerAccount account) {
    final select = onSelect;
    if (select != null) return select(account);
    final auth = ref.read(authProvider.notifier);
    if (inSheet) Navigator.of(context).pop();
    unawaited(auth.switchTo(account.serverId));
  }
}

Future<void> confirmRemoveAccount(
  BuildContext context,
  WidgetRef ref,
  ServerAccount account,
) async {
  final auth = ref.read(authProvider.notifier);
  final summary = await ServerDataCleaner(account.serverId).downloads();
  if (!context.mounted) return;
  final downloads = summary.songs == 0
      ? ''
      : ' Its ${summary.songs} downloaded '
            '${summary.songs == 1 ? 'song' : 'songs'} '
            '(${QueueCachePage.formatBytes(summary.bytes)}) '
            'will be deleted from this device.';
  final confirmed = await showAdaptiveDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text(
        'Log out of ${account.displayName}?',
        textAlign: TextAlign.center,
      ),
      content: Text(
        'You will be signed out of this server.$downloads',
        textAlign: TextAlign.center,
      ),
      actions: [
        AdaptiveDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        AdaptiveDialogAction(
          onPressed: () => Navigator.of(context).pop(true),
          isDestructiveAction: true,
          child: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirmed ?? false) await auth.removeAccount(account.serverId);
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.active,
    required this.onSelect,
    this.onRemove,
  });

  final ServerAccount account;
  final bool active;
  final VoidCallback onSelect;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);
    final details = [
      ?account.userName,
      account.serverType.label,
    ].join(' · ');

    return InkWell(
      onTap: active ? null : onSelect,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          spacing: 12,
          children: [
            ServerLogo(account: account, size: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: active ? FontWeight.w600 : null,
                    ),
                  ),
                  Text(
                    account.needsReauth ? 'Sign in again' : details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: account.needsReauth
                          ? theme.colorScheme.error
                          : muted,
                    ),
                  ),
                ],
              ),
            ),
            if (active) const Icon(Icons.check, size: 16),
            if (onRemove case final remove?)
              IconButton(
                onPressed: remove,
                tooltip: 'Log out of this server',
                visualDensity: VisualDensity.compact,
                iconSize: 18,
                icon: Icon(Icons.logout, color: muted),
              ),
          ],
        ),
      ),
    );
  }
}

class ServerLogo extends StatelessWidget {
  const ServerLogo({required this.account, this.size = 18, super.key});

  final ServerAccount account;
  final double size;

  @override
  Widget build(BuildContext context) => ServerLogoPicture(
    asset: serverLogoAsset(
      account.serverType,
      productName:
          account.productName ??
          (account.serverType == ServerType.subsonic
              ? account.serverName
              : null),
    ),
    size: size,
  );
}

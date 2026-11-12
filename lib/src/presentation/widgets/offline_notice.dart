import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/server_address_settings.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/server_addresses_provider.dart';

class OfflineNotice extends ConsumerWidget {
  const OfflineNotice({
    required this.message,
    this.showDownloadsLink = false,
    super.key,
  });

  final String message;
  final bool showDownloadsLink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isOffline = ref.watch(isOfflineProvider);
    final addresses = ref.watch(serverAddressesProvider);
    final isDesktop = DeviceType.fromScreenSize(
      MediaQuery.sizeOf(context),
    ).isDesktop;
    final buttonStyle = ButtonStyle(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? theme.colorScheme.primary
            : theme.colorScheme.onPrimary,
      ),
    );

    final actions = <Widget>[
      if (showDownloadsLink)
        TextButton(
          style: buttonStyle,
          onPressed: () => context.goNamed(Routes.downloads.name),
          child: const Text('Open downloads'),
        ),
      if (isOffline && addresses != null)
        TextButton(
          style: buttonStyle,
          onPressed: () => showFormModal<void>(
            context,
            builder: (context) => const RemoteAddressForm(),
          ),
          child: Text(
            addresses.remote == null
                ? 'Add remote address'
                : 'Change remote address',
          ),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOffline ? Icons.cloud_off_outlined : Icons.error_outline,
            size: 32,
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.3),
          ),
          const SizedBox(height: 12),
          if (isDesktop)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              children: actions,
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (index, action) in actions.indexed) ...[
                  if (index > 0) const SizedBox(height: 12),
                  action,
                ],
              ],
            ),
        ],
      ),
    );
  }
}

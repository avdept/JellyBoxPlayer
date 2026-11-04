import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/lidarr_provider.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/lidarr_connect_form.dart';

class LidarrSettings extends ConsumerWidget {
  const LidarrSettings({super.key});

  static final ButtonStyle _buttonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  void _openConnectForm(BuildContext context) => unawaited(
    showFormModal<void>(
      context,
      builder: (context) => const LidarrConnectForm(),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(lidarrAccountProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);

    return switch (account.status) {
      LidarrStatus.loading => const SizedBox.shrink(),
      LidarrStatus.connected => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  account.version == null
                      ? 'Connected to ${account.url}'
                      : 'Connected to ${account.url} (v${account.version})',
                  style: TextStyle(color: muted),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => unawaited(
                  ref.read(lidarrAccountProvider.notifier).disconnect(),
                ),
                style: _buttonStyle,
                child: const Text('Disconnect'),
              ),
            ],
          ),
          const _PlacementSettings(),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: ref.watch(
                    settingProvider(AppSetting.lidarrSearchOnAdd),
                  ),
                  onChanged: (value) => ref
                      .read(appSettingsProvider.notifier)
                      .setEnabled(
                        AppSetting.lidarrSearchOnAdd,
                        value: value ?? true,
                      ),
                ),
                const Text('Let Lidarr search for new additions'),
              ],
            ),
          ),
        ],
      ),
      LidarrStatus.disconnected ||
      LidarrStatus.connecting ||
      LidarrStatus.rejected => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          if (account.status == LidarrStatus.rejected)
            if (account.error case final error?)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  error,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          TextButton.icon(
            onPressed: account.status == LidarrStatus.connecting
                ? null
                : () => _openConnectForm(context),
            style: _buttonStyle,
            icon: const Icon(Icons.link),
            label: const Text('Connect Lidarr'),
          ),
        ],
      ),
    };
  }
}

class _PlacementSettings extends ConsumerWidget {
  const _PlacementSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(lidarrOptionsProvider);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);
    return switch (options) {
      AsyncData(value: final options?) => _dropdowns(ref, options),
      AsyncError(:final error) => Padding(
        padding: const EdgeInsets.only(left: 12, top: 4),
        child: Text(
          'Could not read Lidarr settings: $error',
          style: TextStyle(fontSize: 13, color: theme.colorScheme.error),
        ),
      ),
      _ => Padding(
        padding: const EdgeInsets.only(left: 12, top: 4),
        child: Text('Reading Lidarr settings…', style: TextStyle(color: muted)),
      ),
    };
  }

  Widget _dropdowns(WidgetRef ref, LidarrOptions options) {
    final settings = ref.watch(appSettingsProvider.notifier);
    final placement = ref.watch(lidarrPlacementProvider).valueOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingRow<String>(
          label: 'Root folder',
          value: placement?.rootFolder.path ?? '',
          options: {
            for (final folder in options.rootFolders) folder.path: folder.label,
          },
          onChanged: (value) =>
              settings.setValue(AppSetting.lidarrRootFolder, value),
        ),
        _SettingRow<int>(
          label: 'Quality profile',
          value: placement?.qualityProfile?.id ?? 0,
          options: {
            for (final profile in options.qualityProfiles)
              profile.id: profile.name,
          },
          onChanged: (value) =>
              settings.setValue(AppSetting.lidarrQualityProfile, '$value'),
        ),
        _SettingRow<int>(
          label: 'Metadata profile',
          value: placement?.metadataProfile?.id ?? 0,
          options: {
            for (final profile in options.metadataProfiles)
              profile.id: profile.name,
          },
          onChanged: (value) =>
              settings.setValue(AppSetting.lidarrMetadataProfile, '$value'),
        ),
      ],
    );
  }
}

class _SettingRow<T> extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = options.containsKey(value) ? value : null;
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ),
          DropdownButton<T>(
            value: current,
            isDense: true,
            underline: const SizedBox.shrink(),
            items: [
              for (final entry in options.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
        ],
      ),
    );
  }
}

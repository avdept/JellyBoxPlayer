import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/settings/settings_controls.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/network_type_provider.dart';

class ConnectionSettings extends ConsumerWidget {
  const ConnectionSettings({super.key});

  static const Map<StreamQuality, String> _streamQualityLabels = {
    StreamQuality.original: 'Original',
    StreamQuality.kbps320: '320 kbps',
    StreamQuality.kbps256: '256 kbps',
    StreamQuality.kbps192: '192 kbps',
    StreamQuality.kbps128: '128 kbps',
    StreamQuality.kbps96: '96 kbps',
    StreamQuality.kbps64: '64 kbps',
  };

  static const Map<ForwardCacheLimit, String> _forwardCacheLabels = {
    ForwardCacheLimit.off: 'Off',
    ForwardCacheLimit.mb500: '500 MB',
    ForwardCacheLimit.gb1: '1 GB',
    ForwardCacheLimit.gb2: '2 GB',
    ForwardCacheLimit.gb4: '4 GB',
    ForwardCacheLimit.gb8: '8 GB',
  };

  static const Map<ForwardCacheWindow, String> _forwardCacheWindowLabels = {
    ForwardCacheWindow.min10: '10 min',
    ForwardCacheWindow.min15: '15 min',
    ForwardCacheWindow.min30: '30 min',
    ForwardCacheWindow.min45: '45 min',
    ForwardCacheWindow.min60: '60 min',
  };

  static const Map<ContentUpdateInterval, String> _contentUpdateLabels = {
    ContentUpdateInterval.min1: '1 minute',
    ContentUpdateInterval.min5: '5 minutes',
    ContentUpdateInterval.min15: '15 minutes',
    ContentUpdateInterval.min30: '30 minutes',
    ContentUpdateInterval.never: 'Never',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (ref.watch(cloudAvailableProvider)) ...[
          const SettingsGroupHeader('Jellybox Link'),
          const JellyboxCloudSettings(),
          const _DeviceNameRow(),
          if (ref.watch(cloudProvider).account == null)
            const SettingCheckbox(
              setting: AppSetting.hideContinuityInCastPicker,
              label: 'Hide continuity from cast selector',
            ),
          if (!device.isDesktop)
            const SettingCheckbox(
              setting: AppSetting.carTakesQueue,
              label:
                  "Continue the other device's queue here when "
                  'the car connects',
            ),
        ],
        const SettingsGroupHeader('Network'),
        const SettingCheckbox(
          setting: AppSetting.offlineModeToggle,
          label: 'Show offline mode toggle',
        ),
        const SettingNote(
          'Adds a button on the home page that stops all '
          'streaming, downloads and caching. Only downloaded '
          'songs play while it is on.',
        ),
        SettingsEnumDropdown<StreamQuality>(
          label: deviceHasCellular
              ? 'Streaming quality on Wi-Fi'
              : 'Streaming quality',
          setting: AppSetting.streamQualityWifi,
          value: streamQualityWifiProvider,
          options: _streamQualityLabels,
        ),
        if (deviceHasCellular)
          SettingsEnumDropdown<StreamQuality>(
            label: 'Streaming quality on cellular',
            setting: AppSetting.streamQualityCellular,
            value: streamQualityCellularProvider,
            options: _streamQualityLabels,
          ),
        const SettingNote(
          'Songs above the limit are converted by your server. '
          'Changes apply from the next song.',
        ),
        const SettingsGroupHeader('Cache'),
        SettingsEnumDropdown<ForwardCacheLimit>(
          label: 'Cache limit',
          setting: AppSetting.forwardCacheLimit,
          value: forwardCacheLimitProvider,
          options: _forwardCacheLabels,
          trailing: _purgeCacheButton(context, ref),
        ),
        if (ref.watch(forwardCacheLimitProvider).isEnabled)
          SettingsEnumDropdown<ForwardCacheWindow>(
            label: 'Cache ahead',
            setting: AppSetting.forwardCacheWindow,
            value: forwardCacheWindowProvider,
            options: _forwardCacheWindowLabels,
          ),
        TextButton.icon(
          onPressed: () => _onClearImageCachePressed(context),
          style: settingsButtonStyle(),
          icon: const Icon(Icons.image_not_supported_outlined),
          label: const Text('Clear image cache'),
        ),
        const SettingsGroupHeader('Downloads'),
        SettingsEnumDropdown<StreamQuality>(
          label: 'Download quality',
          setting: AppSetting.downloadQuality,
          value: downloadQualityProvider,
          options: _streamQualityLabels,
        ),
        const SettingNote(
          'Songs above the limit are converted by your server '
          'before they are saved. Applies to new downloads only.',
        ),
        if (deviceHasCellular) ...[
          const SettingCheckbox(
            setting: AppSetting.downloadSyncOnCellular,
            label: 'Update downloaded playlists on cellular',
          ),
          const SettingNote(
            'Downloaded playlists follow your server: new songs '
            'are downloaded and removed songs are deleted. '
            'Otherwise this only happens on Wi-Fi.',
          ),
        ],
        const SettingsGroupHeader('Sync'),
        SettingsEnumDropdown<ContentUpdateInterval>(
          label: 'Content update interval',
          setting: AppSetting.contentUpdateInterval,
          value: contentUpdateIntervalProvider,
          options: _contentUpdateLabels,
          trailing: _refreshContentButton(context, ref),
        ),
        const SettingNote(
          'How often the home page refreshes and downloaded '
          'playlists check your server for changes.',
        ),
      ],
    );
  }

  Widget _purgeCacheButton(BuildContext context, WidgetRef ref) => IconButton(
    onPressed: () => _onPurgeCachePressed(context, ref),
    icon: const Icon(Icons.delete_outline, size: 18),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 30, height: 30),
    visualDensity: VisualDensity.compact,
    tooltip: 'Empty cache',
    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
  );

  Future<void> _onPurgeCachePressed(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppDialog<bool>(
      context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Empty the cache?', textAlign: TextAlign.center),
        content: const Text(
          'Tracks cached ahead for offline playback will be deleted.',
          textAlign: TextAlign.center,
        ),
        actions: [
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(forwardCacheProvider.notifier).purge();
    messenger.showSnackBar(const SnackBar(content: Text('Cache emptied')));
  }

  Future<void> _onClearImageCachePressed(BuildContext context) async {
    final confirmed = await showAppDialog<bool>(
      context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text(
          'Clear the image cache?',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Artwork will be downloaded again from your server as you browse.',
          textAlign: TextAlign.center,
        ),
        actions: [
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          AdaptiveDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            isDestructiveAction: true,
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ArtworkCache.instance.emptyCache();
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    messenger.showSnackBar(
      const SnackBar(content: Text('Image cache cleared')),
    );
  }

  Widget _refreshContentButton(BuildContext context, WidgetRef ref) =>
      IconButton(
        onPressed: () {
          ref.refreshHomeSections();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Home page refreshed')),
            );
        },
        tooltip: 'Refresh now',
        iconSize: 20,
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
        icon: const Icon(Icons.refresh),
      );
}

class _DeviceNameRow extends ConsumerWidget {
  const _DeviceNameRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(deviceNameProvider);
    final muted = Theme.of(
      context,
    ).colorScheme.onPrimary.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [
              const Icon(Icons.devices_outlined, size: 18),
              Flexible(
                child: Text(
                  'Device name: $name',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => unawaited(editDeviceName(context)),
                icon: const Icon(Icons.edit_outlined, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 30,
                  height: 30,
                ),
                visualDensity: VisualDensity.compact,
                tooltip: 'Rename this device',
                color: Theme.of(
                  context,
                ).colorScheme.onPrimary.withValues(alpha: 0.7),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              'Name of this device in the continuity device picker.',
              style: TextStyle(fontSize: 12, height: 1.3, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/discord/discord_presence_handler.dart';
import 'package:jplayer/src/core/telemetry/telemetry.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/settings/settings_controls.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class IntegrationsSettings extends ConsumerWidget {
  const IntegrationsSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 4,
    children: [
      const SettingsGroupHeader('ListenBrainz'),
      const ListenBrainzSettings(),
      const SettingsGroupHeader('Last.fm'),
      const LastFmSettings(),
      if (supportsDiscordPresence) ...[
        const SettingsGroupHeader('Discord'),
        SettingCheckbox(
          setting: AppSetting.discordRichPresence,
          label: 'Share what I am listening to on Discord',
          onEnabled: () => Telemetry.integrationConnected('discord'),
        ),
        if (ref.watch(settingProvider(AppSetting.discordRichPresence))) ...[
          const SettingCheckbox(
            setting: AppSetting.discordAlbumArt,
            label: 'Show album covers on Discord',
          ),
          const SettingNote(
            'Covers are looked up on MusicBrainz by album and '
            'artist, so they can differ from the artwork on '
            'your server.',
          ),
        ],
      ],
      const SettingsGroupHeader('fanart.tv'),
      const SettingCheckbox(
        setting: AppSetting.fanartArtistBackgrounds,
        label: 'Show fanart.tv backgrounds on artist pages',
      ),
      if (ref.watch(settingProvider(AppSetting.fanartArtistBackgrounds)))
        const FanartSettings(),
      if (ref.watch(lidarrAvailableProvider)) ...[
        const SettingsGroupHeader('Lidarr'),
        const LidarrSettings(),
        const SettingCheckbox(
          setting: AppSetting.lidarrHideAddButton,
          label: 'Hide "Add to Lidarr"',
        ),
      ],
      if (ref.watch(installedCatalogSourcesProvider).firstOrNull
          case final catalog?) ...[
        const SettingsGroupHeader('Discover'),
        SettingCheckbox(
          setting: AppSetting.catalogDiscovery,
          label: 'Discover music on ${catalog.brand.name}',
        ),
        SettingNote(catalog.brand.description),
      ],
    ],
  );
}

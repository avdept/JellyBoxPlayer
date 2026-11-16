import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/settings/settings_controls.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';

class InterfaceSettings extends ConsumerWidget {
  const InterfaceSettings({super.key});

  static const Map<ItemList, String> _browseTabLabels = {
    ItemList.albums: 'Albums',
    ItemList.artists: 'Artists',
    ItemList.songs: 'Songs',
    ItemList.playlists: 'Playlists',
    ItemList.genres: 'Genres',
  };

  static const Map<StartPage, String> _startPageLabels = {
    StartPage.home: 'Home',
    StartPage.browse: 'Browse',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        const SettingsGroupHeader('Navigation'),
        SettingsEnumDropdown<StartPage>(
          label: 'Default start page',
          setting: AppSetting.defaultStartPage,
          value: defaultStartPageProvider,
          options: _startPageLabels,
        ),
        SettingsEnumDropdown<ItemList>(
          label: 'Default browse tab',
          setting: AppSetting.defaultBrowseTab,
          value: defaultBrowseTabProvider,
          options: _browseTabLabels,
        ),
        const SettingCheckbox(
          setting: AppSetting.letterRuler,
          label: 'Show A–Z index on browse lists sorted by name',
        ),
        const SettingsGroupHeader('Look'),
        const SettingCheckbox(
          setting: AppSetting.artworkAccent,
          label: 'Match button colours to the current track',
        ),
        const SettingCheckbox(
          setting: AppSetting.nowPlayingHalo,
          label: 'Enable halo effect for currently playing media',
        ),
        const SettingCheckbox(
          setting: AppSetting.ratingsHidden,
          label: 'Hide song ratings',
        ),
        if (device.isMobile) ...[
          const SettingCheckbox(
            setting: AppSetting.albumArtTint,
            label: 'Tint album pages with cover art colours',
          ),
          const SettingCheckbox(
            setting: AppSetting.animatedCovers,
            label: 'Animated album covers',
          ),
          const SettingNote(
            'Looks up for animated covers and plays them on Wi-Fi only.',
          ),
        ],
      ],
    );
  }
}

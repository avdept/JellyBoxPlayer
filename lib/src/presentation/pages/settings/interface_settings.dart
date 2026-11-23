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

  static const Map<AnimatedCovers, String> _animatedCoversLabels = {
    AnimatedCovers.always: 'Always',
    AnimatedCovers.wifi: 'On Wi-Fi',
    AnimatedCovers.never: 'Never',
  };

  static const Map<AppFont, String> _fontLabels = {
    AppFont.gilroy: 'Gilroy',
    AppFont.inter: 'Inter',
    AppFont.onest: 'Onest',
    AppFont.montserrat: 'Montserrat',
    AppFont.archivo: 'Archivo',
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
        const ColorThemePicker(),
        SettingsEnumDropdown<AppFont>(
          label: 'App font',
          setting: AppSetting.appFont,
          value: appFontProvider,
          options: _fontLabels,
        ),
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
          SettingsEnumDropdown<AnimatedCovers>(
            label: 'Animated album covers',
            setting: AppSetting.animatedCovers,
            value: animatedCoversProvider,
            options: _animatedCoversLabels,
          ),
        ] else
          const SettingCheckbox(
            setting: AppSetting.desktopAnimatedCovers,
            label: 'Enable animated cover art',
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/settings/settings_controls.dart';

class HomeSettings extends ConsumerWidget {
  const HomeSettings({super.key});

  static const Map<PinLongevity, String> _pinLongevityLabels = {
    PinLongevity.days7: '7 days',
    PinLongevity.days14: '14 days',
    PinLongevity.days30: '30 days',
    PinLongevity.infinite: 'Infinite',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 4,
    children: [
      const SettingsGroupHeader('Rows'),
      const SettingCheckbox(
        setting: AppSetting.generatedPlaylistsDisabled,
        label: 'Disable auto-generated playlists',
      ),
      const SettingCheckbox(
        setting: AppSetting.favouritesHidden,
        label: 'Hide favourites',
      ),
      const SettingCheckbox(
        setting: AppSetting.recentlyPlayedHidden,
        label: 'Hide recently played',
      ),
      const SettingsGroupHeader('Recent releases'),
      const SettingCheckbox(
        setting: AppSetting.recentReleasesHidden,
        label: 'Hide recent releases',
      ),
      const SettingNote(
        'Albums ordered by release year, so new music stays visible '
        'when older albums are added to the library.',
      ),
      const SettingCheckbox(
        setting: AppSetting.recentReleasesTinted,
        label: 'Colour cards from cover art',
      ),
      const SettingsGroupHeader('Pins'),
      const SettingCheckbox(
        setting: AppSetting.pinsEnabled,
        label: 'Enable pins',
      ),
      SettingsEnumDropdown<PinLongevity>(
        label: 'Pins longevity',
        setting: AppSetting.pinLongevity,
        value: pinLongevityProvider,
        options: _pinLongevityLabels,
      ),
      const SettingNote('Auto expire pins to keep it always fresh.'),
    ],
  );
}

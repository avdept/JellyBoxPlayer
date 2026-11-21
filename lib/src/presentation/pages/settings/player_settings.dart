import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/playback/default_output.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/pages/settings/settings_controls.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';

class PlayerSettings extends ConsumerWidget {
  const PlayerSettings({super.key});

  static const Map<KeepScreenOn, String> _keepScreenOnLabels = {
    KeepScreenOn.never: 'Never',
    KeepScreenOn.charging: 'While charging',
    KeepScreenOn.always: 'Always',
  };

  static const Map<AnimationSpeed, String> _animationSpeedLabels = {
    AnimationSpeed.none: 'None',
    AnimationSpeed.slow: 'Slow',
    AnimationSpeed.medium: 'Medium',
    AnimationSpeed.fast: 'Fast',
  };

  static const Map<StudioBackground, String> _studioBackgroundLabels = {
    StudioBackground.aurora: 'Aurora',
    StudioBackground.fluid: 'Fluid',
  };

  static const Map<StudioLyricsPlacement, String> _studioLyricsLabels = {
    StudioLyricsPlacement.right: 'Right side',
    StudioLyricsPlacement.left: 'Left side',
    StudioLyricsPlacement.separate: 'Separate page',
  };

  static const Map<LyricsAlignment, String> _lyricsAlignmentLabels = {
    LyricsAlignment.left: 'Left',
    LyricsAlignment.center: 'Middle',
    LyricsAlignment.right: 'Right',
  };

  static const Map<LyricsBlur, String> _lyricsBlurLabels = {
    LyricsBlur.off: 'Disabled',
    LyricsBlur.medium: 'Medium',
    LyricsBlur.hard: 'Hard',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (device.isMobile) ...[
          const SettingsGroupHeader('Landscape player'),
          SettingsEnumDropdown<KeepScreenOn>(
            label: 'Keep the screen on',
            setting: AppSetting.keepScreenOn,
            value: keepScreenOnProvider,
            options: _keepScreenOnLabels,
          ),
          SettingsEnumDropdown<AnimationSpeed>(
            label: 'Animation speed',
            setting: AppSetting.animationSpeed,
            value: animationSpeedProvider,
            options: _animationSpeedLabels,
          ),
        ] else ...[
          const SettingsGroupHeader('Studio Mode'),
          if (supportsWindowFullscreen)
            const SettingCheckbox(
              setting: AppSetting.studioModeFullscreen,
              label: 'Make player full screen when Studio Mode enabled',
            ),
          const SettingCheckbox(
            setting: AppSetting.studioModeVideoCovers,
            label: 'Use video covers when available',
          ),
          const SettingCheckbox(
            setting: AppSetting.studioModePinnedControls,
            label: 'Always show controls',
          ),
          const SettingCheckbox(
            setting: AppSetting.studioModeCoverOverVideo,
            label: 'Show cover art over video background',
          ),
          const SettingCheckbox(
            setting: AppSetting.studioModeRememberLyrics,
            label: 'Remember lyrics mode',
          ),
          SettingsEnumDropdown<StudioBackground>(
            label: 'Background',
            setting: AppSetting.studioModeBackground,
            value: studioBackgroundProvider,
            options: _studioBackgroundLabels,
          ),
          SettingsEnumDropdown<StudioLyricsPlacement>(
            label: 'Show lyrics',
            setting: AppSetting.studioModeLyricsPlacement,
            value: studioLyricsPlacementProvider,
            options: _studioLyricsLabels,
          ),
          SettingsEnumDropdown<AnimationSpeed>(
            label: 'Animation speed',
            setting: AppSetting.animationSpeed,
            value: animationSpeedProvider,
            options: _animationSpeedLabels,
          ),
          if (supportsKeepScreenOn) ...[
            SettingsEnumDropdown<KeepScreenOn>(
              label: 'Keep the screen on',
              setting: AppSetting.keepScreenOn,
              value: keepScreenOnProvider,
              options: _keepScreenOnLabels,
            ),
            const SettingNote('Applies while Studio Mode is open.'),
          ],
        ],
        const SettingsGroupHeader('Speakers'),
        const _DefaultOutputRow(),
        const SettingNote(
          'To set one, pick a Cast or DLNA speaker in the Play on menu and '
          'turn on "Use as default output". Music started on this device '
          'then plays there. Picking another output lasts until the app '
          'restarts.',
        ),
        const SettingCheckbox(
          setting: AppSetting.fallbackToThisDevice,
          label: "Switch to this device's speakers if a speaker fails to play",
        ),
        const SettingsGroupHeader('Lyrics'),
        SettingsEnumDropdown<LyricsAlignment>(
          label: 'Lyrics text alignment',
          setting: AppSetting.lyricsAlignment,
          value: lyricsAlignmentProvider,
          options: _lyricsAlignmentLabels,
        ),
        SettingsEnumDropdown<LyricsBlur>(
          label: 'Blur of other lines',
          setting: AppSetting.lyricsBlur,
          value: lyricsBlurProvider,
          options: _lyricsBlurLabels,
        ),
        const SettingCheckbox(
          setting: AppSetting.lrclibLyrics,
          label: 'Find missing lyrics on LRCLIB',
        ),
        const SettingNote(
          'When your server has no lyrics for a song, looks '
          'them up on lrclib.net, a free public lyrics library.',
        ),
      ],
    );
  }
}

class _DefaultOutputRow extends ConsumerWidget {
  const _DefaultOutputRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final output = ref.watch(defaultOutputProvider);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              'Default output',
              style: TextStyle(fontSize: 14, height: 1.2, color: muted),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              output?.name ?? 'This device',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.2),
            ),
          ),
          if (output != null) ...[
            const SizedBox(width: 8),
            TextButton(
              style: settingsButtonStyle(),
              onPressed: () => ref
                  .read(appSettingsProvider.notifier)
                  .setMap(AppSetting.defaultOutput, const {}),
              child: const Text('Clear'),
            ),
          ],
        ],
      ),
    );
  }
}

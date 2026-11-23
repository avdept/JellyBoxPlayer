import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/widgets.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';

class TvSettingsPage extends ConsumerWidget {
  const TvSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.read(appSettingsProvider.notifier);
    final recentlyPlayedHidden = ref.watch(
      settingProvider(AppSetting.recentlyPlayedHidden),
    );
    final miniPlayer = ref.watch(settingProvider(AppSetting.tvMiniPlayer));
    final rememberLyrics = ref.watch(
      settingProvider(AppSetting.tvRememberLyrics),
    );
    final browseTab = ref.watch(defaultBrowseTabProvider);
    final cloudAvailable = ref.watch(cloudAvailableProvider);
    final account = ref.watch(cloudProvider.select((state) => state.account));
    final deviceName = ref.watch(deviceNameProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: TvTokens.pagePaddingH,
        vertical: TvTokens.pagePaddingV,
      ),
      children: [
        const Text('Settings', style: TvTokens.title),
        const SizedBox(height: 24),
        const Text('Player', style: TvTokens.sectionTitle),
        const SizedBox(height: 8),
        _TvSwitchRow(
          label: 'Show mini player',
          value: miniPlayer,
          autofocus: true,
          onChanged: (show) =>
              settings.setEnabled(AppSetting.tvMiniPlayer, value: show),
        ),
        const SizedBox(height: 8),
        _TvSwitchRow(
          label: 'Save lyrics state',
          value: rememberLyrics,
          onChanged: (remember) {
            settings
              ..setEnabled(AppSetting.tvRememberLyrics, value: remember)
              ..setEnabled(
                AppSetting.tvLyricsShown,
                value: remember && ref.read(lyricsVisibleProvider),
              );
          },
        ),
        const SizedBox(height: 24),
        const Text('Home', style: TvTokens.sectionTitle),
        const SizedBox(height: 8),
        _TvSwitchRow(
          label: 'Show recently played row',
          value: !recentlyPlayedHidden,
          onChanged: (show) => settings.setEnabled(
            AppSetting.recentlyPlayedHidden,
            value: !show,
          ),
        ),
        const SizedBox(height: 24),
        const Text('Browse', style: TvTokens.sectionTitle),
        const SizedBox(height: 8),
        _TvChoiceRow<ItemList>(
          label: 'Default browse tab',
          value: browseTab,
          options: ItemList.values,
          labelFor: searchCategoryLabel,
          onChanged: (tab) =>
              settings.setValue(AppSetting.defaultBrowseTab, tab.name),
        ),
        if (cloudAvailable) ...[
          const SizedBox(height: 24),
          const Text('Jellybox Link', style: TvTokens.sectionTitle),
          const SizedBox(height: 8),
          if (account == null)
            _TvActionRow(
              label: 'Connect',
              detail: 'Type a code on your phone',
              icon: Icons.cloud_outlined,
              onSelect: () => _connect(context),
            )
          else ...[
            _TvActionRow(
              label: 'Connected as ${account.email}',
              icon: Icons.cloud_done,
            ),
            const SizedBox(height: 8),
            _TvActionRow(
              label: 'Disconnect',
              icon: Icons.logout_rounded,
              onSelect: () =>
                  unawaited(ref.read(cloudProvider.notifier).signOut()),
            ),
          ],
          const SizedBox(height: 8),
          _TvActionRow(
            label: 'Device name',
            detail: deviceName,
            icon: Icons.tv_outlined,
            onSelect: () => unawaited(TvDeviceNameDialog.show(context)),
          ),
        ],
      ],
    );
  }

  Future<void> _connect(BuildContext context) async {
    final linked = await TvLinkDialog.show(context);
    if (linked && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connected to Jellybox Link')),
      );
    }
  }
}

class _TvActionRow extends StatelessWidget {
  const _TvActionRow({
    required this.label,
    required this.icon,
    this.detail,
    this.onSelect,
  });

  final String label;
  final IconData icon;
  final String? detail;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: TvFocusable(
      enabled: onSelect != null,
      onSelect: onSelect,
      debugLabel: 'setting:$label',
      builder: (context, focused) => AnimatedContainer(
        duration: TvTokens.focusDuration,
        curve: TvTokens.focusCurve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: focused ? TvTokens.listFocus(context) : Colors.white10,
          borderRadius: TvTokens.cardRadius,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (detail case final detail?) ...[
              Text(detail, style: TvTokens.caption),
              const SizedBox(width: 8),
            ],
            if (onSelect != null)
              const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    ),
  );
}

class _TvSwitchRow extends StatelessWidget {
  const _TvSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.autofocus = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: TvFocusable(
        autofocus: autofocus,
        debugLabel: 'setting:$label',
        onSelect: () => onChanged(!value),
        builder: (context, focused) => AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: focused ? TvTokens.listFocus(context) : Colors.white10,
            borderRadius: TvTokens.cardRadius,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ExcludeFocus(
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TvChoiceRow<T> extends StatelessWidget {
  const _TvChoiceRow({
    required this.label,
    required this.value,
    required this.options,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> options;
  final String Function(T option) labelFor;
  final ValueChanged<T> onChanged;

  Future<void> _choose(BuildContext context) async {
    final chosen = await showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                for (final option in options)
                  TvOptionRow(
                    icon: Icon(
                      option == value
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    label: Text(labelFor(option)),
                    autofocus: option == value,
                    onSelect: () => Navigator.of(context).pop(option),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (chosen != null && chosen != value) onChanged(chosen);
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: TvFocusable(
      debugLabel: 'setting:$label',
      onSelect: () => _choose(context),
      builder: (context, focused) => AnimatedContainer(
        duration: TvTokens.focusDuration,
        curve: TvTokens.focusCurve,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: focused ? TvTokens.listFocus(context) : Colors.white10,
          borderRadius: TvTokens.cardRadius,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(labelFor(value), style: TvTokens.caption),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    ),
  );
}

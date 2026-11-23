import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/themes/app_colors.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';

ButtonStyle settingsButtonStyle() => TextButton.styleFrom(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
);

class SettingsGroupHeader extends StatelessWidget {
  const SettingsGroupHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 12, top: 20, bottom: 4),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    ),
  );
}

class SettingNote extends StatelessWidget {
  const SettingNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 12, top: 2, right: 12),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        height: 1.3,
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.5),
      ),
    ),
  );
}

class SettingCheckbox extends ConsumerWidget {
  const SettingCheckbox({
    required this.setting,
    required this.label,
    this.onEnabled,
    super.key,
  });

  final AppSetting setting;
  final String label;
  final VoidCallback? onEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(settingProvider(setting));
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: enabled,
            onChanged: (value) {
              final enabled = value ?? false;
              ref
                  .read(appSettingsProvider.notifier)
                  .setEnabled(setting, value: enabled);
              if (enabled) onEnabled?.call();
            },
          ),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}

class SettingDropdown<T> extends StatelessWidget {
  const SettingDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.trailing,
    super.key,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = DeviceType.fromScreenSize(
      MediaQuery.sizeOf(context),
    ).isMobile;
    final text = Text(
      label,
      style: TextStyle(
        fontSize: 14,
        height: 1.2,
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: mobile ? 12 : 0,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisSize: mobile ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (mobile)
            Expanded(child: text)
          else
            SizedBox(width: 170, child: text),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<T>(
                isExpanded: true,
                buttonStyleData: ButtonStyleData(
                  height: 30,
                  padding: const EdgeInsets.only(left: 10, right: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                iconStyleData: const IconStyleData(iconSize: 20),
                menuItemStyleData: const MenuItemStyleData(
                  height: 34,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
                dropdownStyleData: DropdownStyleData(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  offset: const Offset(0, -6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                items: [
                  for (final entry in options.entries)
                    DropdownMenuItem<T>(
                      value: entry.key,
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.2,
                          color: (entry.key == value)
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
                value: value,
                onChanged: (selected) {
                  if (selected != null) onChanged(selected);
                },
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class SettingsEnumDropdown<T extends Enum> extends ConsumerWidget {
  const SettingsEnumDropdown({
    required this.label,
    required this.setting,
    required this.value,
    required this.options,
    this.trailing,
    super.key,
  });

  final String label;
  final AppSetting setting;
  final ProviderListenable<T> value;
  final Map<T, String> options;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingDropdown<T>(
    label: label,
    value: ref.watch(value),
    options: options,
    trailing: trailing,
    onChanged: (selected) =>
        ref.read(appSettingsProvider.notifier).setValue(setting, selected.name),
  );
}

class ColorThemePicker extends ConsumerWidget {
  const ColorThemePicker({super.key});

  static const Map<ColorTheme, String> labels = {
    ColorTheme.oxblood: 'Oxblood',
    ColorTheme.midnightBrass: 'Midnight Brass',
    ColorTheme.champagne: 'Champagne',
    ColorTheme.racingGreen: 'Racing Green',
    ColorTheme.copperNoir: 'Copper Noir',
    ColorTheme.plumVelvet: 'Plum Velvet',
    ColorTheme.inkAndIce: 'Ink & Ice',
    ColorTheme.original: 'Original',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = ref.watch(colorThemeProvider);
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            'Colour theme',
            style: TextStyle(
              fontSize: 14,
              height: 1.2,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (final option in ColorTheme.values)
                _ColorThemeSwatch(
                  colors: AppColors.of(option),
                  label: labels[option]!,
                  selected: option == selected,
                  onTap: () => ref
                      .read(appSettingsProvider.notifier)
                      .setValue(AppSetting.colorTheme, option.name),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorThemeSwatch extends StatelessWidget {
  const _ColorThemeSwatch({
    required this.colors,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppColors colors;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Tooltip(
      message: label,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : Colors.white24,
              width: selected ? 2 : 1,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colors.primary,
                  colors.primary,
                  colors.panel,
                  colors.panel,
                ],
                stops: const [0, 0.5, 0.5, 1],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

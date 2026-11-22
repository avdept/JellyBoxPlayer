import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
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
    super.key,
  });

  final AppSetting setting;
  final String label;

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
            onChanged: (value) => ref
                .read(appSettingsProvider.notifier)
                .setEnabled(setting, value: value ?? false),
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

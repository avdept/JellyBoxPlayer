import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class AppDropdownEntry<T> {
  const AppDropdownEntry({
    required this.value,
    required this.label,
    this.leadingBuilder,
    this.trailingBuilder,
  });

  final T value;
  final String label;
  final Widget Function(Color color)? leadingBuilder;
  final Widget Function(Color color)? trailingBuilder;
}

class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    required this.value,
    required this.entries,
    required this.onChanged,
    this.icon,
    this.buttonBuilder,
    this.width = 150,
    super.key,
  }) : assert(
         (icon == null) != (buttonBuilder == null),
         'Provide either an icon or a buttonBuilder, not both',
       );

  final T? value;
  final List<AppDropdownEntry<T>> entries;
  final ValueChanged<T> onChanged;
  final IconData? icon;
  final Widget Function(bool isOpened)? buttonBuilder;
  final double width;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  var _isOpened = false;

  Widget _button(ThemeData theme) {
    if (widget.buttonBuilder case final builder?) return builder(_isOpened);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(
        widget.icon,
        color: _isOpened ? theme.colorScheme.primary : theme.iconTheme.color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        customButton: _button(theme),
        buttonStyleData: const ButtonStyleData(
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
        dropdownStyleData: DropdownStyleData(
          width: widget.width,
          padding: const EdgeInsets.all(8),
          offset: const Offset(0, -8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        ),
        items: [
          for (final entry in widget.entries)
            DropdownMenuItem(
              value: entry.value,
              child: Builder(
                builder: (context) {
                  final color = entry.value == widget.value
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onPrimary;
                  return Row(
                    children: [
                      if (entry.leadingBuilder case final builder?) ...[
                        builder(color),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            color: color,
                          ),
                        ),
                      ),
                      if (entry.trailingBuilder case final builder?)
                        builder(color),
                    ],
                  );
                },
              ),
            ),
        ],
        value: widget.value,
        onChanged: (value) {
          if (value == null) return;
          widget.onChanged(value);
        },
        onMenuStateChange: (isOpened) {
          if (!mounted) return;
          setState(() => _isOpened = isOpened);
        },
      ),
    );
  }
}

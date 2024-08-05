import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    required this.value,
    this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: (onChanged != null) ? () => onChanged!.call(!value) : null,
      icon: Icon(
        CupertinoIcons.heart,
        color: theme.colorScheme.onPrimary,
      ),
      selectedIcon: Icon(
        CupertinoIcons.heart_fill,
        color: theme.colorScheme.primary,
      ),
      isSelected: value,
    );
  }
}

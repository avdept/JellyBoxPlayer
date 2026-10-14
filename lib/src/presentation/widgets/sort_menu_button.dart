import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/hover_icon_button.dart';

class SortMenuButton<T> extends StatelessWidget {
  const SortMenuButton({
    required this.options,
    required this.selected,
    required this.descending,
    required this.onSelected,
    super.key,
  });

  final Map<T, String> options;
  final T selected;
  final bool descending;
  final ValueChanged<T> onSelected;

  Future<void> _open(BuildContext context) async {
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          button.size.bottomLeft(Offset.zero),
          ancestor: overlay,
        ),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    final choice = await showMenu<T>(
      context: context,
      position: position,
      items: [
        for (final MapEntry(key: value, value: label) in options.entries)
          PopupMenuItem(
            value: value,
            child: Row(
              children: [
                Expanded(child: Text(label)),
                if (value == selected)
                  Icon(
                    descending ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 18,
                  ),
              ],
            ),
          ),
      ],
    );
    if (choice != null) onSelected(choice);
  }

  @override
  Widget build(BuildContext context) => HoverIconButton(
    icon: const Icon(Icons.sort),
    color: Theme.of(context).colorScheme.onPrimary,
    tooltip: 'Sort',
    onPressed: () => _open(context).ignore(),
  );
}

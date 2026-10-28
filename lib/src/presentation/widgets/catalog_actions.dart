import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:responsive_builder/responsive_builder.dart';

void addToLidarr(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Lidarr support is coming soon.')),
  );
}

List<ContextMenuAction> catalogItemActions(BuildContext context) => [
  ContextMenuAction(
    entry: ContextMenuEntry.addToLidarr,
    icon: const Icon(Icons.library_add_outlined),
    label: const Text('Add to Lidarr'),
    run: () async => addToLidarr(context),
  ),
];

class CatalogContextMenuRegion extends StatelessWidget {
  const CatalogContextMenuRegion({
    required this.child,
    this.onTap,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        getDeviceType(MediaQuery.sizeOf(context)) == DeviceScreenType.desktop;
    return GestureDetector(
      onTap: onTap,
      onLongPress: isDesktop || !enabled
          ? null
          : () => showLongPressContextMenuSheet(
              context,
              actions: catalogItemActions(context),
            ),
      onSecondaryTapUp: enabled
          ? (details) => showContextMenu(
              context,
              position: details.globalPosition,
              actions: catalogItemActions(context),
            )
          : null,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

class AddToLidarrButton extends StatelessWidget {
  const AddToLidarrButton({super.key});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => addToLidarr(context),
    icon: const Icon(Icons.library_add_outlined, size: 16),
    label: const Text('Add to Lidarr'),
    style: OutlinedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      side: BorderSide(
        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.4),
      ),
    ),
  );
}

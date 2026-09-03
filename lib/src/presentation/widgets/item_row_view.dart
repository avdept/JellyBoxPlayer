import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ItemRowView extends ConsumerStatefulWidget {
  const ItemRowView({
    required this.item,
    this.onTap,
    this.onPlayPressed,
    this.optionsBuilder,
    this.edgePadding,
    super.key,
  });

  final LibraryItem item;
  final void Function(LibraryItem)? onTap;
  final Future<void> Function(LibraryItem)? onPlayPressed;
  final List<PopupMenuEntry<void>> Function(BuildContext)? optionsBuilder;
  final double? edgePadding;

  @override
  ConsumerState<ItemRowView> createState() => _ItemRowViewState();
}

class _ItemRowViewState extends ConsumerState<ItemRowView> {
  var _isPlayLoading = false;

  LibraryItem get item => widget.item;

  Future<void> _onPlayPressed() async {
    final onPlayPressed = widget.onPlayPressed;
    if (onPlayPressed == null || _isPlayLoading) return;
    setState(() => _isPlayLoading = true);
    try {
      await onPlayPressed(item);
    } finally {
      if (mounted) setState(() => _isPlayLoading = false);
    }
  }

  String? get _subtitle =>
      item.kind == ItemKind.album ? item.albumArtist : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deviceType = getDeviceType(MediaQuery.sizeOf(context));
    final isMobile = deviceType == DeviceScreenType.mobile;
    final isTablet = deviceType == DeviceScreenType.tablet;
    final imageSize = isMobile ? 46.0 : 56.0;
    final horizontal = widget.edgePadding ?? 0;
    final subtitle = _subtitle;
    final isRound = item.kind == ItemKind.artist;

    return SimpleListTile(
      onTap: widget.onTap != null ? () => widget.onTap!(item) : null,
      hoverColor: theme.colorScheme.onPrimary.withValues(alpha: 0.06),
      padding: EdgeInsets.fromLTRB(
        horizontal,
        8,
        widget.optionsBuilder != null ? 4 : horizontal,
        8,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(isRound ? imageSize / 2 : 6),
        child: Image(
          image: ref.read(imageServiceProvider).itemImage(item),
          width: imageSize,
          height: imageSize,
          fit: BoxFit.cover,
        ),
      ),
      leadingToTitle: isMobile ? 12 : 16,
      title: Text(
        item.name,
        style: TextStyle(
          fontSize: isTablet ? 18 : 14,
          fontWeight: FontWeight.w600,
          height: 1.2,
          overflow: TextOverflow.ellipsis,
        ),
        maxLines: 1,
      ),
      subtitle: (subtitle != null && subtitle.isNotEmpty)
          ? Text(
              subtitle,
              maxLines: 1,
              style: TextStyle(
                fontSize: isTablet ? 16 : 12,
                fontWeight: FontWeight.w400,
                height: 1.2,
                color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
      trailing: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (widget.onPlayPressed != null)
            CirclePlayButton(
              size: isMobile ? 36 : 40,
              isLoading: _isPlayLoading,
              onPressed: _onPlayPressed,
            ),
          if (widget.optionsBuilder case final builder?)
            PopupMenuButton<void>(
              itemBuilder: builder,
              icon: const Icon(Icons.more_horiz),
            ),
        ],
      ),
    );
  }
}

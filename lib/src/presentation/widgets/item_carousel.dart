import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/album_card_metrics.dart';
import 'package:jplayer/src/presentation/widgets/album_view.dart';
import 'package:jplayer/src/presentation/widgets/clickable_widget.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';

class ItemCarousel extends StatelessWidget {
  const ItemCarousel({
    required this.title,
    required this.items,
    required this.device,
    required this.onItemTap,
    this.onPlayPressed,
    this.optionsBuilder,
    this.onRetry,
    this.onTitleTap,
    this.trailing,
    this.coverBuilder,
    this.horizontalPadding = 0,
    super.key,
  });

  final String title;
  final AsyncValue<List<LibraryItem>> items;
  final DeviceType device;
  final void Function(LibraryItem) onItemTap;
  final Future<void> Function(LibraryItem)? onPlayPressed;
  final List<PopupMenuEntry<void>> Function(BuildContext, LibraryItem)?
  optionsBuilder;
  final VoidCallback? onRetry;
  final VoidCallback? onTitleTap;
  final Widget? trailing;
  final Widget? Function(LibraryItem)? coverBuilder;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = items.when(
      data: (list) => switch (list) {
        [] when trailing == null => null,
        [] => _message(theme, 'Nothing here yet.'),
        _ => _list(list),
      },
      error: (error, stackTrace) => _message(
        theme,
        'Could not load this section.',
        showRetry: true,
      ),
      loading: _loading,
    );

    if (content == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            0,
            horizontalPadding,
            12,
          ),
          child: _header(theme),
        ),
        content,
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _header(ThemeData theme) {
    final label = _title(theme);
    final action = trailing;
    if (action == null) return label;

    return Row(
      children: [
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: label),
        ),
        action,
      ],
    );
  }

  Widget _title(ThemeData theme) {
    final text = Text(
      title,
      style: TextStyle(
        fontSize: device.isMobile ? 20 : 24,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onPrimary,
      ),
    );
    if (onTitleTap == null) return text;

    return Align(
      alignment: Alignment.centerLeft,
      child: ClickableWidget(
        onPressed: onTitleTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            text,
            Icon(
              Icons.chevron_right,
              size: device.isMobile ? 24 : 28,
              color: theme.colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(List<LibraryItem> list) => SizedBox(
    height: AlbumCardMetrics.carouselHeight(device),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      clipBehavior: Clip.none,
      itemCount: list.length,
      separatorBuilder: (context, index) =>
          SizedBox(width: AlbumCardMetrics.carouselSpacing(device)),
      itemBuilder: (context, index) {
        final item = list[index];
        final builder = optionsBuilder;
        return SizedBox(
          width: AlbumCardMetrics.carouselWidth(device),
          child: AlbumView(
            album: item,
            alignTextStart: true,
            coverOverride: coverBuilder?.call(item),
            onTap: onItemTap,
            onPlayPressed: onPlayPressed,
            optionsBuilder: builder == null
                ? null
                : (context) => builder(context, item),
          ),
        );
      },
    ),
  );

  Widget _loading() => AlbumCardsRowShimmer(
    device: device,
    horizontalPadding: horizontalPadding,
  );

  Widget _message(ThemeData theme, String text, {bool showRetry = false}) =>
      Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          children: [
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                ),
              ),
            ),
            if (showRetry && onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_button.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_focusable.dart';
import 'package:jplayer/src/presentation/widgets/release_card_strip.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';

class TvReleaseShelf extends StatelessWidget {
  const TvReleaseShelf({
    required this.title,
    required this.items,
    this.onSelect,
    this.onLongSelect,
    this.onRetry,
    this.horizontalPadding = TvTokens.pagePaddingH,
    super.key,
  });

  final String title;
  final AsyncValue<List<LibraryItem>> items;
  final void Function(LibraryItem item)? onSelect;
  final void Function(LibraryItem item)? onLongSelect;
  final VoidCallback? onRetry;
  final double horizontalPadding;

  static const rows = 2;
  static const cardHeight = 56.0;
  static const columnWidth = 250.0;
  static const _rowGap = 10.0;
  static const _verticalInset = 14.0;
  static const _glowOverflow = 32.0;
  static const _focusScale = 1.04;
  static const _radius = BorderRadius.all(
    Radius.circular(ReleaseCardFace.radius),
  );
  static const double height =
      cardHeight * rows + _rowGap * (rows - 1) + _verticalInset * 2;

  @override
  Widget build(BuildContext context) {
    if (items.valueOrNull?.isEmpty ?? false) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Text(title, style: TvTokens.sectionTitle),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: height,
            child: items.when(
              data: _strip,
              loading: _loading,
              error: (_, _) => _error(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _columns({
    required int count,
    required Widget Function(int index) builder,
    ScrollPhysics? physics,
  }) => ListView.separated(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    physics: physics,
    padding: EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: _verticalInset,
    ),
    itemCount: (count / rows).ceil(),
    separatorBuilder: (_, _) => const SizedBox(width: TvTokens.cardGap),
    itemBuilder: (context, column) => SizedBox(
      width: columnWidth,
      child: Column(
        spacing: _rowGap,
        children: [
          for (
            var index = column * rows;
            index < (column + 1) * rows && index < count;
            index++
          )
            builder(index),
        ],
      ),
    ),
  );

  Widget _strip(List<LibraryItem> list) => FocusTraversalGroup(
    child: ClipRect(
      clipper: const _HorizontalClipper(overflow: _glowOverflow),
      child: _columns(
        count: list.length,
        builder: (index) => _card(list[index]),
      ),
    ),
  );

  Widget _card(LibraryItem item) => TvFocusable(
    debugLabel: 'release:${item.name}',
    onSelect: onSelect == null ? null : () => onSelect!(item),
    onLongSelect: onLongSelect == null ? null : () => onLongSelect!(item),
    builder: (context, focused) => TvFocusFrame(
      focused: focused,
      borderRadius: _radius,
      scale: _focusScale,
      child: ReleaseCardFace(
        item: item,
        height: cardHeight,
        padding: 6,
        titleSize: 13,
        subtitleSize: 11,
      ),
    ),
  );

  Widget _loading() => _columns(
    count: 6 * rows,
    physics: const NeverScrollableScrollPhysics(),
    builder: (_) => const ShimmerBox(height: cardHeight, radius: 12),
  );

  Widget _error() => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: _verticalInset,
    ),
    child: Row(
      children: [
        const Text('Could not load this section', style: TvTokens.caption),
        if (onRetry != null) ...[
          const SizedBox(width: 16),
          TvButton(label: 'Retry', icon: Icons.refresh, onSelect: onRetry),
        ],
      ],
    ),
  );
}

class _HorizontalClipper extends CustomClipper<Rect> {
  const _HorizontalClipper({required this.overflow});

  final double overflow;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -overflow, size.width, size.height + overflow);

  @override
  bool shouldReclip(_HorizontalClipper oldClipper) =>
      oldClipper.overflow != overflow;
}

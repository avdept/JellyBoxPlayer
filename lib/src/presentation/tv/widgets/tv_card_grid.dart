import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_card.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';

class TvCardGrid extends StatelessWidget {
  const TvCardGrid({
    required this.itemCount,
    required this.itemAt,
    this.imageFor,
    this.subtitleFor,
    this.onSelect,
    this.onLongSelect,
    this.onNearEnd,
    this.autofocusFirst = false,
    this.circular = false,
    this.shrinkWrap = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: TvTokens.pagePaddingH,
      vertical: 16,
    ),
    super.key,
  });

  const TvCardGrid.loading({
    this.itemCount = 18,
    this.shrinkWrap = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: TvTokens.pagePaddingH,
      vertical: 16,
    ),
    super.key,
  }) : itemAt = _none,
       imageFor = null,
       subtitleFor = null,
       onSelect = null,
       onLongSelect = null,
       onNearEnd = null,
       autofocusFirst = false,
       circular = false;

  final int itemCount;
  final LibraryItem? Function(int index) itemAt;
  final ImageProvider Function(LibraryItem item)? imageFor;
  final String? Function(LibraryItem item)? subtitleFor;
  final void Function(LibraryItem item)? onSelect;
  final void Function(LibraryItem item)? onLongSelect;
  final VoidCallback? onNearEnd;
  final bool autofocusFirst;
  final bool circular;
  final bool shrinkWrap;
  final EdgeInsets padding;

  static const _textBlock = 48.0;
  static const _rowGap = 18.0;

  static LibraryItem? _none(int index) => null;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final available = constraints.maxWidth - padding.horizontal;
      final columns = max(
        1,
        ((available + TvTokens.cardGap) /
                (TvTokens.cardWidth + TvTokens.cardGap))
            .floor(),
      );
      final cardWidth =
          (available - (columns - 1) * TvTokens.cardGap) / columns;
      final grid = GridView.builder(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        padding: padding,
        clipBehavior: Clip.none,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: TvTokens.cardGap,
          mainAxisSpacing: _rowGap,
          mainAxisExtent: cardWidth + _textBlock,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (onNearEnd != null && index >= itemCount - columns * 2) {
            onNearEnd!();
          }
          final item = itemAt(index);
          if (item == null) return _Placeholder(width: cardWidth);
          return TvCard(
            title: item.name,
            subtitle: subtitleFor?.call(item),
            image: imageFor?.call(item),
            width: cardWidth,
            circular: circular,
            autofocus: autofocusFirst && index == 0,
            onSelect: onSelect == null ? null : () => onSelect!(item),
            onLongSelect: onLongSelect == null
                ? null
                : () => onLongSelect!(item),
          );
        },
      );
      return FocusTraversalGroup(
        child: shrinkWrap
            ? grid
            : ClipRect(clipper: const _VerticalClipper(), child: grid),
      );
    },
  );
}

class _VerticalClipper extends CustomClipper<Rect> {
  const _VerticalClipper();

  static const _overflow = 32.0;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-_overflow, 0, size.width + _overflow, size.height);

  @override
  bool shouldReclip(_VerticalClipper oldClipper) => false;
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ShimmerBox(width: width, height: width, radius: 10),
      const SizedBox(height: 12),
      const ShimmerBox(width: 90, height: 12),
    ],
  );
}

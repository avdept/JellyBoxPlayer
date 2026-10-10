import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_button.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_card.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';

class TvShelf extends StatelessWidget {
  const TvShelf({
    required this.title,
    required this.items,
    required this.imageFor,
    this.subtitleFor,
    this.coverFor,
    this.onSelect,
    this.onLongSelect,
    this.playsOnSelect,
    this.onRetry,
    this.autofocusFirst = false,
    this.horizontalPadding = TvTokens.pagePaddingH,
    this.emptyLabel = 'Nothing here yet',
    this.hideWhenEmpty = true,
    super.key,
  });

  final String title;
  final AsyncValue<List<LibraryItem>> items;
  final ImageProvider Function(LibraryItem item) imageFor;
  final String? Function(LibraryItem item)? subtitleFor;
  final Widget? Function(LibraryItem item)? coverFor;
  final void Function(LibraryItem item)? onSelect;
  final void Function(LibraryItem item)? onLongSelect;
  final bool Function(LibraryItem item)? playsOnSelect;
  final VoidCallback? onRetry;
  final bool autofocusFirst;
  final double horizontalPadding;
  final String emptyLabel;

  final bool hideWhenEmpty;

  static const _verticalInset = 14.0;
  static const _textBlock = 48.0;
  static const double height =
      TvTokens.cardWidth + _verticalInset * 2 + _textBlock;

  @override
  Widget build(BuildContext context) {
    if (hideWhenEmpty && (items.valueOrNull?.isEmpty ?? false)) {
      return const SizedBox.shrink();
    }
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
              data: _list,
              loading: _loading,
              error: (_, _) => _error(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<LibraryItem> list) {
    if (list.isEmpty) return _message(emptyLabel);
    return FocusTraversalGroup(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: _verticalInset,
        ),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: TvTokens.cardGap),
        itemBuilder: (context, index) {
          final item = list[index];
          return TvCard(
            title: item.name,
            subtitle: subtitleFor?.call(item),
            image: imageFor(item),
            cover: coverFor?.call(item),
            autofocus: autofocusFirst && index == 0,
            playsOnSelect: playsOnSelect?.call(item) ?? false,
            onSelect: onSelect == null ? null : () => onSelect!(item),
            onLongSelect: onLongSelect == null
                ? null
                : () => onLongSelect!(item),
          );
        },
      ),
    );
  }

  Widget _loading() => ListView.separated(
    scrollDirection: Axis.horizontal,
    physics: const NeverScrollableScrollPhysics(),
    padding: EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: _verticalInset,
    ),
    itemCount: 6,
    separatorBuilder: (_, _) => const SizedBox(width: TvTokens.cardGap),
    itemBuilder: (_, _) => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBox(
          width: TvTokens.cardWidth,
          height: TvTokens.cardWidth,
          radius: 10,
        ),
        SizedBox(height: 12),
        ShimmerBox(width: 100, height: 12),
      ],
    ),
  );

  Widget _message(String text) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: _verticalInset,
    ),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: TvTokens.caption),
    ),
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

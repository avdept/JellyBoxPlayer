import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/album_card_metrics.dart';
import 'package:jplayer/src/presentation/widgets/album_view.dart';
import 'package:jplayer/src/presentation/widgets/clickable_widget.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/horizontal_scroll_region.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';

class ItemCarousel extends StatelessWidget {
  const ItemCarousel({
    required this.title,
    required this.items,
    required this.device,
    required this.onItemTap,
    this.onPlayPressed,
    this.optionsBuilder,
    this.hasOptions,
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
  final List<ContextMenuAction> Function(BuildContext, LibraryItem)?
  optionsBuilder;
  final bool Function(LibraryItem)? hasOptions;
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
    child: HorizontalScrollRegion(
      controlsHeight: AlbumCardMetrics.carouselWidth(device),
      controlsInset: horizontalPadding / 2,
      builder: (context, controller) => _AnimatedCards(
        items: list,
        controller: controller,
        device: device,
        horizontalPadding: horizontalPadding,
        cardBuilder: _card,
      ),
    ),
  );

  Widget _card(LibraryItem item) {
    final builder = optionsBuilder;
    return AlbumView(
      album: item,
      alignTextStart: true,
      coverOverride: coverBuilder?.call(item),
      onTap: onItemTap,
      onPlayPressed: onPlayPressed,
      optionsBuilder: builder == null || !(hasOptions?.call(item) ?? true)
          ? null
          : (context) => builder(context, item),
    );
  }

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

const _growDuration = Duration(milliseconds: 280);
const _shrinkDuration = Duration(milliseconds: 180);
const _insertStagger = Duration(milliseconds: 30);
const _maxCascade = Duration(milliseconds: 700);

class _AnimatedCards extends StatefulWidget {
  const _AnimatedCards({
    required this.items,
    required this.controller,
    required this.device,
    required this.horizontalPadding,
    required this.cardBuilder,
  });

  final List<LibraryItem> items;
  final ScrollController controller;
  final DeviceType device;
  final double horizontalPadding;
  final Widget Function(LibraryItem) cardBuilder;

  @override
  State<_AnimatedCards> createState() => _AnimatedCardsState();
}

class _AnimatedCardsState extends State<_AnimatedCards> {
  var _listKey = GlobalKey<AnimatedListState>();
  late List<LibraryItem> _shown;
  List<LibraryItem> _target = const [];
  final _pendingInserts = <int>[];
  Duration _stagger = _insertStagger;
  Timer? _stepTimer;

  @override
  void initState() {
    super.initState();
    _shown = [...widget.items];
  }

  @override
  void didUpdateWidget(covariant _AnimatedCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    _animateTo(widget.items);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  List<String> _ids(List<LibraryItem> items) => [
    for (final item in items) item.id,
  ];

  void _animateTo(List<LibraryItem> target) {
    final inProgress = _stepTimer?.isActive ?? false;
    if (inProgress && listEquals(_ids(_target), _ids(target))) {
      _target = target;
      return;
    }
    _stepTimer?.cancel();
    _pendingInserts.clear();
    _target = target;

    final diff = diffIds(_ids(_shown), _ids(target));
    if (diff.isEmpty) {
      setState(() => _shown = [...target]);
      return;
    }

    final list = _listKey.currentState;
    if (_shown.isEmpty || list == null) {
      setState(() {
        _shown = [...target];
        _listKey = GlobalKey<AnimatedListState>();
      });
      return;
    }

    for (final index in diff.removals) {
      final removed = _shown.removeAt(index);
      list.removeItem(
        index,
        (context, animation) => _card(removed, animation),
        duration: _shrinkDuration,
      );
    }
    _pendingInserts.addAll(diff.insertions);
    _stagger = Duration(
      microseconds: min(
        _insertStagger.inMicroseconds,
        _maxCascade.inMicroseconds ~/ max(1, diff.insertions.length),
      ),
    );
    _insertNext();
  }

  void _insertNext() {
    if (_pendingInserts.isEmpty) {
      setState(() => _shown = [..._target]);
      return;
    }
    final index = _pendingInserts.removeAt(0);
    _shown.insert(index, _target[index]);
    _listKey.currentState?.insertItem(index, duration: _growDuration);
    _stepTimer = Timer(_stagger, _insertNext);
  }

  Widget _card(LibraryItem item, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    final card = FadeTransition(
      opacity: curved,
      child: Padding(
        padding: EdgeInsets.only(
          right: AlbumCardMetrics.carouselSpacing(widget.device),
        ),
        child: SizedBox(
          width: AlbumCardMetrics.carouselWidth(widget.device),
          child: widget.cardBuilder(item),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Align(
        alignment: Alignment.centerLeft,
        widthFactor: curved.value,
        child: child,
      ),
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = AlbumCardMetrics.carouselSpacing(widget.device);
    return AnimatedList(
      key: _listKey,
      controller: widget.controller,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(
        left: widget.horizontalPadding,
        right: max(0, widget.horizontalPadding - spacing),
      ),
      clipBehavior: Clip.none,
      initialItemCount: _shown.length,
      itemBuilder: (context, index, animation) =>
          _card(_shown[index], animation),
    );
  }
}

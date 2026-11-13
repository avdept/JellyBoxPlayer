import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/playlist_song_order_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/hover_icon_button.dart';
import 'package:jplayer/src/presentation/widgets/hover_zoom.dart';
import 'package:jplayer/src/presentation/widgets/play_button.dart';
import 'package:jplayer/src/presentation/widgets/sort_menu_button.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';

Map<PlaylistSongSort, String> playlistSortOptions(
  String defaultLabel, {
  bool ratings = false,
}) => {
  PlaylistSongSort.playlistOrder: defaultLabel,
  PlaylistSongSort.title: 'Title',
  PlaylistSongSort.artist: 'Artist',
  PlaylistSongSort.album: 'Album',
  if (ratings) PlaylistSongSort.rating: 'Rating',
};

class PlaylistControls extends StatefulWidget {
  const PlaylistControls({
    required this.onPlay,
    required this.onShuffle,
    this.isPlayLoading = false,
    this.resume,
    this.download,
    this.sort,
    this.onSearchChanged,
    super.key,
  });

  final VoidCallback onPlay;
  final VoidCallback onShuffle;
  final bool isPlayLoading;
  final Widget? resume;
  final Widget? download;
  final Widget? sort;
  final ValueChanged<String>? onSearchChanged;

  @override
  State<PlaylistControls> createState() => _PlaylistControlsState();
}

class _PlaylistControlsState extends State<PlaylistControls>
    with SingleTickerProviderStateMixin {
  static const _fieldHeight = 38.0;
  static const _desktopFieldWidth = 280.0;

  final GlobalKey _searchButtonKey = GlobalKey();
  final _searchController = TextEditingController();
  late final _searchFocusNode = FocusNode(onKeyEvent: _onSearchKey);
  late final AnimationController _searchAnimation = AnimationController(
    duration: const Duration(milliseconds: 260),
    vsync: this,
  );
  late final Animation<double> _searchExpansion = CurvedAnimation(
    parent: _searchAnimation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  var _searchOpened = false;
  var _collapsedLeft = 0.0;
  var _collapsedRight = 0.0;
  var _collapsedWidth = 0.0;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void dispose() {
    _searchAnimation.dispose();
    _searchController.dispose();
    _searchFocusNode
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _openSearch() {
    _measureCollapsedSlot();
    setState(() => _searchOpened = true);
    unawaited(
      _searchAnimation.forward().then((_) {
        if (mounted && _searchOpened) _searchFocusNode.requestFocus();
      }),
    );
  }

  void _closeSearch() {
    if (!_searchOpened) return;
    _searchOpened = false;
    _searchController.clear();
    widget.onSearchChanged?.call('');
    _searchFocusNode.unfocus();
    _searchAnimation.reverse();
  }

  void _onSearchFocusChanged() {
    if (!_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      _closeSearch();
    }
  }

  KeyEventResult _onSearchKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _closeSearch();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _measureCollapsedSlot() {
    final button =
        _searchButtonKey.currentContext?.findRenderObject() as RenderBox?;
    final host = context.findRenderObject() as RenderBox?;
    if (button == null || host == null) return;
    final offset = button.localToGlobal(Offset.zero, ancestor: host);
    _collapsedLeft = offset.dx;
    _collapsedRight = host.size.width - offset.dx - button.size.width;
    _collapsedWidth = button.size.width;
  }

  @override
  Widget build(BuildContext context) {
    final device = DeviceType.fromScreenSize(MediaQuery.sizeOf(context));
    final searchable = widget.onSearchChanged != null;
    final row = IconTheme.merge(
      data: IconThemeData(size: device.isTablet ? 28 : 24),
      child: Row(
        children: [
          HoverZoom(
            builder: (context, hovered) => SizedBox.square(
              dimension: 40,
              child: Consumer(
                builder: (context, ref, _) => PlayButton(
                  isLoading: widget.isPlayLoading,
                  onPressed: widget.onPlay,
                  color: hovered ? ref.watch(accentColorProvider) : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          HoverIconButton(
            iconSize: 20,
            icon: const Icon(JPlayer.mix),
            color: Theme.of(context).colorScheme.onPrimary,
            tooltip: 'Shuffle play',
            onPressed: widget.isPlayLoading ? null : widget.onShuffle,
          ),
          ?widget.resume,
          ?widget.download,
          if (searchable && !device.isMobile)
            Expanded(child: _desktopSearchSlot())
          else
            const Spacer(),
          if (searchable && device.isMobile) _searchButton(),
          ?widget.sort,
        ],
      ),
    );
    if (!searchable || !device.isMobile) return row;
    return AnimatedBuilder(
      animation: _searchExpansion,
      builder: (context, child) {
        final progress = _searchExpansion.value.clamp(0.0, 1.0);
        return Stack(
          children: [
            IgnorePointer(
              ignoring: progress > 0,
              child: Opacity(opacity: 1 - progress, child: child),
            ),
            if (progress > 0)
              Positioned(
                left: _collapsedLeft * (1 - progress),
                right: _collapsedRight * (1 - progress),
                top: 0,
                bottom: 0,
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) => _revealedField(
                      width: constraints.maxWidth,
                      fullWidth:
                          constraints.maxWidth +
                          (_collapsedLeft + _collapsedRight) * (1 - progress),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: row,
    );
  }

  Widget _desktopSearchSlot() => Align(
    alignment: Alignment.centerRight,
    child: LayoutBuilder(
      builder: (context, constraints) => AnimatedBuilder(
        animation: _searchExpansion,
        builder: (context, child) {
          final progress = _searchExpansion.value.clamp(0.0, 1.0);
          if (progress == 0) return _searchButton();
          final fullWidth = constraints.maxWidth.clamp(0.0, _desktopFieldWidth);
          final width =
              _collapsedWidth + (fullWidth - _collapsedWidth) * progress;
          return _revealedField(width: width, fullWidth: fullWidth);
        },
      ),
    ),
  );

  Widget _searchButton() => HoverIconButton(
    key: _searchButtonKey,
    icon: const Icon(JPlayer.search),
    color: Theme.of(context).colorScheme.onPrimary,
    tooltip: 'Search',
    onPressed: _openSearch,
  );

  Widget _revealedField({required double width, required double fullWidth}) =>
      SizedBox(
        width: width,
        height: _fieldHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: fullWidth,
            maxWidth: fullWidth,
            child: _searchField(),
          ),
        ),
      );

  Widget _searchField() => TextField(
    controller: _searchController,
    focusNode: _searchFocusNode,
    onChanged: (query) => widget.onSearchChanged?.call(query.trim()),
    keyboardType: TextInputType.text,
    textInputAction: TextInputAction.search,
    style: const TextStyle(fontSize: 14, height: 1.2),
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.24),
      isDense: true,
      contentPadding: const EdgeInsets.all(7),
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(40),
      ),
      prefixIcon: const Icon(JPlayer.search, size: 14),
      prefixIconConstraints: const BoxConstraints.tightFor(
        width: 34,
        height: 34,
      ),
      suffixIcon: HoverIconButton(
        onPressed: () {
          if (_searchController.text.isEmpty) {
            _closeSearch();
          } else {
            _searchController.clear();
            widget.onSearchChanged?.call('');
          }
        },
        color: Theme.of(context).colorScheme.onPrimary,
        iconSize: 14,
        style: const ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.zero),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: const Icon(JPlayer.close),
      ),
      suffixIconConstraints: const BoxConstraints.tightFor(
        width: 34,
        height: 34,
      ),
      hintText: 'Search',
      hintStyle: const TextStyle(fontSize: 14, height: 1.2),
    ),
  );
}

class PlaylistSortButton extends ConsumerWidget {
  const PlaylistSortButton({
    required this.order,
    required this.onChanged,
    this.defaultLabel = 'Playlist order',
    super.key,
  });

  final PlaylistSongOrder order;
  final ValueChanged<PlaylistSongOrder> onChanged;
  final String defaultLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      SortMenuButton<PlaylistSongSort>(
        options: playlistSortOptions(
          defaultLabel,
          ratings: ref.watch(ratingsEnabledProvider),
        ),
        selected: order.sort,
        descending: order.descending,
        onSelected: (sort) => onChanged(order.select(sort)),
      );
}

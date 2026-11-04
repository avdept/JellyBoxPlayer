import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/widgets/anchored_dropdown.dart';
import 'package:jplayer/src/presentation/widgets/circle_play_button.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/frosted_panel.dart';
import 'package:jplayer/src/presentation/widgets/hover_zoom.dart';
import 'package:jplayer/src/presentation/widgets/pinned_item_actions.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:updatify_flutter/updatify_flutter.dart';

const _columns = 3;
const _gridSpacing = 12.0;
const _panelPadding = 12.0;
const _panelMargin = 16.0;
const _panelHeightFactor = 0.55;
const _cardTextGap = 6.0;
const _cardNameSize = 13.0;
const _cardKindSize = 11.0;

class PinnedItemsButton extends ConsumerStatefulWidget {
  const PinnedItemsButton({
    this.iconSize = 28,
    this.tapSize = 40,
    super.key,
  });

  final double iconSize;
  final double tapSize;

  @override
  ConsumerState<PinnedItemsButton> createState() => _PinnedItemsButtonState();
}

class _PinnedItemsButtonState extends ConsumerState<PinnedItemsButton> {
  final _dropdown = AnchoredDropdownController();

  void _openItem(LibraryItem item) {
    _dropdown.close();
    final (route, key) = switch (item.kind) {
      ItemKind.album => (Routes.album, 'album'),
      ItemKind.artist => (Routes.artist, 'artist'),
      ItemKind.playlist => (Routes.playlist, 'playlist'),
      _ => (null, ''),
    };
    if (route == null) return;
    if (item.kind == ItemKind.playlist) {
      ref.read(currentPlaylistProvider.notifier).setPlaylist(item);
    }
    unawaited(
      context.pushNamed(branchAwareName(context, route), extra: {key: item}),
    );
  }

  Widget _panel(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * _panelHeightFactor;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, -8 * (1 - value)),
          child: child,
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FrostedPanel(
          elevation: 12,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(_panelPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: _PinnedGrid(onOpen: _openItem),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = ref.watch(accentColorProvider);
    final count = ref.watch(pinsProvider.select((pins) => pins.length));

    return AnchoredDropdown(
      controller: _dropdown,
      margin: _panelMargin,
      menuBuilder: _panel,
      child: HoverZoom(
        builder: (context, hovered) => IconButton(
          onPressed: _dropdown.toggle,
          tooltip: 'Pinned',
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tight(Size.square(widget.tapSize)),
          style: IconButton.styleFrom(
            foregroundColor: hovered ? accent : null,
            overlayColor: Colors.transparent,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: _PinnedIcon(count: count, size: widget.iconSize),
        ),
      ),
    );
  }
}

class _PinnedIcon extends StatelessWidget {
  const _PinnedIcon({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      count > 0 ? Icons.push_pin : Icons.push_pin_outlined,
      size: size,
    );
    if (count == 0) return icon;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -7,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: PingColor.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 10,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PinnedGrid extends ConsumerWidget {
  const _PinnedGrid({required this.onOpen});

  final void Function(LibraryItem item) onOpen;

  static double _cardHeight(double width) =>
      width + _cardTextGap * 2 + _cardNameSize * 1.2 + _cardKindSize * 1.2 + 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(pinsProvider);
    final theme = Theme.of(context);

    if (pins.isEmpty) {
      return Text(
        'Nothing pinned yet. Choose "Pin to home" in the '
        'menu of an album, artist, playlist or song.',
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - _gridSpacing * (_columns - 1)) / _columns;
        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columns,
            mainAxisSpacing: _gridSpacing,
            crossAxisSpacing: _gridSpacing,
            childAspectRatio: cardWidth / _cardHeight(cardWidth),
          ),
          itemCount: pins.length,
          itemBuilder: (context, index) => _PinnedCard(
            key: ValueKey(pins[index].itemId),
            pin: pins[index],
            onOpen: onOpen,
          ),
        );
      },
    );
  }
}

class _PinnedCard extends ConsumerStatefulWidget {
  const _PinnedCard({required this.pin, required this.onOpen, super.key});

  final PinnedItem pin;
  final void Function(LibraryItem item) onOpen;

  @override
  ConsumerState<_PinnedCard> createState() => _PinnedCardState();
}

class _PinnedCardState extends ConsumerState<_PinnedCard> {
  var _isLoading = false;

  PinnedItem get _pin => widget.pin;

  bool get _isSourcePlaying => switch (ref.watch(
    queueSourceStatus(_pin.itemId),
  )) {
    PlaybackStatus.playing || PlaybackStatus.buffering => true,
    _ => false,
  };

  ScaffoldMessengerState? get _messenger => ScaffoldMessenger.maybeOf(context);

  Future<LibraryItem?> _resolve(ScaffoldMessengerState? messenger) async {
    setState(() => _isLoading = true);
    try {
      return await resolvePinnedItem(ref, _pin, messenger: messenger);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _open() async {
    if (_pin.kind == ItemKind.song) return _play();
    final item = await _resolve(_messenger);
    if (item == null || !mounted) return;
    widget.onOpen(item);
  }

  Future<void> _play() async {
    final toggled = toggleQueueSource(ref, _pin.itemId);
    if (toggled != null) return toggled;
    final messenger = _messenger;
    final item = await _resolve(messenger);
    if (item == null) return;
    await playResolvedPinnedItem(ref, item, messenger: messenger);
  }

  void _showMenu() {
    final pins = ref.read(pinsProvider.notifier);
    unawaited(
      showLongPressContextMenuSheet(
        context,
        actions: [
          ContextMenuAction(
            entry: ContextMenuEntry.play,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
            run: _play,
          ),
          ContextMenuAction(
            entry: ContextMenuEntry.pin,
            icon: const Icon(Icons.push_pin_outlined),
            label: const Text('Unpin from home'),
            run: () => pins.unpin(_pin.itemId),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showPlay = _isLoading || _isSourcePlaying;

    return GestureDetector(
      onTap: _open,
      onLongPress: _showMenu,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _cardTextGap,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: pinnedItemCover(ref, _pin, size: 256),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset(Images.album, fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: IgnorePointer(
                    ignoring: !showPlay,
                    child: AnimatedOpacity(
                      opacity: showPlay ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: CirclePlayButton(
                        size: 32,
                        isLoading: _isLoading,
                        isPlaying: _isSourcePlaying,
                        onPressed: _play,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _pin.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: _cardNameSize,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          Text(
            pinnedItemKindLabel(_pin.kind),
            maxLines: 1,
            style: TextStyle(
              fontSize: _cardKindSize,
              height: 1.2,
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

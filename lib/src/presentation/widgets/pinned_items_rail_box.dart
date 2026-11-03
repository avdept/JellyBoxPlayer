import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/circle_play_button.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/custom_navigation_rail.dart';
import 'package:jplayer/src/presentation/widgets/frosted_panel.dart';
import 'package:jplayer/src/presentation/widgets/pinned_item_actions.dart';

const _openDelay = Duration(milliseconds: 120);
const _closeDelay = Duration(milliseconds: 250);
const _barGap = 8.0;
const _cardWidth = 104.0;
const _cardSpacing = 12.0;
const _cardTextGap = 6.0;
const _cardNameSize = 13.0;
const _cardKindSize = 11.0;
const double _cardHeight =
    _cardWidth +
    _cardTextGap * 2 +
    _cardNameSize * 1.2 +
    _cardKindSize * 1.2 +
    2;
const _iconSize = 48.0;
const _coverSize = 36.0;
const _buttonHeight = 60.0;
const _stackedCovers = 3;

typedef _DeckCard = ({double angle, Offset offset});

const _deckLayouts = <int, List<_DeckCard>>{
  1: [(angle: 0, offset: Offset.zero)],
  2: [
    (angle: -0.12, offset: Offset(-4, -3)),
    (angle: 0.16, offset: Offset(6, 4)),
  ],
  3: [
    (angle: -0.18, offset: Offset(-6, -4)),
    (angle: 0, offset: Offset.zero),
    (angle: 0.2, offset: Offset(7, 5)),
  ],
};

typedef _BarHost = ({
  VoidCallback hide,
  VoidCallback menuOpened,
  VoidCallback menuClosed,
});

class PinnedItemsRailBox extends ConsumerStatefulWidget {
  const PinnedItemsRailBox({
    this.horizontalPadding = 30,
    super.key,
  });

  final double horizontalPadding;

  @override
  ConsumerState<PinnedItemsRailBox> createState() => _PinnedItemsRailBoxState();
}

class _PinnedItemsRailBoxState extends ConsumerState<PinnedItemsRailBox> {
  final _link = LayerLink();
  final _controller = OverlayPortalController();
  Timer? _timer;
  var _hovering = false;
  var _menuOpen = false;

  late final _BarHost _host = (
    hide: _hide,
    menuOpened: _onMenuOpened,
    menuClosed: _onMenuClosed,
  );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onEnterBox() {
    _hovering = true;
    _timer?.cancel();
    _timer = Timer(_openDelay, _show);
  }

  void _onEnterBar() {
    _hovering = true;
    _timer?.cancel();
  }

  void _onExit() {
    _hovering = false;
    if (!_menuOpen) _scheduleHide();
  }

  void _onMenuOpened() {
    _menuOpen = true;
    _timer?.cancel();
  }

  void _onMenuClosed() {
    _menuOpen = false;
    if (!_hovering) _scheduleHide();
  }

  void _scheduleHide() {
    _timer?.cancel();
    _timer = Timer(_closeDelay, _hide);
  }

  void _show() {
    _timer?.cancel();
    if (mounted && !_controller.isShowing) _controller.show();
  }

  void _hide() {
    _timer?.cancel();
    if (mounted && _controller.isShowing) _controller.hide();
  }

  double _availableWidth(BuildContext context) {
    final box = this.context.findRenderObject() as RenderBox?;
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (box == null || !box.hasSize) return screenWidth / 2;
    final right = box.localToGlobal(Offset(box.size.width, 0)).dx;
    return math.max(_cardWidth * 2, screenWidth - right - _barGap - 24);
  }

  Widget _bar(BuildContext context) => Positioned(
    left: 0,
    top: 0,
    child: CompositedTransformFollower(
      link: _link,
      showWhenUnlinked: false,
      targetAnchor: Alignment.centerRight,
      followerAnchor: Alignment.centerLeft,
      offset: const Offset(_barGap, 0),
      child: MouseRegion(
        onEnter: (_) => _onEnterBar(),
        onExit: (_) => _onExit(),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(-12 * (1 - value), 0),
              child: child,
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _availableWidth(context)),
            child: _PinnedItemsBar(host: _host),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pins = ref.watch(pinsProvider);
    final count = pins.length;

    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => _onEnterBox(),
        onExit: (_) => _onExit(),
        child: OverlayPortal(
          controller: _controller,
          overlayLocation: OverlayChildLocation.rootOverlay,
          overlayChildBuilder: _bar,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: RailItemButton(
              onPressed: _show,
              icon: _PinnedIcon(
                pins: pins.take(_stackedCovers).toList(),
                total: count,
              ),
              label: Text(count > 0 ? 'Pinned ($count)' : 'Pinned'),
              foregroundColor: theme.colorScheme.onPrimary,
              fontSize: 16,
              height: _buttonHeight,
              horizontalPadding: widget.horizontalPadding,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeckEntry {
  _DeckEntry(this.pin, this.controller, this.slot, this.depth, this.sequence);

  final PinnedItem pin;
  final AnimationController controller;
  final int sequence;
  _DeckCard slot;
  int depth;
  bool leaving = false;

  static int compare(_DeckEntry a, _DeckEntry b) {
    final byDepth = b.depth.compareTo(a.depth);
    if (byDepth != 0) return byDepth;
    if (a.leaving != b.leaving) return a.leaving ? -1 : 1;
    return a.sequence.compareTo(b.sequence);
  }
}

class _PinnedIcon extends ConsumerStatefulWidget {
  const _PinnedIcon({required this.pins, required this.total});

  final List<PinnedItem> pins;
  final int total;

  @override
  ConsumerState<_PinnedIcon> createState() => _PinnedIconState();
}

class _PinnedIconState extends ConsumerState<_PinnedIcon>
    with TickerProviderStateMixin {
  final _entries = <_DeckEntry>[];
  var _sequence = 0;

  @override
  void initState() {
    super.initState();
    _sync(animate: false);
  }

  @override
  void didUpdateWidget(_PinnedIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(animate: true);
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.controller.dispose();
    }
    super.dispose();
  }

  _DeckCard _slotFor(PinnedItem pin) {
    final index = widget.pins.indexWhere((p) => p.itemId == pin.itemId);
    return _deckLayouts[widget.pins.length]![index];
  }

  void _sync({required bool animate}) {
    final targetIds = {for (final pin in widget.pins) pin.itemId};
    for (final entry in _entries) {
      if (entry.leaving || targetIds.contains(entry.pin.itemId)) continue;
      entry.leaving = true;
      unawaited(entry.controller.reverse().whenComplete(() => _remove(entry)));
    }
    final known = {
      for (final entry in _entries)
        if (!entry.leaving) entry.pin.itemId,
    };
    for (final pin in widget.pins.reversed) {
      if (known.contains(pin.itemId)) continue;
      final controller = AnimationController(
        vsync: this,
        duration: _insertDuration,
        reverseDuration: _removeDuration,
        value: animate ? 0 : 1,
      );
      _entries.add(
        _DeckEntry(pin, controller, _slotFor(pin), _depthOf(pin), _sequence++),
      );
      if (animate) controller.forward().ignore();
    }
  }

  int _depthOf(PinnedItem pin) =>
      widget.pins.indexWhere((p) => p.itemId == pin.itemId);

  void _refreshSlots() {
    for (final entry in _entries) {
      if (entry.leaving) continue;
      entry
        ..slot = _slotFor(entry.pin)
        ..depth = _depthOf(entry.pin);
    }
    _entries.sort(_DeckEntry.compare);
  }

  void _remove(_DeckEntry entry) {
    entry.controller.dispose();
    if (!mounted) return;
    setState(() => _entries.remove(entry));
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return const Icon(Icons.push_pin_outlined);
    _refreshSlots();
    final color = IconTheme.of(context).color;

    return SizedBox.square(
      dimension: _iconSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (final entry in _entries)
            _DeckCardView(
              key: ValueKey(entry),
              entry: entry,
              image: pinnedItemCover(ref, entry.pin, size: 64),
            ),
          if (widget.pins.isNotEmpty)
            Positioned(
              top: -4,
              right: -5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.push_pin, size: 13, color: color),
                ),
              ),
            ),
          if (widget.total > _stackedCovers)
            Positioned(
              bottom: -4,
              right: -5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  child: Text(
                    '${widget.total}',
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeckCardView extends StatelessWidget {
  const _DeckCardView({
    required this.entry,
    required this.image,
    super.key,
  });

  final _DeckEntry entry;
  final ImageProvider image;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: entry.controller,
    builder: (context, child) {
      final t = Curves.easeOut.transform(entry.controller.value);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(-_iconSize * 0.6 * (1 - t), 0),
          child: child,
        ),
      );
    },
    child: TweenAnimationBuilder<Offset>(
      tween: Tween(end: entry.slot.offset),
      duration: _insertDuration,
      curve: Curves.easeOut,
      builder: (context, offset, child) =>
          Transform.translate(offset: offset, child: child),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: entry.slot.angle),
        duration: _insertDuration,
        curve: Curves.easeOut,
        builder: (context, angle, child) =>
            Transform.rotate(angle: angle, child: child),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image(
            image: image,
            width: _coverSize,
            height: _coverSize,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Image.asset(
              Images.album,
              width: _coverSize,
              height: _coverSize,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    ),
  );
}

class _PinnedItemsBar extends ConsumerWidget {
  const _PinnedItemsBar({required this.host});

  final _BarHost host;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(pinsProvider);
    final theme = Theme.of(context);

    return FrostedPanel(
      elevation: 12,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, pins.isEmpty ? 12 : 0, 12),
        child: pins.isEmpty
            ? ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Text(
                  'Nothing pinned yet. Choose "Pin to sidebar" in the '
                  'menu of an album, artist, playlist or song.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                  ),
                ),
              )
            : _AnimatedPinCards(pins: pins, host: host),
      ),
    );
  }
}

const _insertDuration = Duration(milliseconds: 280);
const _removeDuration = Duration(milliseconds: 180);

class _AnimatedPinCards extends StatefulWidget {
  const _AnimatedPinCards({required this.pins, required this.host});

  final List<PinnedItem> pins;
  final _BarHost host;

  @override
  State<_AnimatedPinCards> createState() => _AnimatedPinCardsState();
}

class _AnimatedPinCardsState extends State<_AnimatedPinCards> {
  final _listKey = GlobalKey<AnimatedListState>();
  late List<PinnedItem> _shown = [...widget.pins];

  static List<String> _ids(List<PinnedItem> pins) => [
    for (final pin in pins) pin.itemId,
  ];

  @override
  void didUpdateWidget(_AnimatedPinCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.pins;
    final list = _listKey.currentState;
    final diff = diffIds(_ids(_shown), _ids(target));
    if (list == null || diff.isEmpty) {
      _shown = [...target];
      return;
    }
    for (final index in diff.removals) {
      final removed = _shown.removeAt(index);
      list.removeItem(
        index,
        (context, animation) => _card(removed, animation),
        duration: _removeDuration,
      );
    }
    for (final index in diff.insertions) {
      _shown.insert(index, target[index]);
      list.insertItem(index, duration: _insertDuration);
    }
    _shown = [...target];
  }

  Widget _card(PinnedItem pin, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Align(
        alignment: Alignment.centerLeft,
        widthFactor: curved.value,
        child: child,
      ),
      child: FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(-0.5, 0),
            end: Offset.zero,
          ).animate(curved),
          child: Padding(
            padding: const EdgeInsets.only(right: _cardSpacing),
            child: _PinnedCard(
              key: ValueKey(pin.itemId),
              pin: pin,
              host: widget.host,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _cardHeight,
    child: AnimatedList(
      key: _listKey,
      scrollDirection: Axis.horizontal,
      shrinkWrap: true,
      clipBehavior: Clip.none,
      initialItemCount: _shown.length,
      itemBuilder: (context, index, animation) =>
          _card(_shown[index], animation),
    ),
  );
}

class _PinnedCard extends ConsumerStatefulWidget {
  const _PinnedCard({required this.pin, required this.host, super.key});

  final PinnedItem pin;
  final _BarHost host;

  @override
  ConsumerState<_PinnedCard> createState() => _PinnedCardState();
}

class _PinnedCardState extends ConsumerState<_PinnedCard> {
  var _isHovered = false;
  var _isLoading = false;

  PinnedItem get _pin => widget.pin;

  ImageProvider get _image => pinnedItemCover(ref, _pin, size: 256);

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
    final router = GoRouter.of(context);
    final item = await _resolve(_messenger);
    if (item == null || !mounted) return;
    widget.host.hide();
    switch (item.kind) {
      case ItemKind.album:
        router.goNamed(Routes.album.name, extra: {'album': item});
      case ItemKind.artist:
        router.goNamed(Routes.artist.name, extra: {'artist': item});
      case ItemKind.playlist:
        ref.read(currentPlaylistProvider.notifier).setPlaylist(item);
        router.goNamed(Routes.playlist.name, extra: {'playlist': item});
      case _:
        return;
    }
  }

  Future<void> _play() async {
    final toggled = toggleQueueSource(ref, _pin.itemId);
    if (toggled != null) return toggled;
    final messenger = _messenger;
    final item = await _resolve(messenger);
    if (item == null) return;
    await playResolvedPinnedItem(ref, item, messenger: messenger);
  }

  void _showMenu(Offset position) {
    final pins = ref.read(pinsProvider.notifier);
    widget.host.menuOpened();
    showContextMenu(
      context,
      position: position,
      onClosed: widget.host.menuClosed,
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
          label: const Text('Unpin from sidebar'),
          run: () => pins.unpin(_pin.itemId),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showPlay = _isHovered || _isLoading || _isSourcePlaying;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.04 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: GestureDetector(
          onTap: _open,
          onSecondaryTapUp: (details) => _showMenu(details.globalPosition),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: _cardWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: _cardTextGap,
              children: [
                SizedBox.square(
                  dimension: _cardWidth,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image(
                          image: _image,
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
          ),
        ),
      ),
    );
  }
}

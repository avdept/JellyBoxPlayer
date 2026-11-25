import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/themes/app_colors.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/circle_play_button.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';
import 'package:jplayer/src/presentation/widgets/horizontal_scroll_region.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class ReleaseCardStrip extends StatelessWidget {
  const ReleaseCardStrip({
    required this.title,
    required this.items,
    required this.device,
    required this.onItemTap,
    this.onPlayPressed,
    this.optionsBuilder,
    this.onRetry,
    this.horizontalPadding = 0,
    super.key,
  });

  static const rows = 2;
  static const mobilePageFraction = 0.7;
  static const columnWidth = 340.0;

  final String title;
  final AsyncValue<List<LibraryItem>> items;
  final DeviceType device;
  final void Function(LibraryItem) onItemTap;
  final Future<void> Function(LibraryItem)? onPlayPressed;
  final List<ContextMenuAction> Function(BuildContext, LibraryItem)?
  optionsBuilder;
  final VoidCallback? onRetry;
  final double horizontalPadding;

  double get _spacing => device.isMobile ? 8 : 12;

  double get _height =>
      ReleaseCard.heightFor(device) * rows + _spacing * (rows - 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = items.when(
      data: (list) =>
          list.isEmpty ? null : _strip(list.length, (i) => _card(list[i])),
      error: (error, stackTrace) => _message(theme, showRetry: true),
      loading: () =>
          _strip((device.isMobile ? 3 : 6) * rows, (_) => _shimmer()),
    );

    if (content == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Text(
            title,
            style: TextStyle(
              fontSize: device.isMobile ? 20 : 24,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        content,
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _card(LibraryItem item) => ReleaseCard(
    item: item,
    device: device,
    onTap: onItemTap,
    onPlayPressed: onPlayPressed,
    optionsBuilder: optionsBuilder,
  );

  Widget _shimmer() =>
      ShimmerBox(height: ReleaseCard.heightFor(device), radius: 12);

  Widget _strip(int count, Widget Function(int) builder) {
    final pages = (count / rows).ceil();
    Widget page(int page) => Column(
      spacing: _spacing,
      children: [
        for (
          var index = page * rows;
          index < (page + 1) * rows && index < count;
          index++
        )
          builder(index),
      ],
    );
    Widget spaced(Widget child) => Padding(
      padding: EdgeInsets.only(right: _spacing),
      child: child,
    );

    return SizedBox(
      height: _height,
      child: device.isMobile
          ? _MobilePages(
              count: pages,
              leadingInset: horizontalPadding,
              builder: (index) => spaced(page(index)),
            )
          : HorizontalScrollRegion(
              controlsInset: horizontalPadding / 2,
              builder: (context, controller) => ListView.builder(
                controller: controller,
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                scrollCacheExtent: const ScrollCacheExtent.pixels(columnWidth),
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: max(0, horizontalPadding - _spacing),
                ),
                itemCount: pages,
                itemBuilder: (context, index) =>
                    spaced(SizedBox(width: columnWidth, child: page(index))),
              ),
            ),
    );
  }

  Widget _message(ThemeData theme, {bool showRetry = false}) => Padding(
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
    child: Row(
      children: [
        Flexible(
          child: Text(
            'Could not load this section.',
            style: TextStyle(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
          ),
        ),
        if (showRetry && onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _MobilePages extends StatefulWidget {
  const _MobilePages({
    required this.count,
    required this.leadingInset,
    required this.builder,
  });

  final int count;
  final double leadingInset;
  final Widget Function(int) builder;

  @override
  State<_MobilePages> createState() => _MobilePagesState();
}

class _MobilePagesState extends State<_MobilePages> {
  final _controller = PageController(
    viewportFraction: ReleaseCardStrip.mobilePageFraction,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(left: widget.leadingInset),
    child: PageView.builder(
      controller: _controller,
      padEnds: false,
      allowImplicitScrolling: true,
      itemCount: widget.count,
      itemBuilder: (context, index) => widget.builder(index),
    ),
  );
}

class ReleaseCard extends ConsumerStatefulWidget {
  const ReleaseCard({
    required this.item,
    required this.device,
    this.onTap,
    this.onPlayPressed,
    this.optionsBuilder,
    super.key,
  });

  final LibraryItem item;
  final DeviceType device;
  final void Function(LibraryItem)? onTap;
  final Future<void> Function(LibraryItem)? onPlayPressed;
  final List<ContextMenuAction> Function(BuildContext, LibraryItem)?
  optionsBuilder;

  static double heightFor(DeviceType device) => device.isMobile ? 56 : 72;

  static double paddingFor(DeviceType device) => device.isMobile ? 6 : 8;

  @override
  ConsumerState<ReleaseCard> createState() => _ReleaseCardState();
}

class _ReleaseCardState extends ConsumerState<ReleaseCard> {
  var _isHovered = false;
  var _isPlayLoading = false;

  LibraryItem get _item => widget.item;

  bool get _isSourcePlaying => switch (ref.watch(queueSourceStatus(_item.id))) {
    PlaybackStatus.playing || PlaybackStatus.buffering => true,
    _ => false,
  };

  List<ContextMenuAction>? _actions(BuildContext context) =>
      widget.optionsBuilder?.call(context, _item);

  Future<void> _onPlayPressed() async {
    final onPlayPressed = widget.onPlayPressed;
    if (onPlayPressed == null || _isPlayLoading) return;
    final toggled = toggleQueueSource(ref, _item.id);
    if (toggled != null) return toggled;
    setState(() => _isPlayLoading = true);
    try {
      await onPlayPressed(_item);
    } finally {
      if (mounted) setState(() => _isPlayLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final hasMenu = widget.optionsBuilder != null;
    final height = ReleaseCard.heightFor(device);

    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null ? null : () => widget.onTap!(_item),
      onLongPress: !device.isDesktop && hasMenu
          ? () => showLongPressContextMenuSheet(
              context,
              actions: _actions(context)!,
            )
          : null,
      onSecondaryTapUp: hasMenu
          ? (details) => showContextMenu(
              context,
              position: details.globalPosition,
              actions: _actions(context)!,
            )
          : null,
      child: ReleaseCardFace(
        item: _item,
        height: height,
        padding: ReleaseCard.paddingFor(device),
        titleSize: device.isMobile ? 14 : 15,
        subtitleSize: device.isMobile ? 12 : 13,
        coverOverlay: _playButton(height),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: card,
      ),
    );
  }

  Widget? _playButton(double size) {
    if (widget.onPlayPressed == null) return null;
    final isPlayVisible = _isHovered || _isPlayLoading || _isSourcePlaying;
    return IgnorePointer(
      ignoring: !isPlayVisible,
      child: AnimatedOpacity(
        opacity: isPlayVisible ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: CirclePlayButton(
          size: size * 0.55,
          isLoading: _isPlayLoading,
          isPlaying: _isSourcePlaying,
          onPressed: _onPlayPressed,
        ),
      ),
    );
  }
}

class ReleaseCardFace extends ConsumerWidget {
  const ReleaseCardFace({
    required this.item,
    required this.height,
    this.padding = 8,
    this.titleSize = 15,
    this.subtitleSize = 13,
    this.coverOverlay,
    super.key,
  });

  static const radius = 12.0;
  static const _baseTint = Color(0x12FFFFFF);

  final LibraryItem item;
  final double height;
  final double padding;
  final double titleSize;
  final double subtitleSize;
  final Widget? coverOverlay;

  String _subtitle(BuildContext context) =>
      [?item.albumArtist, ?_releaseLabel(context)].join(' · ');

  String? _releaseLabel(BuildContext context) {
    final date = item.originalReleaseDate;
    if (date == null) return item.productionYear?.toString();
    final localizations = MaterialLocalizations.of(context);
    final monthDay = localizations.formatShortMonthDay(date);
    return '$monthDay, ${localizations.formatYear(date)}';
  }

  static Color _dull(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(hsl.saturation * 0.45)
        .withLightness(hsl.lightness * 0.85)
        .toColor();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tinted = ref.watch(settingProvider(AppSetting.recentReleasesTinted));
    final scheme = tinted
        ? ref.watch(itemCoverSchemeProvider(item)).valueOrNull
        : null;
    final subtitle = _subtitle(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: _baseTint,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: tinted ? null : AppColors.from(context).card,
          gradient: scheme == null
              ? null
              : LinearGradient(
                  colors: [
                    _dull(scheme.primary).withValues(alpha: 0.5),
                    _dull(scheme.secondary).withValues(alpha: 0.28),
                  ],
                ),
        ),
        child: Row(
          children: [
            _cover(ref),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: padding + 2,
                  vertical: padding,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: subtitleSize,
                          height: 1.3,
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cover(WidgetRef ref) => SizedBox.square(
    dimension: height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(radius),
          ),
          child: Image(
            image: ref.read(imageServiceProvider).itemImage(item),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Image.asset(Images.album, fit: BoxFit.cover),
          ),
        ),
        if (coverOverlay != null) Center(child: coverOverlay),
      ],
    ),
  );
}

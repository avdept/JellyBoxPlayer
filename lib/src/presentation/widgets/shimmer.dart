import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/utils/utils.dart';
import 'package:jplayer/src/presentation/widgets/album_card_metrics.dart';
import 'package:jplayer/src/presentation/widgets/album_view.dart';

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({this.width, this.height, this.radius = 4, super.key});

  final double? width;
  final double? height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  static final _random = Random();

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 1200),
    vsync: this,
  );

  late final Animation<double> _pulse = Tween<double>(
    begin: 0.6,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _controller.value = _random.nextDouble();
    unawaited(_controller.repeat(reverse: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;
    final radius = BorderRadius.circular(widget.radius);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16 * _pulse.value),
            borderRadius: radius,
          ),
        ),
      ),
    );
  }
}

class AlbumCardShimmer extends StatelessWidget {
  const AlbumCardShimmer({
    required this.width,
    required this.device,
    super.key,
  });

  final double width;
  final DeviceType device;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AlbumView.coverTextSpacing,
      children: [
        const Flexible(
          child: AspectRatio(
            aspectRatio: 1,
            child: ShimmerBox(radius: 12),
          ),
        ),
        ShimmerBox(
          height: (device.isTablet ? 24 : 16) * 1.1,
          width: width * 0.8,
        ),
        ShimmerBox(
          height: (device.isTablet ? 22 : 14) * 1.1,
          width: width * 0.55,
        ),
      ],
    ),
  );
}

class AlbumCardsRowShimmer extends StatelessWidget {
  const AlbumCardsRowShimmer({
    required this.device,
    this.count = 5,
    this.horizontalPadding = 0,
    super.key,
  });

  final DeviceType device;
  final int count;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AlbumCardMetrics.carouselHeight(device),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: count,
      separatorBuilder: (context, index) =>
          SizedBox(width: AlbumCardMetrics.carouselSpacing(device)),
      itemBuilder: (context, index) => AlbumCardShimmer(
        width: AlbumCardMetrics.carouselWidth(device),
        device: device,
      ),
    ),
  );
}

class AlbumCardsGridShimmer extends StatelessWidget {
  const AlbumCardsGridShimmer({
    required this.device,
    this.count = 6,
    this.gridDelegate,
    super.key,
  });

  final DeviceType device;
  final int count;
  final SliverGridDelegate? gridDelegate;

  @override
  Widget build(BuildContext context) => SliverGrid.builder(
    gridDelegate: gridDelegate ?? AlbumCardMetrics.gridDelegate(device),
    itemCount: count,
    itemBuilder: (context, index) => AlbumCardShimmer(
      width: AlbumCardMetrics.maxWidth(device),
      device: device,
    ),
  );
}

class SongRowShimmer extends StatelessWidget {
  const SongRowShimmer({
    required this.device,
    this.edgePadding = 0,
    super.key,
  });

  final DeviceType device;
  final double edgePadding;

  @override
  Widget build(BuildContext context) {
    final coverSize = device.isMobile ? 46.0 : 56.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(edgePadding, 8, edgePadding, 8),
      child: Row(
        children: [
          ShimmerBox(width: coverSize, height: coverSize, radius: 6),
          SizedBox(width: device.isMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(
                  height: (device.isTablet ? 18 : 14) * 1.2,
                  width: coverSize * 3,
                ),
                const SizedBox(height: 6),
                ShimmerBox(
                  height: (device.isTablet ? 16 : 12) * 1.2,
                  width: coverSize * 2,
                ),
              ],
            ),
          ),
          const ShimmerBox(width: 34, height: 12),
        ],
      ),
    );
  }
}

class SongRowsShimmer extends StatelessWidget {
  const SongRowsShimmer({
    required this.device,
    this.count = 5,
    this.edgePadding = 0,
    super.key,
  });

  final DeviceType device;
  final int count;
  final double edgePadding;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var index = 0; index < count; index++)
        SongRowShimmer(device: device, edgePadding: edgePadding),
    ],
  );
}

class SectionsShimmer extends StatelessWidget {
  const SectionsShimmer({
    required this.device,
    this.cardRows = 1,
    this.songRows = 3,
    super.key,
  });

  final DeviceType device;
  final int cardRows;
  final int songRows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var index = 0; index < cardRows; index++) ...[
        const _SectionHeaderShimmer(),
        AlbumCardsRowShimmer(device: device, count: 4),
        SizedBox(height: device.isMobile ? 16 : 24),
      ],
      if (songRows > 0) ...[
        const _SectionHeaderShimmer(),
        SongRowsShimmer(device: device, count: songRows),
      ],
    ],
  );
}

class _SectionHeaderShimmer extends StatelessWidget {
  const _SectionHeaderShimmer();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: ShimmerBox(width: 96, height: 20, radius: 6),
  );
}

class TextLinesShimmer extends StatelessWidget {
  const TextLinesShimmer({
    this.count = 6,
    this.lineHeight = 20,
    this.spacing = 16,
    this.alignment = CrossAxisAlignment.center,
    super.key,
  });

  static const _widthFactors = [0.72, 0.54, 0.83, 0.46, 0.66, 0.78, 0.58];

  final int count;
  final double lineHeight;
  final double spacing;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.hasBoundedWidth ? constraints.maxWidth : 240.0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: alignment,
        children: [
          for (var index = 0; index < count; index++)
            Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: ShimmerBox(
                width: width * _widthFactors[index % _widthFactors.length],
                height: lineHeight,
                radius: 6,
              ),
            ),
        ],
      );
    },
  );
}

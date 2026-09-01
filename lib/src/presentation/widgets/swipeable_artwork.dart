import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class SwipeableArtwork extends ConsumerStatefulWidget {
  const SwipeableArtwork({
    required this.sequenceState,
    required this.artworkBuilder,
    this.borderRadius = 12,
    this.horizontalPadding = 30,
    this.scale = 1,
    super.key,
  });

  final SequenceState sequenceState;
  final Widget Function(MediaItem? item) artworkBuilder;
  final double borderRadius;
  final double horizontalPadding;
  final double scale;

  @override
  ConsumerState<SwipeableArtwork> createState() => _SwipeableArtworkState();
}

class _SwipeableArtworkState extends ConsumerState<SwipeableArtwork> {
  late final PageController _controller;
  late int _page;

  List<int> get _order {
    final state = widget.sequenceState;
    if (state.shuffleModeEnabled &&
        state.shuffleIndices.length == state.sequence.length) {
      return state.shuffleIndices;
    }
    return List.generate(state.sequence.length, (index) => index);
  }

  int get _currentPage {
    final currentIndex = widget.sequenceState.currentIndex;
    if (currentIndex == null) return 0;
    final page = _order.indexOf(currentIndex);
    return page < 0 ? 0 : page;
  }

  @override
  void initState() {
    super.initState();
    _page = _currentPage;
    _controller = PageController(initialPage: _page);
  }

  @override
  void didUpdateWidget(covariant SwipeableArtwork oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _currentPage;
    if (target == _page) return;
    _page = target;
    WidgetsBinding.instance.addPostFrameCallback((_) => _moveTo(target));
  }

  void _moveTo(int target) {
    if (!mounted || !_controller.hasClients) return;
    if (_controller.position.isScrollingNotifier.value) return;
    final current = _controller.page?.round();
    if (current == target) return;
    if (current != null && (current - target).abs() == 1) {
      unawaited(
        _controller.animateToPage(
          target,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      );
    } else {
      _controller.jumpToPage(target);
    }
  }

  Future<void> _onPageChanged(int page) async {
    if (page == _page) return;
    _page = page;

    final order = _order;
    if (page < 0 || page >= order.length) return;
    final index = order[page];
    if (index == widget.sequenceState.currentIndex) return;

    _hapticTick();
    await ref.read(playbackProvider.notifier).skipTo(index);
  }

  void _hapticTick() {
    final platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.android) {
      unawaited(HapticFeedback.selectionClick());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sequence = widget.sequenceState.sequence;
    final order = _order;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min<double>(
          math.max<double>(
            constraints.maxWidth - widget.horizontalPadding * 2,
            0,
          ),
          constraints.maxHeight,
        );
        return Center(
          child: SizedBox(
            width: constraints.maxWidth,
            height: side,
            child: PageView.builder(
              controller: _controller,
              onPageChanged: _onPageChanged,
              allowImplicitScrolling: true,
              itemCount: order.length,
              itemBuilder: (context, page) {
                final index = order[page];
                final item = sequence.elementAtOrNull(index)?.tag as MediaItem?;
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.horizontalPadding,
                  ),
                  child: Center(
                    child: AnimatedScale(
                      scale: widget.scale,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeOutCubic,
                      child: SizedBox.square(
                        dimension: side,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            widget.borderRadius,
                          ),
                          child: widget.artworkBuilder(item),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

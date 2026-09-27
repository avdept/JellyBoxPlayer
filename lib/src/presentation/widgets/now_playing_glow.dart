import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';

class NowPlayingGlow extends ConsumerStatefulWidget {
  const NowPlayingGlow({
    required this.item,
    required this.borderRadius,
    required this.child,
    this.blurRadius = 28,
    super.key,
  });

  final LibraryItem item;
  final BorderRadius borderRadius;
  final double blurRadius;
  final Widget child;

  @override
  ConsumerState<NowPlayingGlow> createState() => _NowPlayingGlowState();
}

class _NowPlayingGlowState extends ConsumerState<NowPlayingGlow>
    with SingleTickerProviderStateMixin {
  static const _fallbackColor = Color(0xFF0066FF);
  static const _pausedLevel = 0.4;

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
    value: 1,
  );

  Color? _color;

  static bool _isPlaying(PlaybackStatus? status) =>
      status == PlaybackStatus.playing || status == PlaybackStatus.buffering;

  @override
  void initState() {
    super.initState();
    _syncBreath(ref.read(queueSourceStatus(widget.item.id)));
  }

  @override
  void didUpdateWidget(NowPlayingGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _color = null;
      _syncBreath(ref.read(queueSourceStatus(widget.item.id)));
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  void _syncBreath(PlaybackStatus? status) {
    if (_isPlaying(status)) {
      if (!_breath.isAnimating) _breath.repeat(reverse: true);
    } else if (_breath.isAnimating || _breath.value != 1) {
      _breath.animateTo(1, duration: const Duration(milliseconds: 400));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = queueSourceStatus(widget.item.id);
    ref.listen(provider, (_, next) => _syncBreath(next));
    final status = ref.watch(provider);
    final isPlaying = _isPlaying(status);
    final isActive = isPlaying || status == PlaybackStatus.paused;

    if (isActive) {
      final resolved = ref.watch(itemGlowColorProvider(widget.item));
      if (resolved.hasValue || resolved.hasError) {
        _color = resolved.valueOrNull ?? _fallbackColor;
      }
    }

    final color = _color;
    final level = color == null || !isActive
        ? 0.0
        : (isPlaying ? 1.0 : _pausedLevel);

    return TweenAnimationBuilder<double>(
      tween: Tween(end: level),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      child: widget.child,
      builder: (context, level, child) => AnimatedBuilder(
        animation: _breath,
        child: child,
        builder: (context, child) {
          final breath = Curves.easeInOut.transform(_breath.value);
          final intensity = level * (0.6 + 0.4 * breath);
          final glow = color ?? _fallbackColor;
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: intensity == 0
                  ? const []
                  : [
                      BoxShadow(
                        color: glow.withValues(alpha: 0.55 * intensity),
                        blurRadius: widget.blurRadius,
                        spreadRadius: widget.blurRadius * 0.1 * intensity,
                      ),
                      BoxShadow(
                        color: glow.withValues(alpha: 0.35 * intensity),
                        blurRadius: widget.blurRadius * 0.35,
                      ),
                    ],
            ),
            child: child,
          );
        },
      ),
    );
  }
}

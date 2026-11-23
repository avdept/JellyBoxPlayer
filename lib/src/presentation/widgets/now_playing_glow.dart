import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/presentation/themes/app_colors.dart';
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
    with TickerProviderStateMixin {
  static const _pausedLevel = 0.4;
  static const _breathPeriod = Duration(milliseconds: 2400);
  static const _breathStep = Duration(milliseconds: 100);

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: 1,
  );

  late final AnimationController _level = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  late final Animation<double> _intensity = _GlowIntensity(_level, _breath);

  Timer? _breathTimer;
  var _breathRising = false;
  var _tickersEnabled = true;
  var _levelTarget = 0.0;
  Color? _color;

  static bool _isPlaying(PlaybackStatus? status) =>
      status == PlaybackStatus.playing || status == PlaybackStatus.buffering;

  @override
  void initState() {
    super.initState();
    _level.addStatusListener((_) => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tickersEnabled = TickerMode.valuesOf(context).enabled;
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
    _breathTimer?.cancel();
    _breath.dispose();
    _level.dispose();
    super.dispose();
  }

  void _syncBreath(PlaybackStatus? status) {
    final breathing =
        _tickersEnabled &&
        _isPlaying(status) &&
        ref.read(settingProvider(AppSetting.nowPlayingHalo));
    if (breathing) {
      _breathTimer ??= Timer.periodic(_breathStep, (_) => _stepBreath());
    } else {
      _breathTimer?.cancel();
      _breathTimer = null;
      if (_breath.value != 1) _breath.animateTo(1);
    }
  }

  void _stepBreath() {
    final delta = _breathStep.inMilliseconds / _breathPeriod.inMilliseconds;
    var next = _breath.value + (_breathRising ? delta : -delta);
    if (next <= 0) {
      next = 0;
      _breathRising = true;
    } else if (next >= 1) {
      next = 1;
      _breathRising = false;
    }
    _breath.value = next;
  }

  void _animateLevelTo(double target) {
    if (target == _levelTarget) return;
    _levelTarget = target;
    _level.animateTo(target, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final provider = queueSourceStatus(widget.item.id);
    ref
      ..listen(provider, (_, next) => _syncBreath(next))
      ..listen(
        settingProvider(AppSetting.nowPlayingHalo),
        (_, _) => _syncBreath(ref.read(provider)),
      );
    final enabled = ref.watch(settingProvider(AppSetting.nowPlayingHalo));
    final status = ref.watch(provider);
    final isPlaying = _isPlaying(status);
    final isActive = enabled && (isPlaying || status == PlaybackStatus.paused);

    final fallback = AppColors.from(context).accent;
    if (isActive) {
      final resolved = ref.watch(itemGlowColorProvider(widget.item));
      if (resolved.hasValue || resolved.hasError) {
        _color = resolved.valueOrNull ?? fallback;
      }
    }

    final color = _color;
    _animateLevelTo(
      color == null || !isActive ? 0.0 : (isPlaying ? 1.0 : _pausedLevel),
    );
    final showGlow = _levelTarget > 0 || _level.isAnimating;

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        if (showGlow)
          Positioned.fill(
            child: _GlowImage(
              color: color ?? fallback,
              borderRadius: widget.borderRadius,
              blurRadius: widget.blurRadius,
              opacity: _intensity,
            ),
          ),
        widget.child,
      ],
    );
  }
}

class _GlowIntensity extends CompoundAnimation<double> {
  _GlowIntensity(Animation<double> level, Animation<double> breath)
    : super(first: level, next: breath);

  @override
  double get value {
    final breath = Curves.easeInOut.transform(next.value);
    return first.value * (0.6 + 0.4 * breath);
  }
}

class _GlowImage extends StatefulWidget {
  const _GlowImage({
    required this.color,
    required this.borderRadius,
    required this.blurRadius,
    required this.opacity,
  });

  final Color color;
  final BorderRadius borderRadius;
  final double blurRadius;
  final Animation<double> opacity;

  @override
  State<_GlowImage> createState() => _GlowImageState();
}

class _GlowImageState extends State<_GlowImage> {
  ui.Image? _image;
  Size? _size;
  double? _dpr;
  Color? _color;
  double? _blurRadius;
  BorderRadius? _borderRadius;

  double get _margin => widget.blurRadius * 2.5;

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  List<BoxShadow> get _shadows => [
    BoxShadow(
      color: widget.color.withValues(alpha: 0.55),
      blurRadius: widget.blurRadius,
      spreadRadius: widget.blurRadius * 0.1,
    ),
    BoxShadow(
      color: widget.color.withValues(alpha: 0.35),
      blurRadius: widget.blurRadius * 0.35,
    ),
  ];

  ui.Image _imageFor(Size size, double dpr) {
    final current = _image;
    if (current != null &&
        _size == size &&
        _dpr == dpr &&
        _color == widget.color &&
        _blurRadius == widget.blurRadius &&
        _borderRadius == widget.borderRadius) {
      return current;
    }
    current?.dispose();
    _size = size;
    _dpr = dpr;
    _color = widget.color;
    _blurRadius = widget.blurRadius;
    _borderRadius = widget.borderRadius;

    final margin = _margin;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(dpr)
      ..translate(margin, margin);
    final rrect = widget.borderRadius.toRRect(Offset.zero & size);
    for (final shadow in _shadows) {
      canvas.drawRRect(rrect.inflate(shadow.spreadRadius), shadow.toPaint());
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      ((size.width + margin * 2) * dpr).ceil(),
      ((size.height + margin * 2) * dpr).ceil(),
    );
    picture.dispose();
    return _image = image;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      if (!size.isFinite || size.isEmpty) return const SizedBox.shrink();
      final dpr = MediaQuery.devicePixelRatioOf(context);
      final width = size.width + _margin * 2;
      final height = size.height + _margin * 2;
      return OverflowBox(
        maxWidth: width,
        maxHeight: height,
        child: RawImage(
          image: _imageFor(size, dpr),
          width: width,
          height: height,
          scale: dpr,
          fit: BoxFit.fill,
          opacity: widget.opacity,
        ),
      );
    },
  );
}

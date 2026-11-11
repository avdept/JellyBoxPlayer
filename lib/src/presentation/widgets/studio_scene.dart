import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/presentation/widgets/studio_clock.dart';
import 'package:jplayer/src/providers/color_scheme_provider.dart';
import 'package:palette_generator/palette_generator.dart';

const studioDimming = 0.65;

const defaultStudioColors = [
  Color(0xFF121212),
  Color(0xFF9470FF),
  Color(0xFF121212),
  Color(0xFF8838FF),
];

List<Color> studioColorsFrom({
  Color? darkMuted,
  Color? darkVibrant,
  Color? vibrant,
  Color? lightVibrant,
  Color? muted,
  Color? dominant,
}) {
  final base = darkMuted ?? darkVibrant ?? defaultStudioColors[0];
  final accent = vibrant ?? dominant ?? muted ?? defaultStudioColors[1];
  final shade = darkVibrant ?? muted ?? base;
  final highlight = lightVibrant ?? accent;
  return [
    for (final color in [base, accent, shade, highlight])
      Color.lerp(color, Colors.black, 1 - studioDimming)!.withValues(alpha: 1),
  ];
}

List<Color> studioColorsFromPalette(PaletteGenerator palette) =>
    studioColorsFrom(
      darkMuted: palette.darkMutedColor?.color,
      darkVibrant: palette.darkVibrantColor?.color,
      vibrant: palette.vibrantColor?.color,
      lightVibrant: palette.lightVibrantColor?.color,
      muted: palette.mutedColor?.color,
      dominant: palette.dominantColor?.color,
    );

List<Color> lerpStudioColors(List<Color> from, List<Color> to, double t) => [
  for (var i = 0; i < to.length; i++)
    Color.lerp(i < from.length ? from[i] : to[i], to[i], t)!,
];

mixin StudioSceneState<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  static const _colorBlendPerTick = 0.12;

  late final StudioClock clock;
  final colors = ValueNotifier<List<Color>>(defaultStudioColors);
  final ownPointer = ValueNotifier<Offset?>(null);
  List<Color> _targetColors = defaultStudioColors;
  PaletteGenerator? _palette;

  bool get animate;
  ValueListenable<Offset?>? get externalPointer;
  bool get sceneReady;

  ValueListenable<Offset?> get pointerSource => externalPointer ?? ownPointer;

  void initScene() {
    clock = StudioClock(playing: ref.read(playbackProvider).status.isPlaying)
      ..addListener(onTick);
    applyAnimationSpeed(ref.read(animationSpeedProvider));
    ref
      ..listenManual(
        animationSpeedProvider,
        (_, speed) => applyAnimationSpeed(speed),
      )
      ..listenManual(
        playbackProvider.select((state) => state.status.isPlaying),
        (_, playing) => clock.isPlaying = playing,
      )
      ..listenManual(
        artworkPaletteProvider,
        (_, palette) => _retarget(palette.valueOrNull),
        fireImmediately: true,
      );
  }

  void disposeScene() {
    clock.dispose();
    colors.dispose();
    ownPointer.dispose();
  }

  @mustCallSuper
  void onTick() => _blendColors();

  void applyAnimationSpeed(AnimationSpeed speed) {
    clock.run(animate: animate, speedScale: speed.multiplier);
    if (!clock.isRunning) colors.value = _targetColors;
  }

  List<Color> colorsFor(PaletteGenerator? palette) =>
      palette == null ? defaultStudioColors : studioColorsFromPalette(palette);

  void refreshColors() {
    _targetColors = colorsFor(_palette);
    if (!clock.isRunning || !sceneReady) colors.value = _targetColors;
  }

  void _retarget(PaletteGenerator? palette) {
    _palette = palette;
    refreshColors();
  }

  void _blendColors() {
    if (colors.value == _targetColors) return;
    final blended = lerpStudioColors(
      colors.value,
      _targetColors,
      _colorBlendPerTick,
    );
    var settled = true;
    for (var i = 0; i < blended.length; i++) {
      final target = _targetColors[i];
      if ((blended[i].r - target.r).abs() > 0.002 ||
          (blended[i].g - target.g).abs() > 0.002 ||
          (blended[i].b - target.b).abs() > 0.002) {
        settled = false;
        break;
      }
    }
    colors.value = settled ? _targetColors : blended;
  }

  void _track(PointerEvent event) => ownPointer.value = event.localPosition;

  void _release(PointerEvent event) {
    if (event.kind != PointerDeviceKind.mouse) ownPointer.value = null;
  }

  Widget capturePointer(Widget child) {
    if (externalPointer != null) return child;
    return MouseRegion(
      opaque: false,
      onExit: (_) => ownPointer.value = null,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerHover: _track,
        onPointerDown: _track,
        onPointerMove: _track,
        onPointerUp: _release,
        onPointerCancel: _release,
        child: child,
      ),
    );
  }
}

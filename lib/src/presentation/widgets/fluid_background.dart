import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/shaders/shaders.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/shader_config_provider.dart';
import 'package:jplayer/src/presentation/widgets/studio_scene.dart';
import 'package:palette_generator/palette_generator.dart';

const fluidShaderAsset = 'shaders/paper/fluid.frag';
const flowShaderAsset = 'shaders/paper/flow.frag';
const fluidNoiseAsset = 'assets/images/paper_noise.png';
const fluidColorSlots = 10;
const fluidIdleTicks = 180;

const _proportion = 0.45;
const _softness = 1.0;
const _shape = 0.0;
const _shapeScale = 0.1;
const _distortion = 0.25;
const _swirl = 0.8;
const _swirlIterations = 10.0;

const waterColors = [Color(0xFF071E33), Color(0xFF0B4F6E), Color(0xFF1E8FB0)];

Future<ui.Image>? _fluidNoiseFuture;

Future<ui.Image> fluidNoiseTexture() => _fluidNoiseFuture ??= () async {
  final bytes = await rootBundle.load(fluidNoiseAsset);
  final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}();

Future<ui.FragmentProgram>? _fluidProgramFuture;
Future<ui.FragmentProgram>? _flowProgramFuture;

Future<ui.FragmentProgram> fluidProgram() =>
    _fluidProgramFuture ??= ui.FragmentProgram.fromAsset(fluidShaderAsset);

Future<ui.FragmentProgram> flowProgram() =>
    _flowProgramFuture ??= ui.FragmentProgram.fromAsset(flowShaderAsset);

List<double> fluidUniforms({
  required Size size,
  required double time,
  required List<Color> colors,
  required FluidSettings settings,
}) {
  final values = <double>[
    size.width,
    size.height,
    1,
    time,
    0,
    1,
    0,
    0.5,
    0.5,
    0,
    0,
    0,
    0,
    1,
  ];
  for (var i = 0; i < fluidColorSlots; i++) {
    if (i < colors.length) {
      final color = colors[i];
      values.addAll([
        color.r * color.a,
        color.g * color.a,
        color.b * color.a,
        color.a,
      ]);
    } else {
      values.addAll(const [0, 0, 0, 0]);
    }
  }
  values.addAll([
    max(1, colors.length).toDouble(),
    _proportion,
    _softness,
    _shape,
    _shapeScale,
    _distortion,
    _swirl,
    _swirlIterations,
    settings.strength,
    settings.flowSize.toDouble(),
  ]);
  return values;
}

List<Color> fluidColorsFromPalette(
  PaletteGenerator? palette, {
  required int coverColors,
}) {
  final accent =
      palette?.vibrantColor?.color ??
      palette?.dominantColor?.color ??
      palette?.mutedColor?.color;
  final highlight =
      palette?.lightVibrantColor?.color ??
      palette?.lightMutedColor?.color ??
      accent;
  final colors = [...waterColors];
  if (coverColors >= 1 && accent != null) colors.insert(2, _dim(accent));
  if (coverColors >= 2 && highlight != null) colors.add(_dim(highlight));
  return colors;
}

Color _dim(Color color) =>
    Color.lerp(color, Colors.black, 1 - studioDimming)!.withValues(alpha: 1);

typedef FluidStroke = ({Offset from, Offset to, Offset velocity, double alpha});

const FluidStroke noFluidStroke = (
  from: Offset.zero,
  to: Offset.zero,
  velocity: Offset.zero,
  alpha: 0,
);

FluidStroke nextFluidStroke(
  FluidStroke previous,
  Offset? pointer, {
  required Size view,
  required double dt,
  required FluidSettings settings,
}) {
  if (pointer == null || view.isEmpty) return noFluidStroke;
  final to = Offset(pointer.dx / view.width, pointer.dy / view.height);
  final from = previous.alpha > 0 ? previous.to : to;
  var velocity = Offset.zero;
  if (dt > 0) {
    final delta = Offset(
      (to.dx - from.dx) * view.aspectRatio,
      to.dy - from.dy,
    );
    velocity = delta / dt * settings.velocityGain;
    if (velocity.distance > 1) velocity /= velocity.distance;
  }
  velocity = Offset.lerp(
    previous.velocity,
    velocity,
    settings.velocitySmoothing,
  )!;
  return (from: from, to: to, velocity: velocity, alpha: 1);
}

List<double> flowUniforms(
  FluidStroke stroke, {
  required double aspect,
  required FluidSettings settings,
}) => [
  settings.flowSize.toDouble(),
  settings.flowSize.toDouble(),
  aspect,
  stroke.from.dx,
  stroke.from.dy,
  stroke.to.dx,
  stroke.to.dy,
  stroke.velocity.dx,
  stroke.velocity.dy,
  stroke.alpha,
  settings.falloff,
  settings.dissipation,
  settings.advection,
];

class FluidFlow {
  FluidFlow(ui.FragmentProgram program, {required int size})
    : _shader = program.fragmentShader(),
      _size = size {
    image.value = _blank(size);
  }

  final ui.FragmentShader _shader;
  final image = ValueNotifier<ui.Image?>(null);
  final _watch = Stopwatch();
  FluidStroke _stroke = noFluidStroke;
  int _size;
  int _idleTicks = fluidIdleTicks;

  static ui.Image _blank(int size) {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 1, 1),
      Paint()..color = const Color(0xFF808000),
    );
    final picture = recorder.endRecording();
    final blank = picture.toImageSync(size, size);
    picture.dispose();
    return blank;
  }

  void step({
    required Size view,
    required Offset? pointer,
    required FluidSettings settings,
  }) {
    if (settings.flowSize != _size) {
      _size = settings.flowSize;
      image.value?.dispose();
      image.value = _blank(_size);
      _idleTicks = fluidIdleTicks;
    }
    final dt = _watch.elapsedMicroseconds / 1e6;
    _watch
      ..reset()
      ..start();
    _stroke = nextFluidStroke(
      _stroke,
      pointer,
      view: view,
      dt: dt,
      settings: settings,
    );
    if (_stroke.alpha > 0) {
      _idleTicks = 0;
    } else if (_idleTicks >= fluidIdleTicks) {
      return;
    } else {
      _idleTicks++;
    }
    final previous = image.value;
    if (previous == null) return;
    final values = flowUniforms(
      _stroke,
      aspect: view.aspectRatio,
      settings: settings,
    );
    for (var i = 0; i < values.length; i++) {
      _shader.setFloat(i, values[i]);
    }
    _shader.setImageSampler(0, previous);
    final recorder = ui.PictureRecorder();
    final side = _size.toDouble();
    Canvas(
      recorder,
    ).drawRect(Rect.fromLTWH(0, 0, side, side), Paint()..shader = _shader);
    final picture = recorder.endRecording();
    image.value = picture.toImageSync(_size, _size);
    picture.dispose();
    previous.dispose();
  }

  void dispose() {
    image.value?.dispose();
    image.dispose();
    _shader.dispose();
  }
}

class FluidPainter extends CustomPainter {
  FluidPainter({
    required this.shader,
    required this.clock,
    required this.colors,
    required this.flow,
    required this.settings,
  }) : super(repaint: Listenable.merge([clock, colors, flow, settings]));

  final ui.FragmentShader shader;
  final ValueListenable<double> clock;
  final ValueListenable<List<Color>> colors;
  final ValueListenable<ui.Image?> flow;
  final ValueListenable<FluidSettings> settings;

  @override
  void paint(Canvas canvas, Size size) {
    final flowImage = flow.value;
    if (size.isEmpty || flowImage == null) return;
    final values = fluidUniforms(
      size: size,
      time: clock.value,
      colors: colors.value,
      settings: settings.value,
    );
    for (var i = 0; i < values.length; i++) {
      shader.setFloat(i, values[i]);
    }
    shader.setImageSampler(1, flowImage);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant FluidPainter oldDelegate) =>
      oldDelegate.shader != shader;
}

class FluidBackground extends ConsumerStatefulWidget {
  const FluidBackground({this.animate = true, this.pointer, super.key});

  final bool animate;
  final ValueListenable<Offset?>? pointer;

  @override
  ConsumerState<FluidBackground> createState() => _FluidBackgroundState();
}

class _FluidBackgroundState extends ConsumerState<FluidBackground>
    with StudioSceneState {
  late final ValueNotifier<FluidSettings> _settings;
  ui.FragmentShader? _shader;
  FluidFlow? _flow;
  Size _view = Size.zero;

  @override
  bool get animate => widget.animate;

  @override
  ValueListenable<Offset?>? get externalPointer => widget.pointer;

  @override
  bool get sceneReady => _shader != null;

  @override
  List<Color> colorsFor(PaletteGenerator? palette) {
    final settings = _settings.value;
    return settings.waterColors
        ? fluidColorsFromPalette(palette, coverColors: settings.coverColors)
        : super.colorsFor(palette);
  }

  @override
  void initState() {
    super.initState();
    _settings = ValueNotifier(
      FluidSettings(ref.read(shaderValuesProvider(FluidShader.config))),
    );
    ref.listenManual(shaderValuesProvider(FluidShader.config), (_, values) {
      final previous = _settings.value;
      final next = FluidSettings(values);
      _settings.value = next;
      clock.fps = next.fps;
      if (previous.waterColors != next.waterColors ||
          previous.coverColors != next.coverColors) {
        refreshColors();
      }
    });
    initScene();
    clock.fps = _settings.value.fps;
    unawaited(_loadShaders());
  }

  @override
  void didUpdateWidget(FluidBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      applyAnimationSpeed(ref.read(animationSpeedProvider));
    }
  }

  @override
  void dispose() {
    disposeScene();
    _settings.dispose();
    _flow?.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  void onTick() {
    super.onTick();
    final settings = _settings.value;
    _flow?.step(
      view: _view,
      pointer: settings.reactToPointer ? pointerSource.value : null,
      settings: settings,
    );
  }

  Future<void> _loadShaders() async {
    try {
      final program = await fluidProgram();
      final flow = await flowProgram();
      final noise = await fluidNoiseTexture();
      if (!mounted) return;
      setState(() {
        _shader = program.fragmentShader()..setImageSampler(0, noise);
        _flow = FluidFlow(flow, size: _settings.value.flowSize);
      });
    } on Object catch (error) {
      dev.log('Failed to build fluid shader', error: error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    final flow = _flow;
    if (shader == null || flow == null) return const SizedBox.expand();
    return capturePointer(
      LayoutBuilder(
        builder: (context, constraints) {
          _view = constraints.biggest;
          return RepaintBoundary(
            child: CustomPaint(
              size: constraints.biggest,
              painter: FluidPainter(
                shader: shader,
                clock: clock,
                colors: colors,
                flow: flow.image,
                settings: _settings,
              ),
            ),
          );
        },
      ),
    );
  }
}

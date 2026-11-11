import 'package:jplayer/src/core/shaders/shader_config.dart';

abstract final class FluidShader {
  static const clockFps = ShaderKnob(
    key: 'fps',
    label: 'Clock fps',
    min: 5,
    max: 60,
    defaultValue: 60,
    divisions: 55,
    decimals: 0,
  );

  static const waterColors = ShaderToggle(
    key: 'waterColors',
    label: 'Water colours',
    defaultValue: false,
  );

  static const reactToPointer = ShaderToggle(
    key: 'reactToPointer',
    label: 'React to mouse movement',
    defaultValue: true,
  );

  static const coverColors = ShaderKnob(
    key: 'coverColors',
    label: 'Cover colours in water',
    min: 0,
    max: 2,
    defaultValue: 2,
    divisions: 2,
    decimals: 0,
    enabledBy: waterColors,
  );

  static const flowSize = ShaderKnob(
    key: 'flowSize',
    label: 'Flow map size',
    min: 64,
    max: 1024,
    defaultValue: 256,
    divisions: 15,
    decimals: 0,
    unit: ' px',
    step: 64,
  );

  static const strength = ShaderKnob(
    key: 'strength',
    label: 'Strength',
    min: 0,
    max: 2,
    defaultValue: 0.7,
  );

  static const falloff = ShaderKnob(
    key: 'falloff',
    label: 'Stroke width',
    min: 0.02,
    max: 0.4,
    defaultValue: 0.12,
    decimals: 3,
  );

  static const dissipation = ShaderKnob(
    key: 'dissipation',
    label: 'Dissipation',
    min: 0.8,
    max: 0.995,
    defaultValue: 0.95,
    decimals: 3,
  );

  static const advection = ShaderKnob(
    key: 'advection',
    label: 'Advection',
    min: 0,
    max: 0.1,
    defaultValue: 0.03,
    decimals: 3,
  );

  static const velocityGain = ShaderKnob(
    key: 'velocityGain',
    label: 'Velocity gain',
    min: 0.1,
    max: 2,
    defaultValue: 0.6,
  );

  static const velocitySmoothing = ShaderKnob(
    key: 'velocitySmoothing',
    label: 'Velocity smoothing',
    min: 0.1,
    max: 1,
    defaultValue: 0.5,
  );

  static const config = ShaderConfig(
    id: 'fluid',
    title: 'Flow tuning',
    toggles: [waterColors, reactToPointer],
    knobs: [
      clockFps,
      coverColors,
      flowSize,
      strength,
      falloff,
      dissipation,
      advection,
      velocityGain,
      velocitySmoothing,
    ],
  );
}

class FluidSettings {
  const FluidSettings([this.values = const ShaderValues(FluidShader.config)]);

  final ShaderValues values;

  int get fps => values.whole(FluidShader.clockFps);
  bool get waterColors => values.flag(FluidShader.waterColors);
  bool get reactToPointer => values.flag(FluidShader.reactToPointer);
  int get coverColors => values.whole(FluidShader.coverColors);
  int get flowSize => values.whole(FluidShader.flowSize);
  double get strength => values.number(FluidShader.strength);
  double get falloff => values.number(FluidShader.falloff);
  double get dissipation => values.number(FluidShader.dissipation);
  double get advection => values.number(FluidShader.advection);
  double get velocityGain => values.number(FluidShader.velocityGain);
  double get velocitySmoothing => values.number(FluidShader.velocitySmoothing);
}

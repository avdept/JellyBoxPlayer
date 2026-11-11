import 'package:flutter/foundation.dart';

class ShaderToggle {
  const ShaderToggle({
    required this.key,
    required this.label,
    required this.defaultValue,
  });

  final String key;
  final String label;
  final bool defaultValue;
}

class ShaderKnob {
  const ShaderKnob({
    required this.key,
    required this.label,
    required this.min,
    required this.max,
    required this.defaultValue,
    this.divisions,
    this.decimals = 2,
    this.unit = '',
    this.step,
    this.enabledBy,
  });

  final String key;
  final String label;
  final double min;
  final double max;
  final double defaultValue;
  final int? divisions;
  final int decimals;
  final String unit;
  final double? step;
  final ShaderToggle? enabledBy;

  double snap(double value) {
    final clamped = value.clamp(min, max);
    final step = this.step;
    if (step == null) return clamped;
    return ((clamped / step).round() * step).clamp(min, max);
  }

  String display(double value) => '${value.toStringAsFixed(decimals)}$unit';
}

@immutable
class ShaderConfig {
  const ShaderConfig({
    required this.id,
    required this.title,
    this.toggles = const [],
    this.knobs = const [],
  });

  final String id;
  final String title;
  final List<ShaderToggle> toggles;
  final List<ShaderKnob> knobs;

  @override
  bool operator ==(Object other) => other is ShaderConfig && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class ShaderValues {
  const ShaderValues(this.config, [this.raw = const {}]);

  factory ShaderValues.fromJson(ShaderConfig config, Object? json) {
    if (json is! Map) return ShaderValues(config);
    final raw = <String, Object>{};
    for (final knob in config.knobs) {
      if (json[knob.key] case final num value) {
        raw[knob.key] = knob.snap(value.toDouble());
      }
    }
    for (final toggle in config.toggles) {
      if (json[toggle.key] case final bool value) raw[toggle.key] = value;
    }
    return ShaderValues(config, raw);
  }

  final ShaderConfig config;
  final Map<String, Object> raw;

  double number(ShaderKnob knob) => switch (raw[knob.key]) {
    final num value => knob.snap(value.toDouble()),
    _ => knob.defaultValue,
  };

  int whole(ShaderKnob knob) => number(knob).round();

  bool flag(ShaderToggle toggle) => switch (raw[toggle.key]) {
    final bool value => value,
    _ => toggle.defaultValue,
  };

  bool enabled(ShaderKnob knob) {
    final toggle = knob.enabledBy;
    return toggle == null || flag(toggle);
  }

  ShaderValues withNumber(ShaderKnob knob, double value) =>
      ShaderValues(config, {...raw, knob.key: knob.snap(value)});

  ShaderValues withFlag(ShaderToggle toggle, {required bool value}) =>
      ShaderValues(config, {...raw, toggle.key: value});

  ShaderValues reset() => ShaderValues(config);

  Map<String, Object> toJson() => Map.of(raw);
}

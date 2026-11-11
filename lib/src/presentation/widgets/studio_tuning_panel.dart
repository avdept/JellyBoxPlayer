import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/shaders/shaders.dart';
import 'package:jplayer/src/domain/providers/shader_config_provider.dart';
import 'package:jplayer/src/presentation/widgets/hover_icon_button.dart';

class StudioTuningPanel extends ConsumerWidget {
  const StudioTuningPanel({required this.shader, super.key});

  final ShaderConfig shader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = ref.watch(shaderValuesProvider(shader));
    final notifier = ref.read(shaderValuesProvider(shader).notifier);
    return SizedBox(
      width: 320,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
          child: DefaultTextStyle(
            style: const TextStyle(color: Colors.white, fontSize: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shader.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    HoverIconButton(
                      onPressed: notifier.reset,
                      color: Colors.white,
                      iconSize: 18,
                      tooltip: 'Reset',
                      icon: const Icon(Icons.restart_alt),
                    ),
                    HoverIconButton(
                      onPressed: () =>
                          ref.read(studioTuningPanelProvider.notifier).state =
                              false,
                      color: Colors.white,
                      iconSize: 18,
                      tooltip: 'Close',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final toggle in shader.toggles)
                  _Toggle(
                    label: toggle.label,
                    value: values.flag(toggle),
                    onChanged: (value) =>
                        notifier.setFlag(toggle, value: value),
                  ),
                for (final knob in shader.knobs)
                  if (values.enabled(knob))
                    _Knob(
                      knob: knob,
                      value: values.number(knob),
                      onChanged: (value) => notifier.setNumber(knob, value),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      SizedBox(
        height: 28,
        child: FittedBox(
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white38,
            inactiveThumbColor: Colors.white70,
            inactiveTrackColor: Colors.white12,
          ),
        ),
      ),
      const SizedBox(width: 8),
    ],
  );
}

class _Knob extends StatelessWidget {
  const _Knob({
    required this.knob,
    required this.value,
    required this.onChanged,
  });

  final ShaderKnob knob;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(child: Text(knob.label)),
          Text(
            knob.display(value),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 8),
        ],
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          activeTrackColor: Colors.white,
          inactiveTrackColor: Colors.white24,
          thumbColor: Colors.white,
        ),
        child: SizedBox(
          height: 24,
          child: Slider(
            value: value.clamp(knob.min, knob.max),
            min: knob.min,
            max: knob.max,
            divisions: knob.divisions,
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );
}

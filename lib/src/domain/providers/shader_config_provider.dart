import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/shaders/shaders.dart';
import 'package:jplayer/src/data/providers/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShaderValuesNotifier extends StateNotifier<ShaderValues> {
  ShaderValuesNotifier(this._prefs, ShaderConfig config)
    : super(_read(_prefs, config));

  static String keyFor(ShaderConfig config) => 'shader_config.${config.id}';

  final SharedPreferences? _prefs;

  static ShaderValues _read(SharedPreferences? prefs, ShaderConfig config) {
    final stored = prefs?.getString(keyFor(config));
    if (stored == null) return ShaderValues(config);
    try {
      return ShaderValues.fromJson(config, jsonDecode(stored));
    } on FormatException {
      return ShaderValues(config);
    }
  }

  void setNumber(ShaderKnob knob, double value) =>
      _store(state.withNumber(knob, value));

  void setFlag(ShaderToggle toggle, {required bool value}) =>
      _store(state.withFlag(toggle, value: value));

  void reset() => _store(state.reset());

  void _store(ShaderValues next) {
    state = next;
    final prefs = _prefs;
    if (prefs == null) return;
    unawaited(prefs.setString(keyFor(next.config), jsonEncode(next.toJson())));
  }
}

final StateNotifierProviderFamily<
  ShaderValuesNotifier,
  ShaderValues,
  ShaderConfig
>
shaderValuesProvider =
    StateNotifierProvider.family<
      ShaderValuesNotifier,
      ShaderValues,
      ShaderConfig
    >(
      (ref, config) => ShaderValuesNotifier(
        ref.watch(sharedPreferencesProvider).valueOrNull,
        config,
      ),
    );

final studioTuningPanelProvider = StateProvider<bool>((_) => false);

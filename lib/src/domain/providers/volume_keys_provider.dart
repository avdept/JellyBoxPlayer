import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/platform/volume_keys.dart';
import 'package:jplayer/src/domain/providers/device_volume_provider.dart';
import 'package:jplayer/src/domain/providers/system_volume_provider.dart';
import 'package:jplayer/src/domain/providers/volume_provider.dart';

final hardwareVolumeKeysProvider = Provider<HardwareVolumeKeys>(
  (ref) => PlatformVolumeKeys(),
);

final capturesVolumeKeysProvider = Provider<bool>(
  (ref) =>
      ref.watch(usesSystemVolumeProvider) &&
      ref.watch(volumeScopeProvider) != VolumeScope.system,
);

final volumeKeysProvider = StateNotifierProvider<VolumeKeysNotifier, bool>(
  (ref) => VolumeKeysNotifier(ref, ref.watch(hardwareVolumeKeysProvider)),
);

class VolumeKeysNotifier extends StateNotifier<bool> {
  VolumeKeysNotifier(this._ref, this._keys) : super(false) {
    _presses = _keys.presses.listen(press);
    _ref.listen(
      capturesVolumeKeysProvider,
      (_, capture) => _setCapture(capture),
      fireImmediately: true,
    );
    try {
      _lifecycle = AppLifecycleListener(onResume: _resync);
    } on Object catch (error) {
      debugPrint('[volume] lifecycle events unavailable: $error');
    }
    if (kDebugMode) HardwareKeyboard.instance.addHandler(_debugKey);
  }

  static const step = 0.05;
  static const showFor = Duration(milliseconds: 1800);
  static const settleAfter = Duration(milliseconds: 400);

  final Ref _ref;
  final HardwareVolumeKeys _keys;
  late final StreamSubscription<VolumeKey> _presses;
  AppLifecycleListener? _lifecycle;
  Timer? _hideTimer;
  Timer? _settleTimer;
  bool _capturing = false;

  void _setCapture(bool capture) {
    if (_capturing == capture) return;
    _capturing = capture;
    if (!capture) dismiss();
    unawaited(_keys.setCapture(capture));
  }

  void _resync() {
    if (!_capturing || _ref.read(volumeScopeProvider) != VolumeScope.player) {
      return;
    }
    unawaited(_ref.read(volumeProvider.notifier).syncFromTarget());
  }

  bool _debugKey(KeyEvent event) {
    if (event is! KeyDownEvent || !HardwareKeyboard.instance.isAltPressed) {
      return false;
    }
    final key = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => VolumeKey.up,
      LogicalKeyboardKey.arrowDown => VolumeKey.down,
      _ => null,
    };
    if (key == null) return false;
    _step(key);
    return true;
  }

  void press(VolumeKey key) {
    if (_capturing) _step(key);
  }

  void _step(VolumeKey key) {
    final base = _ref.read(deviceVolumeProvider).effectiveLevel;
    final delta = key == VolumeKey.up ? step : -step;
    final next = ((base + delta) * 100).round().clamp(0, 100) / 100;
    unawaited(
      _ref.read(deviceVolumeProvider.notifier).setLevel(next, settle: false),
    );
    _settleTimer?.cancel();
    _settleTimer = Timer(settleAfter, () {
      _settleTimer = null;
      if (!mounted) return;
      unawaited(_ref.read(deviceVolumeProvider.notifier).setLevel(next));
    });
    show();
  }

  void show() {
    state = true;
    _hideTimer?.cancel();
    _hideTimer = Timer(showFor, dismiss);
  }

  void dismiss() {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (mounted) state = false;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _settleTimer?.cancel();
    _lifecycle?.dispose();
    if (kDebugMode) HardwareKeyboard.instance.removeHandler(_debugKey);
    unawaited(_presses.cancel());
    if (_capturing) unawaited(_keys.setCapture(false));
    super.dispose();
  }
}

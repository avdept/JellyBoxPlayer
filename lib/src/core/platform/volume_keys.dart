import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:native_route_picker/native_route_picker.dart';

enum VolumeKey { up, down }

abstract class HardwareVolumeKeys {
  Stream<VolumeKey> get presses;

  Future<void> setCapture(bool enabled);
}

class PlatformVolumeKeys implements HardwareVolumeKeys {
  PlatformVolumeKeys() {
    if (Platform.isAndroid) _android.setMethodCallHandler(_onAndroidCall);
  }

  static const _android = MethodChannel('jellybox/volume_keys');

  final _presses = StreamController<VolumeKey>.broadcast();
  StreamSubscription<VolumeButton>? _ios;

  Future<void> _onAndroidCall(MethodCall call) async {
    if (call.method != 'press') return;
    final key = VolumeKey.values.asNameMap()[call.arguments];
    if (key != null) _presses.add(key);
  }

  @override
  Stream<VolumeKey> get presses => _presses.stream;

  @override
  Future<void> setCapture(bool enabled) async {
    try {
      if (Platform.isAndroid) {
        await _android.invokeMethod<void>('setCapture', enabled);
      } else if (Platform.isIOS) {
        if (enabled) {
          _ios ??= NativeRoutePicker.volumeButtons.listen(
            (direction) => _presses.add(
              direction == VolumeButton.up ? VolumeKey.up : VolumeKey.down,
            ),
          );
        } else {
          await _ios?.cancel();
          _ios = null;
        }
        await NativeRoutePicker.captureVolumeButtons(enabled);
      }
    } on PlatformException catch (error) {
      debugPrint('[volume] key capture unavailable: $error');
    } on MissingPluginException catch (error) {
      debugPrint('[volume] key capture unavailable: $error');
    }
  }
}

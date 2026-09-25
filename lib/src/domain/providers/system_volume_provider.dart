import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:native_route_picker/native_route_picker.dart';

abstract class SystemVolume {
  Stream<double> get changes;

  Future<void> write(double level);
}

class PlatformSystemVolume implements SystemVolume {
  PlatformSystemVolume() {
    if (Platform.isAndroid) {
      unawaited(FlutterVolumeController.updateShowSystemUI(false));
    }
  }

  @override
  Stream<double> get changes {
    if (Platform.isIOS) return NativeRoutePicker.outputVolume;
    late final StreamController<double> controller;
    controller = StreamController<double>(
      onListen: () => FlutterVolumeController.addListener(controller.add),
      onCancel: FlutterVolumeController.removeListener,
    );
    return controller.stream;
  }

  @override
  Future<void> write(double level) => FlutterVolumeController.setVolume(level);
}

final usesSystemVolumeProvider = Provider<bool>(
  (ref) => !kIsWeb && (Platform.isIOS || Platform.isAndroid),
);

final systemVolumeSourceProvider = Provider<SystemVolume>(
  (ref) => PlatformSystemVolume(),
);

final systemVolumeProvider =
    StateNotifierProvider<SystemVolumeNotifier, double>(
      (ref) => SystemVolumeNotifier(ref.watch(systemVolumeSourceProvider)),
    );

class SystemVolumeNotifier extends StateNotifier<double> {
  SystemVolumeNotifier(this._source) : super(1) {
    _changes = _source.changes.listen(
      (level) => state = level.clamp(0.0, 1.0),
      onError: (Object error) =>
          debugPrint('[volume] system volume unavailable: $error'),
    );
  }

  final SystemVolume _source;
  late final StreamSubscription<double> _changes;

  Future<void> setLevel(double level) {
    state = level.clamp(0.0, 1.0);
    return _source.write(state);
  }

  @override
  void dispose() {
    unawaited(_changes.cancel());
    super.dispose();
  }
}

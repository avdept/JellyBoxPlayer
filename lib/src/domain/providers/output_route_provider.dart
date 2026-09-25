import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_route_picker/native_route_picker.dart';

class OutputRouteController {
  const OutputRouteController();

  bool get isSupported => NativeRoutePicker.isSupported;
}

final outputRouteProvider = Provider<OutputRouteController>(
  (ref) => const OutputRouteController(),
);

final currentOutputRouteProvider = StreamProvider<OutputRoute?>(
  (ref) => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
      ? NativeRoutePicker.outputRoute
      : Stream.value(null),
);

final externalOutputRouteProvider = Provider<OutputRoute?>((ref) {
  final route = ref.watch(currentOutputRouteProvider).valueOrNull;
  return route != null && route.isExternal ? route : null;
});

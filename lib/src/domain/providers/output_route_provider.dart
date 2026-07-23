import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_route_picker/native_route_picker.dart';

class OutputRouteController {
  const OutputRouteController();

  bool get isSupported => NativeRoutePicker.isSupported;

  Future<bool> showAndroidSwitcher() => NativeRoutePicker.showOutputSwitcher();
}

final outputRouteProvider = Provider<OutputRouteController>(
  (ref) => const OutputRouteController(),
);

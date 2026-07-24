import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeRoutePicker {
  NativeRoutePicker._();

  static const String viewType = 'native_route_picker/view';

  static bool get isSupported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }
}

class RoutePickerButton extends StatelessWidget {
  const RoutePickerButton({
    super.key,
    this.size = 24,
    this.color,
    this.activeColor,
    this.onUnsupported,
  });

  final double size;
  final Color? color;
  final Color? activeColor;
  final VoidCallback? onUnsupported;

  @override
  Widget build(BuildContext context) {
    final tint = color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    final active = activeColor ?? Theme.of(context).colorScheme.primary;

    final params = <String, dynamic>{
      'tintColor': tint.toARGB32(),
      'activeTintColor': active.toARGB32(),
    };

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return SizedBox.square(
          dimension: size,
          child: UiKitView(
            viewType: NativeRoutePicker.viewType,
            creationParams: params,
            creationParamsCodec: const StandardMessageCodec(),
          ),
        );
      case TargetPlatform.macOS:
        return SizedBox.square(
          dimension: size,
          child: AppKitView(
            viewType: NativeRoutePicker.viewType,
            creationParams: params,
            creationParamsCodec: const StandardMessageCodec(),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NativeRoutePicker {
  NativeRoutePicker._();

  static const MethodChannel _channel = MethodChannel('native_route_picker');

  static const String viewType = 'native_route_picker/view';

  static bool get isSupported {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.android:
        return true;
      default:
        return false;
    }
  }

  static Future<bool> showOutputSwitcher() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final result = await _channel.invokeMethod<bool>('showOutputSwitcher');
      return result ?? false;
    } on PlatformException {
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
      case TargetPlatform.android:
        return IconButton(
          iconSize: size,
          color: tint,
          tooltip: 'Output device',
          onPressed: () async {
            final shown = await NativeRoutePicker.showOutputSwitcher();
            if (!shown) onUnsupported?.call();
          },
          icon: const Icon(Icons.speaker_group_outlined),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum OutputRouteKind { builtIn, airPlay, bluetooth, wired, car, other }

@immutable
class OutputRoute {
  const OutputRoute({required this.kind, required this.name});

  final OutputRouteKind kind;
  final String name;

  bool get isExternal => kind != OutputRouteKind.builtIn;

  @override
  bool operator ==(Object other) =>
      other is OutputRoute && other.kind == kind && other.name == name;

  @override
  int get hashCode => Object.hash(kind, name);
}

class NativeRoutePicker {
  NativeRoutePicker._();

  static const String viewType = 'native_route_picker/view';

  static const _channel = MethodChannel('native_route_picker');
  static const _outputVolume = EventChannel('native_route_picker/output_volume');

  static const _outputRoute = EventChannel('native_route_picker/output_route');

  static Stream<OutputRoute> get outputRoute => _outputRoute
      .receiveBroadcastStream()
      .map((value) {
        final route = (value as Map).cast<String, String>();
        return OutputRoute(
          kind: OutputRouteKind.values.asNameMap()[route['kind']] ??
              OutputRouteKind.other,
          name: route['name'] ?? '',
        );
      })
      .distinct();

  static Stream<double> get outputVolume => _outputVolume
      .receiveBroadcastStream()
      .map((value) => (value as num).toDouble());

  static Future<bool> showOutputSwitcher({Offset? anchor}) async {
    if (!isSupported) return false;
    try {
      final shown = await _channel.invokeMethod<bool>('showOutputSwitcher', {
        if (anchor != null) 'x': anchor.dx,
        if (anchor != null) 'y': anchor.dy,
      });
      return shown ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Whether an in-app native picker is available on the current platform.
  ///
  /// Android is intentionally excluded: there's no reliable in-app output
  /// picker there. Local outputs (Bluetooth/wired/speaker) are handled by the
  /// OS media-notification switcher, and networked/Chromecast output needs a
  /// separate Cast integration (not yet implemented).
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
      // Android is handled by the OS notification switcher; no in-app button
      // for now (a Cast-based picker would go here later).
      default:
        return const SizedBox.shrink();
    }
  }
}

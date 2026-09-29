import 'package:flutter/services.dart';

class HomeScreenWidgets {
  const HomeScreenWidgets({required this.appGroup});

  static const _channel = MethodChannel('home_screen_widgets');

  final String appGroup;

  Future<String?> directory() =>
      _channel.invokeMethod<String>('directory', {'appGroup': appGroup});

  Future<void> reload({
    required String androidProvider,
    required String iosKind,
  }) => _channel.invokeMethod('reload', {
    'androidProvider': androidProvider,
    'iosKind': iosKind,
  });
}

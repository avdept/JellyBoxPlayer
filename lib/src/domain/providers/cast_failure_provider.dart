import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class CastFailure {
  const CastFailure({required this.deviceName, required this.reported});

  final String deviceName;
  final bool reported;

  String get message =>
      'Unable to cast to $deviceName — switched back to this device.'
      '${reported ? ' An error report was submitted and Alex will look into '
                'whether this device can be supported.' : ''}';
}

class CastFailureNotifier extends Notifier<CastFailure?> {
  @override
  CastFailure? build() => null;

  void report(String deviceName) => state = CastFailure(
    deviceName: deviceName,
    reported: Sentry.isEnabled,
  );

  void clear() => state = null;
}

final castFailureProvider = NotifierProvider<CastFailureNotifier, CastFailure?>(
  CastFailureNotifier.new,
);

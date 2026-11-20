import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class CastFailure {
  const CastFailure({
    required this.deviceName,
    required this.reported,
    this.takenOver = false,
    this.notFound = false,
    this.switchedHere = true,
  });

  final String deviceName;
  final bool reported;
  final bool takenOver;
  final bool notFound;
  final bool switchedHere;

  String get message {
    if (notFound) {
      return switchedHere
          ? '$deviceName was not found on this network — playing on this '
                'device.'
          : '$deviceName was not found on this network.';
    }
    if (takenOver) {
      return switchedHere
          ? '$deviceName is now playing something else — switched back to '
                'this device.'
          : '$deviceName is now playing something else.';
    }
    final report = reported
        ? ' An error report was submitted and Alex will look into whether '
              'this device can be supported.'
        : '';
    return switchedHere
        ? 'Unable to cast to $deviceName — switched back to this device.$report'
        : 'Unable to play on $deviceName.$report';
  }
}

class CastFailureNotifier extends Notifier<CastFailure?> {
  @override
  CastFailure? build() => null;

  void report(
    String deviceName, {
    bool takenOver = false,
    bool notFound = false,
    bool switchedHere = true,
  }) => state = CastFailure(
    deviceName: deviceName,
    reported: !takenOver && !notFound && Sentry.isEnabled,
    takenOver: takenOver,
    notFound: notFound,
    switchedHere: switchedHere,
  );

  void clear() => state = null;
}

final castFailureProvider = NotifierProvider<CastFailureNotifier, CastFailure?>(
  CastFailureNotifier.new,
);

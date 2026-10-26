import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/generated/l10n.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class CastFailure {
  const CastFailure({
    required this.deviceName,
    required this.reported,
    this.takenOver = false,
  });

  final String deviceName;
  final bool reported;
  final bool takenOver;

  String get message {
    if (takenOver) return S.current.castTakenOver(deviceName);
    final failed = S.current.castFailed(deviceName);
    return reported ? '$failed ${S.current.castFailureReported}' : failed;
  }
}

class CastFailureNotifier extends Notifier<CastFailure?> {
  @override
  CastFailure? build() => null;

  void report(String deviceName, {bool takenOver = false}) =>
      state = CastFailure(
        deviceName: deviceName,
        reported: !takenOver && Sentry.isEnabled,
        takenOver: takenOver,
      );

  void clear() => state = null;
}

final castFailureProvider = NotifierProvider<CastFailureNotifier, CastFailure?>(
  CastFailureNotifier.new,
);

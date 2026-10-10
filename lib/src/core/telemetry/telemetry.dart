import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:plausible/plausible.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Telemetry {
  static const _sentryDsn =
      'https://37200398250012a53c6390d1bd05b60c@o4505940301840384.ingest.sentry.io/4506644062732288';
  static const _plausibleDomain = 'jellybox.app';
  static const _plausibleHost = 'plausible.prodigytech.dev';

  static bool _optedOut = false;

  static bool get isEnabled => !_optedOut;

  static bool optedOutIn(SharedPreferences? prefs) =>
      AppSettingsNotifier.isEnabledIn(prefs, AppSetting.telemetryOptOut);

  static Future<void> start({
    required bool optedOut,
    required FutureOr<void> Function() appRunner,
  }) async {
    _optedOut = optedOut;

    if (optedOut) {
      await appRunner();
      return;
    }

    unawaited(_sendLaunchEvents());
    await SentryFlutter.init(
      _configureSentry,
      appRunner: () {
        _keepConsoleLogging();
        return appRunner();
      },
    );
  }

  static void _keepConsoleLogging() {
    final sentryPrint = debugPrint;
    if (identical(sentryPrint, debugPrintThrottled)) return;
    debugPrint = (String? message, {int? wrapWidth}) {
      sentryPrint(message, wrapWidth: wrapWidth);
      debugPrintThrottled(message, wrapWidth: wrapWidth);
    };
  }

  static void watch(ProviderContainer container) {
    container.listen(
      settingProvider(AppSetting.telemetryOptOut),
      (previous, next) => unawaited(_onOptOutChanged(optedOut: next)),
    );
  }

  static void _configureSentry(SentryFlutterOptions options) {
    options
      ..dsn = _sentryDsn
      ..tracesSampleRate = 1.0;
  }

  static Future<void> _onOptOutChanged({required bool optedOut}) async {
    if (optedOut == _optedOut) return;
    _optedOut = optedOut;

    if (optedOut) {
      unawaited(_sendEvent('analytics-opted-out'));
      await Sentry.close();
    } else {
      unawaited(_sendLaunchEvents());
      await SentryFlutter.init(_configureSentry);
      _keepConsoleLogging();
    }
  }

  static Plausible _plausible() => Plausible(
    domain: _plausibleDomain,
    server: Uri.https(_plausibleHost, '/api/event'),
  );

  static Future<void> _sendLaunchEvents() async {
    try {
      await _plausible().send();
    } on Object catch (error) {
      debugPrint('[Telemetry] $error');
    }
    await _sendEvent('app-launched');
  }

  static Future<void> _sendEvent(String event) async {
    try {
      await _plausible().send(
        event: event,
        props: {'os': Platform.operatingSystem},
      );
    } on Object catch (error) {
      debugPrint('[Telemetry] $error');
    }
  }
}

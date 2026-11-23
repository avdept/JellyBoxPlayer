import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/diagnostics/device_log.dart';
import 'package:jplayer/src/core/platform/tv_mode.dart';
import 'package:jplayer/src/data/backend/server_type.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/providers/current_server_type_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plausible/plausible.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Telemetry {
  static const _sentryDsn =
      'https://37200398250012a53c6390d1bd05b60c@o4505940301840384.ingest.sentry.io/4506644062732288';
  static const _plausibleDomain = 'jellybox.app';
  static const _plausibleHost = 'plausible.prodigytech.dev';

  static const _platformChannel = MethodChannel('jellybox/platform');

  static bool _optedOut = false;
  static String? _userAgent;
  static ServerType? _serverType;
  static ServerType? _reportedServerType;

  static bool get isEnabled => !_optedOut;

  static bool optedOutIn(SharedPreferences? prefs) =>
      AppSettingsNotifier.isEnabledIn(prefs, AppSetting.telemetryOptOut);

  static Future<void> start({
    required bool optedOut,
    required FutureOr<void> Function() appRunner,
  }) async {
    _optedOut = optedOut;

    if (optedOut) {
      DeviceLog.install();
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
    if (!identical(sentryPrint, debugPrintThrottled)) {
      debugPrint = (String? message, {int? wrapWidth}) {
        sentryPrint(message, wrapWidth: wrapWidth);
        debugPrintThrottled(message, wrapWidth: wrapWidth);
      };
    }
    DeviceLog.install();
  }

  static void watch(ProviderContainer container) {
    container
      ..listen(
        settingProvider(AppSetting.telemetryOptOut),
        (previous, next) => unawaited(_onOptOutChanged(optedOut: next)),
      )
      ..listen(currentServerTypeProvider, (previous, next) {
        _serverType = next;
        _reportServerType();
      }, fireImmediately: true);
  }

  static void track(String event, {Map<String, String> props = const {}}) {
    if (_optedOut) return;
    unawaited(_sendEvent(event, props: props));
  }

  static void integrationConnected(String integration) =>
      track('integration-connected', props: {'integration': integration});

  static void _reportServerType() {
    final type = _serverType;
    if (_optedOut || type == null || type == _reportedServerType) return;
    _reportedServerType = type;
    unawaited(_sendEvent('server-connected', props: {'server': type.name}));
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
      DeviceLog.install();
    } else {
      unawaited(_sendLaunchEvents());
      _reportServerType();
      await SentryFlutter.init(_configureSentry);
      _keepConsoleLogging();
    }
  }

  static Plausible _plausible() => Plausible(
    domain: _plausibleDomain,
    server: Uri.https(_plausibleHost, '/api/event'),
    userAgent: _userAgent,
  );

  static String get _platform =>
      TvMode.isTv ? 'android-tv' : Platform.operatingSystem;

  static Map<String, String> get _baseProps => {
    'os': Platform.operatingSystem,
    'platform': _platform,
  };

  static Future<void> _sendLaunchEvents() async {
    _userAgent ??= await _buildUserAgent();
    try {
      await _plausible().send(props: _baseProps);
    } on Object catch (error) {
      debugPrint('[Telemetry] $error');
    }
    await _sendEvent('app-launched');
  }

  static Future<String?> _buildUserAgent() async {
    if (kIsWeb) return null;
    try {
      final version = (await PackageInfo.fromPlatform()).version;
      final app = 'JellyBox/$version';
      if (Platform.isAndroid) {
        final info = await _platformChannel.invokeMapMethod<String, String>(
          'deviceInfo',
        );
        final release = info?['release'] ?? '';
        final model = info?['model'] ?? '';
        return 'Mozilla/5.0 (Linux; Android $release; $model) $app';
      }
      final osVersion = _osVersion();
      if (Platform.isIOS) {
        return 'Mozilla/5.0 (iPhone; CPU iPhone OS $osVersion like Mac OS X) '
            '$app';
      }
      if (Platform.isMacOS) {
        return 'Mozilla/5.0 (Macintosh; Intel Mac OS X $osVersion) $app';
      }
      if (Platform.isWindows) {
        return 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) $app';
      }
      if (Platform.isLinux) return 'Mozilla/5.0 (X11; Linux x86_64) $app';
    } on Object catch (error) {
      debugPrint('[Telemetry] user agent: $error');
    }
    return null;
  }

  static String _osVersion() {
    final match = RegExp(
      r'(\d+)\.(\d+)(?:\.(\d+))?',
    ).firstMatch(Platform.operatingSystemVersion);
    if (match == null) return '';
    return [
      match.group(1),
      match.group(2),
      ?match.group(3),
    ].join('_');
  }

  static Future<void> _sendEvent(
    String event, {
    Map<String, String> props = const {},
  }) async {
    _userAgent ??= await _buildUserAgent();
    try {
      await _plausible().send(
        event: event,
        props: {..._baseProps, ...props},
      );
    } on Object catch (error) {
      debugPrint('[Telemetry] $error');
    }
  }
}

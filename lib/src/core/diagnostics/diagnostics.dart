import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class Diagnostics {
  const Diagnostics();

  Future<void> capture(
    Object error, {
    required String operation,
    StackTrace? stackTrace,
    SentryLevel level = SentryLevel.warning,
    Map<String, String> tags = const {},
    Map<String, Object?> extra = const {},
  }) async {
    debugPrint('[$operation] $error');
    if (!Sentry.isEnabled) return;

    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) async {
        scope.level = level;
        await scope.setTag('operation', operation);
        for (final tag in tags.entries) {
          await scope.setTag(tag.key, tag.value);
        }
        if (extra.isNotEmpty) await scope.setContexts(operation, extra);
      },
    );
  }

  Future<void> report(
    String message, {
    Map<String, Object?> data = const {},
  }) async {
    debugPrint('[report] $message $data');
    if (!Sentry.isEnabled) return;

    await Sentry.captureMessage(
      message,
      withScope: (scope) async {
        await scope.setTag('operation', 'user-report');
        if (data.isNotEmpty) await scope.setContexts('report', data);
      },
    );
  }

  void trail(
    String message, {
    String category = 'app',
    Map<String, Object?> data = const {},
  }) {
    debugPrint('[$category] $message');
    if (!Sentry.isEnabled) return;

    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          category: category,
          data: data.isEmpty ? null : {...data},
        ),
      ),
    );
  }
}

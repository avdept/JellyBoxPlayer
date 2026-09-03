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
      withScope: (scope) {
        scope
          ..level = level
          ..setTag('operation', operation);
        for (final tag in tags.entries) {
          scope.setTag(tag.key, tag.value);
        }
        if (extra.isNotEmpty) scope.setContexts(operation, extra);
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

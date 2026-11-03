import 'dart:async';

import 'package:flutter/foundation.dart';

class WindowCloseSequence {
  WindowCloseSequence({
    required this.steps,
    required this.destroy,
    this.stepTimeout = const Duration(seconds: 3),
  });

  final List<Future<void> Function()> steps;
  final Future<void> Function() destroy;
  final Duration stepTimeout;

  Future<void>? _run;

  bool get started => _run != null;

  Future<void> call() => _run ??= _shutdown();

  Future<void> _shutdown() async {
    for (final step in steps) {
      try {
        await step().timeout(stepTimeout);
      } on Object catch (error) {
        debugPrint('[Shutdown] step failed: $error');
      }
    }
    await destroy();
  }
}

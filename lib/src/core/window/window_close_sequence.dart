import 'dart:async';

import 'package:flutter/foundation.dart';

class CloseStep {
  const CloseStep(this.run, {this.timeout = const Duration(seconds: 3)});

  final Future<void> Function() run;
  final Duration timeout;
}

class WindowCloseSequence {
  WindowCloseSequence({required this.steps, required this.destroy});

  final List<CloseStep> steps;
  final Future<void> Function() destroy;

  Future<void>? _run;

  bool get started => _run != null;

  Future<void> call() => _run ??= _shutdown();

  Future<void> _shutdown() async {
    for (final step in steps) {
      try {
        await step.run().timeout(step.timeout);
      } on Object catch (error) {
        debugPrint('[Shutdown] step failed: $error');
      }
    }
    await destroy();
  }
}

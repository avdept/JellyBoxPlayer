import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/window/window_close_sequence.dart';

void main() {
  test('runs every step in order and then destroys', () async {
    final calls = <String>[];
    final sequence = WindowCloseSequence(
      steps: [
        CloseStep(() async => calls.add('report')),
        CloseStep(() async => calls.add('dispose')),
      ],
      destroy: () async => calls.add('destroy'),
    );

    await sequence();

    expect(calls, ['report', 'dispose', 'destroy']);
  });

  test('a failing step does not stop the window from closing', () async {
    final calls = <String>[];
    final sequence = WindowCloseSequence(
      steps: [
        CloseStep(() async => throw StateError('server unreachable')),
        CloseStep(() async => calls.add('dispose')),
      ],
      destroy: () async => calls.add('destroy'),
    );

    await sequence();

    expect(calls, ['dispose', 'destroy']);
  });

  test('a hung step is abandoned after its own timeout', () {
    fakeAsync((async) {
      final calls = <String>[];
      final sequence = WindowCloseSequence(
        steps: [
          CloseStep(() => Completer<void>().future),
          CloseStep(
            () => Completer<void>().future,
            timeout: const Duration(seconds: 10),
          ),
        ],
        destroy: () async => calls.add('destroy'),
      );

      unawaited(sequence());
      async.elapse(const Duration(seconds: 2));
      expect(calls, isEmpty);

      async.elapse(const Duration(seconds: 2));
      expect(calls, isEmpty);

      async.elapse(const Duration(seconds: 9));
      expect(calls, ['destroy']);
    });
  });

  test('destroy runs once even when close is requested again', () async {
    var destroyed = 0;
    final gate = Completer<void>();
    final sequence = WindowCloseSequence(
      steps: [CloseStep(() => gate.future)],
      destroy: () async => destroyed++,
    );

    final first = sequence();
    final second = sequence();
    expect(sequence.started, isTrue);
    gate.complete();
    await Future.wait([first, second]);

    expect(destroyed, 1);
  });
}

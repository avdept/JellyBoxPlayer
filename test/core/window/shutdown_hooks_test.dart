import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/window/shutdown_hooks.dart';

void main() {
  test('runs every registered hook and forgets them', () async {
    final hooks = ShutdownHooks();
    final calls = <String>[];
    hooks
      ..add('cover', () async => calls.add('cover'))
      ..add('preview', () async => calls.add('preview'));

    await hooks.run();

    expect(calls, unorderedEquals(['cover', 'preview']));
    expect(hooks.length, 0);
  });

  test('a removed owner is not run', () async {
    final hooks = ShutdownHooks();
    final calls = <String>[];
    final owner = Object();
    hooks
      ..add(owner, () async => calls.add('gone'))
      ..add('kept', () async => calls.add('kept'))
      ..remove(owner);

    await hooks.run();

    expect(calls, ['kept']);
  });

  test('re-adding an owner replaces its hook', () async {
    final hooks = ShutdownHooks();
    final calls = <String>[];
    final owner = Object();
    hooks
      ..add(owner, () async => calls.add('old'))
      ..add(owner, () async => calls.add('new'));

    await hooks.run();

    expect(calls, ['new']);
  });

  test('a failing hook does not stop the others', () async {
    final hooks = ShutdownHooks();
    final calls = <String>[];
    hooks
      ..add('bad', () async => throw StateError('player gone'))
      ..add('good', () async => calls.add('good'));

    await hooks.run();

    expect(calls, ['good']);
  });
}

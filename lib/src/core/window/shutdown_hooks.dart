import 'dart:async';

import 'package:flutter/foundation.dart';

typedef ShutdownHook = Future<void> Function();

class ShutdownHooks {
  ShutdownHooks();

  static final instance = ShutdownHooks();

  final _hooks = <Object, ShutdownHook>{};

  int get length => _hooks.length;

  void add(Object owner, ShutdownHook hook) => _hooks[owner] = hook;

  void remove(Object owner) => _hooks.remove(owner);

  Future<void> run() async {
    final hooks = _hooks.values.toList();
    _hooks.clear();
    await Future.wait(hooks.map(_guarded));
  }

  Future<void> _guarded(ShutdownHook hook) async {
    try {
      await hook();
    } on Object catch (error) {
      debugPrint('[Shutdown] hook failed: $error');
    }
  }
}

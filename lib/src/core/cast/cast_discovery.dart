import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

class CastDiscovery {
  CastDiscovery._(this._manager);

  factory CastDiscovery.of(
    GoogleCastDiscoveryManagerPlatformInterface manager,
  ) => _byManager[manager] ??= CastDiscovery._(manager);

  static final _byManager = Expando<CastDiscovery>();

  final GoogleCastDiscoveryManagerPlatformInterface _manager;
  var _holds = 0;

  bool get running => _holds > 0;

  Future<void> hold() async {
    _holds++;
    if (_holds == 1) await _manager.startDiscovery();
  }

  Future<void> release() async {
    if (_holds == 0) return;
    _holds--;
    if (_holds == 0) await _manager.stopDiscovery();
  }

  Future<void> rescan() => _manager.startDiscovery();
}

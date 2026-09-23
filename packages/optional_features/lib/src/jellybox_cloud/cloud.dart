import 'dart:async';

import 'package:optional_features/src/jellybox_cloud/host.dart';
import 'package:optional_features/src/jellybox_cloud/models.dart';
import 'package:meta/meta.dart';

@immutable
class RemoteSession {
  const RemoteSession({
    required this.doc,
    required this.ageMs,
    required this.receivedAt,
  });

  final SessionDoc doc;
  final int ageMs;
  final DateTime receivedAt;

  Duration positionAt(DateTime now) => Duration.zero;
}

@immutable
class CloudState {
  const CloudState({
    this.status = ConductorStatus.off,
    this.devices = const [],
    this.remote,
    this.account,
    this.busy = false,
    this.lastHandoffMs,
    this.error,
  });

  final ConductorStatus status;
  final List<ConductorDevice> devices;
  final RemoteSession? remote;
  final ContinuityAccount? account;
  final bool busy;
  final int? lastHandoffMs;
  final String? error;

  bool get signedIn => account != null;

  bool get isConnected =>
      status == ConductorStatus.listening ||
      status == ConductorStatus.rendering;

  List<ConductorDevice> get targets => devices.where((d) => !d.isSelf).toList();

  ConductorDevice? get remoteRenderer {
    for (final device in devices) {
      if (device.isRenderer && !device.isSelf) return device;
    }
    return null;
  }
}

class JellyboxCloud<S> {
  JellyboxCloud({required CloudHost<S> host});

  static const accountStorageKey = 'continuity_account';

  bool get available => false;

  CloudState get state => const CloudState();

  Stream<CloudState> get states => const Stream<CloudState>.empty();

  Future<void> start({String? benchUrl}) async {}

  Future<void> refresh({String? benchUrl}) async {}

  Future<bool> signIn({
    required String address,
    required String email,
    required String password,
  }) async => false;

  Future<void> signOut() async {}

  void forgetAccount() {}

  Future<void> handoffTo(String deviceId) async {}

  Future<void> claimHere() async {}

  Future<void> dispose() async {}
}

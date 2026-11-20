import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/cast/cast_discovery.dart';
import 'package:jplayer/src/core/cast/cast_runtime.dart';
import 'package:jplayer/src/domain/playback/cast_playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/renderer_locator.dart';
import 'package:jplayer/src/domain/playback/upnp_playback_target.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/upnp_renderers_provider.dart';

enum DefaultOutputKind { cast, upnp }

@immutable
class DefaultOutput {
  const DefaultOutput({
    required this.kind,
    required this.id,
    required this.name,
    this.location,
  });

  static DefaultOutput? of(PlaybackTarget target) => switch (target) {
    CastPlaybackTarget(:final device) => DefaultOutput(
      kind: DefaultOutputKind.cast,
      id: device.deviceID,
      name: device.friendlyName,
    ),
    UpnpPlaybackTarget(:final renderer) => DefaultOutput(
      kind: DefaultOutputKind.upnp,
      id: renderer.id,
      name: renderer.name,
      location: renderer.device.location,
    ),
    _ => null,
  };

  static DefaultOutput? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final json = raw;
    final kind = DefaultOutputKind.values.asNameMap()[json['kind']];
    final id = json['id'];
    final name = json['name'];
    if (kind == null || id is! String || name is! String) return null;
    final rawLocation = json['location'];
    final location = rawLocation is String ? Uri.tryParse(rawLocation) : null;
    if (kind == DefaultOutputKind.upnp &&
        (location == null || !location.hasScheme)) {
      return null;
    }
    return DefaultOutput(
      kind: kind,
      id: id,
      name: name,
      location: kind == DefaultOutputKind.upnp ? location : null,
    );
  }

  final DefaultOutputKind kind;
  final String id;
  final String name;
  final Uri? location;

  String get targetId => switch (kind) {
    DefaultOutputKind.cast => 'cast:$id',
    DefaultOutputKind.upnp => id,
  };

  bool get reachableHere => kind != DefaultOutputKind.cast || castSupported;

  Map<String, Object> toJson() => {
    'kind': kind.name,
    'id': id,
    'name': name,
    if (location case final location?) 'location': '$location',
  };

  @override
  bool operator ==(Object other) =>
      other is DefaultOutput &&
      other.kind == kind &&
      other.id == id &&
      other.name == name &&
      other.location == location;

  @override
  int get hashCode => Object.hash(kind, id, name, location);
}

final defaultOutputProvider = Provider<DefaultOutput?>(
  (ref) => DefaultOutput.fromJson(
    ref.watch(appSettingsProvider)[AppSetting.defaultOutput],
  ),
);

class DefaultOutputFinder {
  DefaultOutputFinder(
    this._locator, {
    this.castSearchTimeout = const Duration(seconds: 6),
    this.discoveryLinger = const Duration(seconds: 15),
  });

  final RendererLocator _locator;
  final Duration castSearchTimeout;
  final Duration discoveryLinger;

  Future<PlaybackTarget?> find(DefaultOutput output) async {
    debugPrint('[Playback] looking for the default output ${output.name}');
    final target = switch (output.kind) {
      DefaultOutputKind.cast => await _findCast(output),
      DefaultOutputKind.upnp => await _findRenderer(output),
    };
    if (target == null) {
      debugPrint('[Playback] default output ${output.name} not found');
    }
    return target;
  }

  Future<PlaybackTarget?> _findCast(DefaultOutput output) async {
    if (!castSupported) return null;
    final manager = GoogleCastDiscoveryManager.instance;
    final discovery = CastDiscovery.of(manager);
    await discovery.hold();
    try {
      final listed = matchCastDevice(manager.devices, output);
      if (listed != null) return CastPlaybackTarget(listed);
      final found = await manager.devicesStream
          .map((devices) => matchCastDevice(devices, output))
          .firstWhere((device) => device != null)
          .timeout(castSearchTimeout);
      return found == null ? null : CastPlaybackTarget(found);
    } on Object {
      return null;
    } finally {
      unawaited(
        Future<void>.delayed(discoveryLinger, discovery.release),
      );
    }
  }

  Future<PlaybackTarget?> _findRenderer(DefaultOutput output) async {
    final location = output.location;
    if (location == null) return null;
    final found = await _locator.find(
      udn: output.id,
      location: location,
      name: output.name,
    );
    if (found == null) return null;
    return UpnpPlaybackTarget(await _locator.coordinatorOf(found));
  }
}

GoogleCastDevice? matchCastDevice(
  List<GoogleCastDevice> devices,
  DefaultOutput output,
) =>
    devices.where((device) => device.deviceID == output.id).firstOrNull ??
    devices.where((device) => device.friendlyName == output.name).firstOrNull;

final defaultOutputFinderProvider = Provider<DefaultOutputFinder>(
  (ref) => DefaultOutputFinder(
    RendererLocator(ref.watch(upnpControlPointProvider)),
  ),
);

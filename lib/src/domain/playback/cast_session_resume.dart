import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/data/storages/cast_session_storage.dart';
import 'package:jplayer/src/domain/playback/renderer_locator.dart';
import 'package:jplayer/src/domain/providers/upnp_renderers_provider.dart';

class ResumableCastSession {
  const ResumableCastSession({
    required this.renderer,
    required this.playing,
    required this.trackUri,
    required this.position,
  });

  final UpnpRenderer renderer;
  final bool playing;
  final Uri trackUri;
  final Duration position;
}

class CastSessionResume {
  CastSessionResume(
    UpnpControlPoint controlPoint, {
    CastSessionStorage? storage,
    this.probeTimeout = const Duration(seconds: 5),
    this.searchTimeout = const Duration(seconds: 3),
  }) : _storage = storage ?? CastSessionStorage(),
       _locator = RendererLocator(
         controlPoint,
         probeTimeout: probeTimeout,
         searchTimeout: searchTimeout,
       );

  final CastSessionStorage _storage;
  final RendererLocator _locator;
  final Duration probeTimeout;
  final Duration searchTimeout;

  Future<ResumableCastSession?> find(String serverId) async {
    final session = await _storage.load(serverId);
    if (session == null) return null;

    final found = await _locator.find(
      udn: session.udn,
      location: session.location,
      name: session.name,
    );
    if (found == null) {
      debugPrint('[Playback] ${session.name} is gone; dropping cast session');
      await _storage.clear(serverId);
      return null;
    }
    final renderer = await _locator.coordinatorOf(found);

    try {
      final info = await renderer.avTransport.transportInfo().timeout(
        probeTimeout,
      );
      final position = await renderer.avTransport.positionInfo().timeout(
        probeTimeout,
      );
      final trackUri = Uri.tryParse(position.trackUri ?? '');
      final live =
          info.state.isPlaying ||
          info.state.isPaused ||
          info.state == AvTransportState.transitioning;
      if (!live || trackUri == null || !trackUri.hasScheme) {
        debugPrint(
          '[Playback] ${session.name} is ${info.state.name}; '
          'dropping cast session',
        );
        await _storage.clear(serverId);
        return null;
      }
      return ResumableCastSession(
        renderer: renderer,
        playing: !info.state.isPaused,
        trackUri: trackUri,
        position: position.position,
      );
    } on Object catch (error) {
      debugPrint('[Playback] probing ${session.name} failed: $error');
      await _storage.clear(serverId);
      return null;
    }
  }
}

final castSessionResumeProvider = Provider<CastSessionResume>(
  (ref) => CastSessionResume(ref.watch(upnpControlPointProvider)),
);

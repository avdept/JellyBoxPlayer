import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/data/storages/cast_session_storage.dart';
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
    this._controlPoint, {
    CastSessionStorage? storage,
    this.probeTimeout = const Duration(seconds: 5),
    this.searchTimeout = const Duration(seconds: 3),
  }) : _storage = storage ?? CastSessionStorage();

  final UpnpControlPoint _controlPoint;
  final CastSessionStorage _storage;
  final Duration probeTimeout;
  final Duration searchTimeout;

  Future<ResumableCastSession?> find(String serverId) async {
    final session = await _storage.load(serverId);
    if (session == null) return null;

    final renderer = await _findRenderer(session);
    if (renderer == null) {
      debugPrint('[Playback] ${session.name} is gone; dropping cast session');
      await _storage.clear(serverId);
      return null;
    }

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

  Future<UpnpRenderer?> _findRenderer(CastSession session) async {
    try {
      final described = await _controlPoint
          .describe(session.location)
          .timeout(probeTimeout);
      if (described != null && described.id == session.udn) return described;
    } on TimeoutException {
      debugPrint('[Playback] describing ${session.name} timed out');
    }
    try {
      return await _controlPoint
          .discoverRenderers(timeout: searchTimeout)
          .firstWhere((renderer) => renderer.id == session.udn);
    } on Object {
      return null;
    }
  }
}

final castSessionResumeProvider = Provider<CastSessionResume>(
  (ref) => CastSessionResume(ref.watch(upnpControlPointProvider)),
);

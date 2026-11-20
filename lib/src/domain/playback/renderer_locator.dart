import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';

class RendererLocator {
  const RendererLocator(
    this._controlPoint, {
    this.probeTimeout = const Duration(seconds: 5),
    this.searchTimeout = const Duration(seconds: 3),
  });

  final UpnpControlPoint _controlPoint;
  final Duration probeTimeout;
  final Duration searchTimeout;

  Future<UpnpRenderer?> find({
    required String udn,
    required Uri location,
    required String name,
  }) async {
    try {
      final described = await _controlPoint
          .describe(location)
          .timeout(probeTimeout);
      if (described != null && described.id == udn) return described;
    } on TimeoutException {
      debugPrint('[Playback] describing $name timed out');
    } on Object catch (error) {
      debugPrint('[Playback] describing $name failed: $error');
    }
    try {
      return await _controlPoint
          .discoverRenderers(timeout: searchTimeout)
          .firstWhere((renderer) => renderer.id == udn);
    } on Object {
      return null;
    }
  }

  Future<UpnpRenderer> coordinatorOf(UpnpRenderer renderer) async {
    final groups = renderer.groups;
    if (groups == null) return renderer;
    try {
      final topology = await groups.topology().timeout(probeTimeout);
      final coordinatorId = topology.coordinatorOf(renderer.id);
      final location = topology.member(coordinatorId ?? '')?.location;
      if (coordinatorId == null ||
          coordinatorId == renderer.id ||
          location == null) {
        return renderer;
      }
      debugPrint(
        '[Playback] ${renderer.name} plays in a group; '
        'following its coordinator',
      );
      final coordinator = await _controlPoint
          .describe(location)
          .timeout(probeTimeout);
      return coordinator ?? renderer;
    } on Object catch (error) {
      debugPrint('[Playback] topology of ${renderer.name} failed: $error');
      return renderer;
    }
  }
}

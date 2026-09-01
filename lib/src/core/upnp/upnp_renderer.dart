import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/connection_manager.dart';
import 'package:jplayer/src/core/upnp/rendering_control.dart';
import 'package:jplayer/src/core/upnp/ssdp_discovery.dart';
import 'package:jplayer/src/core/upnp/upnp_device.dart';
import 'package:jplayer/src/core/upnp/upnp_soap_client.dart';

class UpnpRenderer {
  const UpnpRenderer({
    required this.device,
    required this.avTransport,
    this.renderingControl,
    this.sinkMimeTypes = const <String>{},
  });

  final UpnpDevice device;
  final AvTransport avTransport;
  final RenderingControl? renderingControl;
  final Set<String> sinkMimeTypes;

  String get id => device.udn;

  String get name => device.friendlyName;

  String? get model => device.modelName;
}

class UpnpControlPoint {
  UpnpControlPoint({Dio? dio, SsdpDiscovery? discovery, UpnpSoapClient? soap})
    : _dio = dio ?? Dio(),
      _discovery = discovery ?? SsdpDiscovery(),
      _soap = soap ?? UpnpSoapClient(dio: dio);

  final Dio _dio;
  final SsdpDiscovery _discovery;
  final UpnpSoapClient _soap;

  Stream<UpnpRenderer> discoverRenderers({
    Duration timeout = const Duration(seconds: 4),
  }) {
    final controller = StreamController<UpnpRenderer>();
    final described = <String>{};
    var pending = 0;
    var searching = true;

    void maybeClose() {
      if (!searching && pending == 0 && !controller.isClosed) {
        unawaited(controller.close());
      }
    }

    final subscription = _discovery
        .search(timeout: timeout)
        .listen(
          (response) {
            if (!described.add('${response.location}')) return;
            pending++;
            unawaited(
              describe(response.location)
                  .then((renderer) {
                    if (renderer != null && !controller.isClosed) {
                      controller.add(renderer);
                    }
                  })
                  .whenComplete(() {
                    pending--;
                    maybeClose();
                  }),
            );
          },
          onDone: () {
            searching = false;
            maybeClose();
          },
          onError: (Object _) {
            searching = false;
            maybeClose();
          },
        );

    controller.onCancel = () async {
      searching = false;
      await subscription.cancel();
    };

    return controller.stream;
  }

  Future<UpnpRenderer?> describe(Uri location) async {
    final device = await _fetchDevice(location);
    if (device == null) return null;

    final transportService = device.serviceOfType('AVTransport');
    if (transportService == null) return null;

    final actions = await _fetchActions(transportService.scpdUrl);
    final renderingService = device.serviceOfType('RenderingControl');
    final connectionService = device.serviceOfType('ConnectionManager');

    return UpnpRenderer(
      device: device,
      avTransport: AvTransport(
        soap: _soap,
        controlUrl: transportService.controlUrl,
        actions: actions,
      ),
      renderingControl: renderingService == null
          ? null
          : RenderingControl(
              soap: _soap,
              controlUrl: renderingService.controlUrl,
            ),
      sinkMimeTypes: connectionService == null
          ? const {}
          : await _fetchSinkMimeTypes(connectionService.controlUrl),
    );
  }

  Future<UpnpDevice?> _fetchDevice(Uri location) async {
    try {
      final response = await _dio.getUri<String>(
        location,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final body = response.data;
      if (body == null) return null;
      return UpnpDevice.parse(body, location: location);
    } on Object catch (error) {
      debugPrint('[UPnP] description $location failed: $error');
      return null;
    }
  }

  Future<Set<String>> _fetchActions(Uri? scpdUrl) async {
    if (scpdUrl == null) return const {};
    try {
      final response = await _dio.getUri<String>(
        scpdUrl,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final body = response.data;
      return body == null ? const {} : parseScpdActions(body);
    } on Object catch (error) {
      debugPrint('[UPnP] scpd $scpdUrl failed: $error');
      return const {};
    }
  }

  Future<Set<String>> _fetchSinkMimeTypes(Uri controlUrl) async {
    try {
      return await ConnectionManager(
        soap: _soap,
        controlUrl: controlUrl,
      ).sinkMimeTypes();
    } on Object catch (error) {
      debugPrint('[UPnP] GetProtocolInfo $controlUrl failed: $error');
      return const {};
    }
  }
}

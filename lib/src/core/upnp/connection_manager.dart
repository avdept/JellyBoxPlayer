import 'package:jplayer/src/core/upnp/upnp_soap_client.dart';

class ConnectionManager {
  ConnectionManager({required UpnpSoapClient soap, required this.controlUrl})
    : _soap = soap;

  static const serviceType = 'urn:schemas-upnp-org:service:ConnectionManager:1';

  final UpnpSoapClient _soap;
  final Uri controlUrl;

  Future<Set<String>> sinkMimeTypes() async {
    final result = await _soap.invoke(
      controlUrl: controlUrl,
      serviceType: serviceType,
      action: 'GetProtocolInfo',
    );
    return parseSinkMimeTypes(result['Sink']);
  }
}

Set<String> parseSinkMimeTypes(String? sink) {
  if (sink == null || sink.trim().isEmpty) return const {};
  final mimeTypes = <String>{};
  for (final entry in sink.split(',')) {
    final fields = entry.split(':');
    if (fields.length < 3) continue;
    final mimeType = fields[2].trim().toLowerCase();
    if (mimeType.startsWith('audio/')) mimeTypes.add(mimeType);
  }
  return mimeTypes;
}

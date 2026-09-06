import 'package:upnp_quirks/src/device_fingerprint.dart';

enum DeviceQueueKind {
  none,
  avTransport3,
  openHome,
  sonos,
  linkPlay;

  bool get holdsQueue => this != none;
}

const _openHomePlaylist = 'urn:av-openhome-org:service:playlist';
const _linkPlayQueue = 'urn:schemas-wiimu-com:service:playqueue';

DeviceQueueKind detectQueue(DeviceFingerprint fingerprint) {
  final services = {
    for (final service in fingerprint.services) service.toLowerCase(),
  };
  bool hasService(String needle) =>
      services.any((service) => service.startsWith(needle));

  if (fingerprint.actions.contains('SetStaticPlaylist')) {
    return DeviceQueueKind.avTransport3;
  }
  if (hasService(_openHomePlaylist)) return DeviceQueueKind.openHome;
  if (fingerprint.actions.contains('AddURIToQueue') ||
      fingerprint.actions.contains('AddMultipleURIsToQueue')) {
    return DeviceQueueKind.sonos;
  }
  if (hasService(_linkPlayQueue)) return DeviceQueueKind.linkPlay;
  return DeviceQueueKind.none;
}

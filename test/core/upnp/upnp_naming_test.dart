import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/upnp/upnp_device.dart';

void main() {
  UpnpDevice deviceNamed(
    String friendlyName, {
    String? roomName,
    String host = '192.168.1.51',
  }) => UpnpDevice(
    udn: 'uuid:1',
    friendlyName: friendlyName,
    deviceType: 'urn:schemas-upnp-org:device:MediaRenderer:1',
    location: Uri.parse('http://$host:1400/xml/device.xml'),
    services: const [],
    roomName: roomName,
  );

  group('displayName', () {
    test('- prefers a room name when the device publishes one', () {
      expect(
        deviceNamed(
          '192.168.1.51 - Sonos Play:5',
          roomName: 'Office',
        ).displayName,
        'Office',
      );
    });

    test('- drops an address the device prefixes its name with', () {
      expect(
        deviceNamed('192.168.1.51 - Sonos Play:5 Media Renderer').displayName,
        'Sonos Play:5',
      );
      expect(deviceNamed('192.168.1.51: foobar2000').displayName, 'foobar2000');
      expect(
        deviceNamed(
          '192.168.1.51:8200 MiniDLNA',
          host: '192.168.1.51',
        ).displayName,
        'MiniDLNA',
      );
    });

    test('- drops boilerplate renderer suffixes', () {
      expect(deviceNamed('Kodi (UPnP Renderer)').displayName, 'Kodi');
      expect(deviceNamed('Living Room DMR').displayName, 'Living Room');
      expect(deviceNamed('Study [Media Renderer]').displayName, 'Study');
      expect(
        deviceNamed('Denon AVR-X2700H DLNA Renderer').displayName,
        'Denon AVR-X2700H',
      );
    });

    test('- leaves a name that carries no boilerplate alone', () {
      expect(
        deviceNamed('[TV1476] ROOM 7005').displayName,
        '[TV1476] ROOM 7005',
      );
      expect(deviceNamed('Kitchen').displayName, 'Kitchen');
      expect(
        deviceNamed('Bose SoundTouch 20').displayName,
        'Bose SoundTouch 20',
      );
    });

    test('- keeps the original when tidying would leave nothing', () {
      expect(deviceNamed('192.168.1.51').displayName, '192.168.1.51');
      expect(deviceNamed('Media Renderer').displayName, 'Media Renderer');
    });
  });
}

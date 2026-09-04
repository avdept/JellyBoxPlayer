import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/upnp/connection_manager.dart';
import 'package:jplayer/src/core/upnp/upnp_device.dart';

String fixture(String name) =>
    File('test/fixtures/upnp/$name').readAsStringSync();

void main() {
  final location = Uri.parse('http://172.20.2.138:9197/dmr');

  group('UpnpDevice.parse', () {
    test('- reads the services of a real Samsung DMR', () {
      final device = UpnpDevice.parse(
        fixture('samsung_dmr_description.xml'),
        location: location,
      )!;

      expect(device.friendlyName, '[TV1476] ROOM 7005');
      expect(device.manufacturer, 'Samsung Electronics');
      expect(device.modelName, 'HG55BU800EUXEN');
      expect(device.udn, 'uuid:69ce01d4-b126-4a93-b879-d59d4cee99c4');
      expect(device.isMediaRenderer, isTrue);
      expect(
        device.services.map((service) => service.shortType),
        containsAll(['AVTransport', 'RenderingControl', 'ConnectionManager']),
      );
    });

    test('- resolves relative control URLs against the description URL', () {
      final device = UpnpDevice.parse(
        fixture('samsung_dmr_description.xml'),
        location: location,
      )!;

      expect(
        device.serviceOfType('AVTransport')!.controlUrl,
        Uri.parse('http://172.20.2.138:9197/upnp/control/AVTransport1'),
      );
      expect(
        device.serviceOfType('AVTransport')!.scpdUrl,
        Uri.parse('http://172.20.2.138:9197/AVTransport_1.xml'),
      );
      expect(
        device.serviceOfType('RenderingControl')!.eventSubUrl,
        Uri.parse('http://172.20.2.138:9197/upnp/event/RenderingControl1'),
      );
    });

    test('- prefers URLBase when the description carries one', () {
      final device = UpnpDevice.parse('''
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <URLBase>http://10.0.0.5:8200/</URLBase>
  <device>
    <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
    <friendlyName>Living Room</friendlyName>
    <UDN>uuid:abc</UDN>
    <serviceList>
      <service>
        <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
        <controlURL>ctl/AVTransport</controlURL>
      </service>
    </serviceList>
  </device>
</root>''', location: Uri.parse('http://10.0.0.5:49152/desc.xml'))!;

      expect(
        device.serviceOfType('AVTransport')!.controlUrl,
        Uri.parse('http://10.0.0.5:8200/ctl/AVTransport'),
      );
    });

    test('- rejects XML that is not a device description', () {
      expect(
        UpnpDevice.parse(
          '<screen_sharing><state>ready</state></screen_sharing>',
          location: location,
        ),
        isNull,
      );
      expect(UpnpDevice.parse('not xml at all', location: location), isNull);
    });

    test('- reports a device without AVTransport as no renderer', () {
      final device = UpnpDevice.parse('''
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <device>
    <deviceType>urn:dial-multiscreen-org:device:dial:1</deviceType>
    <friendlyName>Some TV</friendlyName>
    <UDN>uuid:dial</UDN>
    <serviceList>
      <service>
        <serviceType>urn:dial-multiscreen-org:service:dial:1</serviceType>
        <controlURL>/dial</controlURL>
      </service>
    </serviceList>
  </device>
</root>''', location: location)!;

      expect(device.isMediaRenderer, isFalse);
    });
  });

  group('device naming', () {
    test('- prefers the Sonos room name over the friendly name', () {
      final device = UpnpDevice.parse('''
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <device>
    <deviceType>urn:schemas-upnp-org:device:MediaRenderer:1</deviceType>
    <friendlyName>192.168.1.51 - Sonos Play:5 Media Renderer</friendlyName>
    <roomName>Office</roomName>
    <modelName>Sonos Play:5</modelName>
    <UDN>uuid:RINCON_1</UDN>
    <serviceList>
      <service>
        <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
        <controlURL>/MediaRenderer/AVTransport/Control</controlURL>
      </service>
    </serviceList>
  </device>
</root>''', location: Uri.parse('http://192.168.1.51:1400/xml/device.xml'))!;

      expect(device.roomName, 'Office');
      expect(device.displayName, 'Office');
      expect(device.host, '192.168.1.51');
    });

    test('- falls back to the friendly name without a room name', () {
      final device = UpnpDevice.parse(
        fixture('samsung_dmr_description.xml'),
        location: location,
      )!;

      expect(device.roomName, isNull);
      expect(device.displayName, '[TV1476] ROOM 7005');
      expect(device.host, '172.20.2.138');
    });
  });

  group('parseScpdActions', () {
    test('- lists the actions the Samsung AVTransport really implements', () {
      final actions = parseScpdActions(fixture('samsung_avtransport_scpd.xml'));

      expect(
        actions,
        containsAll([
          'Play',
          'Pause',
          'Stop',
          'Seek',
          'SetAVTransportURI',
          'SetNextAVTransportURI',
          'GetPositionInfo',
          'GetTransportInfo',
        ]),
      );
      expect(actions, isNot(contains('InstanceID')));
      expect(actions, isNot(contains('')));
    });

    test('- survives junk', () {
      expect(parseScpdActions('<html>nope</html>'), isEmpty);
      expect(parseScpdActions('}{'), isEmpty);
    });
  });

  group('parseSinkMimeTypes', () {
    test('- keeps only audio types from a real sink list', () {
      final sink = RegExp(
        r'<Sink>(.*?)</Sink>',
        dotAll: true,
      ).firstMatch(fixture('samsung_get_protocol_info.xml'))!.group(1);

      final mimeTypes = parseSinkMimeTypes(sink);

      expect(mimeTypes, contains('audio/mpeg'));
      expect(mimeTypes, contains('audio/x-flac'));
      expect(mimeTypes, contains('audio/mp4'));
      expect(mimeTypes, contains('audio/vnd.dlna.adts'));
      expect(mimeTypes.every((type) => type.startsWith('audio/')), isTrue);
      expect(mimeTypes, isNot(contains('video/mpeg')));
    });

    test('- tolerates an empty or malformed sink', () {
      expect(parseSinkMimeTypes(null), isEmpty);
      expect(parseSinkMimeTypes(''), isEmpty);
      expect(parseSinkMimeTypes('garbage,,:'), isEmpty);
    });
  });
}

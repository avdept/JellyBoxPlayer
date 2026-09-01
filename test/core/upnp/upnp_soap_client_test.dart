import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/didl_lite.dart';
import 'package:jplayer/src/core/upnp/rendering_control.dart';
import 'package:jplayer/src/core/upnp/upnp_duration.dart';
import 'package:jplayer/src/core/upnp/upnp_soap_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:xml/xml.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

String fixture(String name) =>
    File('test/fixtures/upnp/$name').readAsStringSync();

void main() {
  late MockHttpClientAdapter adapter;
  late UpnpSoapClient soap;
  late AvTransport transport;
  final controlUrl = Uri.parse(
    'http://172.20.2.138:9197/upnp/control/AVTransport1',
  );

  setUpAll(() {
    registerFallbackValue(RequestOptions());
  });

  void respondWith(String body, {int statusCode = 200}) {
    when(
      () => adapter.fetch(any(), any(), any()),
    ).thenAnswer(
      (_) async => ResponseBody.fromString(
        body,
        statusCode,
        headers: {
          Headers.contentTypeHeader: ['text/xml; charset="utf-8"'],
        },
      ),
    );
  }

  RequestOptions capturedRequest() =>
      verify(() => adapter.fetch(captureAny(), any(), any())).captured.single
          as RequestOptions;

  setUp(() {
    adapter = MockHttpClientAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    soap = UpnpSoapClient(dio: dio);
    transport = AvTransport(
      soap: soap,
      controlUrl: controlUrl,
      actions: const {
        'Play',
        'Pause',
        'Stop',
        'Seek',
        'SetAVTransportURI',
        'SetNextAVTransportURI',
      },
    );
  });

  group('invoke', () {
    test('- sends a SOAPACTION header and an envelope with the arguments',
        () async {
      respondWith(fixture('samsung_get_transport_info.xml'));

      await transport.transportInfo();

      final request = capturedRequest();
      expect(
        request.headers['SOAPACTION'],
        '"urn:schemas-upnp-org:service:AVTransport:1#GetTransportInfo"',
      );
      expect(request.contentType, 'text/xml; charset="utf-8"');
      expect(request.data as String, contains('<InstanceID>0</InstanceID>'));
    });

    test('- throws a fault carrying the UPnP error code', () async {
      respondWith('''
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>
<s:Fault><faultcode>s:Client</faultcode><faultstring>UPnPError</faultstring>
<detail><UPnPError xmlns="urn:schemas-upnp-org:control-1-0">
<errorCode>701</errorCode><errorDescription>Transition not available</errorDescription>
</UPnPError></detail></s:Fault></s:Body></s:Envelope>''', statusCode: 500);

      await expectLater(
        transport.play(),
        throwsA(
          isA<UpnpSoapFault>()
              .having((fault) => fault.errorCode, 'errorCode', '701')
              .having((fault) => fault.statusCode, 'statusCode', 500)
              .having(
                (fault) => fault.description,
                'description',
                'Transition not available',
              ),
        ),
      );
    });

    test('- throws when the body is not the expected response', () async {
      respondWith('<html><body>go away</body></html>');

      await expectLater(transport.play(), throwsA(isA<UpnpSoapFault>()));
    });
  });

  group('AVTransport', () {
    test('- reads the real GetTransportInfo response', () async {
      respondWith(fixture('samsung_get_transport_info.xml'));

      final info = await transport.transportInfo();

      expect(info.state, AvTransportState.noMediaPresent);
      expect(info.state.isIdle, isTrue);
      expect(info.status, 'OK');
    });

    test('- reads the real GetPositionInfo response', () async {
      respondWith(fixture('samsung_get_position_info.xml'));

      final info = await transport.positionInfo();

      expect(info.position, Duration.zero);
      expect(info.trackDuration, Duration.zero);
      expect(info.trackUri, isNull);
    });

    test('- treats an empty GetCurrentTransportActions as no actions',
        () async {
      respondWith(fixture('samsung_get_transport_actions.xml'));

      expect(await transport.currentTransportActions(), isEmpty);
    });

    test('- escapes the DIDL metadata inside the envelope', () async {
      respondWith('''
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>
<u:SetAVTransportURIResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"/>
</s:Body></s:Envelope>''');

      final metadata = buildDidlLite(
        itemId: 'song-1',
        title: 'Sour Times & Roads',
        uri: Uri.parse('http://jelly.local:8096/Audio/x/universal?ApiKey=t&a=1'),
        mimeType: 'audio/flac',
        duration: const Duration(minutes: 4, seconds: 21),
        artist: 'Portishead',
        album: 'Dummy',
      );

      await transport.setUri(
        Uri.parse('http://jelly.local:8096/Audio/x/universal?ApiKey=t&a=1'),
        metadata: metadata,
      );

      final envelope = capturedRequest().data as String;
      expect(envelope, isNot(contains('<DIDL-Lite')));
      expect(envelope, contains('&lt;DIDL-Lite'));
      expect(envelope, contains('Sour Times &amp;amp; Roads'));
      expect(envelope, contains('ApiKey=t&amp;a=1'));

      final document = XmlDocument.parse(envelope);
      final metadataText = document.descendantElements
          .firstWhere((e) => e.localName == 'CurrentURIMetaData')
          .innerText;
      final didl = XmlDocument.parse(metadataText);
      expect(
        didl.descendantElements
            .firstWhere((e) => e.localName == 'title')
            .innerText,
        'Sour Times & Roads',
      );
      expect(
        didl.descendantElements
            .firstWhere((e) => e.localName == 'res')
            .getAttribute('duration'),
        '0:04:21.000',
      );
    });

    test('- reports capabilities from the action list', () {
      expect(transport.supportsNextUri, isTrue);
      expect(transport.supportsSeek, isTrue);

      final limited = AvTransport(
        soap: soap,
        controlUrl: controlUrl,
        actions: const {'Play', 'Stop', 'SetAVTransportURI'},
      );
      expect(limited.supportsNextUri, isFalse);
      expect(limited.supportsSeek, isFalse);
      expect(limited.supportsPause, isFalse);
    });

    test('- assumes everything works when the action list is unknown', () {
      final unknown = AvTransport(soap: soap, controlUrl: controlUrl);

      expect(unknown.supportsNextUri, isTrue);
      expect(unknown.supportsSeek, isTrue);
    });

    test('- formats a seek target as a UPnP time', () async {
      respondWith('''
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>
<u:SeekResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1"/>
</s:Body></s:Envelope>''');

      await transport.seek(const Duration(hours: 1, minutes: 2, seconds: 3));

      expect(capturedRequest().data as String, contains('<Target>1:02:03'));
    });
  });

  group('RenderingControl', () {
    test('- reads the real GetVolume response as a fraction', () async {
      respondWith(fixture('samsung_get_volume.xml'));

      final control = RenderingControl(
        soap: soap,
        controlUrl: Uri.parse(
          'http://172.20.2.138:9197/upnp/control/RenderingControl1',
        ),
      );

      expect(await control.volume(), 0.05);
    });

    test('- scales a fraction to the 0-100 device range', () async {
      respondWith('''
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>
<u:SetVolumeResponse xmlns:u="urn:schemas-upnp-org:service:RenderingControl:1"/>
</s:Body></s:Envelope>''');

      final control = RenderingControl(
        soap: soap,
        controlUrl: Uri.parse('http://device/rc'),
      );
      await control.setVolume(0.37);

      final envelope = capturedRequest().data as String;
      expect(envelope, contains('<DesiredVolume>37</DesiredVolume>'));
      expect(envelope, contains('<Channel>Master</Channel>'));
    });
  });

  group('upnp durations', () {
    test('- round-trip', () {
      expect(formatUpnpDuration(const Duration(seconds: 5)), '0:00:05');
      expect(
        formatUpnpDuration(const Duration(hours: 2, minutes: 3, seconds: 4)),
        '2:03:04',
      );
      expect(formatUpnpDuration(const Duration(seconds: -5)), '0:00:00');
      expect(parseUpnpDuration('0:01:23'), const Duration(minutes: 1, seconds: 23));
      expect(
        parseUpnpDuration('00:01:23.500'),
        const Duration(minutes: 1, seconds: 23, milliseconds: 500),
      );
      expect(parseUpnpDuration('NOT_IMPLEMENTED'), isNull);
      expect(parseUpnpDuration(''), isNull);
      expect(parseUpnpDuration(null), isNull);
      expect(parseUpnpDuration('garbage'), isNull);
    });
  });
}

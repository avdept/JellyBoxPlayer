import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/server_type.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_probe.dart';
import 'package:mocktail/mocktail.dart';

import 'subsonic_test_support.dart';

void main() {
  late MockHttpClientAdapter adapter;
  late SubsonicProbe probe;

  setUpAll(registerSubsonicFallbacks);

  setUp(() {
    adapter = MockHttpClientAdapter();
    probe = SubsonicProbe(Dio()..httpClientAdapter = adapter);
  });

  void respond(ResponseBody Function() body) {
    when(
      () => adapter.fetch(any(), any(), any()),
    ).thenAnswer((_) async => body());
  }

  test(
    '- identifies Navidrome from the unauthenticated ping envelope',
    () async {
      respond(() => jsonBody(subsonicFailed(10, "missing parameter: 'u'")));

      final identity = await probe.identify('http://music.local:4533/');

      expect(identity?.serverType, ServerType.subsonic);
      expect(identity?.productName, 'navidrome');
      expect(identity?.name, 'Navidrome');
      expect(identity?.version, '0.64.0 (1072e9f7)');
      expect(identity?.serverId, 'http://music.local:4533');
      expect(identity?.quickConnect, isFalse);
      expect(
        await probe.identifyType('http://music.local:4533'),
        ServerType.subsonic,
      );
    },
  );

  test('- ignores servers that answer with something else', () async {
    respond(
      () => ResponseBody.fromString(
        '<!doctype html><html><body>Jellyfin</body></html>',
        200,
        headers: {
          Headers.contentTypeHeader: ['text/html'],
        },
      ),
    );

    expect(await probe.identify('http://jelly.local'), isNull);
    expect(await probe.identifyType('http://jelly.local'), isNull);
  });

  test('- ignores unreachable hosts', () async {
    when(
      () => adapter.fetch(any(), any(), any()),
    ).thenThrow(
      DioException.connectionError(
        requestOptions: RequestOptions(path: '/'),
        reason: 'refused',
      ),
    );

    expect(await probe.identify('http://nowhere.local'), isNull);
  });

  test('- probes only the URL as typed', () {
    expect(probe.pathCandidates('http://music.local/nav/'), [
      'http://music.local/nav',
    ]);
  });

  test('subsonicProductLabel capitalises the server flavour', () {
    expect(subsonicProductLabel('navidrome'), 'Navidrome');
    expect(subsonicProductLabel('gonic'), 'Gonic');
    expect(subsonicProductLabel(null), 'Subsonic');
    expect(subsonicProductLabel(' '), 'Subsonic');
  });
}

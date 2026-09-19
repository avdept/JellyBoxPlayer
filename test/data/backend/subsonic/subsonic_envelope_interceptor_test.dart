import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/data/backend/media_server_exception.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_envelope_interceptor.dart';
import 'package:mocktail/mocktail.dart';

import 'subsonic_test_support.dart';

void main() {
  late MockHttpClientAdapter adapter;
  late Dio dio;
  final seenByFollowingInterceptor = <int?>[];

  setUpAll(registerSubsonicFallbacks);

  setUp(() {
    adapter = MockHttpClientAdapter();
    seenByFollowingInterceptor.clear();
    dio = Dio()..httpClientAdapter = adapter;
    SubsonicEnvelopeInterceptor.install(dio);
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          seenByFollowingInterceptor.add(error.response?.statusCode);
          handler.next(error);
        },
      ),
    );
  });

  void respond(Object? body) {
    when(
      () => adapter.fetch(any(), any(), any()),
    ).thenAnswer((_) async => jsonBody(body));
  }

  Future<DioException> failure() async {
    try {
      await dio.get<Object?>('http://music.local/rest/ping');
    } on DioException catch (e) {
      return e;
    }
    fail('expected a DioException');
  }

  test(
    '- turns a wrong-password envelope into an unauthorized error',
    () async {
      respond(subsonicFailed(40, 'Wrong username or password'));

      final error = await failure();

      expect(error.response?.statusCode, 401);
      expect(error.response?.statusMessage, 'Wrong username or password');
      expect(MediaServerException.fromDio(error).isUnauthorized, isTrue);
      expect(seenByFollowingInterceptor, [401]);
    },
  );

  test('- turns a missing-item envelope into a not-found error', () async {
    respond(subsonicFailed(70, 'Library 999 not found or not accessible'));

    final error = await failure();

    expect(error.response?.statusCode, 404);
    expect(MediaServerException.fromDio(error).isNotFound, isTrue);
  });

  test('- maps other Subsonic error codes without triggering a logout', () {
    expect(SubsonicEnvelopeInterceptor.httpStatusForCode(41), 401);
    expect(SubsonicEnvelopeInterceptor.httpStatusForCode(50), 409);
    expect(SubsonicEnvelopeInterceptor.httpStatusForCode(10), 500);
    expect(SubsonicEnvelopeInterceptor.httpStatusForCode(0), 500);
    expect(SubsonicEnvelopeInterceptor.httpStatusForCode(null), 500);
  });

  test('- a permission-denied envelope is a plain server error', () async {
    respond(
      subsonicFailed(50, 'User is not authorized for the given operation'),
    );

    final error = await failure();

    final mapped = MediaServerException.fromDio(error);
    expect(mapped.isUnauthorized, isFalse);
    expect(mapped.isNotFound, isFalse);
    expect(mapped.kind, MediaServerErrorKind.server);
  });

  test(
    '- leaves non-Subsonic routes alone even with a look-alike body',
    () async {
      respond(subsonicFailed(40, 'not for us'));

      final response = await dio.get<Object?>('http://jelly.local/Items');

      expect(response.statusCode, 200);
    },
  );

  test('- lets successful envelopes through untouched', () async {
    respond(subsonicOk({'ping': true}));

    final response = await dio.get<Object?>('http://music.local/rest/ping');

    expect(response.statusCode, 200);
    expect(seenByFollowingInterceptor, isEmpty);
  });

  test('- ignores bodies that are not Subsonic envelopes', () async {
    respond({'Items': <Object?>[], 'TotalRecordCount': 0});

    final response = await dio.get<Object?>('http://jelly.local/Items');

    expect(response.statusCode, 200);
    expect(response.data, {'Items': <Object?>[], 'TotalRecordCount': 0});
  });

  test(
    '- reaches error interceptors registered before it, like auto-logout',
    () async {
      final seenByEarlierInterceptor = <int?>[];
      final earlyDio = Dio()..httpClientAdapter = adapter;
      earlyDio.interceptors.add(
        InterceptorsWrapper(
          onError: (error, handler) {
            seenByEarlierInterceptor.add(error.response?.statusCode);
            handler.next(error);
          },
        ),
      );
      SubsonicEnvelopeInterceptor.install(earlyDio);
      respond(subsonicFailed(40, 'Wrong username or password'));

      await expectLater(
        earlyDio.get<Object?>('http://music.local/rest/ping'),
        throwsA(isA<DioException>()),
      );

      expect(seenByEarlierInterceptor, [401]);
    },
  );

  test('- installs itself only once per Dio', () {
    SubsonicEnvelopeInterceptor.install(dio);
    SubsonicEnvelopeInterceptor.install(dio);

    expect(
      dio.interceptors.whereType<SubsonicEnvelopeInterceptor>().length,
      1,
    );
  });
}

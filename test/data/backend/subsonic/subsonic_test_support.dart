import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

typedef SubsonicRoute = Object? Function(Uri uri);

void registerSubsonicFallbacks() {
  registerFallbackValue(RequestOptions(path: '/'));
  registerFallbackValue(const Stream<Uint8List>.empty());
}

ResponseBody jsonBody(Object? body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, Object?> subsonicOk([Map<String, Object?> payload = const {}]) => {
  'subsonic-response': {
    'status': 'ok',
    'version': '1.16.1',
    'type': 'navidrome',
    'serverVersion': '0.64.0 (1072e9f7)',
    'openSubsonic': true,
    ...payload,
  },
};

Map<String, Object?> subsonicFailed(int code, String message) => {
  'subsonic-response': {
    'status': 'failed',
    'version': '1.16.1',
    'type': 'navidrome',
    'serverVersion': '0.64.0 (1072e9f7)',
    'openSubsonic': true,
    'error': {'code': code, 'message': message},
  },
};

class SubsonicFakeServer {
  SubsonicFakeServer() {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer((
      invocation,
    ) async {
      final options = invocation.positionalArguments.first as RequestOptions;
      requests.add(options.uri);
      final method = options.uri.pathSegments.last.replaceAll('.view', '');
      final route = routes[method];
      if (route == null) {
        return jsonBody(subsonicFailed(70, 'no route for $method'));
      }
      return jsonBody(route(options.uri));
    });
    dio = Dio()..httpClientAdapter = adapter;
  }

  final adapter = MockHttpClientAdapter();
  final requests = <Uri>[];
  final routes = <String, SubsonicRoute>{};
  late final Dio dio;

  void ok(String method, Map<String, Object?> payload) =>
      routes[method] = (_) => subsonicOk(payload);

  void on(String method, SubsonicRoute route) => routes[method] = route;

  List<Uri> calls(String method) => [
    for (final uri in requests)
      if (uri.pathSegments.last.replaceAll('.view', '') == method) uri,
  ];
}

Map<String, Object?> childJson(
  String id, {
  String title = 'Song',
  String? albumId = 'album-1',
  String? album = 'Album',
  String suffix = 'mp3',
  int bitDepth = 0,
  int playCount = 0,
  int? track,
  int? disc,
  List<String> genres = const ['Rock'],
  String? coverArt,
}) => {
  'id': id,
  'title': title,
  'album': album,
  'albumId': albumId,
  'artist': 'Artist',
  'artistId': 'artist-1',
  'suffix': suffix,
  'bitDepth': bitDepth,
  'bitRate': 320,
  'duration': 200,
  'playCount': playCount,
  if (track != null) 'track': track,
  if (disc != null) 'discNumber': disc,
  'coverArt': coverArt ?? 'mf-$id',
  'genres': [
    for (final genre in genres) {'name': genre},
  ],
};

Map<String, Object?> albumJson(
  String id, {
  String name = 'Album',
  int playCount = 0,
  int? year,
  String? created,
  List<String> genres = const ['Rock'],
  List<Map<String, Object?>> songs = const [],
}) => {
  'id': id,
  'name': name,
  'artist': 'Artist',
  'artistId': 'artist-1',
  'coverArt': 'al-$id',
  'songCount': songs.length,
  'playCount': playCount,
  if (year != null) 'year': year,
  if (created != null) 'created': created,
  'genres': [
    for (final genre in genres) {'name': genre},
  ],
  'song': songs,
};

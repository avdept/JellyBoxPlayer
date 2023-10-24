import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final dioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      headers: {
        'X-Emby-Authorization':
            'MediaBrowser Client="Jellyfin Web", Device="Chrome", DeviceId="TW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNykgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzExNy4wLjAuMCBTYWZhcmkvNTM3LjM2fDE2OTcyODE5MTQ0NTA1", Version="10.8.10"'
      },
      contentType: 'application/json',
    ),
  )
    ..interceptors.add(ref.watch(errorHandlerProvider))
    // ..interceptors
    //     .add(PrettyDioLogger(requestHeader: true, requestBody: true, responseBody: true, responseHeader: false, error: true, compact: true, maxWidth: 90)),
);

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';

final dioProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      headers: {
        'X-Emby-Authorization':
            'MediaBrowser Client="Jellybox", Device="Chrome", DeviceId="TW96aWxsYS81LjAgKE1hY2ludG9zaDsgSW50ZWwgTWFjIE9TIFggMTBfMTVfNykgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzExNy4wLjAuMCBTYWZhcmkvNTM3LjM2fDE2OTcyODE5MTQ0NTA1", Version="1.8"'
      },
      contentType: 'application/json',
    ),
  )..interceptors.add(interceptor),
  // ..interceptors
  //     .add(PrettyDioLogger(requestHeader: true, requestBody: true, responseBody: true, responseHeader: false, error: true, compact: true, maxWidth: 90)),
);

InterceptorsWrapper interceptor = InterceptorsWrapper(
  onError: (error, handler) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.next(error.copyWith(error: NetworkException.timeout()));

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          handler.next(error.copyWith(error: NetworkException.cancel()));
          return;
        }
        final err = error.response?.data as String?;
        handler.next(
          error.copyWith(
            error: NetworkException.badResponse(
              statusCode: statusCode,
              message: err,
            ),
          ),
        );

      case DioExceptionType.connectionError:
        handler.next(error.copyWith(error: NetworkException.connection()));

      case DioExceptionType.cancel:
        handler.next(error.copyWith(error: NetworkException.cancel()));

      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          handler.next(error.copyWith(error: NetworkException.connection()));
        } else {
          debugPrintStack(
            stackTrace: error.stackTrace,
            label: error.error?.toString(),
          );
          handler.next(error.copyWith(error: NetworkException.unknown()));
        }
    }
  },
);

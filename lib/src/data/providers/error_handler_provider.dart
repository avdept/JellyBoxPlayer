import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';

final errorHandlerProvider = Provider<Interceptor>(
  (ref) => InterceptorsWrapper(
    onError: (error, handler) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          handler.next(error.copyWith(error: NetworkException.timeout()));

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final json = error.response?.data as Map<String, dynamic>?;
          handler.next(
            error.copyWith(
              error: NetworkException.badResponse(
                statusCode: statusCode,
                message: json?['error'] as String?,
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
  ),
);

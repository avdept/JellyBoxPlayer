import 'package:dio/dio.dart';

enum MediaServerErrorKind {
  unauthorized,
  notFound,
  unavailable,
  transport,
  server,
}

class MediaServerException implements Exception {
  const MediaServerException(this.kind, {this.statusCode, this.message});

  factory MediaServerException.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    return MediaServerException(
      _kindOf(error, statusCode),
      statusCode: statusCode,
      message: error.message,
    );
  }

  final MediaServerErrorKind kind;
  final int? statusCode;
  final String? message;

  static MediaServerErrorKind _kindOf(DioException error, int? statusCode) {
    switch (error.type) {
      case DioExceptionType.badResponse:
        if (statusCode == 401 || statusCode == 403) {
          return MediaServerErrorKind.unauthorized;
        }
        if (statusCode == 404 || statusCode == 400) {
          return MediaServerErrorKind.notFound;
        }
        return MediaServerErrorKind.server;

      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return MediaServerErrorKind.unavailable;

      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return MediaServerErrorKind.transport;
    }
  }

  bool get isUnauthorized => kind == MediaServerErrorKind.unauthorized;

  bool get isNotFound => kind == MediaServerErrorKind.notFound;

  @override
  String toString() =>
      message ?? 'MediaServerException(${kind.name}, status: $statusCode)';
}

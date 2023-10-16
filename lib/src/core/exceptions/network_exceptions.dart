import 'package:jplayer/src/core/enums/network_exceptions.dart';


class NetworkException implements Exception {
  NetworkException.badResponse({this.statusCode, this.message})
      : type = (statusCode != null)
            ? NetworkExceptionType.badResponse
            : NetworkExceptionType.other;

  NetworkException.cancel()
      : type = NetworkExceptionType.cancel,
        statusCode = null,
        message = null;

  NetworkException.connection()
      : type = NetworkExceptionType.connection,
        statusCode = null,
        message = null;

  NetworkException.timeout()
      : type = NetworkExceptionType.timeout,
        statusCode = null,
        message = null;

  NetworkException.unknown()
      : type = NetworkExceptionType.other,
        statusCode = null,
        message = null;

  final NetworkExceptionType type;
  final int? statusCode;
  final String? message;

  @override
  String toString() {
    if (message != null) return message!;

    switch (type) {
      case NetworkExceptionType.badResponse:
        return 'Bad response status: $statusCode';

      case NetworkExceptionType.cancel:
        return 'Network request canceled';

      case NetworkExceptionType.connection:
        return 'Network connection error';

      case NetworkExceptionType.timeout:
        return 'Network connection timeout';

      case NetworkExceptionType.other:
        return 'Unknown network error';
    }
  }
}

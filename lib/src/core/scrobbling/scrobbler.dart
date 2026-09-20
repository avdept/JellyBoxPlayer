import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';

enum ScrobblerAvailability { disabled, enabled, suspended }

enum ScrobbleFailure { unauthorized, rejected, rateLimited, unavailable }

class ScrobbleException implements Exception {
  const ScrobbleException(
    this.message, {
    this.failure = ScrobbleFailure.unavailable,
    this.statusCode,
    this.retryAfter,
  });

  factory ScrobbleException.fromStatus(
    int? statusCode,
    String message, {
    Duration? retryAfter,
  }) => ScrobbleException(
    message,
    failure: switch (statusCode) {
      401 => ScrobbleFailure.unauthorized,
      429 => ScrobbleFailure.rateLimited,
      final status? when status >= 400 && status < 500 =>
        ScrobbleFailure.rejected,
      _ => ScrobbleFailure.unavailable,
    },
    statusCode: statusCode,
    retryAfter: retryAfter,
  );

  final String message;
  final ScrobbleFailure failure;
  final int? statusCode;
  final Duration? retryAfter;

  bool get isUnauthorized => failure == ScrobbleFailure.unauthorized;

  bool get isRejected => failure == ScrobbleFailure.rejected;

  bool get isRateLimited => failure == ScrobbleFailure.rateLimited;

  @override
  String toString() =>
      'ScrobbleException(${failure.name}${statusCode == null ? '' : ' $statusCode'}): $message';
}

abstract class Scrobbler {
  String get id;

  ProviderListenable<ScrobblerAvailability> get availability;

  int get maxBatchSize;

  Future<void> updateNowPlaying(Listen listen);

  Future<void> scrobble(List<Listen> listens);

  void onUnauthorized();
}

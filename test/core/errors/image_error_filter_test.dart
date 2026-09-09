import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/errors/image_error_filter.dart';

void main() {
  FlutterErrorDetails imageFailure(Object exception) => FlutterErrorDetails(
    exception: exception,
    library: 'image resource service',
  );

  group('isUnreachableImageFailure', () {
    test('- catches a failed host lookup', () {
      expect(
        isUnreachableImageFailure(
          imageFailure(const SocketException("Failed host lookup: 'jelly'")),
        ),
        isTrue,
      );
    });

    test('- catches a client exception wrapping a socket failure', () {
      expect(
        isUnreachableImageFailure(
          imageFailure(
            Exception('ClientException with SocketException: host lookup'),
          ),
        ),
        isTrue,
      );
    });

    test('- leaves a decode failure alone', () {
      expect(
        isUnreachableImageFailure(imageFailure(Exception('Invalid image'))),
        isFalse,
      );
    });

    test('- leaves errors from other libraries alone', () {
      expect(
        isUnreachableImageFailure(
          const FlutterErrorDetails(
            exception: SocketException('Failed host lookup'),
            library: 'widgets library',
          ),
        ),
        isFalse,
      );
    });
  });
}

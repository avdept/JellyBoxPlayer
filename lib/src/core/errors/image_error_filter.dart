import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';

const _imageLibrary = 'image resource service';

bool isUnreachableImageFailure(FlutterErrorDetails details) {
  if (details.library != _imageLibrary) return false;

  final exception = details.exception;
  if (exception is SocketException) return true;

  final description = exception.toString();
  return description.contains('SocketException') ||
      description.contains('Failed host lookup') ||
      description.contains('Connection refused') ||
      description.contains('Connection closed') ||
      description.contains('Connection timed out');
}

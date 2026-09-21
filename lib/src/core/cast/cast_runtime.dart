import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:jplayer/src/core/cast/cast_media_feed.dart';

var _castReady = false;

bool get castSupported => Platform.isAndroid && _castReady;

Future<void> initializeCast() async {
  if (!Platform.isAndroid) return;
  try {
    await GoogleCastContext.instance.setSharedInstanceWithOptions(
      GoogleCastOptionsAndroid(
        appId: GoogleCastDiscoveryCriteria.kDefaultApplicationId,
      ),
    );
    GoogleCastRemoteMediaClient.instance;
    CastChannelFeed.instance.claimChannel();
    _castReady = true;
  } on Object catch (error) {
    debugPrint('[Cast] unavailable on this device: $error');
  }
}

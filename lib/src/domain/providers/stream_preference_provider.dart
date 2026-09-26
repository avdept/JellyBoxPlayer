import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/audio/stream_preference.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/providers/network_type_provider.dart';

final activeStreamPreferenceProvider = Provider<StreamPreference>((ref) {
  final quality = switch (ref.watch(networkTypeProvider)) {
    NetworkType.cellular => ref.watch(streamQualityCellularProvider),
    NetworkType.wifi => ref.watch(streamQualityWifiProvider),
  };
  return StreamPreference(maxBitRate: quality.maxBitRate);
});

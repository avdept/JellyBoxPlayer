import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/services/image_service.dart';

final baseUrlProvider = StateProvider<String?>((ref) {
  return null;
});

final imageProvider = Provider<ImageService>((ref) {
  var url = ref.watch(baseUrlProvider);
  return ImageService(serverUrl: url!);
});

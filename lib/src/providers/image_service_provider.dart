import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/services/image_service.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';

final imageServiceProvider = Provider<ImageService>((ref) {
  final url = ref.watch(baseUrlProvider);
  return ImageService(serverUrl: url!);
});

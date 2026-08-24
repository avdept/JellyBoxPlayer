import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/services/image_service.dart';

final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService(client: ref.watch(mediaServerClientProvider));
});

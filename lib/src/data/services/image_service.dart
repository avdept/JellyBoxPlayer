import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';

class ImageService {
  ImageService({required this.client});
  final MediaServerClient client;

  static const _sizeParams = {
    'fillwidth',
    'fillheight',
    'maxwidth',
    'maxheight',
  };

  static Uri resize(Uri uri, int size) {
    final params = uri.queryParameters;
    if (params.isEmpty) return uri;
    return uri.replace(
      queryParameters: {
        for (final entry in params.entries)
          entry.key: _sizeParams.contains(entry.key.toLowerCase())
              ? '$size'
              : entry.value,
      },
    );
  }

  String imagePath({required String tagId, required String id}) =>
      client.imageUrl(id: id, tagId: tagId);

  String imagePathById({required String id}) => client.imageUrl(id: id);

  ImageProvider albumIP({required String? tagId, required String id}) {
    final downloaded = DownloadPaths.coverFile(id);
    if (downloaded != null) return FileImage(downloaded);

    if (tagId == null) return const AssetImage(Images.album);

    return CachedNetworkImageProvider(client.imageUrl(id: id, tagId: tagId));
  }

  ImageProvider backdropIp({required String? tagId, required String id}) {
    if (tagId == null) return const AssetImage(Images.album);

    return CachedNetworkImageProvider(
      client.imageUrl(id: id, tagId: tagId, kind: ImageKind.backdrop),
    );
  }
}

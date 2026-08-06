import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';

class ImageService {
  ImageService({required this.serverUrl});
  final String serverUrl;

  static Uri resize(Uri uri, int size) {
    if (uri.queryParameters.isEmpty) return uri;
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'fillWidth': '$size',
        'fillHeight': '$size',
      },
    );
  }

  String imagePath({required String tagId, required String id}) {
    return '$serverUrl/Items/$id/Images/Primary?fillHeight=420&fillWidth=420&quality=96&tag=$tagId';
  }

  String imagePathById({required String id}) {
    return '$serverUrl/Items/$id/Images/Primary?fillHeight=420&fillWidth=420&quality=96';
  }

  ImageProvider albumIP({required String? tagId, required String id}) {
    final downloaded = DownloadPaths.coverFile(id);
    if (downloaded != null) return FileImage(downloaded);

    if (tagId == null) return const AssetImage(Images.album);

    return CachedNetworkImageProvider(
      '$serverUrl/Items/$id/Images/Primary?fillHeight=420&fillWidth=420&quality=96&tag=$tagId',
    );
  }

  ImageProvider backdropIp({required String? tagId, required String id}) {
    if (tagId == null) return const AssetImage(Images.album);

    return CachedNetworkImageProvider(
      '$serverUrl/Items/$id/Images/Backdrop?fillHeight=420&fillWidth=420&quality=96&tag=$tagId',
    );
  }

  String _backdropPath({required String tagId, required String id}) {
    return '$serverUrl/Items/$id/Images/Backdrop?fillHeight=420&fillWidth=420&quality=96&tag=$tagId';
  }
}

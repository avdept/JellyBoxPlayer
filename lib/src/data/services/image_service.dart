import 'package:flutter/widgets.dart';
import 'package:jplayer/resources/resources.dart';

class ImageService {
  ImageService({required this.serverUrl});
  final String serverUrl;

  String imagePath({required String tagId, required String id}) {
    return '$serverUrl/Items/$id/Images/Primary?fillHeight=420&fillWidth=420&quality=96&tag=$tagId';
  }

  ImageProvider albumIP({required String? tagId, required String id}) {
    if (tagId == null) return AssetImage(Images.albumSample);

    return NetworkImage('$serverUrl/Items/$id/Images/Primary?fillHeight=420&fillWidth=420&quality=96&tag=$tagId');
  }
}

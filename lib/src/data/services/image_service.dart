class ImageService {
  final String serverUrl;

  ImageService({required this.serverUrl});

  String imagePath({required String tagId, required String id}) {
    return '$serverUrl/Items/$id/Images/Primary?fillHeight=420&fillWidth=420&quality=96&tag=$tagId';
  }
}

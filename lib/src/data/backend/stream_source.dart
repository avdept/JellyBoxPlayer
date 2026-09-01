class StreamSource {
  const StreamSource({
    required this.uri,
    required this.isHls,
    required this.outputContainer,
    required this.mimeType,
  });

  final Uri uri;
  final bool isHls;
  final String outputContainer;
  final String mimeType;
}

enum ImageKind { primary, album, backdrop }

class StreamSource {
  const StreamSource({
    required this.uri,
    required this.isHls,
    required this.outputContainer,
    required this.mimeType,
    this.requiresTranscode = false,
  });

  final Uri uri;
  final bool isHls;
  final String outputContainer;
  final String mimeType;
  final bool requiresTranscode;
}

enum ImageKind { primary, album, backdrop }

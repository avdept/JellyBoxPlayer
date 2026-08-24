class StreamSource {
  const StreamSource({
    required this.uri,
    required this.isHls,
    required this.outputContainer,
  });

  final Uri uri;
  final bool isHls;
  final String outputContainer;
}

enum ImageKind { primary, album, backdrop }

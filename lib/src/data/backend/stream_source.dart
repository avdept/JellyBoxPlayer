/// A resolved, playable audio source: either a direct/progressive stream or
/// an HLS playlist, plus the container the returned bytes will be in (needed
/// to name downloaded files correctly).
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

enum ImageKind { primary, backdrop }

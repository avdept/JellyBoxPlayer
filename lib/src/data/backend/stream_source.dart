import 'package:jplayer/src/domain/models/library_item/audio_source_info.dart';

class StreamSource {
  const StreamSource({
    required this.uri,
    required this.isHls,
    required this.outputContainer,
    required this.mimeType,
    this.requiresTranscode = false,
    this.delivered,
  });

  final Uri uri;
  final bool isHls;
  final String outputContainer;
  final String mimeType;
  final bool requiresTranscode;
  final AudioSourceInfo? delivered;
}

enum ImageKind { primary, album, backdrop }

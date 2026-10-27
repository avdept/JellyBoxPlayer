import 'package:jplayer/src/core/audio/audio_container_mime.dart';
import 'package:jplayer/src/domain/models/library_item/audio_source_info.dart';
import 'package:jplayer/src/domain/models/library_item/library_item.dart';

class StreamSource {
  const StreamSource({
    required this.uri,
    required this.isHls,
    required this.outputContainer,
    required this.mimeType,
    this.location,
    this.requiresTranscode = false,
    this.delivered,
  });

  final Uri uri;
  final Uri? location;
  final bool isHls;
  final String outputContainer;
  final String mimeType;
  final bool requiresTranscode;
  final AudioSourceInfo? delivered;
}

StreamSource? radioStreamSource(LibraryItem song) {
  final url = song.radioStreamUrl;
  if (url == null) return null;
  final uri = Uri.tryParse(url);
  if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
    return null;
  }
  var container = song.audioSources.firstOrNull?.container?.toLowerCase();
  if (container == 'strm') container = null;
  final isHls =
      uri.path.toLowerCase().endsWith('.m3u8') ||
      container == 'm3u8' ||
      container == 'hls';
  final outputContainer = isHls ? 'm3u8' : (container ?? 'mp3');
  return StreamSource(
    uri: uri,
    isHls: isHls,
    outputContainer: outputContainer,
    mimeType: mimeTypeForContainer(outputContainer),
    delivered: song.audioSources.firstOrNull,
  );
}

enum ImageKind { primary, album, backdrop }

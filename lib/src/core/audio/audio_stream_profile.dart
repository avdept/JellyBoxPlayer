import 'dart:io' show Platform;

/// Codec names Jellyfin reports for lossless audio streams. Used to pick a
/// lossless transcode target (FLAC) so lossless sources stay lossless, while
/// lossy sources transcode to AAC without pointless size inflation.
const _losslessCodecs = <String>{
  'alac', 'flac', 'wav', 'wave', 'pcm', 'aiff', 'aif',
  'ape', 'wavpack', 'wv', 'tta', 'tak', 'dsd', 'dsf', 'mlp', 'truehd',
};

/// Resolves the Jellyfin `/Audio/{id}/universal` parameters for the current
/// platform and a given source stream, and predicts the container the returned
/// bytes will be in (needed to name downloaded files correctly).
///
/// On Android `just_audio` uses ExoPlayer, which has no native ALAC decoder
/// (ALAC needs the unbundled FFmpeg extension). ALAC lives inside an `m4a`
/// container, so simply listing/omitting `m4a` isn't enough — the container is
/// pinned to AAC via Jellyfin's `container|codec` syntax (`m4a|aac`) so ALAC
/// falls through to transcoding while AAC-in-m4a still direct-plays. iOS
/// (AVPlayer) and desktop (media_kit/mpv) decode ALAC natively and direct-play
/// everything.
class AudioStreamProfile {
  const AudioStreamProfile({
    required this.directPlayContainers,
    required this.transcodingContainer,
    required this.transcodingAudioCodec,
    required this.outputContainer,
  });

  factory AudioStreamProfile.forSource({
    String? sourceContainer,
    String? sourceCodec,
    bool? isAndroid,
  }) {
    final android = isAndroid ?? Platform.isAndroid;
    final codec = sourceCodec?.toLowerCase();
    final container = _normalizeContainer(sourceContainer);

    final directPlayContainers = android
        ? 'mp3,aac,m4a|aac,m4b|aac,flac,wav'
        : 'mp3,aac,m4a,m4b,flac,wav,aiff,aif';

    final isLossless = codec != null && _losslessCodecs.contains(codec);
    final transcodingContainer = isLossless ? 'flac' : 'm4a';
    final transcodingAudioCodec = isLossless ? 'flac' : 'aac';

    final directPlays = _willDirectPlay(
      container: container,
      codec: codec,
      isAndroid: android,
    );
    final outputContainer = directPlays && container != null
        ? container
        : transcodingContainer;

    return AudioStreamProfile(
      directPlayContainers: directPlayContainers,
      transcodingContainer: transcodingContainer,
      transcodingAudioCodec: transcodingAudioCodec,
      outputContainer: outputContainer,
    );
  }

  /// Value for the `Container` query param — the containers (optionally pinned
  /// to a codec via `container|codec`) the client can direct-play.
  final String directPlayContainers;

  /// Value for the `TranscodingContainer` query param.
  final String transcodingContainer;

  /// Value for the `AudioCodec` query param (the transcode target codec).
  final String transcodingAudioCodec;

  /// The container the returned bytes will actually be in: the source container
  /// when Jellyfin direct-plays, otherwise [transcodingContainer]. Use this as
  /// the file extension for downloads.
  final String outputContainer;
}

String? _normalizeContainer(String? container) {
  final lower = container?.toLowerCase();
  if (lower == null || lower.isEmpty) return null;
  // Jellyfin can report a comma-separated list or aliases; take the first and
  // fold aliases onto the canonical extension we stream/save as.
  final first = lower.split(',').first.trim();
  return switch (first) {
    'mp4' => 'm4a',
    'wave' => 'wav',
    'aif' => 'aiff',
    _ => first,
  };
}

bool _willDirectPlay({
  required String? container,
  required String? codec,
  required bool isAndroid,
}) {
  switch (container) {
    case 'mp3':
    case 'aac':
    case 'flac':
    case 'wav':
      return true;
    case 'm4a':
    case 'm4b':
      // AAC-in-m4a direct-plays everywhere; ALAC only where a native decoder
      // exists (i.e. not Android).
      if (codec == 'aac') return true;
      if (codec == 'alac') return !isAndroid;
      return false;
    case 'aiff':
      return !isAndroid;
    default:
      return false;
  }
}

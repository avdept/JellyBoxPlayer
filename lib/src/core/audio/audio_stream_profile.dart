import 'package:jplayer/src/core/audio/audio_container_mime.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';

const _losslessCodecs = <String>{
  'alac',
  'flac',
  'wav',
  'wave',
  'pcm',
  'aiff',
  'aif',
  'ape',
  'wavpack',
  'wv',
  'tta',
  'tak',
  'dsd',
  'dsf',
  'mlp',
  'truehd',
};

/// Works out how a media server should deliver one audio source to one target,
/// covering what that target can direct play, what to transcode to otherwise,
/// and which container the bytes will actually arrive in.
class AudioStreamProfile {
  const AudioStreamProfile({
    required this.directPlayContainers,
    required this.transcodingContainer,
    required this.transcodingAudioCodec,
    required this.outputContainer,
    required this.requiresTranscode,
    required this.hlsSegmentContainer,
    required this.useHls,
  });

  factory AudioStreamProfile.forSource({
    required StreamTargetProfile target,
    String? sourceContainer,
    String? sourceCodec,
  }) {
    final codec = sourceCodec?.toLowerCase();
    final container = _normalizeContainer(sourceContainer);

    final isLossless = codec != null && _losslessCodecs.contains(codec);
    final transcode = target.transcodeFor(isLossless: isLossless);

    final directPlays = target.canDirectPlay(
      container: container,
      codec: codec,
    );
    final outputContainer = directPlays && container != null
        ? container
        : transcode.container;

    return AudioStreamProfile(
      directPlayContainers: target.directPlayContainers,
      transcodingContainer: transcode.container,
      transcodingAudioCodec: transcode.codec,
      outputContainer: outputContainer,
      requiresTranscode: !directPlays,
      hlsSegmentContainer: transcode.hlsSegmentContainer,
      useHls: !directPlays && target.supportsHls,
    );
  }

  final String directPlayContainers;
  final String transcodingContainer;
  final String transcodingAudioCodec;
  final String outputContainer;
  final bool requiresTranscode;
  final String hlsSegmentContainer;
  final bool useHls;

  String get outputMimeType => useHls
      ? mimeTypeForContainer('m3u8')
      : mimeTypeForContainer(outputContainer);
}

String? _normalizeContainer(String? container) {
  final lower = container?.toLowerCase();
  if (lower == null || lower.isEmpty) return null;
  final first = lower.split(',').first.trim();
  return switch (first) {
    'mp4' => 'm4a',
    'wave' => 'wav',
    'aif' => 'aiff',
    _ => first,
  };
}

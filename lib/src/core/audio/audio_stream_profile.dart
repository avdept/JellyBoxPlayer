import 'package:jplayer/src/core/audio/audio_container_mime.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/domain/models/library_item/audio_source_info.dart';

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
    this.bitRateCap,
  });

  factory AudioStreamProfile.forSource({
    required StreamTargetProfile target,
    String? sourceContainer,
    String? sourceCodec,
    int? sourceBitRate,
  }) {
    final codec = sourceCodec?.toLowerCase();
    final container = _normalizeContainer(sourceContainer);

    final cap = target.maxBitRate;
    final exceedsCap =
        cap != null && (sourceBitRate == null || sourceBitRate > cap * 1000);

    final isLossless = codec != null && _losslessCodecs.contains(codec);
    final transcode = exceedsCap
        ? target.lossyTarget
        : target.transcodeFor(isLossless: isLossless);

    final directPlays =
        !exceedsCap && target.canDirectPlay(container: container, codec: codec);
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
      bitRateCap: cap,
      useHls:
          target.supportsHls &&
          (!directPlays || target.prefersHls(container: container)),
    );
  }

  final String directPlayContainers;
  final String transcodingContainer;
  final String transcodingAudioCodec;
  final String outputContainer;
  final bool requiresTranscode;
  final String hlsSegmentContainer;
  final bool useHls;
  final int? bitRateCap;

  static const _maxLossySampleRate = 48000;

  bool get transcodesLossless =>
      _losslessCodecs.contains(transcodingAudioCodec);

  AudioSourceInfo deliveredQuality(
    AudioSourceInfo? source, {
    required bool transcodes,
    int? bitRateCeiling,
  }) {
    if (!transcodes) {
      return source ?? AudioSourceInfo(container: outputContainer);
    }
    if (transcodesLossless) {
      return AudioSourceInfo(
        container: transcodingContainer,
        codec: transcodingAudioCodec,
        bitRate: source?.bitRate,
        sampleRate: source?.sampleRate,
        bitDepth: source?.bitDepth,
        channels: source?.channels,
      );
    }
    final kbps = switch ((bitRateCap, bitRateCeiling)) {
      (final int requested, final int ceiling) when ceiling < requested =>
        ceiling,
      (final int requested, _) => requested,
      _ => null,
    };
    final sampleRate = source?.sampleRate;
    return AudioSourceInfo(
      container: transcodingContainer,
      codec: transcodingAudioCodec,
      bitRate: kbps == null ? null : kbps * 1000,
      sampleRate: sampleRate == null || sampleRate <= _maxLossySampleRate
          ? sampleRate
          : _maxLossySampleRate,
      channels: source?.channels,
    );
  }

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

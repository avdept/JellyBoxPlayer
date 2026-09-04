import 'dart:io' show Platform;

import 'package:jplayer/src/core/audio/audio_container_mime.dart';

class DirectPlayRule {
  const DirectPlayRule(
    this.container, {
    this.codecs,
    this.aliases = const <String>{},
  });

  final String container;
  final Set<String>? codecs;
  final Set<String> aliases;

  bool matches({required String? container, String? codec}) {
    if (container == null) return false;
    if (container != this.container && !aliases.contains(container)) {
      return false;
    }
    final allowed = codecs;
    if (allowed == null) return true;
    return codec != null && allowed.contains(codec);
  }

  Iterable<String> get queryEntries {
    final containers = [container, ...aliases];
    final allowed = codecs;
    if (allowed == null) return containers;
    return [
      for (final container in containers)
        for (final codec in allowed) '$container|$codec',
    ];
  }
}

class TranscodeTarget {
  const TranscodeTarget({
    required this.container,
    required this.codec,
    required this.hlsSegmentContainer,
  });

  static const flac = TranscodeTarget(
    container: 'flac',
    codec: 'flac',
    hlsSegmentContainer: 'mp4',
  );

  static const aac = TranscodeTarget(
    container: 'm4a',
    codec: 'aac',
    hlsSegmentContainer: 'ts',
  );

  static const mp3 = TranscodeTarget(
    container: 'mp3',
    codec: 'mp3',
    hlsSegmentContainer: 'ts',
  );

  final String container;
  final String codec;
  final String hlsSegmentContainer;
}

class StreamTargetProfile {
  const StreamTargetProfile({
    required this.directPlay,
    required this.lossyTranscode,
    required this.losslessTranscode,
    required this.supportsHls,
  });

  factory StreamTargetProfile.localPlayer({
    bool? isAndroid,
    bool supportsHls = true,
  }) {
    final android = isAndroid ?? Platform.isAndroid;
    return StreamTargetProfile(
      directPlay: [
        const DirectPlayRule('mp3'),
        const DirectPlayRule('aac'),
        DirectPlayRule(
          'm4a',
          codecs: android ? const {'aac'} : const {'aac', 'alac'},
          aliases: const {'m4b'},
        ),
        const DirectPlayRule('flac'),
        const DirectPlayRule('wav'),
        if (!android) const DirectPlayRule('aiff', aliases: {'aif'}),
      ],
      lossyTranscode: TranscodeTarget.aac,
      losslessTranscode: TranscodeTarget.flac,
      supportsHls: supportsHls,
    );
  }

  factory StreamTargetProfile.download({bool? isAndroid}) =>
      StreamTargetProfile.localPlayer(isAndroid: isAndroid, supportsHls: false);

  factory StreamTargetProfile.renderer({
    required Set<String> sinkMimeTypes,
  }) {
    final containers = {
      for (final mimeType in sinkMimeTypes) ...containersForMimeType(mimeType),
    };
    if (containers.isEmpty) containers.add('mp3');

    TranscodeTarget pick(List<TranscodeTarget> preferences) =>
        preferences.firstWhere(
          (target) => containers.contains(target.container),
          orElse: () => TranscodeTarget.mp3,
        );

    return StreamTargetProfile(
      directPlay: [
        if (containers.contains('mp3')) const DirectPlayRule('mp3'),
        if (containers.contains('flac')) const DirectPlayRule('flac'),
        if (containers.contains('wav')) const DirectPlayRule('wav'),
        if (containers.contains('m4a'))
          const DirectPlayRule('m4a', codecs: {'aac'}, aliases: {'m4b'}),
        if (containers.contains('aac')) const DirectPlayRule('aac'),
        if (containers.contains('ogg'))
          const DirectPlayRule('ogg', aliases: {'oga'}),
        if (containers.contains('aiff'))
          const DirectPlayRule('aiff', aliases: {'aif'}),
      ],
      lossyTranscode: pick([
        TranscodeTarget.mp3,
        TranscodeTarget.aac,
        TranscodeTarget.flac,
      ]),
      losslessTranscode: containers.contains('flac')
          ? TranscodeTarget.flac
          : null,
      supportsHls: false,
    );
  }

  final List<DirectPlayRule> directPlay;
  final TranscodeTarget lossyTranscode;
  final TranscodeTarget? losslessTranscode;
  final bool supportsHls;

  String get directPlayContainers =>
      directPlay.expand((rule) => rule.queryEntries).join(',');

  bool canDirectPlay({required String? container, String? codec}) => directPlay
      .any((rule) => rule.matches(container: container, codec: codec));

  TranscodeTarget transcodeFor({required bool isLossless}) =>
      isLossless ? (losslessTranscode ?? lossyTranscode) : lossyTranscode;
}

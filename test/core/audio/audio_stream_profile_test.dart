import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/audio_stream_profile.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';

void main() {
  group('AudioStreamProfile', () {
    test('routes ALAC on Android through a lossless HLS transcode', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'm4a',
        sourceCodec: 'alac',
        target: StreamTargetProfile.localPlayer(isAndroid: true),
      );

      expect(profile.requiresTranscode, isTrue);
      expect(profile.transcodingAudioCodec, 'flac');
      expect(profile.hlsSegmentContainer, 'mp4');
      expect(profile.outputContainer, 'flac');
    });

    test('direct-plays ALAC everywhere else', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'm4a',
        sourceCodec: 'alac',
        target: StreamTargetProfile.localPlayer(isAndroid: false),
      );

      expect(profile.requiresTranscode, isFalse);
      expect(profile.outputContainer, 'm4a');
    });

    test('direct-plays FLAC on Android', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'flac',
        sourceCodec: 'flac',
        target: StreamTargetProfile.localPlayer(isAndroid: true),
      );

      expect(profile.requiresTranscode, isFalse);
      expect(profile.outputContainer, 'flac');
    });

    test('direct-plays AAC-in-m4a on Android', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'm4a',
        sourceCodec: 'aac',
        target: StreamTargetProfile.localPlayer(isAndroid: true),
      );

      expect(profile.requiresTranscode, isFalse);
      expect(profile.directPlayContainers, contains('m4a|aac'));
    });

    test('sends a lossy source to AAC in TS segments', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'ogg',
        sourceCodec: 'vorbis',
        target: StreamTargetProfile.localPlayer(isAndroid: true),
      );

      expect(profile.requiresTranscode, isTrue);
      expect(profile.transcodingAudioCodec, 'aac');
      expect(profile.hlsSegmentContainer, 'ts');
    });
    test('never streams over HLS for a download target', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'ogg',
        sourceCodec: 'vorbis',
        target: StreamTargetProfile.download(isAndroid: true),
      );

      expect(profile.requiresTranscode, isTrue);
      expect(profile.useHls, isFalse);
      expect(profile.outputContainer, 'm4a');
      expect(profile.outputMimeType, 'audio/mp4');
    });

    test('reports the playlist mime type while streaming over HLS', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'ogg',
        sourceCodec: 'vorbis',
        target: StreamTargetProfile.localPlayer(isAndroid: true),
      );

      expect(profile.useHls, isTrue);
      expect(profile.outputMimeType, 'application/vnd.apple.mpegurl');
    });

    test('transcodes everything to mp3 for an mp3-only renderer', () {
      final target = StreamTargetProfile.renderer(
        sinkMimeTypes: const {'audio/mpeg'},
      );

      final lossless = AudioStreamProfile.forSource(
        sourceContainer: 'flac',
        sourceCodec: 'flac',
        target: target,
      );
      final lossy = AudioStreamProfile.forSource(
        sourceContainer: 'ogg',
        sourceCodec: 'vorbis',
        target: target,
      );

      expect(lossless.requiresTranscode, isTrue);
      expect(lossless.useHls, isFalse);
      expect(lossless.transcodingContainer, 'mp3');
      expect(lossless.outputMimeType, 'audio/mpeg');
      expect(lossy.transcodingContainer, 'mp3');
    });

    test('direct-plays FLAC on a renderer that advertises it', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'flac',
        sourceCodec: 'flac',
        target: StreamTargetProfile.renderer(
          sinkMimeTypes: const {'audio/mpeg', 'audio/x-flac'},
        ),
      );

      expect(profile.requiresTranscode, isFalse);
      expect(profile.outputContainer, 'flac');
      expect(profile.outputMimeType, 'audio/flac');
    });
  });
}

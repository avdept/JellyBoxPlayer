import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/audio_stream_profile.dart';

void main() {
  group('AudioStreamProfile', () {
    test('routes ALAC on Android through a lossless HLS transcode', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'm4a',
        sourceCodec: 'alac',
        isAndroid: true,
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
        isAndroid: false,
      );

      expect(profile.requiresTranscode, isFalse);
      expect(profile.outputContainer, 'm4a');
    });

    test('direct-plays FLAC on Android', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'flac',
        sourceCodec: 'flac',
        isAndroid: true,
      );

      expect(profile.requiresTranscode, isFalse);
      expect(profile.outputContainer, 'flac');
    });

    test('direct-plays AAC-in-m4a on Android', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'm4a',
        sourceCodec: 'aac',
        isAndroid: true,
      );

      expect(profile.requiresTranscode, isFalse);
      expect(profile.directPlayContainers, contains('m4a|aac'));
    });

    test('sends a lossy source to AAC in TS segments', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'ogg',
        sourceCodec: 'vorbis',
        isAndroid: true,
      );

      expect(profile.requiresTranscode, isTrue);
      expect(profile.transcodingAudioCodec, 'aac');
      expect(profile.hlsSegmentContainer, 'ts');
    });
  });
}

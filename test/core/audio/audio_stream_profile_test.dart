import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/audio_stream_profile.dart';
import 'package:jplayer/src/core/audio/stream_preference.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/domain/models/library_item/audio_source_info.dart';

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
      expect(profile.useHls, isFalse);
    });

    test('streams FLAC over HLS on Apple platforms without transcoding', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'flac',
        sourceCodec: 'flac',
        target: StreamTargetProfile.localPlayer(
          isAndroid: false,
          isDarwin: true,
        ),
      );

      expect(profile.useHls, isTrue);
      expect(profile.requiresTranscode, isFalse);
      expect(profile.hlsSegmentContainer, 'mp4');
      expect(profile.transcodingAudioCodec, 'flac');
      expect(profile.outputMimeType, 'application/vnd.apple.mpegurl');
    });

    test('leaves lossy sources on Apple platforms direct', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'mp3',
        sourceCodec: 'mp3',
        target: StreamTargetProfile.localPlayer(
          isAndroid: false,
          isDarwin: true,
        ),
      );

      expect(profile.useHls, isFalse);
      expect(profile.requiresTranscode, isFalse);
      expect(profile.outputContainer, 'mp3');
    });

    test('downloads FLAC directly on Apple platforms, never over HLS', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'flac',
        sourceCodec: 'flac',
        target: StreamTargetProfile.download(isAndroid: false),
      );

      expect(profile.useHls, isFalse);
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

  group('AudioStreamProfile with a bitrate cap', () {
    StreamTargetProfile capped(int kbps, {bool isAndroid = false}) =>
        StreamTargetProfile.localPlayer(
          isAndroid: isAndroid,
        ).withPreference(StreamPreference(maxBitRate: kbps));

    test('transcodes a lossless source to the lossy target', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'flac',
        sourceCodec: 'flac',
        sourceBitRate: 1800000,
        target: capped(192),
      );

      expect(profile.requiresTranscode, isTrue);
      expect(profile.transcodingAudioCodec, 'aac');
      expect(profile.transcodingContainer, 'm4a');
      expect(profile.bitRateCap, 192);
      expect(profile.useHls, isTrue);
    });

    test('keeps ALAC on Android lossy under a cap', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'm4a',
        sourceCodec: 'alac',
        sourceBitRate: 900000,
        target: capped(128, isAndroid: true),
      );

      expect(profile.transcodingAudioCodec, 'aac');
      expect(profile.transcodesLossless, isFalse);
    });

    test('direct-plays a source at or under the cap', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'mp3',
        sourceCodec: 'mp3',
        sourceBitRate: 320000,
        target: capped(320),
      );

      expect(profile.requiresTranscode, isFalse);
      expect(profile.outputContainer, 'mp3');
    });

    test('transcodes a source over the cap even when it could direct play', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'mp3',
        sourceCodec: 'mp3',
        sourceBitRate: 320000,
        target: capped(128),
      );

      expect(profile.requiresTranscode, isTrue);
      expect(profile.bitRateCap, 128);
    });

    test('transcodes a source of unknown bitrate', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'mp3',
        sourceCodec: 'mp3',
        target: capped(128),
      );

      expect(profile.requiresTranscode, isTrue);
    });

    test('leaves an uncapped target as it was', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'mp3',
        sourceCodec: 'mp3',
        target: StreamTargetProfile.localPlayer(isAndroid: false),
      );

      expect(profile.requiresTranscode, isFalse);
      expect(profile.bitRateCap, isNull);
    });

    test('uses the codec of the preference when one is set', () {
      final profile = AudioStreamProfile.forSource(
        sourceContainer: 'flac',
        sourceCodec: 'flac',
        sourceBitRate: 1000000,
        target: StreamTargetProfile.localPlayer(isAndroid: false)
            .withPreference(
              const StreamPreference(
                maxBitRate: 128,
                codec: TranscodeTarget.mp3,
              ),
            ),
      );

      expect(profile.transcodingAudioCodec, 'mp3');
      expect(profile.transcodingContainer, 'mp3');
    });
  });

  group('AudioStreamProfile.deliveredQuality', () {
    const hiRes = AudioSourceInfo(
      container: 'flac',
      codec: 'flac',
      bitRate: 3000000,
      sampleRate: 96000,
      bitDepth: 24,
      channels: 2,
    );

    AudioStreamProfile profileFor(StreamTargetProfile target) =>
        AudioStreamProfile.forSource(
          sourceContainer: hiRes.container,
          sourceCodec: hiRes.codec,
          sourceBitRate: hiRes.bitRate,
          target: target,
        );

    test('is the source when nothing is transcoded', () {
      final profile = profileFor(
        StreamTargetProfile.localPlayer(isAndroid: false),
      );

      expect(profile.deliveredQuality(hiRes, transcodes: false), hiRes);
    });

    test('reports the capped bitrate and a lossy sample rate', () {
      final profile = profileFor(
        StreamTargetProfile.localPlayer(
          isAndroid: false,
        ).withPreference(const StreamPreference(maxBitRate: 192)),
      );

      final delivered = profile.deliveredQuality(hiRes, transcodes: true);

      expect(delivered.codec, 'aac');
      expect(delivered.bitRate, 192000);
      expect(delivered.sampleRate, 48000);
      expect(delivered.bitDepth, isNull);
    });

    test('never reports more than the server can encode', () {
      final profile = profileFor(
        StreamTargetProfile.localPlayer(
          isAndroid: false,
        ).withPreference(const StreamPreference(maxBitRate: 320)),
      );

      final delivered = profile.deliveredQuality(
        hiRes,
        transcodes: true,
        bitRateCeiling: 256,
      );

      expect(delivered.bitRate, 256000);
    });

    test('keeps the source resolution through a lossless transcode', () {
      const alac = AudioSourceInfo(
        container: 'm4a',
        codec: 'alac',
        bitRate: 900000,
        sampleRate: 44100,
        bitDepth: 16,
      );
      final profile = AudioStreamProfile.forSource(
        sourceContainer: alac.container,
        sourceCodec: alac.codec,
        sourceBitRate: alac.bitRate,
        target: StreamTargetProfile.localPlayer(isAndroid: true),
      );

      final delivered = profile.deliveredQuality(alac, transcodes: true);

      expect(delivered.codec, 'flac');
      expect(delivered.bitRate, 900000);
      expect(delivered.sampleRate, 44100);
      expect(delivered.bitDepth, 16);
    });
  });
}

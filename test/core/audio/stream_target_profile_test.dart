import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';

void main() {
  group('StreamTargetProfile.localPlayer', () {
    test('- pins m4a to AAC on Android and allows ALAC elsewhere', () {
      final android = StreamTargetProfile.localPlayer(isAndroid: true);
      final desktop = StreamTargetProfile.localPlayer(isAndroid: false);

      expect(android.directPlayContainers, contains('m4a|aac'));
      expect(android.directPlayContainers, isNot(contains('alac')));
      expect(desktop.directPlayContainers, contains('m4a|alac'));

      expect(
        android.canDirectPlay(container: 'm4a', codec: 'alac'),
        isFalse,
      );
      expect(
        desktop.canDirectPlay(container: 'm4a', codec: 'alac'),
        isTrue,
      );
    });

    test('- offers AIFF direct play everywhere but Android', () {
      expect(
        StreamTargetProfile.localPlayer(
          isAndroid: true,
        ).canDirectPlay(container: 'aiff', codec: 'pcm'),
        isFalse,
      );
      expect(
        StreamTargetProfile.localPlayer(
          isAndroid: false,
        ).canDirectPlay(container: 'aiff', codec: 'pcm'),
        isTrue,
      );
    });

    test('- direct-plays containers that carry a single codec regardless of '
        'the reported codec', () {
      final target = StreamTargetProfile.localPlayer(isAndroid: true);

      expect(target.canDirectPlay(container: 'mp3'), isTrue);
      expect(target.canDirectPlay(container: 'flac'), isTrue);
      expect(target.canDirectPlay(container: 'wav'), isTrue);
      expect(target.canDirectPlay(container: 'ogg'), isFalse);
      expect(target.canDirectPlay(container: null), isFalse);
    });

    test('- keeps lossless sources lossless and lossy sources in AAC', () {
      final target = StreamTargetProfile.localPlayer(isAndroid: true);

      expect(target.transcodeFor(isLossless: true).codec, 'flac');
      expect(target.transcodeFor(isLossless: false).codec, 'aac');
      expect(target.supportsHls, isTrue);
    });
  });

  group('StreamTargetProfile.download', () {
    test('- keeps the platform rules but never allows HLS', () {
      final target = StreamTargetProfile.download(isAndroid: true);

      expect(target.supportsHls, isFalse);
      expect(target.directPlayContainers, contains('m4a|aac'));
      expect(target.canDirectPlay(container: 'm4a', codec: 'alac'), isFalse);
    });
  });

  group('StreamTargetProfile.renderer', () {
    test('- maps a sink protocol info list onto direct-play containers', () {
      final target = StreamTargetProfile.renderer(
        sinkMimeTypes: const {
          'audio/mpeg',
          'audio/x-flac',
          'audio/mp4',
          'audio/x-wav',
        },
      );

      expect(target.supportsHls, isFalse);
      expect(target.canDirectPlay(container: 'mp3'), isTrue);
      expect(target.canDirectPlay(container: 'flac'), isTrue);
      expect(target.canDirectPlay(container: 'wav'), isTrue);
      expect(target.canDirectPlay(container: 'm4a', codec: 'aac'), isTrue);
      expect(target.canDirectPlay(container: 'm4b', codec: 'aac'), isTrue);
      expect(target.canDirectPlay(container: 'm4a', codec: 'alac'), isFalse);
      expect(target.canDirectPlay(container: 'ogg'), isFalse);
      expect(target.transcodeFor(isLossless: true).container, 'flac');
      expect(target.transcodeFor(isLossless: false).container, 'mp3');
    });

    test('- falls back to mp3 when the device advertises nothing usable', () {
      final target = StreamTargetProfile.renderer(
        sinkMimeTypes: const {'video/mpeg', 'image/jpeg'},
      );

      expect(target.directPlayContainers, 'mp3');
      expect(target.transcodeFor(isLossless: true).container, 'mp3');
      expect(target.transcodeFor(isLossless: false).container, 'mp3');
    });

    test('- transcodes to FLAC on a device that only takes FLAC', () {
      final target = StreamTargetProfile.renderer(
        sinkMimeTypes: const {'audio/flac'},
      );

      expect(target.canDirectPlay(container: 'mp3'), isFalse);
      expect(target.transcodeFor(isLossless: true).container, 'flac');
      expect(target.transcodeFor(isLossless: false).container, 'flac');
    });
    test('- reads a real Samsung DMR sink list', () {
      final target = StreamTargetProfile.renderer(
        sinkMimeTypes: const {
          'audio/3ga',
          'audio/3gpp',
          'audio/L16',
          'audio/mp4',
          'audio/mpeg',
          'audio/ogg',
          'audio/vnd.dlna.adts',
          'audio/vnd.dolby.dd-raw',
          'audio/x-flac',
          'audio/x-m4a',
          'audio/x-ms-wma',
          'audio/x-sony-oma',
          'audio/x-wav',
        },
      );

      expect(
        target.directPlayContainers,
        'mp3,flac,wav,m4a|aac,m4b|aac,aac,ogg,oga',
      );
      expect(target.canDirectPlay(container: 'flac'), isTrue);
      expect(target.canDirectPlay(container: 'ogg', codec: 'vorbis'), isTrue);
      expect(target.canDirectPlay(container: 'm4a', codec: 'alac'), isFalse);
      expect(target.transcodeFor(isLossless: true).container, 'flac');
      expect(target.transcodeFor(isLossless: false).container, 'mp3');
    });
  });
}

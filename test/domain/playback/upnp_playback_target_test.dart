import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/rendering_control.dart';
import 'package:jplayer/src/core/upnp/upnp_device.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/upnp_playback_target.dart';
import 'package:mocktail/mocktail.dart';

class MockAvTransport extends Mock implements AvTransport {}

class MockRenderingControl extends Mock implements RenderingControl {}

void main() {
  late MockAvTransport transport;
  late MockRenderingControl control;
  late UpnpPlaybackTarget target;

  const pollInterval = Duration(milliseconds: 5);

  final device = UpnpDevice(
    udn: 'uuid:tv',
    friendlyName: '[TV1476] ROOM 7005',
    deviceType: 'urn:schemas-upnp-org:device:MediaRenderer:1',
    location: Uri.parse('http://172.20.2.138:9197/dmr'),
    services: const [],
    modelName: 'HG55BU800EUXEN',
  );

  TargetTrack track(int number) => TargetTrack(
    itemId: 'song-$number',
    uri: Uri.parse('http://jelly.local:8096/Audio/song-$number/universal'),
    mimeType: 'audio/flac',
    isHls: false,
    title: 'Track $number',
    duration: const Duration(minutes: 3),
    artist: 'Portishead',
    album: 'Dummy',
  );

  void deviceReports(
    AvTransportState state, {
    Duration position = Duration.zero,
    String? trackUri,
  }) {
    when(transport.transportInfo).thenAnswer(
      (_) async => AvTransportInfo(state: state, status: 'OK'),
    );
    when(transport.positionInfo).thenAnswer(
      (_) async => AvPositionInfo(
        position: position,
        trackDuration: const Duration(minutes: 3),
        trackUri: trackUri,
      ),
    );
  }

  Future<void> pump([int ticks = 3]) =>
      Future<void>.delayed(pollInterval * ticks);

  UpnpPlaybackTarget targetWith({
    Set<String> actions = const {
      'Play',
      'Pause',
      'Stop',
      'Seek',
      'SetAVTransportURI',
      'SetNextAVTransportURI',
    },
    Set<String> sinkMimeTypes = const {'audio/mpeg', 'audio/x-flac'},
  }) {
    when(() => transport.supportsNextUri)
        .thenReturn(actions.contains('SetNextAVTransportURI'));
    when(() => transport.supportsSeek).thenReturn(actions.contains('Seek'));
    when(() => transport.supportsPause).thenReturn(actions.contains('Pause'));
    return UpnpPlaybackTarget(
      UpnpRenderer(
        device: device,
        avTransport: transport,
        renderingControl: control,
        sinkMimeTypes: sinkMimeTypes,
      ),
      pollInterval: pollInterval,
    );
  }

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://example.org'));
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    transport = MockAvTransport();
    control = MockRenderingControl();

    when(() => transport.setUri(any(), metadata: any(named: 'metadata')))
        .thenAnswer((_) async {});
    when(() => transport.setNextUri(any(), metadata: any(named: 'metadata')))
        .thenAnswer((_) async {});
    when(() => transport.setNextUri(null, metadata: any(named: 'metadata')))
        .thenAnswer((_) async {});
    when(transport.play).thenAnswer((_) async {});
    when(transport.pause).thenAnswer((_) async {});
    when(transport.stopTransport).thenAnswer((_) async {});
    when(() => transport.seek(any())).thenAnswer((_) async {});
    when(() => control.setVolume(any())).thenAnswer((_) async {});
    deviceReports(AvTransportState.playing);

    target = targetWith();
  });

  tearDown(() => target.dispose());

  group('identity', () {
    test('- derives its stream profile from the device sink', () {
      expect(target.id, 'uuid:tv');
      expect(target.name, '[TV1476] ROOM 7005');
      expect(target.kind, PlaybackTargetKind.upnp);
      expect(target.supportsLocalFiles, isFalse);
      expect(target.streamProfile.supportsHls, isFalse);
      expect(
        target.streamProfile.canDirectPlay(container: 'flac'),
        isTrue,
      );
      expect(target.streamProfile.transcodeFor(isLossless: false).container,
          'mp3');
    });
  });

  group('load', () {
    test('- sets the URI with DIDL metadata, plays, and queues the next '
        'track', () async {
      await target.load(
        [track(1), track(2)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );

      final metadata =
          verify(
                () => transport.setUri(
                  track(1).uri,
                  metadata: captureAny(named: 'metadata'),
                ),
              ).captured.single
              as String;
      expect(metadata, contains('<dc:title>Track 1</dc:title>'));
      expect(metadata, contains('audio/flac'));
      expect(metadata, contains('DLNA.ORG_OP=01'));
      verify(transport.play).called(1);
      verify(
        () => transport.setNextUri(
          track(2).uri,
          metadata: any(named: 'metadata'),
        ),
      ).called(1);
    });

    test('- seeks to the handoff position after starting', () async {
      await target.load(
        [track(1)],
        initialIndex: 0,
        initialPosition: const Duration(seconds: 42),
        autoPlay: true,
      );

      verify(() => transport.seek(const Duration(seconds: 42))).called(1);
    });

    test('- does not queue a next track on a device without the action',
        () async {
      await target.dispose();
      target = targetWith(
        actions: const {'Play', 'Stop', 'SetAVTransportURI'},
      );

      await target.load(
        [track(1), track(2)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );

      verifyNever(
        () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
      );
      expect(target.state.canSeek, isFalse);
    });
  });

  group('polling', () {
    test('- mirrors the device transport state', () async {
      await target.load(
        [track(1)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      deviceReports(
        AvTransportState.pausedPlayback,
        position: const Duration(seconds: 30),
      );
      await pump();

      expect(target.state.status, PlaybackStatus.paused);
      expect(target.state.position, const Duration(seconds: 30));
      expect(target.state.duration, const Duration(minutes: 3));
    });

    test('- advances to the next track once the device stops after playing',
        () async {
      await target.load(
        [track(1), track(2)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      await pump();
      deviceReports(AvTransportState.stopped);
      await pump();

      verify(
        () => transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
      ).called(1);
      expect(target.state.currentIndex, 1);
    });

    test('- does not advance while the device has not started playing yet',
        () async {
      deviceReports(AvTransportState.noMediaPresent);
      await target.load(
        [track(1), track(2)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      await pump(5);

      verifyNever(
        () => transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
      );
    });

    test('- does not advance after an explicit stop', () async {
      await target.load(
        [track(1), track(2)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      await pump();
      await target.stop();
      deviceReports(AvTransportState.stopped);
      await pump(5);

      verifyNever(
        () => transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
      );
      expect(target.state.status, PlaybackStatus.stopped);
    });

    test('- reports completion at the end of the last track', () async {
      final completions = target.stateStream
          .where((state) => state.completed)
          .take(1)
          .toList();

      await target.load(
        [track(1)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      await pump();
      deviceReports(AvTransportState.stopped);

      final state = (await completions).single;
      expect(state.completed, isTrue);
      expect(state.status, PlaybackStatus.stopped);
    });

    test('- adopts a track the device moved to on its own', () async {
      await target.load(
        [track(1), track(2), track(3)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      deviceReports(
        AvTransportState.playing,
        trackUri: '${track(2).uri}',
        position: const Duration(seconds: 4),
      );
      await pump();

      expect(target.state.currentIndex, 1);
      verify(
        () => transport.setNextUri(
          track(3).uri,
          metadata: any(named: 'metadata'),
        ),
      ).called(1);
      verifyNever(
        () => transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
      );
    });

    test('- gives up and reports an error after repeated failures', () async {
      await target.load(
        [track(1)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      when(transport.transportInfo).thenThrow(Exception('device gone'));
      await pump(8);

      expect(target.state.status, PlaybackStatus.error);
    });
  });

  group('transport', () {
    test('- restarts the current track when previous is pressed late',
        () async {
      await target.load(
        [track(1), track(2)],
        initialIndex: 1,
        initialPosition: const Duration(seconds: 30),
        autoPlay: true,
      );
      deviceReports(
        AvTransportState.playing,
        position: const Duration(seconds: 30),
        trackUri: '${track(2).uri}',
      );
      await pump();

      await target.seekToPrevious();

      verify(() => transport.seek(Duration.zero)).called(1);
    });

    test('- steps back a track when previous is pressed early', () async {
      await target.load(
        [track(1), track(2)],
        initialIndex: 1,
        initialPosition: Duration.zero,
        autoPlay: true,
      );

      await target.seekToPrevious();

      verify(
        () => transport.setUri(track(1).uri, metadata: any(named: 'metadata')),
      ).called(1);
    });

    test('- stops at the end of the queue instead of skipping past it',
        () async {
      await target.load(
        [track(1)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );

      await target.seekToNext();

      verify(transport.stopTransport).called(1);
    });

    test('- falls back to stop when the device cannot pause', () async {
      await target.dispose();
      target = targetWith(actions: const {'Play', 'Stop', 'SetAVTransportURI'});

      await target.pause();

      verify(transport.stopTransport).called(1);
      verifyNever(transport.pause);
    });

    test('- ignores seeks on a device that cannot seek', () async {
      await target.dispose();
      target = targetWith(actions: const {'Play', 'Stop', 'SetAVTransportURI'});

      await target.seek(const Duration(seconds: 10));

      verifyNever(() => transport.seek(any()));
    });

    test('- forwards volume to the rendering control', () async {
      await target.setVolume(0.25);

      verify(() => control.setVolume(0.25)).called(1);
    });
  });
}

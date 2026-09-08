import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/diagnostics/diagnostics.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/rendering_control.dart';
import 'package:jplayer/src/core/upnp/upnp_soap_client.dart';
import 'package:jplayer/src/core/upnp/upnp_device.dart';
import 'package:jplayer/src/core/upnp/upnp_renderer.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/upnp_playback_target.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:upnp_quirks/upnp_quirks.dart';

class MockAvTransport extends Mock implements AvTransport {}

class _RecordingDiagnostics extends Diagnostics {
  const _RecordingDiagnostics(this.captured, this.trails);

  final List<String> captured;
  final List<String> trails;

  @override
  Future<void> capture(
    Object error, {
    required String operation,
    StackTrace? stackTrace,
    SentryLevel level = SentryLevel.warning,
    Map<String, String> tags = const {},
    Map<String, Object?> extra = const {},
  }) async {
    captured.add('$operation:$error');
  }

  @override
  void trail(
    String message, {
    String category = 'app',
    Map<String, Object?> data = const {},
  }) {
    trails.add(message);
  }
}

class MockRenderingControl extends Mock implements RenderingControl {}

class MockDeviceQueue extends Mock implements DeviceQueue {}

void main() {
  late MockAvTransport transport;
  late MockRenderingControl control;
  late UpnpPlaybackTarget target;
  late List<String> captured;
  late List<String> trails;

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

  Future<void> start(
    List<TargetTrack> tracks, {
    int index = 0,
    Duration at = Duration.zero,
    bool autoPlay = true,
  }) => target.load(
    tracks,
    initialIndex: index,
    initialPosition: at,
    autoPlay: autoPlay,
  );

  Future<void> useTarget(UpnpPlaybackTarget Function() build) async {
    await target.dispose();
    target = build();
  }

  void expectStarted(int number, {int times = 1}) => verify(
    () => transport.setUri(track(number).uri, metadata: any(named: 'metadata')),
  ).called(times);

  void expectNeverStarted(int number) => verifyNever(
    () => transport.setUri(track(number).uri, metadata: any(named: 'metadata')),
  );

  void expectPrefetched(int number) => verify(
    () => transport.setNextUri(
      track(number).uri,
      metadata: any(named: 'metadata'),
    ),
  ).called(1);

  Iterable<String> capturedFor(String operation) =>
      captured.where((entry) => entry.startsWith('upnp.$operation'));

  UpnpSoapFault refused(String action, [String code = '701']) =>
      UpnpSoapFault(action: action, statusCode: 500, errorCode: code);

  UpnpPlaybackTarget quirkyTargetWith({
    required DeviceQuirks quirks,
    String manufacturer = 'Acme Audio',
    Duration interval = pollInterval,
  }) {
    when(() => transport.supportsNextUri).thenReturn(true);
    when(() => transport.supportsSeek).thenReturn(true);
    when(() => transport.supportsPause).thenReturn(true);

    final fingerprint = DeviceFingerprint(
      manufacturer: manufacturer,
      modelName: 'Play:5',
      deviceType: device.deviceType,
      actions: const {
        'Play',
        'Stop',
        'SetAVTransportURI',
        'SetNextAVTransportURI',
      },
      sinkMimeTypes: const {'audio/mpeg'},
    );

    return UpnpPlaybackTarget(
      UpnpRenderer(
        device: device,
        avTransport: transport,
        renderingControl: control,
        sinkMimeTypes: const {'audio/mpeg'},
        fingerprint: fingerprint,
        quirks: quirks,
      ),
      pollInterval: interval,
      diagnostics: _RecordingDiagnostics(captured, trails),
    );
  }

  UpnpPlaybackTarget targetWith({
    Duration interval = pollInterval,
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
    when(
      () => transport.supportsNextUri,
    ).thenReturn(actions.contains('SetNextAVTransportURI'));
    when(() => transport.supportsSeek).thenReturn(actions.contains('Seek'));
    when(() => transport.supportsPause).thenReturn(actions.contains('Pause'));
    return UpnpPlaybackTarget(
      UpnpRenderer(
        device: device,
        avTransport: transport,
        renderingControl: control,
        sinkMimeTypes: sinkMimeTypes,
      ),
      pollInterval: interval,
      diagnostics: _RecordingDiagnostics(captured, trails),
    );
  }

  setUpAll(() {
    registerFallbackValue(<QueuedTrack>[]);
    registerFallbackValue(Uri.parse('http://example.org'));
    registerFallbackValue(Duration.zero);
    registerFallbackValue(0);
  });

  setUp(() {
    captured = [];
    trails = [];
    transport = MockAvTransport();
    control = MockRenderingControl();

    when(
      () => transport.setUri(any(), metadata: any(named: 'metadata')),
    ).thenAnswer((_) async {});
    when(
      () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
    ).thenAnswer((_) async {});
    when(
      () => transport.setNextUri(null, metadata: any(named: 'metadata')),
    ).thenAnswer((_) async {});
    when(transport.play).thenAnswer((_) async {});
    when(transport.pause).thenAnswer((_) async {});
    when(transport.stopTransport).thenAnswer((_) async {});
    when(
      () => transport.seek(any(), unit: any(named: 'unit')),
    ).thenAnswer((_) async {});
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
      expect(
        target.streamProfile.transcodeFor(isLossless: false).container,
        'mp3',
      );
    });
  });

  group('load', () {
    test('- sets the URI with DIDL metadata, plays, and queues the next '
        'track', () async {
      await start([track(1), track(2)]);

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
      expectPrefetched(2);
    });

    test('- seeks to the handoff position once the device plays', () async {
      await start([track(1)], at: const Duration(seconds: 42));

      verifyNever(() => transport.seek(any(), unit: any(named: 'unit')));

      deviceReports(AvTransportState.playing);
      await target.pollNow();

      verify(
        () => transport.seek(const Duration(seconds: 42), unit: 'REL_TIME'),
      ).called(1);

      await target.pollNow();
      verifyNever(() => transport.seek(any(), unit: any(named: 'unit')));
    });

    test('- keeps playing when the device refuses the resume seek', () async {
      when(() => transport.seek(any(), unit: any(named: 'unit'))).thenThrow(
        const UpnpSoapFault(
          action: 'Seek',
          statusCode: 500,
          errorCode: '710',
          description: 'Seek mode not supported',
        ),
      );

      await start([track(1)], at: const Duration(seconds: 42));
      deviceReports(AvTransportState.playing);
      await target.pollNow();

      expect(target.state.status, isNot(PlaybackStatus.error));
      expect(captured, isEmpty);
      expect(trails, anyElement(startsWith('resume seek refused')));
    });

    test(
      '- does not queue a next track on a device without the action',
      () async {
        await useTarget(
          () =>
              targetWith(actions: const {'Play', 'Stop', 'SetAVTransportURI'}),
        );

        await start([track(1), track(2)]);

        verifyNever(
          () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
        );
        expect(target.state.canSeek, isFalse);
      },
    );
  });

  group('polling', () {
    test('- mirrors the device transport state', () async {
      await start([track(1)]);
      deviceReports(
        AvTransportState.pausedPlayback,
        position: const Duration(seconds: 30),
      );
      await pump();

      expect(target.state.status, PlaybackStatus.paused);
      expect(target.state.position, const Duration(seconds: 30));
      expect(target.state.duration, const Duration(minutes: 3));
    });

    test(
      '- advances to the next track once the device stops after playing',
      () async {
        await start([track(1), track(2)]);
        await pump();
        deviceReports(AvTransportState.stopped);
        await pump();

        expectStarted(2);
        expect(target.state.currentIndex, 1);
      },
    );

    test(
      '- does not advance while the device has not started playing yet',
      () async {
        deviceReports(AvTransportState.noMediaPresent);
        await start([track(1), track(2)]);
        await pump(5);

        expectNeverStarted(2);
      },
    );

    test('- does not advance after an explicit stop', () async {
      await start([track(1), track(2)]);
      await pump();
      await target.stop();
      deviceReports(AvTransportState.stopped);
      await pump(5);

      expectNeverStarted(2);
      expect(target.state.status, PlaybackStatus.stopped);
    });

    test('- reports completion at the end of the last track', () async {
      final completions = target.stateStream
          .where((state) => state.completed)
          .take(1)
          .toList();

      await start([track(1)]);
      await pump();
      deviceReports(AvTransportState.stopped);

      final state = (await completions).single;
      expect(state.completed, isTrue);
      expect(state.status, PlaybackStatus.stopped);
    });

    test('- adopts a track the device moved to on its own', () async {
      await start([track(1), track(2), track(3)]);
      deviceReports(
        AvTransportState.playing,
        trackUri: '${track(2).uri}',
        position: const Duration(seconds: 4),
      );
      await pump();

      expect(target.state.currentIndex, 1);
      expectPrefetched(3);
      expectNeverStarted(2);
    });

    test(
      '- keeps playing and reports when a queued next track is refused',
      () async {
        when(
          () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
        ).thenThrow(Exception('718 queue conflict'));

        await start([track(1), track(2), track(3)]);
        await pump();
        deviceReports(AvTransportState.stopped);
        await pump(6);

        expectStarted(2);
        expect(target.state.currentIndex, 1);
        expect(target.state.status, isNot(PlaybackStatus.error));
        expect(capturedFor('setNextUri'), isNotEmpty);
      },
    );

    test(
      '- waits out one idle poll before advancing a queued next track',
      () async {
        await useTarget(() => targetWith(interval: const Duration(hours: 1)));

        await start([track(1), track(2)]);

        deviceReports(AvTransportState.playing);
        await target.pollNow();

        deviceReports(AvTransportState.stopped);
        await target.pollNow();

        expectNeverStarted(2);

        await target.pollNow();

        expectStarted(2);
      },
    );

    test(
      '- advances on the first idle poll when the device cannot prefetch',
      () async {
        await useTarget(
          () => targetWith(
            interval: const Duration(hours: 1),
            actions: const {'Play', 'Stop', 'SetAVTransportURI'},
          ),
        );

        await start([track(1), track(2)]);

        deviceReports(AvTransportState.playing);
        await target.pollNow();
        deviceReports(AvTransportState.stopped);
        await target.pollNow();

        expectStarted(2);
      },
    );

    test('- adopts a device URI that comes back re-encoded', () async {
      await start([track(1), track(2)]);
      deviceReports(
        AvTransportState.playing,
        trackUri: 'http://jelly.local:8096/Audio/song-2/universal?ApiKey=other',
      );
      await pump();

      expect(target.state.currentIndex, 1);
    });

    test(
      '- surfaces and reports an error when the next track is rejected',
      () async {
        await start([track(1), track(2)]);
        await pump();
        when(
          () =>
              transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
        ).thenThrow(Exception('800 invalid uri'));
        deviceReports(AvTransportState.stopped);
        await pump(6);

        expect(target.state.status, PlaybackStatus.error);
        expectStarted(2);
        expect(capturedFor('setUri'), hasLength(1));
      },
    );

    test(
      '- ignores a poll that lands after the transport was stopped',
      () async {
        await start([track(1), track(2)]);
        await pump();

        await target.stop();
        await pump(4);

        expect(target.state.status, PlaybackStatus.stopped);
        expect(target.state.position, Duration.zero);
      },
    );

    test('- breadcrumbs poll failures, then reports and gives up', () async {
      await start([track(1)]);
      when(transport.transportInfo).thenThrow(Exception('device gone'));
      await pump(8);

      expect(
        trails.where((entry) => entry.contains('poll failed')),
        isNotEmpty,
      );
      expect(capturedFor('poll'), hasLength(1));
      expect(target.state.status, PlaybackStatus.error);
    });

    test('- gives up and reports an error after repeated failures', () async {
      await start([track(1)]);
      when(transport.transportInfo).thenThrow(Exception('device gone'));
      await pump(8);

      expect(target.state.status, PlaybackStatus.error);
    });
  });

  group('manufacturer quirks', () {
    test('- never prefetches when a rule turns it off', () async {
      await useTarget(
        () => quirkyTargetWith(
          quirks: const DeviceQuirks(queueNextTrack: false),
        ),
      );

      await start([track(1), track(2)]);
      await pump();

      verifyNever(
        () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
      );
      expect(captured, isEmpty);
    });

    test('- still advances the queue without prefetching', () async {
      await useTarget(
        () => quirkyTargetWith(
          quirks: const DeviceQuirks(queueNextTrack: false),
          interval: const Duration(hours: 1),
        ),
      );

      await start([track(1), track(2)]);

      deviceReports(AvTransportState.playing);
      await target.pollNow();
      deviceReports(AvTransportState.stopped);
      await target.pollNow();

      expectStarted(2);
      expect(target.state.currentIndex, 1);
    });

    test('- keeps prefetching on the defaults', () async {
      await useTarget(() => quirkyTargetWith(quirks: DeviceQuirks.defaults));

      await start([track(1), track(2)]);

      expectPrefetched(2);
    });

    test('- sends no DIDL metadata when a rule turns it off', () async {
      await useTarget(
        () => quirkyTargetWith(
          quirks: const DeviceQuirks(sendTrackMetadata: false),
        ),
      );

      await start([track(1)]);

      verify(() => transport.setUri(track(1).uri, metadata: '')).called(1);
    });

    test('- stops the transport first when a rule asks for it', () async {
      await useTarget(
        () => quirkyTargetWith(
          quirks: const DeviceQuirks(stopBeforeSetUri: true),
        ),
      );

      await start([track(1)]);

      verifyInOrder([
        transport.stopTransport,
        () => transport.setUri(track(1).uri, metadata: any(named: 'metadata')),
      ]);
    });

    test('- seeks in the unit the rule names', () async {
      await useTarget(
        () => quirkyTargetWith(
          quirks: const DeviceQuirks(seekUnit: SeekUnit.absoluteTime),
        ),
      );

      await start([track(1)]);
      await target.seek(const Duration(seconds: 30));

      verify(
        () => transport.seek(const Duration(seconds: 30), unit: 'ABS_TIME'),
      ).called(1);
    });

    test('- scales volume into a coarse device range', () async {
      await useTarget(
        () => quirkyTargetWith(quirks: const DeviceQuirks(volumeRange: 15)),
      );

      await target.setVolume(0.5);

      verify(() => control.setVolume(8)).called(1);
    });

    test('- drops mime types the rule says the device cannot play', () async {
      await useTarget(
        () => quirkyTargetWith(
          quirks: const DeviceQuirks(unsupportedMimeTypes: {'audio/mpeg'}),
        ),
      );

      expect(target.streamProfile.directPlayContainers, 'mp3');
    });
  });

  group('a device that holds the queue', () {
    late MockDeviceQueue deviceQueue;

    UpnpPlaybackTarget queueDrivenTarget({
      Duration interval = const Duration(hours: 1),
    }) {
      when(() => transport.supportsNextUri).thenReturn(false);
      when(() => transport.supportsSeek).thenReturn(true);
      when(() => transport.supportsPause).thenReturn(true);
      return UpnpPlaybackTarget(
        UpnpRenderer(
          device: device,
          avTransport: transport,
          renderingControl: control,
          sinkMimeTypes: const {'audio/mpeg'},
          queueDriver: deviceQueue,
        ),
        pollInterval: interval,
        diagnostics: _RecordingDiagnostics(captured, trails),
      );
    }

    setUp(() {
      deviceQueue = MockDeviceQueue();
      when(
        () => deviceQueue.load(
          any(),
          startIndex: any(named: 'startIndex'),
          autoPlay: any(named: 'autoPlay'),
        ),
      ).thenAnswer((_) async {});
      when(() => deviceQueue.skipTo(any())).thenAnswer((_) async {});
    });

    test('- hands the whole queue over instead of one track', () async {
      await useTarget(() => queueDrivenTarget());

      await start([track(1), track(2), track(3)], index: 1);

      final handed =
          verify(
                () => deviceQueue.load(
                  captureAny(),
                  startIndex: 1,
                  autoPlay: true,
                ),
              ).captured.single
              as List<QueuedTrack>;
      expect(handed.map((t) => t.title), ['Track 1', 'Track 2', 'Track 3']);
      verifyNever(
        () => transport.setUri(any(), metadata: any(named: 'metadata')),
      );
      verifyNever(
        () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
      );
    });

    test('- never pushes a next track to a queue-driven device', () async {
      await useTarget(() => queueDrivenTarget());

      await start([track(1), track(2)]);
      deviceReports(AvTransportState.playing);
      await target.pollNow();

      verifyNever(
        () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
      );
    });

    test('- leaves advancing to the device when it goes idle', () async {
      await useTarget(() => queueDrivenTarget());

      await start([track(1), track(2)]);
      deviceReports(AvTransportState.playing);
      await target.pollNow();
      deviceReports(AvTransportState.stopped);
      await target.pollNow();
      await target.pollNow();
      await target.pollNow();

      verifyNever(
        () => transport.setUri(any(), metadata: any(named: 'metadata')),
      );
      verifyNever(() => deviceQueue.skipTo(any()));
    });

    test('- skips by telling the device which index to play', () async {
      await useTarget(() => queueDrivenTarget());

      await start([track(1), track(2), track(3)]);
      await target.seekToNext();

      verify(() => deviceQueue.skipTo(1)).called(1);
      expect(target.state.currentIndex, 1);
    });

    test('- surfaces an error when the hand-over is refused', () async {
      await useTarget(() => queueDrivenTarget());
      when(
        () => deviceQueue.load(
          any(),
          startIndex: any(named: 'startIndex'),
          autoPlay: any(named: 'autoPlay'),
        ),
      ).thenThrow(Exception('ParseXmltoPlayList error'));

      await start([track(1)]);

      expect(target.state.status, PlaybackStatus.error);
      expect(
        captured.where((entry) => entry.startsWith('upnp.queue.load')),
        hasLength(1),
      );
    });
  });

  group('a device that refuses a command', () {
    test('- reports a refused Pause instead of claiming it paused', () async {
      await start([track(1)]);
      deviceReports(AvTransportState.playing);
      await target.pollNow();
      when(transport.pause).thenThrow(refused('Pause'));

      await expectLater(target.pause(), completes);

      expect(capturedFor('pause'), hasLength(1));
      expect(target.state.status, isNot(PlaybackStatus.paused));
    });

    test('- re-reads the device state after a refusal', () async {
      await start([track(1)]);
      when(transport.pause).thenThrow(refused('Pause'));
      deviceReports(
        AvTransportState.playing,
        position: const Duration(seconds: 12),
      );

      await target.pause();
      await pump();

      expect(target.state.status, PlaybackStatus.playing);
      expect(target.state.position, const Duration(seconds: 12));
    });

    test('- survives a refused play, seek and volume too', () async {
      when(transport.play).thenThrow(Exception('701'));
      when(
        () => transport.seek(any(), unit: any(named: 'unit')),
      ).thenThrow(Exception('710'));
      when(() => control.setVolume(any())).thenThrow(Exception('402'));

      await expectLater(target.play(), completes);
      await expectLater(target.seek(const Duration(seconds: 5)), completes);
      await expectLater(target.setVolume(0.3), completes);

      expect(
        capturedFor('play'),
        hasLength(1),
      );
      expect(
        capturedFor('seek'),
        hasLength(1),
      );
      expect(
        capturedFor('setVolume'),
        hasLength(1),
      );
    });
  });

  group('transport', () {
    test(
      '- restarts the current track when previous is pressed late',
      () async {
        await start(
          [track(1), track(2)],
          index: 1,
          at: const Duration(seconds: 30),
        );
        deviceReports(
          AvTransportState.playing,
          position: const Duration(seconds: 30),
          trackUri: '${track(2).uri}',
        );
        await pump();

        await target.seekToPrevious();

        verify(
          () => transport.seek(Duration.zero, unit: any(named: 'unit')),
        ).called(1);
      },
    );

    test('- steps back a track when previous is pressed early', () async {
      await start([track(1), track(2)], index: 1);

      await target.seekToPrevious();

      expectStarted(1);
    });

    test(
      '- stops at the end of the queue instead of skipping past it',
      () async {
        await start([track(1)]);

        await target.seekToNext();

        verify(transport.stopTransport).called(1);
      },
    );

    test('- falls back to stop when the device cannot pause', () async {
      await useTarget(
        () => targetWith(actions: const {'Play', 'Stop', 'SetAVTransportURI'}),
      );

      await target.pause();

      verify(transport.stopTransport).called(1);
      verifyNever(transport.pause);
    });

    test('- ignores seeks on a device that cannot seek', () async {
      await useTarget(
        () => targetWith(actions: const {'Play', 'Stop', 'SetAVTransportURI'}),
      );

      await target.seek(const Duration(seconds: 10));

      verifyNever(() => transport.seek(any(), unit: any(named: 'unit')));
    });

    test('- forwards volume to the rendering control', () async {
      await target.setVolume(0.25);

      verify(() => control.setVolume(25)).called(1);
    });
  });

  group('a device that refuses to start', () {
    test('- waits out a 701 on play instead of giving up', () async {
      var attempts = 0;
      when(transport.play).thenAnswer((_) async {
        attempts++;
        if (attempts < 3) throw refused('Play');
      });
      deviceReports(AvTransportState.stopped);
      target = targetWith();

      await start([track(1)]);

      expect(attempts, 3);
      expect(target.state.status, isNot(PlaybackStatus.error));
      expect(captured, isEmpty);
    });

    test('- gives up on a 701 that never clears', () async {
      when(transport.play).thenThrow(refused('Play'));
      deviceReports(AvTransportState.stopped);
      target = targetWith();

      await start([track(1)]);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(verify(transport.play).callCount, 5);
      expect(target.state.status, PlaybackStatus.error);
      expect(capturedFor('setUri'), hasLength(1));
    });

    test('- does not retry other refusals', () async {
      when(transport.play).thenThrow(refused('Play', '718'));
      deviceReports(AvTransportState.stopped);
      target = targetWith();

      await start([track(1)]);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      verify(transport.play).called(1);
      expect(target.state.status, PlaybackStatus.error);
    });
  });

  group('a device that never starts', () {
    test('- gives up when the renderer stays in TRANSITIONING', () async {
      await useTarget(
        () => UpnpPlaybackTarget(
          UpnpRenderer(
            device: device,
            avTransport: transport,
            renderingControl: control,
            sinkMimeTypes: const {'audio/mpeg'},
          ),
          pollInterval: pollInterval,
          startTimeout: const Duration(milliseconds: 30),
          diagnostics: _RecordingDiagnostics(captured, trails),
        ),
      );
      when(() => transport.supportsNextUri).thenReturn(false);
      when(() => transport.supportsSeek).thenReturn(true);
      deviceReports(AvTransportState.transitioning);

      await start([track(1)]);

      await target.pollNow();
      expect(target.state.status, PlaybackStatus.buffering);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      await target.pollNow();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(target.state.status, PlaybackStatus.error);
      expect(
        captured.single,
        startsWith('upnp.stalled:Bad state: renderer never left TRANSITIONING'),
      );
    });

    test('- clears the stall clock once the device starts', () async {
      target = targetWith();
      deviceReports(AvTransportState.transitioning);
      await start([track(1)]);
      await target.pollNow();

      deviceReports(
        AvTransportState.playing,
        position: const Duration(seconds: 2),
      );
      await target.pollNow();

      expect(target.state.status, PlaybackStatus.playing);
      expect(target.state.position, const Duration(seconds: 2));
    });
  });

  group('metadata for a transcoded stream', () {
    test('- declares CI=1 and drops the byte-seek claim', () async {
      target = targetWith();
      deviceReports(AvTransportState.stopped);

      await start([
        TargetTrack(
          itemId: 'song-9',
          uri: Uri.parse('http://jelly.local:8096/Audio/song-9/universal'),
          mimeType: 'audio/mpeg',
          isHls: false,
          title: 'Transcoded',
          duration: const Duration(minutes: 3),
          transcoded: true,
        ),
      ]);

      final metadata =
          verify(
                () => transport.setUri(
                  any(),
                  metadata: captureAny(named: 'metadata'),
                ),
              ).captured.single
              as String;

      expect(metadata, contains('DLNA.ORG_OP=00'));
      expect(metadata, contains('DLNA.ORG_CI=1'));
    });

    test('- keeps byte-seek for a direct-played stream', () async {
      target = targetWith();
      deviceReports(AvTransportState.stopped);

      await start([track(1)]);

      final metadata =
          verify(
                () => transport.setUri(
                  any(),
                  metadata: captureAny(named: 'metadata'),
                ),
              ).captured.single
              as String;

      expect(metadata, contains('DLNA.ORG_OP=01'));
      expect(metadata, contains('DLNA.ORG_CI=0'));
    });
  });
}

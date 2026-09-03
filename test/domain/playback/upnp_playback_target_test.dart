import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/diagnostics/diagnostics.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/core/upnp/av_transport.dart';
import 'package:jplayer/src/core/upnp/rendering_control.dart';
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

  late List<String> captured;
  late List<String> trails;

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

      verify(
        () => transport.seek(const Duration(seconds: 42), unit: 'REL_TIME'),
      ).called(1);
    });

    test(
      '- does not queue a next track on a device without the action',
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
      },
    );
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

    test(
      '- advances to the next track once the device stops after playing',
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
          () =>
              transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
        ).called(1);
        expect(target.state.currentIndex, 1);
      },
    );

    test(
      '- does not advance while the device has not started playing yet',
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
          () =>
              transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
        );
      },
    );

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

    test(
      '- keeps playing when the device refuses a queued next track',
      () async {
        when(
          () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
        ).thenThrow(Exception('718 queue conflict'));

        await target.load(
          [track(1), track(2), track(3)],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        await pump();
        deviceReports(AvTransportState.stopped);
        await pump(6);

        verify(
          () =>
              transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
        ).called(1);
        expect(target.state.currentIndex, 1);
        expect(target.state.status, isNot(PlaybackStatus.error));
      },
    );

    test(
      '- stops retrying the next-track push once it has been refused',
      () async {
        when(
          () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
        ).thenThrow(Exception('718 queue conflict'));

        await target.load(
          [track(1), track(2), track(3)],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        await pump();
        deviceReports(AvTransportState.stopped);
        await pump(6);

        verify(
          () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
        ).called(1);
      },
    );

    test(
      '- waits out one idle poll before advancing a queued next track',
      () async {
        await target.dispose();
        target = targetWith(interval: const Duration(hours: 1));

        await target.load(
          [track(1), track(2)],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );

        deviceReports(AvTransportState.playing);
        await target.pollNow();

        deviceReports(AvTransportState.stopped);
        await target.pollNow();

        verifyNever(
          () =>
              transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
        );

        await target.pollNow();

        verify(
          () =>
              transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
        ).called(1);
      },
    );

    test(
      '- advances immediately when nothing was queued on the device',
      () async {
        await target.dispose();
        target = targetWith(
          interval: const Duration(hours: 1),
          actions: const {'Play', 'Stop', 'SetAVTransportURI'},
        );

        await target.load(
          [track(1), track(2)],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );

        deviceReports(AvTransportState.playing);
        await target.pollNow();
        deviceReports(AvTransportState.stopped);
        await target.pollNow();

        verify(
          () =>
              transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
        ).called(1);
      },
    );

    test('- adopts a device URI that comes back re-encoded', () async {
      await target.load(
        [track(1), track(2)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      deviceReports(
        AvTransportState.playing,
        trackUri: 'http://jelly.local:8096/Audio/song-2/universal?ApiKey=other',
      );
      await pump();

      expect(target.state.currentIndex, 1);
    });

    test(
      '- surfaces an error and gives up when the next track is rejected',
      () async {
        await target.load(
          [track(1), track(2)],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        await pump();
        when(
          () =>
              transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
        ).thenThrow(Exception('800 invalid uri'));
        deviceReports(AvTransportState.stopped);
        await pump(6);

        expect(target.state.status, PlaybackStatus.error);
        verify(
          () =>
              transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
        ).called(1);
      },
    );

    test(
      '- ignores a poll that lands after the transport was stopped',
      () async {
        await target.load(
          [track(1), track(2)],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        await pump();

        await target.stop();
        await pump(4);

        expect(target.state.status, PlaybackStatus.stopped);
        expect(target.state.position, Duration.zero);
      },
    );

    test('- reports a refused next track to diagnostics once', () async {
      when(
        () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
      ).thenThrow(Exception('718 queue conflict'));

      await target.load(
        [track(1), track(2), track(3)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      await pump();
      deviceReports(AvTransportState.stopped);
      await pump(6);

      expect(
        captured.where((entry) => entry.startsWith('upnp.setNextUri')),
        hasLength(1),
      );
    });

    test(
      '- breadcrumbs each poll failure and reports once it gives up',
      () async {
        await target.load(
          [track(1)],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );
        when(transport.transportInfo).thenThrow(Exception('device gone'));
        await pump(8);

        expect(trails.where((entry) => entry.contains('poll of')), isNotEmpty);
        expect(
          captured.where((entry) => entry.startsWith('upnp.poll')),
          hasLength(1),
        );
      },
    );

    test('- reports a rejected track that stops playback', () async {
      await target.load(
        [track(1), track(2)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      await pump();
      when(
        () => transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
      ).thenThrow(Exception('800 invalid uri'));
      deviceReports(AvTransportState.stopped);
      await pump(6);

      expect(
        captured.where((entry) => entry.startsWith('upnp.setUri')),
        hasLength(1),
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

  group('manufacturer quirks', () {
    test('- never prefetches when a rule turns it off', () async {
      await target.dispose();
      target = quirkyTargetWith(
        quirks: const DeviceQuirks(queueNextTrack: false),
      );

      await target.load(
        [track(1), track(2)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      await pump();

      verifyNever(
        () => transport.setNextUri(any(), metadata: any(named: 'metadata')),
      );
      expect(captured, isEmpty);
    });

    test('- still advances the queue without prefetching', () async {
      await target.dispose();
      target = quirkyTargetWith(
        quirks: const DeviceQuirks(queueNextTrack: false),
        interval: const Duration(hours: 1),
      );

      await target.load(
        [track(1), track(2)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );

      deviceReports(AvTransportState.playing);
      await target.pollNow();
      deviceReports(AvTransportState.stopped);
      await target.pollNow();

      verify(
        () => transport.setUri(track(2).uri, metadata: any(named: 'metadata')),
      ).called(1);
      expect(target.state.currentIndex, 1);
    });

    test('- keeps prefetching on the defaults', () async {
      await target.dispose();
      target = quirkyTargetWith(quirks: DeviceQuirks.defaults);

      await target.load(
        [track(1), track(2)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );

      verify(
        () => transport.setNextUri(
          track(2).uri,
          metadata: any(named: 'metadata'),
        ),
      ).called(1);
    });

    test('- sends no DIDL metadata when a rule turns it off', () async {
      await target.dispose();
      target = quirkyTargetWith(
        quirks: const DeviceQuirks(sendTrackMetadata: false),
      );

      await target.load(
        [track(1)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );

      verify(() => transport.setUri(track(1).uri, metadata: '')).called(1);
    });

    test('- stops the transport first when a rule asks for it', () async {
      await target.dispose();
      target = quirkyTargetWith(
        quirks: const DeviceQuirks(stopBeforeSetUri: true),
      );

      await target.load(
        [track(1)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );

      verifyInOrder([
        transport.stopTransport,
        () => transport.setUri(track(1).uri, metadata: any(named: 'metadata')),
      ]);
    });

    test('- seeks in the unit the rule names', () async {
      await target.dispose();
      target = quirkyTargetWith(
        quirks: const DeviceQuirks(seekUnit: SeekUnit.absoluteTime),
      );

      await target.load(
        [track(1)],
        initialIndex: 0,
        initialPosition: Duration.zero,
        autoPlay: true,
      );
      await target.seek(const Duration(seconds: 30));

      verify(
        () => transport.seek(const Duration(seconds: 30), unit: 'ABS_TIME'),
      ).called(1);
    });

    test('- scales volume into a coarse device range', () async {
      await target.dispose();
      target = quirkyTargetWith(quirks: const DeviceQuirks(volumeRange: 15));

      await target.setVolume(0.5);

      verify(() => control.setVolume(8)).called(1);
    });

    test('- drops mime types the rule says the device cannot play', () async {
      await target.dispose();
      target = quirkyTargetWith(
        quirks: const DeviceQuirks(unsupportedMimeTypes: {'audio/mpeg'}),
      );

      expect(target.streamProfile.directPlayContainers, 'mp3');
    });
  });

  group('transport', () {
    test(
      '- restarts the current track when previous is pressed late',
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

        verify(
          () => transport.seek(Duration.zero, unit: any(named: 'unit')),
        ).called(1);
      },
    );

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

    test(
      '- stops at the end of the queue instead of skipping past it',
      () async {
        await target.load(
          [track(1)],
          initialIndex: 0,
          initialPosition: Duration.zero,
          autoPlay: true,
        );

        await target.seekToNext();

        verify(transport.stopTransport).called(1);
      },
    );

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

      verifyNever(() => transport.seek(any(), unit: any(named: 'unit')));
    });

    test('- forwards volume to the rendering control', () async {
      await target.setVolume(0.25);

      verify(() => control.setVolume(25)).called(1);
    });
  });
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/cast_failure_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

class _FakeTarget implements PlaybackTarget {
  _FakeTarget({required this.id, required this.name, required this.kind});

  @override
  final String id;
  @override
  final String name;
  @override
  final PlaybackTargetKind kind;

  final _controller = StreamController<TargetPlaybackState>.broadcast();
  var stopped = false;
  var disposed = false;
  TargetPlaybackState _state = TargetPlaybackState.idle;

  void fail() {
    _state = const TargetPlaybackState(
      status: PlaybackStatus.error,
      position: Duration.zero,
    );
    _controller.add(_state);
  }

  @override
  TargetPlaybackState get state => _state;

  @override
  Stream<TargetPlaybackState> get stateStream => _controller.stream;

  @override
  Future<void> stop() async => stopped = true;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }

  @override
  StreamTargetProfile get streamProfile => StreamTargetProfile.localPlayer(
    isAndroid: false,
  );

  @override
  bool get supportsLocalFiles => kind == PlaybackTargetKind.local;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeTarget local;
  late _FakeTarget speaker;
  late ProviderContainer container;

  setUp(() {
    local = _FakeTarget(
      id: 'local',
      name: 'This device',
      kind: PlaybackTargetKind.local,
    );
    speaker = _FakeTarget(
      id: 'uuid:kef',
      name: 'LSX II LT',
      kind: PlaybackTargetKind.upnp,
    );
    container = ProviderContainer(
      overrides: [localPlaybackTargetProvider.overrideWithValue(local)],
    );
    addTearDown(container.dispose);
    container.read(playbackProvider);
  });

  Future<void> castTo(_FakeTarget target) async {
    container.read(playbackTargetProvider.notifier).select(target);
    await Future<void>.delayed(Duration.zero);
  }

  test('- hands playback back to this device when a cast fails', () async {
    await castTo(speaker);
    expect(container.read(playbackTargetProvider).id, 'uuid:kef');

    speaker.fail();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(playbackTargetProvider).id, 'local');
    expect(speaker.stopped, isTrue);
    expect(speaker.disposed, isTrue);
  });

  test('- names the speaker in the message it surfaces', () async {
    await castTo(speaker);
    speaker.fail();
    await Future<void>.delayed(Duration.zero);

    final failure = container.read(castFailureProvider);
    expect(failure?.deviceName, 'LSX II LT');
    expect(failure?.message, contains('Unable to cast to LSX II LT'));
    expect(failure?.message, contains('switched back to this device'));
  });

  test('- falls back once, however many errors the device emits', () async {
    await castTo(speaker);

    speaker
      ..fail()
      ..fail()
      ..fail();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(playbackTargetProvider).id, 'local');
  });

  test('- leaves a local failure on this device', () async {
    local.fail();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(playbackTargetProvider).id, 'local');
    expect(container.read(castFailureProvider), isNull);
    expect(container.read(playbackProvider).status, PlaybackStatus.error);
  });

  test('- can cast again after a failure', () async {
    await castTo(speaker);
    speaker.fail();
    await Future<void>.delayed(Duration.zero);

    final second = _FakeTarget(
      id: 'uuid:wiim',
      name: 'Kitchen Ceiling',
      kind: PlaybackTargetKind.upnp,
    );
    await castTo(second);
    expect(container.read(playbackTargetProvider).id, 'uuid:wiim');

    second.fail();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(playbackTargetProvider).id, 'local');
    expect(container.read(castFailureProvider)?.deviceName, 'Kitchen Ceiling');
  });
}

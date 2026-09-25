import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/domain/playback/playback_target.dart';
import 'package:jplayer/src/domain/playback/playback_target_provider.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/cast_failure_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final volumes = <double>[];
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
  Future<void> setVolume(double level) async => volumes.add(level);

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

  test('- starts a speaker it has never seen at a quiet level', () async {
    await container.read(playbackProvider.notifier).switchTarget(speaker);

    expect(speaker.volumes, [0.1]);
  });

  test('- starts a known speaker at the level it was left at', () async {
    SharedPreferences.setMockInitialValues({
      'app_settings': '{"renderer_volumes":{"uuid:kef":0.35}}',
    });
    final prefs = await SharedPreferences.getInstance();
    final remembering = ProviderContainer(
      overrides: [
        localPlaybackTargetProvider.overrideWithValue(local),
        appSettingsProvider.overrideWith((_) => AppSettingsNotifier(prefs)),
      ],
    );
    addTearDown(remembering.dispose);

    await remembering.read(playbackProvider.notifier).switchTarget(speaker);

    expect(speaker.volumes, [0.35]);
  });

  test('- finishes a switch only once the old output has stopped', () async {
    await container.read(playbackProvider.notifier).switchTarget(speaker);

    expect(local.stopped, isTrue);
    expect(container.read(playbackProvider.notifier).target.id, 'uuid:kef');
    expect(container.read(playbackTargetProvider).id, 'uuid:kef');
  });

  test('- runs two quick switches one after the other', () async {
    final second = _FakeTarget(
      id: 'uuid:wiim',
      name: 'WiiM',
      kind: PlaybackTargetKind.upnp,
    );
    final playback = container.read(playbackProvider.notifier);

    unawaited(playback.switchTarget(speaker));
    await playback.switchTarget(second);

    expect(speaker.stopped, isTrue);
    expect(speaker.disposed, isTrue);
    expect(playback.target.id, 'uuid:wiim');
  });

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

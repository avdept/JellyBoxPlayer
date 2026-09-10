import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/discord/discord_frame.dart';
import 'package:jplayer/src/core/discord/discord_presence_client.dart';
import 'package:jplayer/src/core/discord/discord_presence_handler.dart';
import 'package:jplayer/src/core/discord/discord_transport.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';

class _StubPlayback extends StateNotifier<PlaybackState>
    implements PlaybackNotifier {
  _StubPlayback() : super(PlaybackState.initial());

  PlaybackState get current => state;

  set current(PlaybackState next) => state = next;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTransport implements DiscordTransport {
  final _controller = StreamController<List<int>>();
  final _reader = DiscordFrameReader();
  final sent = <DiscordFrame>[];

  @override
  Stream<List<int>> get incoming => _controller.stream;

  @override
  void send(List<int> data) => sent.addAll(_reader.add(data));

  @override
  Future<void> close() async {
    if (!_controller.isClosed) await _controller.close();
  }

  Future<void> becomeReady() async {
    _controller.add(
      encodeDiscordFrame(DiscordOpcode.frame, {
        'cmd': 'DISPATCH',
        'evt': 'READY',
      }),
    );
    await pumpEventQueue();
  }

  List<Map<String, Object?>?> get activities => sent
      .where((frame) => frame.payload['cmd'] == 'SET_ACTIVITY')
      .map(
        (frame) =>
            (frame.payload['args']! as Map<String, Object?>)['activity']
                as Map<String, Object?>?,
      )
      .toList();
}

void main() {
  LibraryItem songNamed(String id, String name) => LibraryItem(
    id: id,
    name: name,
    kind: ItemKind.song,
    albumArtist: 'Portishead',
    albumName: 'Dummy',
    duration: const Duration(minutes: 3),
  );

  PlaybackState stateWith(PlaybackStatus status) => PlaybackState(
    album: const LibraryItem(
      id: 'album-1',
      name: 'Dummy',
      kind: ItemKind.album,
    ),
    songs: [songNamed('song-1', 'Sour Times')],
    status: status,
    position: Duration.zero,
    cacheProgress: Duration.zero,
    currentMediaIndex: 0,
  );

  late _StubPlayback playback;
  late _FakeTransport transport;
  late AppSettingsNotifier settings;
  late ProviderContainer container;

  setUp(() {
    DiscordPresenceHandler.reset();
    playback = _StubPlayback();
    transport = _FakeTransport();
    settings = AppSettingsNotifier(null);
    container = ProviderContainer(
      overrides: [
        playbackProvider.overrideWith((ref) => playback),
        appSettingsProvider.overrideWith((ref) => settings),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(DiscordPresenceHandler.reset);

    DiscordPresenceHandler.initialize(
      container,
      client: DiscordPresenceClient(
        applicationId: 'test-app',
        connect: () async => transport,
        sendBudget: 1000,
      ),
    );
  });

  Future<void> enable() async {
    settings.setEnabled(AppSetting.discordRichPresence, value: true);
    await pumpEventQueue();
    await transport.becomeReady();
  }

  test('stays off the socket until the setting is enabled', () async {
    playback.current = stateWith(PlaybackStatus.playing);
    await pumpEventQueue();

    expect(transport.sent, isEmpty);
  });

  test('publishes the current track once enabled', () async {
    playback.current = stateWith(PlaybackStatus.playing);
    await pumpEventQueue();
    await enable();

    expect(transport.activities.last, containsPair('details', 'Sour Times'));
    expect(transport.activities.last, containsPair('state', 'Portishead'));
    expect(transport.activities.last, containsPair('type', 2));
  });

  test('publishes a track that starts after being enabled', () async {
    await enable();
    expect(transport.activities, isEmpty);

    playback.current = stateWith(PlaybackStatus.playing);
    await pumpEventQueue();

    expect(transport.activities.last, containsPair('details', 'Sour Times'));
  });

  test('sends timestamps while playing', () async {
    await enable();
    playback.current = stateWith(PlaybackStatus.playing);
    await pumpEventQueue();

    expect(transport.activities.last, contains('timestamps'));
  });

  test('clears the activity when playback is paused', () async {
    await enable();
    playback.current = stateWith(PlaybackStatus.playing);
    await pumpEventQueue();

    playback.current = stateWith(PlaybackStatus.paused);
    await pumpEventQueue();

    expect(transport.activities.last, isNull);
  });

  test('republishes the track when playback resumes', () async {
    await enable();
    playback
      ..current = stateWith(PlaybackStatus.playing)
      ..current = stateWith(PlaybackStatus.paused);
    await pumpEventQueue();

    playback.current = stateWith(PlaybackStatus.playing);
    await pumpEventQueue();

    expect(transport.activities.last, containsPair('details', 'Sour Times'));
    expect(transport.activities.last, contains('timestamps'));
  });

  test('keeps the presence up while a track buffers', () async {
    await enable();
    playback.current = stateWith(PlaybackStatus.playing);
    await pumpEventQueue();
    final published = transport.activities.length;

    playback.current = stateWith(PlaybackStatus.buffering);
    await pumpEventQueue();

    expect(transport.activities, hasLength(published));
  });

  test('holds the timeline steady while the position ticks', () async {
    await enable();
    playback.current = stateWith(PlaybackStatus.playing);
    await pumpEventQueue();
    final published = transport.activities.length;

    for (var second = 1; second < 4; second++) {
      playback.current = stateWith(
        PlaybackStatus.playing,
      ).copyWith(position: Duration(seconds: second));
      await pumpEventQueue();
    }

    expect(transport.activities, hasLength(published));
  });

  test('clears the activity when playback stops', () async {
    await enable();
    playback.current = stateWith(PlaybackStatus.playing);
    await pumpEventQueue();

    playback.current = PlaybackState.initial();
    await pumpEventQueue();

    expect(transport.activities.last, isNull);
  });

  test('clears the activity when the setting is switched off', () async {
    await enable();
    playback.current = stateWith(PlaybackStatus.playing);
    await pumpEventQueue();

    settings.setEnabled(AppSetting.discordRichPresence, value: false);
    await pumpEventQueue();

    expect(transport.activities.last, isNull);
  });
}

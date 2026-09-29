import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/home_widget/now_playing_widget_sync.dart';
import 'package:jplayer/src/core/home_widget/widget_artwork.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:just_audio/just_audio.dart' show LoopMode;
import 'package:path/path.dart' as p;

class _StubPlayback extends StateNotifier<PlaybackState>
    implements PlaybackNotifier {
  _StubPlayback() : super(PlaybackState.initial());

  PlaybackState get current => state;

  set current(PlaybackState next) => state = next;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHost implements WidgetHost {
  _FakeHost(this.path);

  final String? path;
  int reloads = 0;

  @override
  Future<String?> directory() async => path;

  @override
  Future<void> reload() async => reloads++;
}

void main() {
  late Directory root;
  late _StubPlayback playback;
  late ProviderContainer container;
  late _FakeHost host;
  late NowPlayingWidgetSync sync;
  late List<String> artworkLoads;
  late StreamController<LoopMode> loopModes;
  late StateProvider<AsyncValue<bool?>> signedIn;

  final artwork = WidgetArtwork(
    png: Uint8List.fromList([1, 2, 3]),
    background: const Color(0xFF203040),
    foreground: const Color(0xFFE0E0F0),
  );

  LibraryItem song(String id, String name, {bool liked = false}) => LibraryItem(
    id: id,
    name: name,
    kind: ItemKind.song,
    albumArtist: 'Portishead',
    albumName: 'Dummy',
    userData: PlaybackUserData(isFavorite: liked),
  );

  PlaybackState stateWith(
    List<LibraryItem> songs,
    PlaybackStatus status, {
    bool shuffle = false,
  }) => PlaybackState(
    album: null,
    songs: songs,
    status: status,
    position: Duration.zero,
    cacheProgress: Duration.zero,
    currentMediaIndex: songs.isEmpty ? null : 0,
    shuffleEnabled: shuffle,
  );

  void start({String? path}) {
    host = _FakeHost(path);
    sync = NowPlayingWidgetSync(
      host: host,
      artwork: (item) async {
        artworkLoads.add(item.id);
        return item.id == 'bare' ? null : artwork;
      },
    )..attach(container, loopModes: loopModes.stream, signedIn: signedIn);
  }

  Future<void> signIn(AsyncValue<bool?> value) async {
    container.read(signedIn.notifier).state = value;
    await pumpEventQueue();
    await sync.idle;
  }

  Future<void> emit(PlaybackState state) async {
    playback.current = state;
    await pumpEventQueue();
    await sync.idle;
  }

  File file(String name) => File(p.join(root.path, name));

  Map<String, Object?> snapshot() =>
      jsonDecode(file(NowPlayingWidgetSync.snapshotFile).readAsStringSync())
          as Map<String, Object?>;

  setUp(() {
    root = Directory.systemTemp.createTempSync('widget_sync_');
    addTearDown(() => root.deleteSync(recursive: true));
    artworkLoads = [];
    loopModes = StreamController<LoopMode>();
    signedIn = StateProvider((ref) => const AsyncData(true));
    addTearDown(loopModes.close);
    playback = _StubPlayback();
    container = ProviderContainer(
      overrides: [playbackProvider.overrideWith((ref) => playback)],
    );
    addTearDown(container.dispose);
  });

  test('writes nothing until a track is loaded', () async {
    start(path: root.path);
    await emit(stateWith(const [], PlaybackStatus.stopped));

    expect(file(NowPlayingWidgetSync.snapshotFile).existsSync(), isFalse);
    expect(host.reloads, 0);
  });

  test('publishes the current track with its cover and tint', () async {
    start(path: root.path);
    await emit(stateWith([song('1', 'Sour Times')], PlaybackStatus.playing));

    expect(snapshot(), {
      'title': 'Sour Times',
      'artist': 'Portishead',
      'playing': true,
      'liked': false,
      'shuffle': false,
      'repeat': 'off',
      'cover': file(NowPlayingWidgetSync.coverFile).path,
      'background': 0xFF203040,
      'foreground': 0xFFE0E0F0,
    });
    expect(file(NowPlayingWidgetSync.coverFile).readAsBytesSync(), [1, 2, 3]);
    expect(host.reloads, 1);
  });

  test('pausing updates the state without reloading the artwork', () async {
    start(path: root.path);
    final songs = [song('1', 'Sour Times')];
    await emit(stateWith(songs, PlaybackStatus.playing));
    await emit(stateWith(songs, PlaybackStatus.paused));

    expect(snapshot()['playing'], isFalse);
    expect(artworkLoads, ['1']);
    expect(host.reloads, 2);
  });

  test('treats buffering as playing', () async {
    start(path: root.path);
    await emit(stateWith([song('1', 'Sour Times')], PlaybackStatus.buffering));

    expect(snapshot()['playing'], isTrue);
  });

  test('publishes like, shuffle and repeat', () async {
    start(path: root.path);
    await emit(
      stateWith(
        [song('1', 'Sour Times', liked: true)],
        PlaybackStatus.playing,
        shuffle: true,
      ),
    );
    loopModes.add(LoopMode.all);
    await pumpEventQueue();
    await sync.idle;

    expect(snapshot(), containsPair('liked', true));
    expect(snapshot(), containsPair('shuffle', true));
    expect(snapshot(), containsPair('repeat', 'all'));
    expect(artworkLoads, ['1']);
  });

  test('liking the playing song republishes it', () async {
    start(path: root.path);
    await emit(stateWith([song('1', 'Sour Times')], PlaybackStatus.playing));
    await emit(
      stateWith([song('1', 'Sour Times', liked: true)], PlaybackStatus.playing),
    );

    expect(snapshot()['liked'], isTrue);
    expect(host.reloads, 2);
  });

  test('a track without artwork drops the previous cover', () async {
    start(path: root.path);
    await emit(stateWith([song('1', 'Sour Times')], PlaybackStatus.playing));

    await emit(stateWith([song('bare', 'Roads')], PlaybackStatus.playing));

    expect(snapshot()['title'], 'Roads');
    expect(snapshot()['cover'], isNull);
    expect(snapshot()['background'], isNull);
    expect(file(NowPlayingWidgetSync.coverFile).existsSync(), isFalse);
  });

  test('clearing the queue empties the widget', () async {
    start(path: root.path);
    await emit(stateWith([song('1', 'Sour Times')], PlaybackStatus.playing));
    await emit(stateWith(const [], PlaybackStatus.stopped));

    expect(snapshot(), isEmpty);
    expect(host.reloads, 2);
  });

  test('shows the signed-out state after logout', () async {
    start(path: root.path);
    await emit(stateWith([song('1', 'Sour Times')], PlaybackStatus.playing));
    await signIn(const AsyncData(false));

    expect(snapshot(), {'signedOut': true});
  });

  test('stays unchanged while the session is still loading', () async {
    start(path: root.path);
    await emit(stateWith([song('1', 'Sour Times')], PlaybackStatus.paused));
    await signIn(const AsyncLoading());

    expect(snapshot()['title'], 'Sour Times');
  });

  test('signing in replaces the signed-out state with an empty one', () async {
    start(path: root.path);
    await signIn(const AsyncData(false));
    await signIn(const AsyncData(true));

    expect(snapshot(), isEmpty);
  });

  test('does nothing when the platform has no shared directory', () async {
    start();
    await emit(stateWith([song('1', 'Sour Times')], PlaybackStatus.playing));

    expect(root.listSync(), isEmpty);
    expect(host.reloads, 0);
  });
}

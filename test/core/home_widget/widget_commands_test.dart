import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/home_widget/widget_commands.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:just_audio_background/just_audio_background.dart';

class _StubPlayback extends StateNotifier<PlaybackState>
    implements PlaybackNotifier {
  _StubPlayback(super._state);

  final calls = <String>[];

  @override
  Future<void> playPause() async => calls.add('playPause');

  @override
  Future<void> next() async => calls.add('next');

  @override
  Future<void> prev() async => calls.add('prev');

  @override
  Future<void> setShuffle({required bool enabled}) async =>
      calls.add('shuffle:$enabled');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  PlaybackState stateWith(List<LibraryItem> songs) => PlaybackState(
    album: null,
    songs: songs,
    status: PlaybackStatus.paused,
    position: Duration.zero,
    cacheProgress: Duration.zero,
    currentMediaIndex: songs.isEmpty ? null : 0,
  );

  const song = LibraryItem(id: '1', name: 'Sour Times', kind: ItemKind.song);

  late _StubPlayback playback;
  late ProviderContainer container;

  void start(PlaybackState state) {
    playback = _StubPlayback(state);
    container = ProviderContainer(
      overrides: [playbackProvider.overrideWith((ref) => playback)],
    );
    addTearDown(container.dispose);
  }

  setUp(JustAudioBackground.takePendingPlay);

  test('routes transport commands to the player', () async {
    start(stateWith([song]));
    await WidgetCommands.handle(container, 'playPause');
    await WidgetCommands.handle(container, 'next');
    await WidgetCommands.handle(container, 'previous');
    await WidgetCommands.handle(container, 'shuffle');

    expect(playback.calls, ['playPause', 'next', 'prev', 'shuffle:true']);
  });

  test(
    'remembers a play tap that arrives before the queue is restored',
    () async {
      start(stateWith(const []));
      await WidgetCommands.handle(container, 'playPause');

      expect(playback.calls, isEmpty);
      expect(JustAudioBackground.takePendingPlay(), isTrue);
    },
  );

  test('ignores other commands while there is no queue', () async {
    start(stateWith(const []));
    await WidgetCommands.handle(container, 'next');

    expect(playback.calls, isEmpty);
    expect(JustAudioBackground.takePendingPlay(), isFalse);
  });
}

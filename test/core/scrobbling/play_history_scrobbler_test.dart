import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/core/scrobbling/play_history_scrobbler.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:jplayer/src/data/providers/play_history_database_provider.dart';
import 'package:jplayer/src/data/storages/play_history_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../provider_container.dart';

class MockPlayHistoryDatabase extends Mock implements PlayHistoryDatabase {}

void main() {
  setUpAll(() => registerFallbackValue(const <SongPlay>[]));

  const song = LibraryItem(id: 'song-1', name: 'Song', kind: ItemKind.song);
  final listenedAt = DateTime.utc(2026, 10, 21);

  test('- is enabled exactly while a user is signed in', () {
    final container = createProviderContainer(
      overrides: [
        currentUserProvider.overrideWith(
          (_) => const User(userId: 'user-1', token: 't'),
        ),
      ],
    );
    final scrobbler = PlayHistoryScrobbler(container);

    expect(
      container.read(scrobbler.availability),
      ScrobblerAvailability.enabled,
    );

    final signedOut = createProviderContainer(
      overrides: [currentUserProvider.overrideWith((_) => null)],
    );
    expect(
      signedOut.read(PlayHistoryScrobbler(signedOut).availability),
      ScrobblerAvailability.disabled,
    );
  });

  test('- records each listen as a play', () async {
    final history = MockPlayHistoryDatabase();
    when(() => history.addPlays(any())).thenAnswer((_) async {});
    final container = createProviderContainer(
      overrides: [playHistoryDatabaseProvider.overrideWithValue(history)],
    );

    await PlayHistoryScrobbler(
      container,
    ).scrobble([Listen(song: song, listenedAt: listenedAt)]);

    final plays =
        verify(() => history.addPlays(captureAny())).captured.single
            as List<SongPlay>;
    expect(plays.single.song.id, 'song-1');
    expect(plays.single.playedAt, listenedAt);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:jplayer/src/data/providers/play_history_database_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

class PlayHistoryScrobbler implements Scrobbler {
  PlayHistoryScrobbler(this._container);

  static const serviceId = 'play-history';

  final ProviderContainer _container;

  @override
  String get id => serviceId;

  @override
  int get maxBatchSize => 100;

  @override
  ProviderListenable<ScrobblerAvailability> get availability =>
      currentUserProvider.select(
        (user) => user == null
            ? ScrobblerAvailability.disabled
            : ScrobblerAvailability.enabled,
      );

  @override
  Future<void> updateNowPlaying(Listen listen) async {}

  @override
  Future<void> scrobble(List<Listen> listens) =>
      _container.read(playHistoryDatabaseProvider).addPlays([
        for (final listen in listens)
          (song: listen.song, playedAt: listen.listenedAt),
      ]);

  @override
  void onUnauthorized() {}
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/lastfm/lastfm_client.dart';
import 'package:jplayer/src/core/lastfm/lastfm_payload.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:jplayer/src/domain/providers/lastfm_account_provider.dart';

class LastFmScrobbler implements Scrobbler {
  LastFmScrobbler(this._container, {LastFmClient? client})
    : _client = client ?? LastFmClient();

  static const serviceId = 'lastfm';

  final ProviderContainer _container;
  final LastFmClient _client;

  @override
  String get id => serviceId;

  @override
  int get maxBatchSize => 50;

  @override
  ProviderListenable<ScrobblerAvailability> get availability =>
      lastFmAccountProvider.select(availabilityFor);

  static ScrobblerAvailability availabilityFor(LastFmAccount account) =>
      switch (account.status) {
        LastFmStatus.connected => ScrobblerAvailability.enabled,
        LastFmStatus.sessionRejected => ScrobblerAvailability.suspended,
        _ => ScrobblerAvailability.disabled,
      };

  @override
  Future<void> updateNowPlaying(Listen listen) async {
    final (credentials, sessionKey) = _session();
    await _client.updateNowPlaying(
      credentials,
      lastFmTrackParams(listen, withTimestamp: false),
      sessionKey: sessionKey,
    );
  }

  @override
  Future<void> scrobble(List<Listen> listens) async {
    final (credentials, sessionKey) = _session();
    final ignored = await _client.scrobble(
      credentials,
      lastFmScrobbleParams(listens),
      sessionKey: sessionKey,
    );
    if (ignored > 0) {
      debugPrint('[Scrobble] lastfm ignored $ignored of ${listens.length}');
    }
  }

  @override
  void onUnauthorized() =>
      _container.read(lastFmAccountProvider.notifier).markSessionRejected();

  (LastFmCredentials, String) _session() {
    final account = _container.read(lastFmAccountProvider);
    final credentials = account.credentials;
    final key = account.sessionKey;
    if (!account.isConnected || credentials == null || key == null) {
      throw const ScrobbleException('Last.fm is not connected');
    }
    return (credentials, key);
  }
}

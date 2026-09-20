import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/listenbrainz/listenbrainz_client.dart';
import 'package:jplayer/src/core/listenbrainz/listenbrainz_payload.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:jplayer/src/domain/providers/listenbrainz_account_provider.dart';

class ListenBrainzScrobbler implements Scrobbler {
  ListenBrainzScrobbler(
    this._container, {
    required String clientVersion,
    ListenBrainzClient? client,
  }) : _clientVersion = clientVersion,
       _client = client ?? ListenBrainzClient();

  static const serviceId = 'listenbrainz';

  final ProviderContainer _container;
  final ListenBrainzClient _client;
  final String _clientVersion;

  @override
  String get id => serviceId;

  @override
  int get maxBatchSize => 100;

  @override
  ProviderListenable<ScrobblerAvailability> get availability =>
      listenBrainzAccountProvider.select(availabilityFor);

  static ScrobblerAvailability availabilityFor(ListenBrainzAccount account) =>
      switch (account.status) {
        ListenBrainzStatus.connected => ScrobblerAvailability.enabled,
        ListenBrainzStatus.tokenRejected => ScrobblerAvailability.suspended,
        _ => ScrobblerAvailability.disabled,
      };

  @override
  Future<void> updateNowPlaying(Listen listen) =>
      _submit(ListenType.playingNow, [
        listenBrainzPayload(
          listen,
          clientVersion: _clientVersion,
          withTimestamp: false,
        ),
      ]);

  @override
  Future<void> scrobble(List<Listen> listens) => _submit(
    listens.length == 1 ? ListenType.single : ListenType.import,
    [
      for (final listen in listens)
        listenBrainzPayload(listen, clientVersion: _clientVersion),
    ],
  );

  @override
  void onUnauthorized() =>
      _container.read(listenBrainzAccountProvider.notifier).markTokenRejected();

  Future<void> _submit(
    String listenType,
    List<Map<String, Object?>> payload,
  ) async {
    final account = _container.read(listenBrainzAccountProvider);
    final token = account.token;
    if (!account.isConnected || token == null) {
      throw const ScrobbleException('ListenBrainz is not connected');
    }
    await _client.submitListens(
      token: token,
      listenType: listenType,
      payload: payload,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/lastfm/lastfm_client.dart';
import 'package:jplayer/src/core/lastfm/lastfm_scrobbler.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/lastfm_account_provider.dart';

import '../../provider_container.dart';

class _StubAccount extends LastFmAccountNotifier {
  _StubAccount(super.ref, LastFmAccount initial) : super(restore: false) {
    state = initial;
  }
}

class _Call {
  const _Call(this.method, this.credentials, this.params, this.sessionKey);

  final String method;
  final LastFmCredentials credentials;
  final Map<String, String> params;
  final String sessionKey;
}

class _FakeClient extends LastFmClient {
  final calls = <_Call>[];

  @override
  Future<void> updateNowPlaying(
    LastFmCredentials credentials,
    Map<String, String> track, {
    required String sessionKey,
  }) async {
    calls.add(_Call('track.updateNowPlaying', credentials, track, sessionKey));
  }

  @override
  Future<int> scrobble(
    LastFmCredentials credentials,
    Map<String, String> tracks, {
    required String sessionKey,
  }) async {
    calls.add(_Call('track.scrobble', credentials, tracks, sessionKey));
    return 0;
  }
}

void main() {
  const credentials = LastFmCredentials(apiKey: 'key', apiSecret: 'secret');
  const connected = LastFmAccount(
    status: LastFmStatus.connected,
    credentials: credentials,
    userName: 'alex',
    sessionKey: 'sk',
  );
  final listen = Listen(
    song: const LibraryItem(
      id: 'song',
      name: 'Sour Times',
      kind: ItemKind.song,
      albumArtist: 'Portishead',
    ),
    listenedAt: DateTime.utc(2026, 9, 20, 12),
  );

  late ProviderContainer container;
  late _FakeClient client;
  late LastFmScrobbler scrobbler;

  void build(LastFmAccount initial) {
    container = createProviderContainer(
      overrides: [
        lastFmAccountProvider.overrideWith((ref) => _StubAccount(ref, initial)),
      ],
    );
    client = _FakeClient();
    scrobbler = LastFmScrobbler(container, client: client);
  }

  test('maps account status onto availability', () {
    build(connected);
    expect(
      container.read(scrobbler.availability),
      ScrobblerAvailability.enabled,
    );
    container.read(lastFmAccountProvider.notifier).markSessionRejected();
    expect(
      container.read(scrobbler.availability),
      ScrobblerAvailability.suspended,
    );
    expect(
      LastFmScrobbler.availabilityFor(
        const LastFmAccount(status: LastFmStatus.authorizing),
      ),
      ScrobblerAvailability.disabled,
    );
  });

  test('sends now playing without a timestamp using the account', () async {
    build(connected);
    await scrobbler.updateNowPlaying(listen);

    final call = client.calls.single;
    expect(call.method, 'track.updateNowPlaying');
    expect(call.credentials, credentials);
    expect(call.sessionKey, 'sk');
    expect(call.params['artist'], 'Portishead');
    expect(call.params.containsKey('timestamp'), isFalse);
  });

  test('scrobbles a batch with indexed parameters', () async {
    build(connected);
    await scrobbler.scrobble([listen, listen]);

    final call = client.calls.single;
    expect(call.method, 'track.scrobble');
    expect(call.params['timestamp[0]'], '1789905600');
    expect(call.params['track[1]'], 'Sour Times');
  });

  test('refuses to submit without a connected account', () async {
    build(const LastFmAccount(status: LastFmStatus.disconnected));
    await expectLater(
      scrobbler.updateNowPlaying(listen),
      throwsA(
        isA<ScrobbleException>().having(
          (e) => e.failure,
          'failure',
          ScrobbleFailure.unavailable,
        ),
      ),
    );
    expect(client.calls, isEmpty);
  });

  test('onUnauthorized marks the session rejected', () {
    build(connected);
    scrobbler.onUnauthorized();
    expect(
      container.read(lastFmAccountProvider).status,
      LastFmStatus.sessionRejected,
    );
  });
}

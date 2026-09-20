import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/listenbrainz/listenbrainz_client.dart';
import 'package:jplayer/src/core/listenbrainz/listenbrainz_scrobbler.dart';
import 'package:jplayer/src/core/scrobbling/listen.dart';
import 'package:jplayer/src/core/scrobbling/scrobbler.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/listenbrainz_account_provider.dart';

import '../../provider_container.dart';

class _StubAccount extends ListenBrainzAccountNotifier {
  _StubAccount(super.ref, ListenBrainzAccount initial) : super(restore: false) {
    state = initial;
  }
}

class _Submission {
  const _Submission(this.token, this.listenType, this.payload);

  final String token;
  final String listenType;
  final List<Map<String, Object?>> payload;
}

class _FakeClient extends ListenBrainzClient {
  final submissions = <_Submission>[];

  @override
  Future<void> submitListens({
    required String token,
    required String listenType,
    required List<Map<String, Object?>> payload,
  }) async {
    submissions.add(_Submission(token, listenType, payload));
  }
}

void main() {
  const connected = ListenBrainzAccount(
    status: ListenBrainzStatus.connected,
    userName: 'alex',
    token: 'secret',
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
  late ListenBrainzScrobbler scrobbler;

  void build(ListenBrainzAccount initial) {
    container = createProviderContainer(
      overrides: [
        listenBrainzAccountProvider.overrideWith(
          (ref) => _StubAccount(ref, initial),
        ),
      ],
    );
    client = _FakeClient();
    scrobbler = ListenBrainzScrobbler(
      container,
      clientVersion: '2.0',
      client: client,
    );
  }

  test('maps account status onto availability', () {
    build(connected);
    expect(
      container.read(scrobbler.availability),
      ScrobblerAvailability.enabled,
    );
    container.read(listenBrainzAccountProvider.notifier).markTokenRejected();
    expect(
      container.read(scrobbler.availability),
      ScrobblerAvailability.suspended,
    );
    expect(
      ListenBrainzScrobbler.availabilityFor(
        const ListenBrainzAccount(status: ListenBrainzStatus.loading),
      ),
      ScrobblerAvailability.disabled,
    );
  });

  test('sends now playing without a timestamp using the account', () async {
    build(connected);
    await scrobbler.updateNowPlaying(listen);

    final sent = client.submissions.single;
    expect(sent.token, 'secret');
    expect(sent.listenType, ListenType.playingNow);
    expect(sent.payload.single.containsKey('listened_at'), isFalse);
    final info =
        (sent.payload.single['track_metadata']! as Map)['additional_info']
            as Map;
    expect(info['submission_client_version'], '2.0');
  });

  test('scrobbles one listen as single and several as import', () async {
    build(connected);
    await scrobbler.scrobble([listen]);
    await scrobbler.scrobble([listen, listen]);

    expect(client.submissions[0].listenType, ListenType.single);
    expect(client.submissions[0].payload.single['listened_at'], 1789905600);
    expect(client.submissions[1].listenType, ListenType.import);
    expect(client.submissions[1].payload, hasLength(2));
  });

  test('refuses to submit without a connected account', () async {
    build(const ListenBrainzAccount(status: ListenBrainzStatus.disconnected));
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
    expect(client.submissions, isEmpty);
  });

  test('onUnauthorized marks the token rejected', () {
    build(connected);
    scrobbler.onUnauthorized();
    expect(
      container.read(listenBrainzAccountProvider).status,
      ListenBrainzStatus.tokenRejected,
    );
  });
}

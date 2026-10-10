import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:optional_features/genre_playlists.dart';

void main() {
  final at = DateTime.fromMillisecondsSinceEpoch(1700000000000);

  test('- liked songs carry the user id', () {
    final id = EphemeralPlaylistId.likedSongs('user-7');

    expect(id, 'jellybox:liked-songs:user-7');
    final parsed = EphemeralPlaylistId.parse(id)!;
    expect(parsed.kind, EphemeralPlaylistKind.likedSongs);
    expect(parsed.key, 'user-7');
    expect(EphemeralPlaylistId.isLikedSongs(id), isTrue);
    expect(EphemeralPlaylistId.parse('jellybox:liked-songs:'), isNull);
    expect(EphemeralPlaylistId.parse('jellybox:liked-songs'), isNull);
  });

  test('- instant mixes keep the seed and the moment they were made', () {
    final id = EphemeralPlaylistId.instantMix('album-1', at);

    expect(id, 'instant-mix:album-1:1700000000000');
    final parsed = EphemeralPlaylistId.parse(id)!;
    expect(parsed.kind, EphemeralPlaylistKind.instantMix);
    expect(parsed.key, 'album-1');
    expect(parsed.createdAt, at);
    expect(EphemeralPlaylistId.isInstantMix(id), isTrue);
  });

  test('- a mix saved before timestamps still parses', () {
    final parsed = EphemeralPlaylistId.parse('instant-mix:album-1')!;

    expect(parsed.kind, EphemeralPlaylistKind.instantMix);
    expect(parsed.key, 'album-1');
    expect(parsed.createdAt, isNull);
  });

  test('- a numeric seed is not mistaken for a timestamp', () {
    final parsed = EphemeralPlaylistId.parse('instant-mix:12345')!;

    expect(parsed.key, '12345');
    expect(parsed.createdAt, isNull);
  });

  test('- sound mixes keep the query', () {
    final seed = EphemeralPlaylistId.soundSeed('  Calm Piano ');
    final id = EphemeralPlaylistId.instantMix(seed, at);

    final parsed = EphemeralPlaylistId.parse(id)!;
    expect(parsed.kind, EphemeralPlaylistKind.soundMix);
    expect(parsed.key, 'calm piano');
    expect(parsed.createdAt, at);
    expect(EphemeralPlaylistId.isInstantMix(id), isTrue);
  });

  test('- genre playlists come through with their genres and stamp', () {
    final mix = genreMixId(['rock-id', 'metal-id'], at: at);
    final discovery = genreDiscoveryId(['jazz-id'], at: at);

    final parsedMix = EphemeralPlaylistId.parse(mix)!;
    expect(parsedMix.kind, EphemeralPlaylistKind.genreMix);
    expect(parsedMix.key, 'rock-id,metal-id');
    expect(parsedMix.createdAt, at);
    final parsedDiscovery = EphemeralPlaylistId.parse(discovery)!;
    expect(parsedDiscovery.kind, EphemeralPlaylistKind.genreDiscovery);
    expect(parsedDiscovery.createdAt, at);
    expect(EphemeralPlaylistId.isGenerated(mix), isTrue);
    expect(
      EphemeralPlaylistId.parse(genreMixId(['rock-id']))!.createdAt,
      isNull,
    );
  });

  test('- server ids are not ephemeral', () {
    expect(EphemeralPlaylistId.parse('3f2a9c'), isNull);
    expect(EphemeralPlaylistId.isEphemeral('playlist-1'), isFalse);
  });
}

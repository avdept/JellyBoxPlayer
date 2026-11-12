import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:jplayer/src/core/discord/discord_artwork.dart';
import 'package:jplayer/src/core/musicbrainz/cover_art_finder.dart';
import 'package:optional_features/catalog.dart';

class _MemoryStore implements CatalogCacheStore {
  final Map<String, CatalogCacheEntry> entries = {};

  @override
  Future<CatalogCacheEntry?> read(String source, String key) async =>
      entries['$source:$key'];

  @override
  Future<void> write(
    String source,
    String key,
    String json, {
    required DateTime expires,
  }) async {
    entries['$source:$key'] = CatalogCacheEntry(
      json: json,
      fetchedAt: DateTime(2026),
      expires: expires,
    );
  }
}

void main() {
  const query = CoverArtQuery(artist: 'Portishead', album: 'Dummy');
  const found = 'https://coverartarchive.org/release-group/abc/front-500';

  late DateTime now;
  late int lookups;
  late int notified;
  late Future<String?> Function(CoverArtQuery) find;
  late _MemoryStore store;

  DiscordArtwork build() => DiscordArtwork(
    find: (query) {
      lookups++;
      return find(query);
    },
    cache: store,
    now: () => now,
  )..onCoverFound = () => notified++;

  setUp(() {
    now = DateTime(2026, 11, 12);
    lookups = 0;
    notified = 0;
    find = (_) async => found;
    store = _MemoryStore();
  });

  test('returns nothing at first, then the cover once it is found', () async {
    final artwork = build();

    expect(artwork.coverFor(query), isNull);
    await pumpEventQueue();

    expect(notified, 1);
    expect(artwork.coverFor(query), found);
    expect(lookups, 1);
  });

  test('asks once while a lookup is still running', () async {
    final pending = Completer<String?>();
    find = (_) => pending.future;
    final artwork = build();

    for (var i = 0; i < 5; i++) {
      expect(artwork.coverFor(query), isNull);
    }
    await pumpEventQueue();

    expect(lookups, 1);
  });

  test('remembers an album without a cover and stays quiet', () async {
    find = (_) async => null;
    final artwork = build()..coverFor(query);
    await pumpEventQueue();

    expect(artwork.coverFor(query), isNull);
    await pumpEventQueue();

    expect(lookups, 1);
    expect(notified, 0);
  });

  test('answers from the stored cover after a restart', () async {
    build().coverFor(query);
    await pumpEventQueue();

    final restarted = build()..coverFor(query);
    await pumpEventQueue();

    expect(restarted.coverFor(query), found);
    expect(lookups, 1);
    expect(notified, 2);
  });

  test('keeps a miss for days, then looks again', () async {
    find = (_) async => null;
    build().coverFor(query);
    await pumpEventQueue();

    now = now.add(DiscordArtwork.missingLifetime - const Duration(hours: 1));
    build().coverFor(query);
    await pumpEventQueue();
    expect(lookups, 1);

    now = now.add(const Duration(hours: 2));
    build().coverFor(query);
    await pumpEventQueue();
    expect(lookups, 2);
  });

  test('looks a stored cover up again once it expires', () async {
    build().coverFor(query);
    await pumpEventQueue();

    now = now.add(DiscordArtwork.foundLifetime + const Duration(minutes: 1));
    build().coverFor(query);
    await pumpEventQueue();

    expect(lookups, 2);
  });

  test('waits before retrying a failed lookup and stores nothing', () async {
    find = (_) async => throw const CoverArtException('HTTP 503');
    final artwork = build()..coverFor(query);
    await pumpEventQueue();

    artwork.coverFor(query);
    await pumpEventQueue();
    expect(lookups, 1);
    expect(store.entries, isEmpty);

    find = (_) async => found;
    now = now.add(DiscordArtwork.retryDelay);
    artwork.coverFor(query);
    await pumpEventQueue();

    expect(lookups, 2);
    expect(artwork.coverFor(query), found);
  });

  test('shares one lookup between spellings of the same album', () async {
    final artwork = build()..coverFor(query);
    await pumpEventQueue();

    const respelled = CoverArtQuery(artist: 'PORTISHEAD', album: ' dummy!');
    expect(artwork.coverFor(respelled), found);
    expect(lookups, 1);
  });
}

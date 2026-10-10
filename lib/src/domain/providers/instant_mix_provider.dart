import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/instant_mix_database_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/storages/instant_mix_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';

const recentInstantMixesLimit = 5;

class InstantMixesNotifier extends StateNotifier<List<InstantMix>> {
  InstantMixesNotifier(this._ref, this._database, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const []) {
    restored = _restore();
  }

  final Ref _ref;
  final InstantMixDatabase _database;
  final DateTime Function() _now;
  final _fresh = <String>{};

  late final Future<void> restored;

  Future<void> _restore() async {
    final List<InstantMix> stored;
    try {
      stored = await _database.getMixes();
    } on Object {
      return;
    }
    if (!mounted) return;
    final known = {for (final mix in state) mix.item.id};
    state = [
      ...state,
      for (final mix in stored)
        if (!known.contains(mix.item.id)) mix,
    ].take(recentInstantMixesLimit).toList();
  }

  InstantMix? byId(String id) {
    for (final mix in state) {
      if (mix.item.id == id) return mix;
    }
    return null;
  }

  Future<InstantMix?> create(LibraryItem seed) async {
    final fetched = await _ref
        .read(mediaServerClientProvider)
        .getInstantMix(seed.id);
    if (fetched.isEmpty) return null;

    final songs = seed.kind == ItemKind.song
        ? [
            fetched.firstWhere(
              (song) => song.id == seed.id,
              orElse: () => seed,
            ),
            for (final song in fetched)
              if (song.id != seed.id) song,
          ]
        : fetched;

    return _register(seed, songs);
  }

  InstantMix? createSoundMix(String query, List<LibraryItem> songs) {
    if (songs.isEmpty) return null;
    return _register(soundMixSeed(query), songs);
  }

  InstantMix _register(LibraryItem seed, List<LibraryItem> songs) {
    final mix = InstantMix.create(
      seed: seed,
      songs: songs,
      createdAt: _now(),
      libraryId: _ref.read(currentLibraryProvider).valueOrNull?.id,
    );
    _fresh.add(mix.item.id);
    _remember(mix);
    return mix;
  }

  Future<void> refresh(String id) async {
    final mix = byId(id);
    if (mix == null || !_fresh.add(id)) return;
    final List<LibraryItem> songs;
    try {
      songs = await _ref.read(mediaServerClientProvider).getItemsByIds([
        for (final song in mix.songs) song.id,
      ]);
    } on Object {
      _fresh.remove(id);
      return;
    }
    if (!mounted) return;
    final current = byId(id);
    if (current != null) _setSongs(current, songs);
  }

  void touch(String id) {
    final mix = byId(id);
    if (mix != null) _remember(mix);
  }

  void updateSong(String mixId, LibraryItem updated) {
    final mix = byId(mixId);
    if (mix == null) return;
    _setSongs(mix, [
      for (final song in mix.songs)
        if (song.id == updated.id) updated else song,
    ]);
  }

  void _setSongs(InstantMix mix, List<LibraryItem> songs) {
    final updated = mix.withSongs(songs);
    state = [
      for (final other in state)
        if (other.item.id == mix.item.id) updated else other,
    ];
    _database.updateSongs(updated).ignore();
  }

  void _remember(InstantMix mix) {
    state = [
      mix,
      ...state.where((other) => other.item.id != mix.item.id),
    ].take(recentInstantMixesLimit).toList();
    _database.saveMix(mix, keep: recentInstantMixesLimit).ignore();
  }
}

final instantMixesProvider =
    StateNotifierProvider<InstantMixesNotifier, List<InstantMix>>(
      (ref) => InstantMixesNotifier(ref, ref.watch(instantMixDatabaseProvider)),
    );

final AutoDisposeProvider<List<InstantMix>> libraryInstantMixesProvider =
    Provider.autoDispose((ref) {
      final libraryId = ref.watch(currentLibraryProvider).valueOrNull?.id;
      return [
        for (final mix in ref.watch(instantMixesProvider))
          if (mix.libraryId == libraryId) mix,
      ];
    });

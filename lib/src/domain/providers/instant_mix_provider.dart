import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';

const instantMixIdPrefix = 'instant-mix:';
const recentInstantMixesLimit = 5;

bool isInstantMixId(String id) => id.startsWith(instantMixIdPrefix);

LibraryItem instantMixItem(LibraryItem seed) => LibraryItem(
  id: '$instantMixIdPrefix${seed.id}',
  name: "${seed.name}'s mix",
  kind: ItemKind.playlist,
  images: seed.images,
);

class InstantMix {
  const InstantMix({
    required this.seed,
    required this.item,
    required this.songs,
    this.libraryId,
  });

  final LibraryItem seed;
  final LibraryItem item;
  final List<LibraryItem> songs;
  final String? libraryId;

  InstantMix withSongs(List<LibraryItem> songs) => InstantMix(
    seed: seed,
    item: item,
    songs: songs,
    libraryId: libraryId,
  );
}

class InstantMixesNotifier extends StateNotifier<List<InstantMix>> {
  InstantMixesNotifier(this._ref) : super(const []);

  final Ref _ref;

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

    final mix = InstantMix(
      seed: seed,
      item: instantMixItem(seed),
      songs: songs,
      libraryId: _ref.read(currentLibraryProvider).valueOrNull?.id,
    );
    _remember(mix);
    return mix;
  }

  void touch(String id) {
    final mix = byId(id);
    if (mix != null) _remember(mix);
  }

  void updateSong(String mixId, LibraryItem updated) {
    state = [
      for (final mix in state)
        if (mix.item.id == mixId)
          mix.withSongs([
            for (final song in mix.songs)
              if (song.id == updated.id) updated else song,
          ])
        else
          mix,
    ];
  }

  void _remember(InstantMix mix) {
    state = [
      mix,
      ...state.where((other) => other.item.id != mix.item.id),
    ].take(recentInstantMixesLimit).toList();
  }
}

final instantMixesProvider =
    StateNotifierProvider<InstantMixesNotifier, List<InstantMix>>(
      InstantMixesNotifier.new,
    );

final AutoDisposeProvider<List<InstantMix>> libraryInstantMixesProvider =
    Provider.autoDispose((ref) {
      final libraryId = ref.watch(currentLibraryProvider).valueOrNull?.id;
      return [
        for (final mix in ref.watch(instantMixesProvider))
          if (mix.libraryId == libraryId) mix,
      ];
    });

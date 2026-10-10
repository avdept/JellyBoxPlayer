import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/instant_mix_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class SoundSearchNotifier extends AutoDisposeAsyncNotifier<List<LibraryItem>> {
  late MediaServerClient _client;
  var _searchTerm = '';
  String? _mixId;

  @override
  FutureOr<List<LibraryItem>> build() async {
    if (ref.watch(isOfflineProvider)) throw const OfflineException();
    _client = ref.watch(mediaServerClientProvider);
    if (!ref.watch(serverCapabilitiesProvider).soundSearch) return const [];

    final query = ref.watch(searchProvider)?.trim() ?? '';
    if (query == _searchTerm) return state.valueOrNull ?? const [];

    _searchTerm = query;
    _mixId = null;
    if (query.isEmpty) return const [];
    return _client.searchBySound(query);
  }

  InstantMix? mix() {
    final songs = state.valueOrNull;
    if (songs == null || songs.isEmpty) return null;
    final mixes = ref.read(instantMixesProvider.notifier);
    final existing = _mixId == null ? null : mixes.byId(_mixId!);
    if (existing != null) return existing;
    final created = mixes.createSoundMix(_searchTerm, songs);
    _mixId = created?.item.id;
    return created;
  }

  void updateItem(LibraryItem updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData([
      for (final item in current)
        if (item.id == updated.id) updated else item,
    ]);
  }
}

final soundSearchProvider =
    AutoDisposeAsyncNotifierProvider<SoundSearchNotifier, List<LibraryItem>>(
      SoundSearchNotifier.new,
    );

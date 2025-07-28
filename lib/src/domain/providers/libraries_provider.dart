import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/api/api.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/providers.dart';

class LibrariesNotifier extends AutoDisposeAsyncNotifier<List<ItemDTO>> {
  late JellyfinApi _api;

  @override
  FutureOr<List<ItemDTO>> build() async {
    _api = ref.watch(jellyfinApiProvider);
    state = const AsyncLoading();
    try {
      final libraries = await _api.getLibraries(
        userId: ref.read(currentUserProvider)!.userId,
      );
      return List.unmodifiable(
        libraries.data.items.where(
          (element) =>
              element.type == 'CollectionFolder' &&
              element.collectionType == 'music',
        ),
      );
    } catch (_) {
      return const [];
    }
  }
}

final librariesProvider =
    AutoDisposeAsyncNotifierProvider<LibrariesNotifier, List<ItemDTO>>(
      LibrariesNotifier.new,
    );

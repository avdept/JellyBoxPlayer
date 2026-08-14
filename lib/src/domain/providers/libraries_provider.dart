import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class LibrariesNotifier extends AutoDisposeAsyncNotifier<List<LibraryItem>> {
  late MediaServerClient _client;

  @override
  FutureOr<List<LibraryItem>> build() async {
    if (ref.watch(isOfflineProvider)) throw const OfflineException();
    _client = ref.watch(mediaServerClientProvider);
    state = const AsyncLoading();
    try {
      final libraries = await _client.getLibraries(
        userId: ref.read(currentUserProvider)!.userId,
      );
      return List.unmodifiable(
        libraries.items.where(
          (element) =>
              element.kind == ItemKind.library &&
              element.collectionType == 'music',
        ),
      );
    } catch (e) {
      print('Error in build: type=${e.runtimeType}, message=$e');
      return const [];
    }
  }
}

final librariesProvider =
    AutoDisposeAsyncNotifierProvider<LibrariesNotifier, List<LibraryItem>>(
      LibrariesNotifier.new,
    );

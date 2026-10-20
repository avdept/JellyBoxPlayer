import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/exceptions/exceptions.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/library_artwork.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';
import 'package:jplayer/src/providers/server_addresses_provider.dart';

List<LibraryItem> musicLibraries(Iterable<LibraryItem> items) =>
    List.unmodifiable(
      items.where(
        (element) =>
            element.kind == ItemKind.library &&
            element.collectionType == 'music',
      ),
    );

class LibrariesNotifier extends AutoDisposeAsyncNotifier<List<LibraryItem>> {
  late MediaServerClient _client;

  @override
  FutureOr<List<LibraryItem>> build() async {
    if (ref.watch(isOfflineProvider)) throw const OfflineException();
    if (!_hasSession) return const [];
    _client = ref.watch(mediaServerClientProvider);
    state = const AsyncLoading();
    try {
      final libraries = musicLibraries((await _client.getLibraries()).items);
      unawaited(_remember(libraries));
      return libraries;
    } catch (e) {
      print('Error in build: type=${e.runtimeType}, message=$e');
      return const [];
    }
  }

  Future<void> _remember(List<LibraryItem> libraries) async {
    final serverId = ref.read(currentServerIdProvider);
    if (serverId == null || !ref.exists(authProvider)) return;
    try {
      final saved = savedLibraries(
        libraries,
        imageOf: ref.read(imageServiceProvider).itemUri,
        addresses: ref.read(serverAddressesProvider)?.candidates ?? const [],
      );
      await ref.read(authProvider.notifier).rememberLibraries(serverId, saved);
      await prefetchLibraryArtwork(saved);
    } on Object {
      return;
    }
  }

  bool get _hasSession {
    final user = ref.watch(currentUserProvider);
    final baseUrl = ref.watch(baseUrlProvider);
    return user != null &&
        user.userId.isNotEmpty &&
        baseUrl != null &&
        baseUrl.isNotEmpty;
  }
}

final librariesProvider =
    AutoDisposeAsyncNotifierProvider<LibrariesNotifier, List<LibraryItem>>(
      LibrariesNotifier.new,
    );

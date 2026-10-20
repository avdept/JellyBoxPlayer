import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/data/backend/media_server_backends.dart';
import 'package:jplayer/src/data/backend/server_auth_headers.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/data/services/library_artwork.dart';
import 'package:jplayer/src/data/storages/account_store.dart';
import 'package:jplayer/src/domain/providers/libraries_provider.dart';
import 'package:jplayer/src/providers/accounts_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';

final AutoDisposeFutureProviderFamily<List<SavedLibrary>, String>
accountLibrariesProvider = FutureProvider.autoDispose
    .family<List<SavedLibrary>, String>((ref, serverId) async {
      final link = ref.keepAlive();
      final expiry = Timer(const Duration(minutes: 10), link.close);
      ref.onDispose(expiry.cancel);
      ServerAccount? find(List<ServerAccount> accounts) =>
          accounts.where((account) => account.serverId == serverId).firstOrNull;
      ref.watch(
        accountsProvider.select((accounts) {
          final account = find(accounts);
          return (
            account?.url,
            account?.remoteUrl,
            account?.relayUrl,
            account?.token,
            account?.needsReauth,
          );
        }),
      );
      final account = find(ref.read(accountsProvider));
      if (account == null || account.needsReauth) return const [];

      final shared = ref.read(dioProvider);
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          contentType: shared.options.contentType,
          headers: authHeadersFor(
            account.serverType,
            deviceId: deviceId,
            deviceName: getCurrentPlatformName(),
            version: appInfo.version,
          ).build(token: account.token),
        ),
      )..httpClientAdapter = shared.httpClientAdapter;

      final addresses = [account.url, ?account.remoteUrl, ?account.relayUrl];
      for (final url in addresses) {
        try {
          final client = clientFor(
            account.serverType,
            dio: dio,
            baseUrl: url,
            userId: account.userId,
            token: account.token,
            deviceId: deviceId,
          );
          final page = await client.getLibraries().timeout(
            const Duration(seconds: 8),
          );
          final saved = savedLibraries(
            musicLibraries(page.items),
            imageOf: (library) =>
                library.images.hasCover ? client.imageUri(library) : null,
            addresses: addresses,
          );
          if (ref.exists(authProvider)) {
            unawaited(
              ref
                  .read(authProvider.notifier)
                  .rememberLibraries(serverId, saved)
                  .then((_) => prefetchLibraryArtwork(saved)),
            );
          }
          return saved;
        } on Exception {
          continue;
        }
      }
      return account.libraries;
    });

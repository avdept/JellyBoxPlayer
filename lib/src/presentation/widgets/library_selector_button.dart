import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/data/services/artwork_cache.dart';
import 'package:jplayer/src/data/storages/account_store.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/widgets/app_dropdown.dart';
import 'package:jplayer/src/presentation/widgets/server_accounts.dart';
import 'package:jplayer/src/providers/accounts_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/current_server_id_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

@immutable
sealed class _Choice {
  const _Choice();
}

final class _Server extends _Choice {
  const _Server(this.serverId);

  final String serverId;

  @override
  bool operator ==(Object other) =>
      other is _Server && other.serverId == serverId;

  @override
  int get hashCode => serverId.hashCode;
}

final class _Library extends _Choice {
  const _Library(this.serverId, this.library);

  final String serverId;
  final LibraryItem? library;

  @override
  bool operator ==(Object other) =>
      other is _Library &&
      other.serverId == serverId &&
      other.library?.id == library?.id;

  @override
  int get hashCode => Object.hash(serverId, library?.id);
}

final class _AddServer extends _Choice {
  const _AddServer();

  @override
  bool operator ==(Object other) => other is _AddServer;

  @override
  int get hashCode => 0;
}

class LibrarySelectorButton extends ConsumerWidget {
  const LibrarySelectorButton({
    required this.size,
    this.showName = false,
    this.maxNameWidth = 180,
    super.key,
  });

  final double size;
  final bool showName;
  final double maxNameWidth;

  Widget _avatar(
    WidgetRef ref,
    ThemeData theme,
    LibraryItem? library,
    double size,
  ) {
    final image = (library != null)
        ? ref.read(imageServiceProvider).itemImageOrNull(library)
        : null;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.surface,
      backgroundImage: image,
      child: image == null ? Icon(Icons.library_music, size: size / 2) : null,
    );
  }

  Widget _customButton(WidgetRef ref, ThemeData theme, LibraryItem? library) {
    final avatar = _avatar(ref, theme, library, size);
    final name = library?.name;
    if (!showName || name == null || name.isEmpty) return avatar;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxNameWidth),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size >= 40 ? 18 : 16,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  List<AppDropdownEntry<_Choice>> _activeEntries(
    WidgetRef ref,
    ThemeData theme,
    String serverId,
    List<LibraryItem> libraries,
  ) => [
    for (final lib in libraries)
      AppDropdownEntry(
        value: _Library(serverId, lib),
        label: lib.name,
        leadingBuilder: (color) => _avatar(ref, theme, lib, 28),
      ),
  ];

  List<AppDropdownEntry<_Choice>> _otherEntries(
    WidgetRef ref,
    ThemeData theme,
    ServerAccount account,
  ) {
    if (account.needsReauth) {
      return [
        AppDropdownEntry(
          value: _Server(account.serverId),
          label: 'Sign in again',
          leadingBuilder: (color) => Icon(Icons.login, size: 20, color: color),
        ),
      ];
    }
    final fetched = ref
        .watch(accountLibrariesProvider(account.serverId))
        .valueOrNull;
    final known = fetched == null || fetched.isEmpty
        ? account.libraries
        : fetched;
    final libraries = known.isNotEmpty
        ? known
        : [
            if (account.libraryId case final id?)
              SavedLibrary(
                id: id,
                name: account.libraryName ?? '',
                path: account.libraryPath,
              ),
          ];
    if (libraries.isEmpty) {
      return [
        AppDropdownEntry(
          value: _Server(account.serverId),
          label: 'Open',
          leadingBuilder: (color) =>
              Icon(Icons.dns_outlined, size: 20, color: color),
        ),
      ];
    }
    return [
      for (final lib in libraries)
        AppDropdownEntry(
          value: _Library(account.serverId, lib.toItem()),
          label: lib.name,
          leadingBuilder: (color) => _savedAvatar(theme, lib, 28),
        ),
    ];
  }

  Widget _savedAvatar(ThemeData theme, SavedLibrary library, double size) {
    final url = library.imageUrl;
    final image = url == null
        ? null
        : CachedNetworkImageProvider(
            url,
            cacheKey: library.imageKey,
            cacheManager: ArtworkCache.instance,
          );
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.surface,
      backgroundImage: image,
      onBackgroundImageError: image == null ? null : (_, _) {},
      child: image == null ? Icon(Icons.library_music, size: size / 2) : null,
    );
  }

  Widget _logoutButton(
    BuildContext context,
    WidgetRef ref,
    ServerAccount account,
    Color color,
  ) => Builder(
    builder: (menuContext) => IconButton(
      onPressed: () {
        Navigator.of(menuContext).pop();
        unawaited(confirmRemoveAccount(context, ref, account));
      },
      tooltip: 'Log out of ${account.displayName}',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      iconSize: 16,
      icon: Icon(Icons.logout, color: color),
    ),
  );

  void _onChanged(
    BuildContext context,
    WidgetRef ref,
    _Choice choice,
    String? activeId,
  ) {
    switch (choice) {
      case _Library(:final serverId, :final library?) when serverId == activeId:
        unawaited(
          ref.read(currentLibraryProvider.notifier).setLibrary(library),
        );
      case _Library(:final serverId, :final library):
        unawaited(
          ref.read(authProvider.notifier).switchTo(serverId, library: library),
        );
      case _Server(:final serverId):
        unawaited(ref.read(authProvider.notifier).switchTo(serverId));
      case _AddServer():
        unawaited(context.push(Routes.addServer.path));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = ref.watch(currentLibraryProvider).valueOrNull;
    final libraries =
        ref.watch(librariesProvider).valueOrNull ?? const <LibraryItem>[];
    final accounts = ref.watch(accountsProvider);
    final activeId = ref.watch(currentServerIdProvider) ?? '';

    // The library restored from prefs carries no imageTags, so resolve the
    // full DTO from librariesProvider (by id) to show the real cover image.
    final selected = libraries.firstWhereOrNull((l) => l.id == current?.id);

    final entries = <AppDropdownEntry<_Choice>>[
      if (accounts.length < 2)
        ..._activeEntries(ref, theme, activeId, libraries)
      else
        for (final account in accounts) ...[
          AppDropdownEntry.header(
            value: _Server('header:${account.serverId}'),
            label: account.displayName,
            leadingBuilder: (_) => ServerLogo(account: account),
            trailingBuilder: (color) =>
                _logoutButton(context, ref, account, color),
          ),
          if (account.serverId == activeId)
            ..._activeEntries(ref, theme, activeId, libraries)
          else
            ..._otherEntries(ref, theme, account),
        ],
      AppDropdownEntry(
        value: const _AddServer(),
        label: 'Add server',
        leadingBuilder: (color) => Icon(Icons.add, size: 20, color: color),
      ),
    ];
    final value = _Library(activeId, selected);

    return AppDropdown<_Choice>(
      width: 240,
      value: entries.any((entry) => entry.value == value) ? value : null,
      buttonBuilder: (isOpened) =>
          _customButton(ref, theme, selected ?? current),
      onChanged: (choice) => _onChanged(context, ref, choice, activeId),
      entries: entries,
    );
  }
}

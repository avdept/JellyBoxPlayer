import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

ImageProvider pinnedItemCover(
  WidgetRef ref,
  PinnedItem pin, {
  required int size,
}) {
  final local = DownloadPaths.coverFile(pin.itemId)?.uri;
  return ref
      .read(imageServiceProvider)
      .artworkImage(local ?? pin.imageUrl, size: size);
}

String pinnedItemKindLabel(ItemKind kind) => switch (kind) {
  ItemKind.song => 'Song',
  ItemKind.album => 'Album',
  ItemKind.artist => 'Artist',
  ItemKind.playlist => 'Playlist',
  _ => '',
};

Future<LibraryItem?> resolvePinnedItem(
  WidgetRef ref,
  PinnedItem pin, {
  ScaffoldMessengerState? messenger,
}) async {
  void notify(String message) =>
      messenger?.showSnackBar(SnackBar(content: Text(message)));
  if (ref.read(isOfflineProvider)) {
    notify('Not available offline');
    return null;
  }
  try {
    return await ref
        .read(mediaServerClientProvider)
        .getItem(pin.itemId, kind: pin.kind);
  } on Object {
    notify('Could not open "${pin.name}"');
    return null;
  }
}

Future<void> playResolvedPinnedItem(
  WidgetRef ref,
  LibraryItem item, {
  ScaffoldMessengerState? messenger,
}) async {
  final notifier = ref.read(setPlaybackProvider.notifier);
  try {
    final result = await switch (item.kind) {
      ItemKind.album => notifier.playAlbum(item),
      ItemKind.artist => notifier.playArtist(item),
      ItemKind.playlist => notifier.playPlaylist(item),
      ItemKind.song => notifier.playSongs(item, [item]),
      _ => Future.value(SetPlaybackResult.busy),
    };
    if (result == SetPlaybackResult.empty) {
      messenger?.showSnackBar(
        SnackBar(content: Text('Nothing to play in "${item.name}"')),
      );
    }
  } on Object {
    messenger?.showSnackBar(
      SnackBar(content: Text('Could not start playing "${item.name}"')),
    );
  }
}

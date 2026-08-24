import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/domain/models/models.dart';

class ImageService {
  ImageService({required MediaServerClient Function() client})
    : _client = client;

  final MediaServerClient Function() _client;

  static const _sizeParams = {
    'fillwidth',
    'fillheight',
    'maxwidth',
    'maxheight',
  };

  static Uri resize(Uri uri, int size) {
    final params = uri.queryParameters;
    if (params.isEmpty) return uri;
    return uri.replace(
      queryParameters: {
        for (final entry in params.entries)
          entry.key: _sizeParams.contains(entry.key.toLowerCase())
              ? '$size'
              : entry.value,
      },
    );
  }

  static ImageProvider? uriImageOrNull(Uri? uri, {int? size}) {
    if (uri == null) return null;
    if (uri.isScheme('file')) return FileImage(File.fromUri(uri));
    return CachedNetworkImageProvider(
      (size != null ? resize(uri, size) : uri).toString(),
    );
  }

  static ImageProvider uriImage(
    Uri? uri, {
    int? size,
    String fallback = Images.album,
  }) => uriImageOrNull(uri, size: size) ?? AssetImage(fallback);

  Uri? itemUri(
    LibraryItem item, {
    ImageKind kind = ImageKind.primary,
    int? size,
  }) {
    if (kind == ImageKind.backdrop) {
      return remoteImageUri(
        id: item.id,
        tagId: item.images.backdrops.firstOrNull,
        kind: kind,
        size: size,
      );
    }

    final downloaded =
        DownloadPaths.coverFile(item.coverImageId) ??
        DownloadPaths.coverFile(item.albumId);
    if (downloaded != null) return downloaded.uri;

    return remoteImageUri(
      id: item.coverImageId,
      tagId: item.coverImageTag,
      kind: kind,
      size: size,
    );
  }

  ImageProvider? itemImageOrNull(
    LibraryItem item, {
    ImageKind kind = ImageKind.primary,
    int? size,
  }) => uriImageOrNull(itemUri(item, kind: kind, size: size));

  ImageProvider itemImage(
    LibraryItem item, {
    ImageKind kind = ImageKind.primary,
    int? size,
    String fallback = Images.album,
  }) => itemImageOrNull(item, kind: kind, size: size) ?? AssetImage(fallback);

  Uri? remoteImageUri({
    required String id,
    required String? tagId,
    ImageKind kind = ImageKind.primary,
    int? size,
  }) {
    if (tagId == null) return null;
    return Uri.parse(
      (size == null)
          ? _client().imageUrl(id: id, tagId: tagId, kind: kind)
          : _client().imageUrl(id: id, tagId: tagId, kind: kind, size: size),
    );
  }
}

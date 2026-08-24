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

  Uri? itemUri(
    LibraryItem item, {
    ImageKind kind = ImageKind.primary,
    int? size,
  }) {
    if (kind == ImageKind.backdrop) {
      if (!item.images.hasBackdrop) return null;
      return _client().imageUri(item, kind: kind, size: size);
    }

    final downloaded = DownloadPaths.coverFile(item.albumId ?? item.id);
    if (downloaded != null) return downloaded.uri;
    if (!item.images.hasCover) return null;

    return _client().imageUri(item, kind: kind, size: size);
  }

  ImageProvider? itemImageOrNull(
    LibraryItem item, {
    ImageKind kind = ImageKind.primary,
    int? size,
  }) => _imageOf(itemUri(item, kind: kind, size: size));

  ImageProvider itemImage(
    LibraryItem item, {
    ImageKind kind = ImageKind.primary,
    int? size,
    String fallback = Images.album,
  }) => itemImageOrNull(item, kind: kind, size: size) ?? AssetImage(fallback);

  ImageProvider? artworkImageOrNull(Uri? uri, {int? size}) {
    if (uri == null || uri.isScheme('file') || size == null) {
      return _imageOf(uri);
    }
    return _imageOf(_client().resizedImageUri(uri, size));
  }

  ImageProvider artworkImage(
    Uri? uri, {
    int? size,
    String fallback = Images.album,
  }) => artworkImageOrNull(uri, size: size) ?? AssetImage(fallback);

  ImageProvider? _imageOf(Uri? uri) {
    if (uri == null) return null;
    if (uri.isScheme('file')) return FileImage(File.fromUri(uri));
    return CachedNetworkImageProvider(uri.toString());
  }
}

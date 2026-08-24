import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/data/services/image_service.dart';

ImageProvider artworkImage(Uri? artUri, {int? size}) {
  if (artUri == null) return const AssetImage(Images.album);
  if (artUri.isScheme('file')) return FileImage(File.fromUri(artUri));
  final uri = size != null ? ImageService.resize(artUri, size) : artUri;
  return CachedNetworkImageProvider(uri.toString());
}

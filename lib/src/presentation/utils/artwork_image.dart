import 'dart:io' show File;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:jplayer/resources/resources.dart';

ImageProvider artworkImage(Uri? artUri) {
  if (artUri == null) return const AssetImage(Images.album);
  if (artUri.isScheme('file')) return FileImage(File.fromUri(artUri));
  return CachedNetworkImageProvider(artUri.toString());
}

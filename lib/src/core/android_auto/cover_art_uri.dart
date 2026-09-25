import 'dart:convert';

import 'package:crypto/crypto.dart';

const coverArtAuthority = 'com.prodigytech.jellybox.covers';
const coverArtChannel = 'com.prodigytech.jellybox/cover_art';
const remoteCoverSegment = 'remote';

class RemoteCoverArt {
  RemoteCoverArt({this.capacity = 2000});

  final int capacity;
  final _urls = <String, String>{};

  Uri register(Uri uri) {
    final url = uri.toString();
    final key = sha1.convert(utf8.encode(url)).toString();
    _urls
      ..remove(key)
      ..[key] = url;
    while (_urls.length > capacity) {
      _urls.remove(_urls.keys.first);
    }
    return Uri(
      scheme: 'content',
      host: coverArtAuthority,
      pathSegments: [remoteCoverSegment, key],
    );
  }

  String? urlFor(String key) => _urls[key];
}

Uri? androidCoverArtUri(Uri? uri, {RemoteCoverArt? remote}) {
  if (uri == null) return null;
  if (remote != null && (uri.isScheme('http') || uri.isScheme('https'))) {
    return remote.register(uri);
  }
  if (!uri.isScheme('file')) return uri;
  final segments = uri.pathSegments;
  if (segments.length < 2) return null;
  return Uri(
    scheme: 'content',
    host: coverArtAuthority,
    pathSegments: [segments[segments.length - 2]],
  );
}

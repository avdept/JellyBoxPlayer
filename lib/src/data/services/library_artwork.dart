import 'package:jplayer/src/data/services/artwork_cache.dart';
import 'package:jplayer/src/data/storages/account_store.dart';
import 'package:jplayer/src/domain/models/models.dart';

List<SavedLibrary> savedLibraries(
  List<LibraryItem> libraries, {
  required Uri? Function(LibraryItem library) imageOf,
  required List<String> addresses,
}) {
  final route = ArtworkRoute(addresses: addresses);
  return [
    for (final library in libraries)
      _saved(library, _networkUrl(imageOf(library)), route),
  ];
}

SavedLibrary _saved(LibraryItem library, String? url, ArtworkRoute route) =>
    SavedLibrary(
      id: library.id,
      name: library.name,
      path: library.path,
      imageUrl: url,
      imageKey: url == null ? null : route.keyFor(url),
    );

Future<void> prefetchLibraryArtwork(List<SavedLibrary> libraries) async {
  for (final library in libraries) {
    final url = library.imageUrl;
    final key = library.imageKey;
    if (url == null || key == null) continue;
    try {
      if (await ArtworkCache.instance.getFileFromCache(key) != null) continue;
      await ArtworkCache.instance.downloadFile(url, key: key);
    } on Object {
      continue;
    }
  }
}

String? _networkUrl(Uri? uri) =>
    uri != null && (uri.isScheme('http') || uri.isScheme('https'))
    ? uri.toString()
    : null;

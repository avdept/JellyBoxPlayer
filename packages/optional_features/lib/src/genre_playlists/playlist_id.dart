const genreMixIdPrefix = 'jellybox:genre-mix:';
const genreDiscoveryIdPrefix = 'jellybox:genre-discovery:';

final _stamp = RegExp(r':(\d+)$');

String _encodeGenreIds(List<String> genreIds) =>
    genreIds.map(Uri.encodeComponent).join(',');

String _stamped(String id, DateTime? at) =>
    at == null ? id : '$id:${at.millisecondsSinceEpoch}';

String genreMixId(List<String> genreIds, {DateTime? at}) =>
    _stamped('$genreMixIdPrefix${_encodeGenreIds(genreIds)}', at);

String genreDiscoveryId(List<String> genreIds, {DateTime? at}) =>
    _stamped('$genreDiscoveryIdPrefix${_encodeGenreIds(genreIds)}', at);

bool isDiscoveryPlaylistId(String id) => id.startsWith(genreDiscoveryIdPrefix);

bool isGeneratedPlaylistId(String id) =>
    id.startsWith(genreMixIdPrefix) || isDiscoveryPlaylistId(id);

String _genrePart(String playlistId) {
  final prefix = isDiscoveryPlaylistId(playlistId)
      ? genreDiscoveryIdPrefix
      : genreMixIdPrefix;
  final body = playlistId.substring(prefix.length);
  final stamp = _stamp.firstMatch(body);
  return stamp == null || stamp.start == 0
      ? body
      : body.substring(0, stamp.start);
}

DateTime? generatedPlaylistCreatedAt(String playlistId) {
  if (!isGeneratedPlaylistId(playlistId)) return null;
  final body = playlistId.substring(
    (isDiscoveryPlaylistId(playlistId)
            ? genreDiscoveryIdPrefix
            : genreMixIdPrefix)
        .length,
  );
  final stamp = _stamp.firstMatch(body);
  if (stamp == null || stamp.start == 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(int.parse(stamp.group(1)!));
}

List<String> genreIdsOf(String playlistId) => [
  for (final part in _genrePart(playlistId).split(','))
    if (part.isNotEmpty) Uri.decodeComponent(part),
];

const genreMixIdPrefix = 'jellybox:genre-mix:';
const genreDiscoveryIdPrefix = 'jellybox:genre-discovery:';

String _encodeGenreIds(List<String> genreIds) =>
    genreIds.map(Uri.encodeComponent).join(',');

String genreMixId(List<String> genreIds) =>
    '$genreMixIdPrefix${_encodeGenreIds(genreIds)}';

String genreDiscoveryId(List<String> genreIds) =>
    '$genreDiscoveryIdPrefix${_encodeGenreIds(genreIds)}';

bool isDiscoveryPlaylistId(String id) => id.startsWith(genreDiscoveryIdPrefix);

bool isGeneratedPlaylistId(String id) =>
    id.startsWith(genreMixIdPrefix) || isDiscoveryPlaylistId(id);

List<String> genreIdsOf(String playlistId) {
  final prefix = isDiscoveryPlaylistId(playlistId)
      ? genreDiscoveryIdPrefix
      : genreMixIdPrefix;
  return [
    for (final part in playlistId.substring(prefix.length).split(','))
      if (part.isNotEmpty) Uri.decodeComponent(part),
  ];
}

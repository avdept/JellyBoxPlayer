enum Routes {
  login('/login'),
  library('/library'),
  settings('/settings'),
  downloads('/downloads'),
  browse('/browse'),
  album('album'),
  artist('artist'),
  genre('genre'),
  palette('palette'),
  searchResults('search-results'),
  playlist('playlist');

  const Routes(this.path);

  final String path;
}

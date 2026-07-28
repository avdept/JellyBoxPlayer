enum Routes {
  login('/login'),
  library('/library'),
  search('/search'),
  settings('/settings'),
  downloads('/downloads'),
  listen('/listen'),
  album('album'),
  artist('artist'),
  genre('genre'),
  palette('palette'),
  playlist('playlist');

  const Routes(this.path);

  final String path;
}

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

enum Routes {
  login('/login'),
  library('/library'),
  settings('/settings'),
  downloads('/downloads'),
  home('/home'),
  browse('/browse'),
  album('album'),
  artist('artist'),
  genre('genre'),
  palette('palette'),
  searchResults('search-results'),
  playlist('playlist'),
  favourites('favourites'),
  favouriteSongs('favourite-songs'),
  homeAlbum('album'),
  homeArtist('artist'),
  homeGenre('genre'),
  homePlaylist('playlist'),
  homeFavourites('favourites'),
  homeFavouriteSongs('favourite-songs');

  const Routes(this.path);

  final String path;
}

String branchAwareName(BuildContext context, Routes route) {
  final inHomeBranch = GoRouterState.of(
    context,
  ).matchedLocation.startsWith(Routes.home.path);
  if (!inHomeBranch) return route.name;

  return switch (route) {
    Routes.album => Routes.homeAlbum.name,
    Routes.artist => Routes.homeArtist.name,
    Routes.genre => Routes.homeGenre.name,
    Routes.playlist => Routes.homePlaylist.name,
    Routes.favourites => Routes.homeFavourites.name,
    Routes.favouriteSongs => Routes.homeFavouriteSongs.name,
    _ => route.name,
  };
}

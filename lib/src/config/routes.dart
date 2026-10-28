import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

enum Routes {
  login('/login'),
  addServer('/add-server'),
  library('/library'),
  settings('/settings'),
  downloads('/downloads'),
  home('/home'),
  browse('/browse'),
  album('album'),
  artist('artist'),
  catalogArtist('catalog-artist'),
  catalogAlbum('catalog-album'),
  genre('genre'),
  palette('palette'),
  queueCache('queue-cache'),
  support('support'),
  searchResults('search-results'),
  playlist('playlist'),
  favourites('favourites'),
  favouriteSongs('favourite-songs'),
  onRepeat('on-repeat'),
  instantMix('instant-mix'),
  homeAlbum('album'),
  homeArtist('artist'),
  homeCatalogArtist('catalog-artist'),
  homeCatalogAlbum('catalog-album'),
  homeGenre('genre'),
  homeGeneratedPlaylist('generated-playlist'),
  homeInstantMix('instant-mix'),
  homePlaylist('playlist'),
  homeFavourites('favourites'),
  homeFavouriteSongs('favourite-songs'),
  homeOnRepeat('on-repeat');

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
    Routes.catalogArtist => Routes.homeCatalogArtist.name,
    Routes.catalogAlbum => Routes.homeCatalogAlbum.name,
    Routes.genre => Routes.homeGenre.name,
    Routes.playlist => Routes.homePlaylist.name,
    Routes.favourites => Routes.homeFavourites.name,
    Routes.favouriteSongs => Routes.homeFavouriteSongs.name,
    Routes.onRepeat => Routes.homeOnRepeat.name,
    Routes.instantMix => Routes.homeInstantMix.name,
    _ => route.name,
  };
}

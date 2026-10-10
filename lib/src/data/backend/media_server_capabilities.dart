import 'package:jplayer/src/core/enums/enums.dart';

class MediaServerCapabilities {
  const MediaServerCapabilities({
    this.lyrics = true,
    this.similarAlbums = true,
    this.playlistSearch = true,
    this.playlistFavourites = true,
    this.soundSearch = false,
    this.artistScopes = const {ArtistScope.albumArtists},
  });

  final bool lyrics;
  final bool similarAlbums;
  final bool playlistSearch;
  final bool playlistFavourites;
  final bool soundSearch;
  final Set<ArtistScope> artistScopes;

  MediaServerCapabilities copyWith({
    bool? lyrics,
    bool? similarAlbums,
    bool? playlistSearch,
    bool? playlistFavourites,
    bool? soundSearch,
    Set<ArtistScope>? artistScopes,
  }) => MediaServerCapabilities(
    lyrics: lyrics ?? this.lyrics,
    similarAlbums: similarAlbums ?? this.similarAlbums,
    playlistSearch: playlistSearch ?? this.playlistSearch,
    playlistFavourites: playlistFavourites ?? this.playlistFavourites,
    soundSearch: soundSearch ?? this.soundSearch,
    artistScopes: artistScopes ?? this.artistScopes,
  );
}

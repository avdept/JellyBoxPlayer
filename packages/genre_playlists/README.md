# genre_playlists

Stub package. Defines the interface JellyBox uses to build "Made for you"
genre mixes (`GenrePlaylistSource`, `SongTraits`, `GenrePlaylistGenerator`)
and the playlist id helpers, but generates nothing: `generate` and `songsFor`
return empty lists, so public builds simply show no mixes.

The real generation policy lives in a private package with the same API and is
swapped in through `pubspec_overrides.yaml` (see `pubspec_overrides.yaml.example`
at the repository root).

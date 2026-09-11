import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/domain/models/models.dart';

enum SessionStatus { valid, invalid, unreachable }

abstract class MediaServerClient {
  MediaServerCapabilities get capabilities;

  Future<MediaServerCapabilities> resolveCapabilities();

  Future<LibraryPage> getAlbums(LibraryQuery query);

  Future<LibraryPage> getArtists(LibraryQuery query);

  Future<LibraryPage> getGenres(LibraryQuery query);

  Future<LibraryPage> getPlaylists(LibraryQuery query);

  Future<LibraryPage> getAllSongs(LibraryQuery query);

  Future<LibraryPage> getSongsOfSet(LibraryQuery query);

  Future<LibraryPage> getSongs(String albumId);

  Future<LibraryPage> getPlaylistSongs(String playlistId);

  Future<LibraryPage> getSimilarAlbums(String albumId, {int limit = 12});

  Future<List<GeneratedPlaylist>> generateTodaysPlaylists({
    String? libraryId,
    bool includeDiscovery = false,
  });

  Future<List<LibraryItem>> getGeneratedPlaylistSongs({
    required String playlistId,
    String? libraryId,
  });

  Future<LibraryPage> getLibraries();

  Future<LibraryItem> getItem(String itemId, {required ItemKind kind});

  Future<LibraryPage> searchAlbums(SearchQuery query);

  Future<LibraryPage> searchArtists(SearchQuery query);

  Future<LibraryPage> searchSongs(SearchQuery query);

  Future<LibraryPage> searchPlaylists(SearchQuery query);

  Future<void> setFavorite(String itemId, {required bool favorite});

  Future<void> createPlaylist(PlaylistData values);

  Future<void> deletePlaylist(String playlistId);

  Future<void> addPlaylistItems({
    required String playlistId,
    required List<String> itemIds,
  });

  Future<void> removePlaylistItem({
    required String playlistId,
    required String entryId,
  });

  Future<Lyrics?> getLyrics(String itemId);

  Future<StreamSource> resolveStreamSource(
    LibraryItem song, {
    required String playSessionId,
    required StreamTargetProfile target,
  });

  Uri? imageUri(
    LibraryItem item, {
    ImageKind kind = ImageKind.primary,
    int? size,
  });

  Uri resizedImageUri(Uri uri, int size);

  Future<void> reportPlaybackStarted(PlaybackReport report);

  Future<void> reportPlaybackProgress(PlaybackReport report);

  Future<void> reportPlaybackStopped(PlaybackReport report);

  Future<SessionStatus> validateSession();

  Future<void> signOut();
}

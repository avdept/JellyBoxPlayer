import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/domain/models/models.dart';

enum SessionStatus { valid, invalid, unreachable }

abstract class MediaServerClient {
  Future<LibraryPage> getAlbums({
    required String userId,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'DateCreated,SortName',
    String? contributingArtistIds,
    String sortOrder = 'Descending',
    List<String> artistIds = const [],
    List<String> genreIds = const [],
    List<String> filters = const [],
    List<String> ids = const [],
  });

  Future<LibraryPage> getArtists({
    required String userId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'SortName',
    String sortOrder = 'Descending',
    List<String> filters = const [],
  });

  Future<LibraryPage> getGenres({
    required String userId,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
  });

  Future<LibraryPage> getPlaylists({
    required String userId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'DateCreated,SortName',
    String? contributingArtistIds,
    String sortOrder = 'Descending',
    List<String> artistIds = const [],
  });

  Future<LibraryPage> getAllSongs({
    required String userId,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortBy = 'SortName',
    String sortOrder = 'Ascending',
    List<String> filters = const [],
    List<String> fields = const ['MediaSources'],
  });

  Future<LibraryPage> getSongs({
    required String userId,
    required String albumId,
  });

  Future<LibraryPage> getSongsOfSet({
    required String userId,
    String? libraryId,
    List<String> artistIds = const [],
    List<String> genreIds = const [],
    List<String> filters = const [],
    String sortBy = 'AlbumArtist,Album,ParentIndexNumber,IndexNumber',
    String sortOrder = 'Ascending',
    String startIndex = '0',
    String limit = '300',
    List<String> fields = const ['MediaSources'],
  });

  Future<LibraryPage> getPlaylistSongs({
    required String userId,
    required String playlistId,
  });

  Future<LibraryPage> getSimilarAlbums({
    required String userId,
    required String albumId,
    String limit = '12',
  });

  Future<List<GeneratedPlaylist>> generateTodaysPlaylists({
    required String userId,
    String? libraryId,
    bool includeDiscovery = false,
  });

  Future<List<LibraryItem>> getGeneratedPlaylistSongs({
    required String userId,
    required String playlistId,
    String? libraryId,
  });

  Future<LibraryPage> getLibraries({required String userId});

  Future<LibraryItem> getItem(String itemId);

  Future<LibraryPage> searchAlbums({
    required String userId,
    required String searchTerm,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
  });

  Future<LibraryPage> searchArtists({
    required String userId,
    required String searchTerm,
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
  });

  Future<LibraryPage> searchSongs({
    required String userId,
    required String searchTerm,
    String? libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
  });

  Future<LibraryPage> searchPlaylists({
    required String userId,
    required String searchTerm,
    required String libraryId,
    String startIndex = '0',
    String limit = '100',
    String sortOrder = 'Descending',
  });

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

  Future<LyricsDTO> getLyrics(String itemId);

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

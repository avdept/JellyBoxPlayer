import 'dart:math';

import 'package:dio/dio.dart';
import 'package:jplayer/src/core/audio/audio_container_mime.dart';
import 'package:jplayer/src/core/audio/audio_stream_profile.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/data/api/subsonic/subsonic_api.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/media_server_exception.dart';
import 'package:jplayer/src/data/backend/playback_report.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/backend/subsonic/mappers/subsonic_item_mapper.dart';
import 'package:jplayer/src/data/backend/subsonic/mappers/subsonic_lyrics_mapper.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_credentials.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_envelope_interceptor.dart';
import 'package:jplayer/src/data/backend/genre_playlists.dart';
import 'package:jplayer/src/data/backend/subsonic/subsonic_query.dart';
import 'package:jplayer/src/data/dto/subsonic/subsonic_dto.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/domain/models/models.dart';

class SubsonicClient implements MediaServerClient {
  SubsonicClient({
    required Dio dio,
    required String baseUrl,
    required this.userId,
    required this.token,
    required this.deviceId,
    Random? random,
    DateTime Function()? now,
  }) : _api = SubsonicApi(
         dio,
         baseUrl: baseUrl,
         credentials: SubsonicCredentials.decode(
           username: userId,
           encodedToken: token,
         ),
       ),
       _random = random ?? Random(),
       _now = now ?? DateTime.now {
    SubsonicEnvelopeInterceptor.install(dio);
  }

  static const songLyricsExtension = 'songLyrics';
  static const playbackReportExtension = 'playbackReport';
  static const directPlayFormat = 'raw';
  static const lossyTranscodeFormat = 'mp3';
  static const losslessTranscodeFormat = 'flac';
  static const transcodeBitRate = 320;
  static const artistIndexTtl = Duration(seconds: 60);
  static const extensionRetryInterval = Duration(minutes: 5);
  static const playedAlbumsScanLimit = 25;
  static const genreSetScanLimit = 500;
  static const minimumPlayDuration = Duration(minutes: 4);

  static const _defaultImageSize = 420;
  static const _albumFanOut = 8;
  static const _baseCapabilities = MediaServerCapabilities(
    similarAlbums: false,
  );

  final SubsonicApi _api;
  final String userId;
  final String token;
  final String deviceId;
  final Random _random;
  final DateTime Function() _now;

  Set<String>? _extensionNamesCache;
  Future<Set<String>>? _extensionsInFlight;
  DateTime? _extensionsFailedAt;
  MediaServerCapabilities? _resolved;
  final _artistIndex =
      <String?, ({DateTime fetchedAt, List<SubsonicArtistDTO> artists})>{};
  final _startedAt = <String, DateTime>{};

  @override
  MediaServerCapabilities get capabilities => _resolved ?? _baseCapabilities;

  @override
  Future<MediaServerCapabilities> resolveCapabilities() async {
    final extensions = await _extensionNames();
    if (extensions == null) return capabilities;
    return _resolved = _baseCapabilities.copyWith(
      lyrics: extensions.contains(songLyricsExtension),
    );
  }

  Future<Set<String>?> _extensionNames() async {
    final cached = _extensionNamesCache;
    if (cached != null) return cached;
    final failedAt = _extensionsFailedAt;
    if (failedAt != null &&
        _now().difference(failedAt) < extensionRetryInterval) {
      return null;
    }
    final inFlight = _extensionsInFlight ??= _api
        .getOpenSubsonicExtensions()
        .then(
          (extensions) => {for (final extension in extensions) extension.name},
        );
    try {
      return _extensionNamesCache = await inFlight;
    } on Object {
      _extensionsFailedAt = _now();
      return null;
    } finally {
      if (identical(_extensionsInFlight, inFlight)) _extensionsInFlight = null;
    }
  }

  Future<bool> _supports(String extension) async =>
      (await _extensionNames())?.contains(extension) ?? false;

  @override
  Future<LibraryPage> getAlbums(LibraryQuery query) async {
    if (query.appearsOnArtistId != null) return const LibraryPage();

    if (query.ids.isNotEmpty) {
      final albums = await _albumsByIds(query.ids);
      return LibraryPage(
        items: [for (final album in albums) album.toLibraryItem()],
        totalRecordCount: albums.length,
      );
    }

    if (query.artistIds.isNotEmpty) {
      final albums = <SubsonicAlbumDTO>[];
      for (final artistId in query.artistIds) {
        albums.addAll((await _api.getArtist(artistId)).album);
      }
      return _albumPage(albums, query);
    }

    if (query.filters.contains(ItemFilterFlag.favorite)) {
      final starred = await _api.getStarred2(musicFolderId: query.libraryId);
      return _albumPage(starred.album, query);
    }

    if (query.genreIds.isNotEmpty) {
      final seen = <String>{};
      final albums = <LibraryItem>[];
      for (final genre in query.genreIds) {
        final batch = await _api.getAlbumList2(
          type: subsonicByGenreListType,
          genre: genre,
          size: query.limit,
          offset: query.startIndex,
          musicFolderId: query.libraryId,
        );
        for (final album in batch) {
          if (seen.add(album.id)) albums.add(album.toLibraryItem());
        }
      }
      return subsonicOpenPage(albums, startIndex: query.startIndex);
    }

    final albums = await _api.getAlbumList2(
      type: subsonicAlbumListType(query.sort),
      size: query.limit,
      offset: query.startIndex,
      musicFolderId: query.libraryId,
    );
    return subsonicOpenPage(
      [for (final album in albums) album.toLibraryItem()],
      startIndex: query.startIndex,
    );
  }

  LibraryPage _albumPage(List<SubsonicAlbumDTO> albums, LibraryQuery query) {
    final sorted = subsonicSortAlbums(
      albums,
      query.sort,
      query.direction,
      random: _random,
    );
    return subsonicPageOf(
      [for (final album in sorted) album.toLibraryItem()],
      startIndex: query.startIndex,
      limit: query.limit,
    );
  }

  Future<List<SubsonicAlbumDTO>> _albumsByIds(List<String> ids) async {
    final albums = <SubsonicAlbumDTO>[];
    for (var i = 0; i < ids.length; i += _albumFanOut) {
      final chunk = ids.sublist(i, min(i + _albumFanOut, ids.length));
      final results = await Future.wait([
        for (final id in chunk) _albumOrNull(id),
      ]);
      albums.addAll(results.nonNulls);
    }
    return albums;
  }

  Future<SubsonicAlbumDTO?> _albumOrNull(String id) async {
    try {
      return await _api.getAlbum(id);
    } on DioException catch (e) {
      if (MediaServerException.fromDio(e).isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<LibraryPage> getArtists(LibraryQuery query) async {
    final artists = query.filters.contains(ItemFilterFlag.favorite)
        ? (await _api.getStarred2(musicFolderId: query.libraryId)).artist
        : await _artistsIndex(query.libraryId);
    final sorted = subsonicSortArtists(
      artists,
      query.sort,
      query.direction,
      random: _random,
    );
    return subsonicPageOf(
      [for (final artist in sorted) artist.toLibraryItem()],
      startIndex: query.startIndex,
      limit: query.limit,
    );
  }

  Future<List<SubsonicArtistDTO>> _artistsIndex(String? libraryId) async {
    final cached = _artistIndex[libraryId];
    if (cached != null &&
        _now().difference(cached.fetchedAt) < artistIndexTtl) {
      return cached.artists;
    }
    final artists = await _api.getArtists(musicFolderId: libraryId);
    _artistIndex[libraryId] = (fetchedAt: _now(), artists: artists);
    return artists;
  }

  @override
  Future<LibraryPage> getGenres(LibraryQuery query) async {
    final genres = subsonicSortGenres(
      await _api.getGenres(),
      query.sort,
      query.direction,
      random: _random,
    );
    return subsonicPageOf(
      [for (final genre in genres) genre.toLibraryItem()],
      startIndex: query.startIndex,
      limit: query.limit,
    );
  }

  @override
  Future<LibraryPage> getPlaylists(LibraryQuery query) async {
    if (query.artistIds.isNotEmpty || query.appearsOnArtistId != null) {
      return const LibraryPage();
    }
    final playlists = subsonicSortPlaylists(
      await _api.getPlaylists(),
      query.sort,
      query.direction,
      random: _random,
    );
    return subsonicPageOf(
      [for (final playlist in playlists) playlist.toLibraryItem()],
      startIndex: query.startIndex,
      limit: query.limit,
    );
  }

  @override
  Future<LibraryPage> getAllSongs(LibraryQuery query) async {
    if (query.filters.contains(ItemFilterFlag.favorite)) {
      final starred = await _api.getStarred2(musicFolderId: query.libraryId);
      return _songPage(starred.song, query);
    }

    if (query.sort == ItemSort.random) {
      final songs = await _api.getRandomSongs(
        size: query.limit,
        musicFolderId: query.libraryId,
      );
      return subsonicOpenPage(
        _songItems(subsonicFilterSongs(songs, query.filters)),
        startIndex: query.startIndex,
      );
    }

    if (query.filters.contains(ItemFilterFlag.played) &&
        (query.sort == ItemSort.playCount ||
            query.sort == ItemSort.datePlayed)) {
      final frequent = await _api.getAlbumList2(
        type: subsonicAlbumListType(query.sort),
        size: playedAlbumsScanLimit,
        musicFolderId: query.libraryId,
      );
      final songs = <SubsonicChildDTO>[];
      for (final album in await _albumsByIds([
        for (final album in frequent) album.id,
      ])) {
        songs.addAll(album.song);
      }
      return _songPage(songs, query);
    }

    final result = await _api.search3(
      query: '',
      songCount: query.limit,
      songOffset: query.startIndex,
      musicFolderId: query.libraryId,
    );
    return subsonicOpenPage(
      _songItems(subsonicFilterSongs(result.song, query.filters)),
      startIndex: query.startIndex,
    );
  }

  @override
  Future<LibraryPage> getSongsOfSet(LibraryQuery query) async {
    if (query.artistIds.isNotEmpty) {
      final songs = <SubsonicChildDTO>[];
      for (final artistId in query.artistIds) {
        final artist = await _api.getArtist(artistId);
        final albums = subsonicSortAlbums(
          artist.album,
          ItemSort.releaseDate,
          SortDirection.ascending,
        );
        for (final album in await _albumsByIds([
          for (final album in albums) album.id,
        ])) {
          songs.addAll(subsonicAlbumOrder(album.song));
        }
      }
      return _songPage(songs, query);
    }

    if (query.genreIds.isNotEmpty) {
      final random = query.sort == ItemSort.random;
      final filtered =
          query.filters.isNotEmpty || query.sort == ItemSort.playCount;
      final fetchSize = filtered
          ? min(genreSetScanLimit, query.limit * 5)
          : query.limit;
      final seen = <String>{};
      final songs = <SubsonicChildDTO>[];
      for (final genre in query.genreIds) {
        final batch = random
            ? await _api.getRandomSongs(
                size: fetchSize,
                genre: genre,
                musicFolderId: query.libraryId,
              )
            : await _api.getSongsByGenre(
                genre: genre,
                count: fetchSize,
                offset: filtered ? 0 : query.startIndex,
                musicFolderId: query.libraryId,
              );
        for (final song in batch) {
          if (seen.add(song.id)) songs.add(song);
        }
      }
      final ordered = subsonicSortSongs(
        subsonicFilterSongs(songs, query.filters),
        query.sort,
        query.direction,
        random: _random,
      );
      if (random || filtered) {
        return subsonicOpenPage(
          ordered.length > query.limit
              ? _songItems(ordered.sublist(0, query.limit))
              : _songItems(ordered),
          startIndex: query.startIndex,
        );
      }
      return subsonicOpenPage(
        _songItems(ordered),
        startIndex: query.startIndex,
      );
    }

    return getAllSongs(query);
  }

  LibraryPage _songPage(List<SubsonicChildDTO> songs, LibraryQuery query) {
    final sorted = subsonicSortSongs(
      subsonicFilterSongs(songs, query.filters),
      query.sort,
      query.direction,
      random: _random,
    );
    return subsonicPageOf(
      _songItems(sorted),
      startIndex: query.startIndex,
      limit: query.limit,
    );
  }

  List<LibraryItem> _songItems(List<SubsonicChildDTO> songs) => [
    for (final song in songs)
      song.toLibraryItem(lyricsAvailable: capabilities.lyrics),
  ];

  @override
  Future<LibraryPage> getSongs(String albumId) async {
    final album = await _api.getAlbum(albumId);
    final songs = _songItems(subsonicAlbumOrder(album.song));
    return LibraryPage(items: songs, totalRecordCount: songs.length);
  }

  @override
  Future<LibraryPage> getPlaylistSongs(String playlistId) async {
    final playlist = await _api.getPlaylist(playlistId);
    final songs = [
      for (final (index, entry) in playlist.entry.indexed)
        entry.toLibraryItem(
          playlistItemId: subsonicPlaylistEntryId(index, entry.id),
          indexNumber: index + 1,
          lyricsAvailable: capabilities.lyrics,
        ),
    ];
    return LibraryPage(items: songs, totalRecordCount: songs.length);
  }

  @override
  Future<LibraryPage> getSimilarAlbums(
    String albumId, {
    int limit = 12,
  }) async => const LibraryPage();

  @override
  Future<List<LibraryItem>> getInstantMix(
    String itemId, {
    int limit = 100,
  }) async => _songItems(await _api.getSimilarSongs(id: itemId, count: limit));

  Future<List<LibraryItem>> _albumList(
    String type, {
    required String? libraryId,
    required int limit,
  }) async {
    final albums = await _api.getAlbumList2(
      type: type,
      size: limit,
      musicFolderId: libraryId,
    );
    return [for (final album in albums) album.toLibraryItem()];
  }

  @override
  Future<List<LibraryItem>> getLatestAlbums({
    String? libraryId,
    int limit = 20,
  }) => _albumList(subsonicNewestListType, libraryId: libraryId, limit: limit);

  @override
  Future<List<LibraryItem>> getRecentlyPlayedAlbums({
    String? libraryId,
    int limit = 20,
  }) => _albumList(subsonicRecentListType, libraryId: libraryId, limit: limit);

  @override
  Future<List<LibraryItem>> getMostPlayedAlbums({
    String? libraryId,
    int limit = 20,
  }) =>
      _albumList(subsonicFrequentListType, libraryId: libraryId, limit: limit);

  @override
  Future<List<GeneratedPlaylist>> generateTodaysPlaylists({
    String? libraryId,
    bool includeDiscovery = false,
  }) => generateGenrePlaylists(
    this,
    libraryId: libraryId,
    includeDiscovery: includeDiscovery,
    random: _random,
  );

  @override
  Future<List<LibraryItem>> getGeneratedPlaylistSongs({
    required String playlistId,
    String? libraryId,
  }) => fetchGenrePlaylistSongs(
    this,
    playlistId: playlistId,
    libraryId: libraryId,
    random: _random,
  );

  @override
  Future<LibraryPage> getLibraries() async {
    final folders = await _api.getMusicFolders();
    final items = [for (final folder in folders) folder.toLibraryItem()];
    return LibraryPage(items: items, totalRecordCount: items.length);
  }

  @override
  Future<List<LibraryItem>> getItemsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];

    final songs = await Future.wait([for (final id in ids) _songOrNull(id)]);
    return [
      for (final song in songs)
        if (song != null) song,
    ];
  }

  Future<LibraryItem?> _songOrNull(String id) async {
    try {
      return (await _api.getSong(
        id,
      )).toLibraryItem(lyricsAvailable: capabilities.lyrics);
    } on DioException catch (e) {
      if (MediaServerException.fromDio(e).isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<LibraryItem> getItem(String itemId, {required ItemKind kind}) async =>
      switch (kind) {
        ItemKind.song => (await _api.getSong(
          itemId,
        )).toLibraryItem(lyricsAvailable: capabilities.lyrics),
        ItemKind.album => (await _api.getAlbum(itemId)).toLibraryItem(),
        ItemKind.artist => await _artistWithInfo(itemId),
        ItemKind.playlist => (await _api.getPlaylist(itemId)).toLibraryItem(),
        ItemKind.genre => LibraryItem(
          id: itemId,
          name: itemId,
          kind: ItemKind.genre,
        ),
        ItemKind.library || ItemKind.unknown =>
          (await _api.getMusicFolders())
              .firstWhere(
                (folder) => folder.id == itemId,
                orElse: () => throw const MediaServerException(
                  MediaServerErrorKind.notFound,
                ),
              )
              .toLibraryItem(),
      };

  Future<LibraryItem> _artistWithInfo(String id) async {
    final results = await Future.wait<Object?>([
      _api.getArtist(id),
      _api
          .getArtistInfo2(id)
          .then<Object?>((info) => info, onError: (_) => null),
    ]);
    final artist = (results[0]! as SubsonicArtistDTO).toLibraryItem();
    final info = results[1] as SubsonicArtistInfoDTO?;
    final biography = subsonicPlainText(info?.biography);
    return biography == null ? artist : artist.copyWith(overview: biography);
  }

  @override
  Future<LibraryPage> searchAlbums(SearchQuery query) async {
    final result = await _api.search3(
      query: query.term,
      albumCount: query.limit,
      albumOffset: query.startIndex,
      musicFolderId: query.libraryId,
    );
    return subsonicOpenPage(
      [for (final album in result.album) album.toLibraryItem()],
      startIndex: query.startIndex,
    );
  }

  @override
  Future<LibraryPage> searchArtists(SearchQuery query) async {
    final result = await _api.search3(
      query: query.term,
      artistCount: query.limit,
      artistOffset: query.startIndex,
      musicFolderId: query.libraryId,
    );
    return subsonicOpenPage(
      [for (final artist in result.artist) artist.toLibraryItem()],
      startIndex: query.startIndex,
    );
  }

  @override
  Future<LibraryPage> searchSongs(SearchQuery query) async {
    final result = await _api.search3(
      query: query.term,
      songCount: query.limit,
      songOffset: query.startIndex,
      musicFolderId: query.libraryId,
    );
    return subsonicOpenPage(
      _songItems(result.song),
      startIndex: query.startIndex,
    );
  }

  @override
  Future<LibraryPage> searchPlaylists(SearchQuery query) async {
    final term = query.term.trim().toLowerCase();
    final playlists = [
      for (final playlist in await _api.getPlaylists())
        if (term.isEmpty || playlist.name.toLowerCase().contains(term))
          playlist,
    ];
    final sorted = subsonicSortPlaylists(
      playlists,
      ItemSort.name,
      SortDirection.ascending,
    );
    return subsonicPageOf(
      [for (final playlist in sorted) playlist.toLibraryItem()],
      startIndex: query.startIndex,
      limit: query.limit,
    );
  }

  @override
  Future<void> setFavorite(String itemId, {required bool favorite}) =>
      favorite ? _api.star(itemId) : _api.unstar(itemId);

  @override
  Future<void> createPlaylist(PlaylistData values) async {
    var created = await _api.createPlaylist(name: values.name);
    if (!values.isPublic) return;
    created ??= subsonicSortPlaylists(
      [
        for (final playlist in await _api.getPlaylists())
          if (playlist.name == values.name) playlist,
      ],
      ItemSort.dateCreated,
      SortDirection.descending,
    ).firstOrNull;
    if (created == null) return;
    await _api.updatePlaylist(playlistId: created.id, public: true);
  }

  @override
  Future<void> deletePlaylist(String playlistId) =>
      _api.deletePlaylist(playlistId);

  @override
  Future<void> addPlaylistItems({
    required String playlistId,
    required List<String> itemIds,
  }) => _api.updatePlaylist(playlistId: playlistId, songIdToAdd: itemIds);

  @override
  Future<void> removePlaylistItem({
    required String playlistId,
    required String entryId,
  }) async {
    final entry = subsonicPlaylistEntryOf(entryId);
    if (entry == null) {
      throw const MediaServerException(MediaServerErrorKind.notFound);
    }
    final playlist = await _api.getPlaylist(playlistId);
    final entries = playlist.entry;
    var index = entry.index;
    if (index >= entries.length || entries[index].id != entry.songId) {
      final matches = [
        for (final (i, candidate) in entries.indexed)
          if (candidate.id == entry.songId) i,
      ];
      if (matches.length != 1) {
        throw const MediaServerException(MediaServerErrorKind.notFound);
      }
      index = matches.single;
    }
    await _api.updatePlaylist(
      playlistId: playlistId,
      songIndexToRemove: [index],
    );
  }

  @override
  Future<Lyrics?> getLyrics(String itemId) async {
    try {
      return (await _api.getLyricsBySongId(itemId)).toLyrics();
    } on DioException catch (e) {
      if (MediaServerException.fromDio(e).isNotFound) return null;
      rethrow;
    }
  }

  @override
  Future<StreamSource> resolveStreamSource(
    LibraryItem song, {
    required String playSessionId,
    required StreamTargetProfile target,
    bool forceTranscode = false,
    Duration? startPosition,
  }) async {
    final audioSource = song.audioSources.firstOrNull;
    final profile = AudioStreamProfile.forSource(
      target: target,
      sourceContainer: audioSource?.container,
      sourceCodec: audioSource?.codec,
    );

    if (!forceTranscode && !profile.requiresTranscode) {
      final container = profile.outputContainer;
      return StreamSource(
        uri: _api.streamUri(song.id, format: directPlayFormat),
        isHls: false,
        outputContainer: container,
        mimeType: mimeTypeForContainer(container),
      );
    }

    final lossless = profile.transcodingAudioCodec == losslessTranscodeFormat;
    final format = lossless ? losslessTranscodeFormat : lossyTranscodeFormat;
    return StreamSource(
      uri: _api.streamUri(
        song.id,
        format: format,
        maxBitRate: lossless ? null : transcodeBitRate,
      ),
      isHls: false,
      outputContainer: format,
      mimeType: mimeTypeForContainer(format),
      requiresTranscode: true,
    );
  }

  @override
  Uri? imageUri(
    LibraryItem item, {
    ImageKind kind = ImageKind.primary,
    int? size,
  }) {
    final id = switch (kind) {
      ImageKind.primary => item.images.primary ?? item.images.albumPrimary,
      ImageKind.album => item.images.albumPrimary ?? item.images.primary,
      ImageKind.backdrop => item.images.backdrops.firstOrNull,
    };
    if (id == null) return null;
    final absolute = Uri.tryParse(id);
    if (absolute != null && absolute.hasScheme && absolute.host.isNotEmpty) {
      return absolute;
    }
    return _api.coverArtUri(id, size: size ?? _defaultImageSize);
  }

  @override
  Uri resizedImageUri(Uri uri, int size) {
    final params = uri.queryParameters;
    if (!params.containsKey('size')) return uri;
    return uri.replace(queryParameters: {...params, 'size': '$size'});
  }

  @override
  Future<void> reportPlaybackStarted(PlaybackReport report) async {
    _startedAt[report.itemId] = _now();
    if (await _supports(playbackReportExtension)) {
      await _api.reportPlayback(
        mediaId: report.itemId,
        state: 'starting',
        position: report.position,
      );
      return;
    }
    await _api.scrobble(id: report.itemId, submission: false);
  }

  @override
  Future<void> reportPlaybackProgress(PlaybackReport report) async {
    if (!await _supports(playbackReportExtension)) return;
    await _api.reportPlayback(
      mediaId: report.itemId,
      state: report.isPaused ?? false ? 'paused' : 'playing',
      position: report.position,
    );
  }

  @override
  Future<void> reportPlaybackStopped(PlaybackReport report) async {
    final startedAt = _startedAt.remove(report.itemId);
    if (await _supports(playbackReportExtension)) {
      await _api.reportPlayback(
        mediaId: report.itemId,
        state: 'stopped',
        position: report.position,
      );
      return;
    }
    if (!countsAsPlay(position: report.position, duration: report.duration)) {
      return;
    }
    await _api.scrobble(id: report.itemId, submission: true, time: startedAt);
  }

  static bool countsAsPlay({
    required Duration? position,
    required Duration? duration,
  }) {
    if (position == null) return false;
    if (duration == null || duration <= Duration.zero) {
      return position >= minimumPlayDuration;
    }
    final threshold = duration ~/ 2 < minimumPlayDuration
        ? duration ~/ 2
        : minimumPlayDuration;
    return position >= threshold;
  }

  @override
  Future<SessionStatus> validateSession() async {
    if (_api.credentials == null) return SessionStatus.invalid;
    try {
      await _api.ping();
      return SessionStatus.valid;
    } on DioException catch (e) {
      if (MediaServerException.fromDio(e).isUnauthorized) {
        return SessionStatus.invalid;
      }
      return SessionStatus.unreachable;
    } on Object {
      return SessionStatus.unreachable;
    }
  }

  @override
  Future<void> signOut() async {}
}

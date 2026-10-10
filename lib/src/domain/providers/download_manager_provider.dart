import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/core/enums/download_status.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/backend/stream_source.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/services/download_service.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';

class DownloadManagerNotifier extends AsyncNotifier<List<DownloadedSong>> {
  late DownloadService _downloadService;
  late DownloadDatabase _database;
  final _cancelled = <String>{};
  final _currentSong = <String, String>{};

  @override
  FutureOr<List<DownloadedSong>> build() async {
    _downloadService = ref.watch(downloadServiceProvider);
    _database = ref.watch(downloadDatabaseProvider);
    state = const AsyncValue.loading();
    return _database.getDownloadedSongs();
  }

  Future<void> downloadSong(LibraryItem song) async {
    final client = ref.read(mediaServerClientProvider);

    try {
      // Start download
      final task = await _downloadService.downloadSong(
        song,
        client,
        deviceId: deviceId,
      );

      // Wait for download to complete
      await _waitForDownloadCompletion(task);

      // If download completed successfully, add to database
      if (task.status.value == DownloadStatus.completed) {
        final file = File(task.destination);

        // Add to database
        await _database.insertDownloadedSong(song, file: file);

        final albumId = song.albumId;
        if (albumId != null) {
          await _downloadService.downloadAlbumCover(
            albumId,
            client.imageUri(song, kind: ImageKind.album),
          );
        }

        // Refresh state
        ref.invalidateSelf();
      }
    } catch (error, stackTrace) {
      print(
        'Error in downloadSong: type=${error.runtimeType}, message=$error\n$stackTrace',
      );
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> downloadAlbum(LibraryItem album, List<LibraryItem> songs) async {
    final client = ref.read(mediaServerClientProvider);

    try {
      await _downloadCollection(album.id, songs, (stored) async {
        if (stored.isEmpty) return;
        await _database.insertDownloadedAlbum(
          album,
          files: [for (final (_, file) in stored) file],
        );
        await _downloadService.downloadAlbumCover(
          album.id,
          client.imageUri(album),
        );
      });
      ref.invalidateSelf();
    } catch (error, stackTrace) {
      print(
        'Error in downloadAlbum: type=${error.runtimeType}, message=$error\n$stackTrace',
      );
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> downloadPlaylist(
    LibraryItem playlist,
    List<LibraryItem> songs,
  ) async {
    try {
      await _storePlaylist(playlist, songs);
      ref.invalidateSelf();
    } catch (error, stackTrace) {
      print(
        'Error in downloadPlaylist: type=${error.runtimeType}, message=$error\n$stackTrace',
      );
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> syncPlaylist(
    LibraryItem playlist,
    List<LibraryItem> songs, {
    bool keepLocalOrder = false,
  }) async {
    final database = _database;
    final localIds = await database.getPlaylistSongIds(playlist.id);
    final ordered = keepLocalOrder ? mergeLikedOrder(localIds, songs) : songs;
    final wantedIds = [for (final song in ordered) song.id];
    if (listEquals(localIds, wantedIds)) return false;

    await _storePlaylist(playlist, ordered);

    final wanted = wantedIds.toSet();
    await database.pruneSongs(localIds.where((id) => !wanted.contains(id)));
    ref.invalidateSelf();
    return true;
  }

  Future<void> _storePlaylist(
    LibraryItem playlist,
    List<LibraryItem> songs,
  ) {
    final client = ref.read(mediaServerClientProvider);
    return _downloadCollection(playlist.id, songs, (stored) async {
      if (stored.isEmpty) return;
      await _database.insertDownloadedPlaylist(
        playlist,
        songs: [for (final (song, _) in stored) song],
        files: [for (final (_, file) in stored) file],
      );
      final covers = <String, LibraryItem>{
        for (final (song, _) in stored) ?song.albumId: song,
      };
      for (final MapEntry(key: albumId, value: song) in covers.entries) {
        await _downloadService.downloadAlbumCover(
          albumId,
          client.imageUri(song, kind: ImageKind.album),
        );
      }
      await _downloadService.downloadAlbumCover(
        playlist.id,
        client.imageUri(playlist),
      );
    });
  }

  Future<void> _downloadCollection(
    String id,
    List<LibraryItem> songs,
    Future<void> Function(List<(LibraryItem, File)> stored) save,
  ) async {
    final client = ref.read(mediaServerClientProvider);
    final database = _database;
    final stored = <(LibraryItem, File)>[];
    final inserted = <String>[];
    _setProgress(id, 0);

    try {
      for (final (index, song) in songs.indexed) {
        if (_cancelled.contains(id)) break;
        _currentSong[id] = song.id;
        final existing = await _existingDownload(song);
        if (existing == null && _cancelled.contains(id)) break;
        final file =
            existing ??
            await _downloadSongFile(
              song,
              client,
              onProgress: (value) =>
                  _setProgress(id, (index + value) / songs.length),
            );
        _setProgress(id, (index + 1) / songs.length);
        if (file == null) continue;

        stored.add((song, file));
        if (existing == null) {
          await database.insertDownloadedSong(song, file: file);
          inserted.add(song.id);
        }
      }

      if (_cancelled.contains(id)) {
        await database.pruneSongs(inserted);
        ref.invalidateSelf();
        return;
      }
      await save(stored);
    } finally {
      _cancelled.remove(id);
      _currentSong.remove(id);
      _setProgress(id, null);
    }
  }

  Future<void> _cancelCollection(String id) async {
    if (!ref.read(activeDownloadsProvider).containsKey(id)) return;
    _cancelled.add(id);
    final songId = _currentSong[id];
    if (songId != null) await _downloadService.cancelDownload(songId);
  }

  void _setProgress(String id, double? progress) {
    final notifier = ref.read(activeDownloadsProvider.notifier);
    notifier.state = progress == null
        ? ({...notifier.state}..remove(id))
        : {...notifier.state, id: progress};
  }

  Future<File?> _existingDownload(LibraryItem song) async {
    final path = await _database.getDownloadedSongPath(song.id);
    if (path == null) return null;
    final file = File(path);
    return file.existsSync() ? file : null;
  }

  Future<File?> _downloadSongFile(
    LibraryItem song,
    MediaServerClient client, {
    void Function(double progress)? onProgress,
  }) async {
    final task = await _downloadService.downloadSong(
      song,
      client,
      deviceId: deviceId,
    );
    void report() =>
        onProgress?.call((task.progress.value ?? 0).clamp(0.0, 1.0));
    task.progress.addListener(report);
    try {
      await _waitForDownloadCompletion(task);
    } finally {
      task.progress.removeListener(report);
    }
    if (task.status.value != DownloadStatus.completed) return null;
    return File(task.destination);
  }

  Future<void> _waitForDownloadCompletion(DownloadTask task) async {
    final completer = Completer<void>();

    void listener() {
      const completedStatuses = {
        DownloadStatus.completed,
        DownloadStatus.failed,
        DownloadStatus.canceled,
      };

      if (completedStatuses.contains(task.status.value)) {
        task.status.removeListener(listener);
        completer.complete();
      }
    }

    task.status.addListener(listener);

    // In case the status is already completed
    listener();

    return completer.future;
  }

  Future<void> deleteSong(String id) async {
    try {
      await _database.deleteDownloadedSong(id);

      // Refresh state
      ref.invalidateSelf();
    } catch (error, stackTrace) {
      print(
        'Error in deleteSong: type=${error.runtimeType}, message=$error\n$stackTrace',
      );
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    try {
      await _cancelCollection(albumId);
      await _database.deleteDownloadedAlbum(albumId);
      await DownloadPaths.deleteAlbumDirectory(albumId);

      // Refresh state
      ref.invalidateSelf();
    } catch (error, stackTrace) {
      print(
        'Error in deleteAlbum: type=${error.runtimeType}, message=$error\n$stackTrace',
      );
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _cancelCollection(playlistId);
      await _database.deleteDownloadedPlaylist(playlistId);
      await DownloadPaths.deleteAlbumDirectory(playlistId);

      ref.invalidateSelf();
    } catch (error, stackTrace) {
      print(
        'Error in deletePlaylist: type=${error.runtimeType}, message=$error\n$stackTrace',
      );
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> isSongDownloaded(String id) => _database.isSongDownloaded(id);

  Future<bool> isAlbumDownloaded(String albumId) =>
      _database.isAlbumDownloaded(albumId);

  Future<bool> isPlaylistDownloaded(String playlistId) =>
      _database.isPlaylistDownloaded(playlistId);

  Future<List<DownloadedAlbum>> getDownloadedAlbums() =>
      _database.getDownloadedAlbums();

  Future<List<DownloadedPlaylist>> getDownloadedPlaylists() =>
      _database.getDownloadedPlaylists();
}

final activeDownloadsProvider = StateProvider<Map<String, double>>(
  (ref) => const {},
);

final downloadManagerProvider =
    AsyncNotifierProvider<DownloadManagerNotifier, List<DownloadedSong>>(
      DownloadManagerNotifier.new,
    );

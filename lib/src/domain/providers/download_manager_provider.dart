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
import 'package:jplayer/src/domain/providers/download_activity_provider.dart';
import 'package:jplayer/src/domain/providers/downloads_revision_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';

class DownloadManager {
  DownloadManager({
    required DownloadService service,
    required DownloadDatabase database,
    required DownloadActivityNotifier activity,
    required DownloadsRevision revision,
    required MediaServerClient Function() client,
  }) : _service = service,
       _database = database,
       _activity = activity,
       _revision = revision,
       _client = client;

  final DownloadService _service;
  final DownloadDatabase _database;
  final DownloadActivityNotifier _activity;
  final DownloadsRevision _revision;
  final MediaServerClient Function() _client;
  final _active = <String>{};
  final _cancelled = <String>{};
  final _currentSong = <String, String>{};

  Future<void> downloadSong(LibraryItem song) =>
      _attempt('downloadSong', () async {
        final client = _client();
        final file = await _downloadSongFile(song, client);
        if (file == null) return;
        await _database.insertDownloadedSong(song, file: file);
        final albumId = song.albumId;
        if (albumId != null) {
          await _service.downloadAlbumCover(
            albumId,
            client.imageUri(song, kind: ImageKind.album),
          );
        }
        _revision.bump();
      });

  Future<void> downloadAlbum(LibraryItem album, List<LibraryItem> songs) =>
      _attempt('downloadAlbum', () async {
        final client = _client();
        await _downloadCollection(album.id, songs, (stored) async {
          if (stored.isEmpty) return;
          await _database.insertDownloadedAlbum(
            album,
            files: [for (final (_, file) in stored) file],
          );
          await _service.downloadAlbumCover(album.id, client.imageUri(album));
        });
      });

  Future<void> downloadPlaylist(
    LibraryItem playlist,
    List<LibraryItem> songs,
  ) => _attempt('downloadPlaylist', () => _storePlaylist(playlist, songs));

  Future<bool> syncPlaylist(
    LibraryItem playlist,
    List<LibraryItem> songs, {
    bool keepLocalOrder = false,
  }) async {
    final localIds = await _database.getPlaylistSongIds(playlist.id);
    final ordered = keepLocalOrder ? mergeLikedOrder(localIds, songs) : songs;
    final wantedIds = [for (final song in ordered) song.id];
    if (listEquals(localIds, wantedIds)) return false;

    await _storePlaylist(playlist, ordered);

    final wanted = wantedIds.toSet();
    await _database.pruneSongs(localIds.where((id) => !wanted.contains(id)));
    _revision.bump();
    return true;
  }

  Future<void> deleteSong(String id) => _attempt('deleteSong', () async {
    await _database.deleteDownloadedSong(id);
    _activity.untrackSong(id);
    _revision.bump();
  });

  Future<void> deleteAlbum(String albumId) => _attempt('deleteAlbum', () async {
    await _cancelCollection(albumId);
    await _database.deleteDownloadedAlbum(albumId);
    await DownloadPaths.deleteAlbumDirectory(albumId);
    _activity.pruneSettled();
    _revision.bump();
  });

  Future<void> deletePlaylist(String playlistId) =>
      _attempt('deletePlaylist', () async {
        await _cancelCollection(playlistId);
        await _database.deleteDownloadedPlaylist(playlistId);
        await DownloadPaths.deleteAlbumDirectory(playlistId);
        _activity.pruneSettled();
        _revision.bump();
      });

  Future<void> _attempt(String operation, Future<void> Function() body) async {
    try {
      await body();
    } on Object catch (error, stackTrace) {
      debugPrint('[Downloads] $operation failed: $error\n$stackTrace');
    }
  }

  Future<void> _storePlaylist(LibraryItem playlist, List<LibraryItem> songs) {
    final client = _client();
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
        await _service.downloadAlbumCover(
          albumId,
          client.imageUri(song, kind: ImageKind.album),
        );
      }
      await _service.downloadAlbumCover(playlist.id, client.imageUri(playlist));
    });
  }

  Future<void> _downloadCollection(
    String id,
    List<LibraryItem> songs,
    Future<void> Function(List<(LibraryItem, File)> stored) save,
  ) async {
    final client = _client();
    final stored = <(LibraryItem, File)>[];
    final inserted = <String>[];
    var saved = false;
    _active.add(id);
    _activity.setCollectionProgress(id, 0);

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
              onProgress: (value) => _activity.setCollectionProgress(
                id,
                (index + value) / songs.length,
              ),
              isCancelled: () => _cancelled.contains(id),
            );
        _activity.setCollectionProgress(id, (index + 1) / songs.length);
        if (file == null) continue;

        stored.add((song, file));
        if (existing == null) {
          await _database.insertDownloadedSong(song, file: file, pending: true);
          inserted.add(song.id);
        }
      }

      if (!_cancelled.contains(id)) {
        await save(stored);
        saved = true;
      }
    } finally {
      if (!saved) await _database.pruneSongs(inserted);
      _revision.bump();
      _active.remove(id);
      _cancelled.remove(id);
      _currentSong.remove(id);
      _activity.setCollectionProgress(id, null);
    }
  }

  Future<void> _cancelCollection(String id) async {
    if (!_active.contains(id)) return;
    _cancelled.add(id);
    final songId = _currentSong[id];
    if (songId != null) await _service.cancelDownload(songId);
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
    bool Function()? isCancelled,
  }) async {
    final task = await _service.downloadSong(song, client, deviceId: deviceId);
    _activity
      ..pruneSettled()
      ..trackSong(task);
    if ((isCancelled?.call() ?? false) &&
        task.status.value != DownloadStatus.canceled) {
      await _service.cancelDownload(task.id);
    }
    void report() =>
        onProgress?.call((task.progress.value ?? 0).clamp(0.0, 1.0));
    task.progress.addListener(report);
    try {
      await _waitForDownloadCompletion(task);
    } finally {
      task.progress.removeListener(report);
    }
    if (task.status.value != DownloadStatus.completed) {
      _activity.untrackSong(task.id);
      return null;
    }
    return File(task.destination);
  }

  Future<void> _waitForDownloadCompletion(DownloadTask task) {
    const settled = {
      DownloadStatus.completed,
      DownloadStatus.failed,
      DownloadStatus.canceled,
    };
    final completer = Completer<void>();

    void listener() {
      if (settled.contains(task.status.value)) {
        task.status.removeListener(listener);
        completer.complete();
      }
    }

    task.status.addListener(listener);
    listener();
    return completer.future;
  }
}

final downloadManagerProvider = Provider<DownloadManager>(
  (ref) => DownloadManager(
    service: ref.watch(downloadServiceProvider),
    database: ref.watch(downloadDatabaseProvider),
    activity: ref.watch(downloadActivityProvider.notifier),
    revision: ref.watch(downloadsRevisionProvider.notifier),
    client: () => ref.read(mediaServerClientProvider),
  ),
);

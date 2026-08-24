import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/main.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/core/enums/download_status.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/data/services/download_service.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';

class DownloadManagerNotifier extends AsyncNotifier<List<DownloadedSong>> {
  late DownloadService _downloadService;
  late DownloadDatabase _database;

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
            song.images.albumPrimary ?? song.images.primary,
            client,
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
      final files = <File>[];

      // Download songs one at a time sequentially
      for (final song in songs) {
        final task = await _downloadService.downloadSong(
          song,
          client,
          deviceId: deviceId,
        );
        await _waitForDownloadCompletion(task);

        if (task.status.value == DownloadStatus.completed) {
          final file = File(task.destination);
          files.add(file);
          await _database.insertDownloadedSong(song, file: file);
        }
      }

      // Add album to database
      if (files.isNotEmpty) {
        await _database.insertDownloadedAlbum(album, files: files);
        await _downloadService.downloadAlbumCover(
          album.id,
          album.images.primary,
          client,
        );
      }

      // Refresh state
      ref.invalidateSelf();
    } catch (error, stackTrace) {
      print(
        'Error in downloadAlbum: type=${error.runtimeType}, message=$error\n$stackTrace',
      );
      state = AsyncValue.error(error, stackTrace);
    }
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

  Future<bool> isSongDownloaded(String id) => _database.isSongDownloaded(id);

  Future<bool> isAlbumDownloaded(String albumId) =>
      _database.isAlbumDownloaded(albumId);

  Future<List<DownloadedAlbum>> getDownloadedAlbums() =>
      _database.getDownloadedAlbums();
}

final downloadManagerProvider =
    AsyncNotifierProvider<DownloadManagerNotifier, List<DownloadedSong>>(
      DownloadManagerNotifier.new,
    );

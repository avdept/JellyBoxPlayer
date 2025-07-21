import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/download_status.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/data/providers/download_database_provider.dart';
import 'package:jplayer/src/data/services/download_service.dart';
import 'package:jplayer/src/data/storages/download_database.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/providers/base_url_provider.dart';
import 'package:jplayer/src/providers/download_service_provider.dart';

class DownloadManagerNotifier extends AsyncNotifier<List<DownloadedSongDTO>> {
  DownloadManagerNotifier();
  late DownloadService _downloadService;
  late DownloadDatabase _database;

  @override
  FutureOr<List<DownloadedSongDTO>> build() async {
    _downloadService = ref.watch(downloadServiceProvider);
    _database = ref.watch(downloadDatabaseProvider);
    state = const AsyncValue.loading();
    return _database.getDownloadedSongs();
  }

  Future<void> downloadSong(SongDTO song) async {
    // Get server URL and token
    final serverUrl = ref.read(baseUrlProvider)!;
    final token = ref.read(currentUserProvider)!.token;

    try {
      // Start download
      final task = await _downloadService.downloadSong(song, serverUrl, token);

      // Wait for download to complete
      await _waitForDownloadCompletion(task);

      // If download completed successfully, add to database
      if (task.status.value == DownloadStatus.completed) {
        final file = File(task.destination);

        // Add to database
        await _database.insertDownloadedSong(song, file: file);

        // Refresh state
        ref.invalidateSelf();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> downloadAlbum(ItemDTO album, List<SongDTO> songs) async {
    // Get server URL and token
    final serverUrl = ref.read(baseUrlProvider)!;
    final token = ref.read(currentUserProvider)!.token;

    try {
      // Start downloads
      final tasks = await _downloadService.downloadSongs(
        songs,
        serverUrl,
        token,
      );

      // Wait for all downloads to complete
      await Future.wait(tasks.map(_waitForDownloadCompletion));

      // Calculate total size of downloaded files
      final files = <File>[];
      for (final task in tasks) {
        if (task.status.value == DownloadStatus.completed) {
          final file = File(task.destination);
          files.add(file);

          // Find the corresponding song
          final song = songs.firstWhere((s) => s.id == task.id);

          // Add to database
          await _database.insertDownloadedSong(song, file: file);
        }
      }

      // Add album to database
      if (files.isNotEmpty) {
        await _database.insertDownloadedAlbum(album, files: files);
      }

      // Refresh state
      ref.invalidateSelf();
    } catch (error, stackTrace) {
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
      // Get file path
      final filePath = await _database.getDownloadedSongPath(id);
      if (filePath != null) {
        // Delete file
        final file = File(filePath);
        if (file.existsSync()) await file.delete();

        // Remove from database
        await _database.deleteDownloadedSong(id);

        // Refresh state
        ref.invalidateSelf();
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    try {
      // Get songs in album
      final songs = await _database.getDownloadedSongsByAlbum(albumId);

      // Delete each song file
      for (final song in songs) {
        final file = File(song.filePath);
        if (file.existsSync()) await file.delete();
      }

      // Remove from database
      await _database.deleteDownloadedAlbum(albumId);

      // Refresh state
      ref.invalidateSelf();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> isSongDownloaded(String id) => _database.isSongDownloaded(id);

  Future<bool> isAlbumDownloaded(String albumId) =>
      _database.isAlbumDownloaded(albumId);

  Future<List<DownloadedAlbumDTO>> getDownloadedAlbums() =>
      _database.getDownloadedAlbums();
}

final downloadManagerProvider =
    AsyncNotifierProvider<DownloadManagerNotifier, List<DownloadedSongDTO>>(
      DownloadManagerNotifier.new,
    );

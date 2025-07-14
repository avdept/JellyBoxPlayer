import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:jplayer/src/core/enums/download_status.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService {
  DownloadService(this._dio);
  final Dio _dio;
  final _tasks = <String, DownloadTask>{};
  final _cancelTokens = <String, CancelToken>{};

  Future<String> getDownloadDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/music');
    if (!downloadDir.existsSync()) await downloadDir.create(recursive: true);

    return downloadDir.path;
  }

  Future<DownloadTask> downloadSong(
    SongDTO song,
    String serverUrl,
    String token,
  ) async {
    final downloadDir = await getDownloadDirectory();
    final songDir = Directory('$downloadDir/${song.albumId ?? "unknown"}');
    if (!songDir.existsSync()) await songDir.create(recursive: true);

    final fileName = '${song.name?.replaceAll('/', '_') ?? song.id}.mp3';

    final task = DownloadTask(
      id: song.id,
      name: song.name ?? 'Unknown',
      // Create URL for downloading
      url: '$serverUrl/Audio/${song.id}/universal?api_key=$token',
      destination: '${songDir.path}/$fileName',
    );

    _tasks[song.id] = task;
    unawaited(_startDownload(task));

    return task;
  }

  Future<List<DownloadTask>> downloadAlbum(
    ItemDTO album,
    List<SongDTO> songs,
    String serverUrl,
    String token,
  ) async {
    return Future.wait(
      songs.map((song) => downloadSong(song, serverUrl, token)),
    );
  }

  Future<void> _startDownload(DownloadTask task) async {
    _cancelTokens[task.id] = CancelToken();
    task.status.value = DownloadStatus.downloading;

    try {
      await _dio.download(
        task.url,
        task.destination,
        cancelToken: _cancelTokens[task.id],
        onReceiveProgress: (received, total) {
          if (total != -1) {
            task.progress.value = received / total;
          }
        },
      );

      task
        ..progress.value = 1
        ..status.value = DownloadStatus.completed;
    } on DioException catch (e) {
      task.status.value =
          (e.type == DioExceptionType.cancel)
              ? DownloadStatus.canceled
              : DownloadStatus.failed;
    }
  }

  void pauseDownload(String id) {
    final task = _tasks[id];
    if (task != null && task.status.value == DownloadStatus.downloading) {
      _cancelTokens[task.id]?.cancel();
      task.status.value = DownloadStatus.paused;
    }
  }

  void resumeDownload(String id) {
    final task = _tasks[id];
    if (task != null && task.status.value == DownloadStatus.paused) {
      _startDownload(task);
    }
  }

  void cancelDownload(String id) {
    final task = _tasks[id];
    if (task != null) {
      _cancelTokens[task.id]?.cancel();
      task.status.value = DownloadStatus.canceled;
      // Optionally delete the partial file
      File(task.destination).delete().ignore();
      _tasks.remove(id);
    }
  }

  DownloadTask? getTask(String id) => _tasks[id];

  List<DownloadTask> getAllTasks() => _tasks.values.toList();
}

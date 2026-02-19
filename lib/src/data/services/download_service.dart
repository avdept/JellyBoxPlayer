import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/enums/download_status.dart';
import 'package:jplayer/src/data/dto/dto.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService extends ChangeNotifier {
  final _tasks = <String, DownloadTask>{};
  final _bdTasks = <String, bd.DownloadTask>{};

  Future<String> getDownloadDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadDir = Directory('${dir.path}/music');
    if (!downloadDir.existsSync()) await downloadDir.create(recursive: true);
    return downloadDir.path;
  }

  Future<DownloadTask> downloadSong(
    ItemDTO song,
    String serverUrl,
    String token,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final albumSubdir = song.albumId ?? 'unknown';
    final fileName = '${song.name.replaceAll('/', '_')}.mp3';
    final destination = '${dir.path}/music/$albumSubdir/$fileName';

    final task = DownloadTask(
      id: song.id,
      name: song.name,
      url: '$serverUrl/Items/${song.id}/Download',
      destination: destination,
    );

    _tasks[song.id] = task;
    notifyListeners();
    unawaited(_startDownload(task, token, albumSubdir, fileName));

    return task;
  }

  Future<void> _startDownload(
    DownloadTask task,
    String token,
    String albumSubdir,
    String fileName,
  ) async {
    task.status.value = DownloadStatus.downloading;

    final bdTask = bd.DownloadTask(
      taskId: task.id,
      url: '${task.url}?api_key=$token',
      filename: fileName,
      directory: 'music/$albumSubdir',
      baseDirectory: bd.BaseDirectory.applicationDocuments,
      allowPause: true,
      retries: 3,
    );

    _bdTasks[task.id] = bdTask;

    debugPrint('[Download] Starting "${task.name}" → $fileName');

    final result = await bd.FileDownloader().download(
      bdTask,
      onProgress: (progress) {
        task.progress.value = progress;
        debugPrint('[Download] "${task.name}": ${(progress * 100).toStringAsFixed(1)}%');
      },
      onStatus: (status) {
        debugPrint('[Download] "${task.name}" status: $status');
        switch (status) {
          case bd.TaskStatus.running:
            task.status.value = DownloadStatus.downloading;
          case bd.TaskStatus.paused:
            task.status.value = DownloadStatus.paused;
          case bd.TaskStatus.failed:
          case bd.TaskStatus.notFound:
            task.status.value = DownloadStatus.failed;
          case bd.TaskStatus.canceled:
            task.status.value = DownloadStatus.canceled;
          case bd.TaskStatus.complete:
            task.progress.value = 1;
            task.status.value = DownloadStatus.completed;
          default:
            break;
        }
      },
    );

    debugPrint('[Download] "${task.name}" finished with result: ${result.status} (exception: ${result.exception})');

    // Ensure final state is set after await returns
    if (result.status == bd.TaskStatus.complete) {
      task.progress.value = 1;
      task.status.value = DownloadStatus.completed;
    } else if (result.status == bd.TaskStatus.failed ||
        result.status == bd.TaskStatus.notFound) {
      task.status.value = DownloadStatus.failed;
    }
  }

  Future<void> pauseDownload(String id) async {
    final bdTask = _bdTasks[id];
    if (bdTask != null) {
      await bd.FileDownloader().pause(bdTask);
    }
  }

  Future<void> resumeDownload(String id) async {
    final bdTask = _bdTasks[id];
    if (bdTask != null) {
      await bd.FileDownloader().resume(bdTask);
    }
  }

  Future<void> cancelDownload(String id) async {
    final task = _tasks[id];
    if (task != null) {
      final bdTask = _bdTasks.remove(id);
      if (bdTask != null) {
        await bd.FileDownloader().cancelTasksWithIds([id]);
      }
      task.status.value = DownloadStatus.canceled;
      File(task.destination).delete().ignore();
      _tasks.remove(id);
      task.dispose();
    }
  }

  DownloadTask? getTask(String id) => _tasks[id];

  List<DownloadTask> getAllTasks() => _tasks.values.toList();
}

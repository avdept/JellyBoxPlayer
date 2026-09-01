import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:flutter/foundation.dart';
import 'package:jplayer/src/core/audio/stream_target_profile.dart';
import 'package:jplayer/src/core/downloads/download_paths.dart';
import 'package:jplayer/src/core/enums/download_status.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:path_provider/path_provider.dart';

class DownloadService extends ChangeNotifier {
  final _tasks = <String, DownloadTask>{};
  final _bdTasks = <String, bd.DownloadTask>{};

  Future<String> getDownloadDirectory() => DownloadPaths.init();

  Future<DownloadTask> downloadSong(
    LibraryItem song,
    MediaServerClient client, {
    required String deviceId,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final albumSubdir = song.albumId ?? 'unknown';

    // Download through the same transcoding endpoint the player streams from,
    // so codecs the local player can't decode (e.g. ALAC on Android/ExoPlayer)
    // are fetched as a playable, still-lossless FLAC rather than the raw
    // original. The file extension must match the container that endpoint
    // actually returns. See [AudioStreamProfile].
    final resolved = await client.resolveStreamSource(
      song,
      playSessionId: 'download-$deviceId-${song.id}',
      target: StreamTargetProfile.download(),
    );

    final fileName =
        '${song.name.replaceAll('/', '_')}.${resolved.outputContainer}';
    final destination = '${dir.path}/music/$albumSubdir/$fileName';

    final task = DownloadTask(
      id: song.id,
      name: song.name,
      url: resolved.uri.toString(),
      destination: destination,
    );

    _tasks[song.id] = task;
    notifyListeners();
    unawaited(_startDownload(task, albumSubdir, fileName));

    return task;
  }

  Future<void> _startDownload(
    DownloadTask task,
    String albumSubdir,
    String fileName,
  ) async {
    task.status.value = DownloadStatus.downloading;

    final bdTask = bd.DownloadTask(
      taskId: task.id,
      url: task.url,
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
        debugPrint(
          '[Download] "${task.name}": ${(progress * 100).toStringAsFixed(1)}%',
        );
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

    debugPrint(
      '[Download] "${task.name}" finished with result: ${result.status} (exception: ${result.exception})',
    );

    // Ensure final state is set after await returns
    if (result.status == bd.TaskStatus.complete) {
      task.progress.value = 1;
      task.status.value = DownloadStatus.completed;
    } else if (result.status == bd.TaskStatus.failed ||
        result.status == bd.TaskStatus.notFound) {
      task.status.value = DownloadStatus.failed;
    }
  }

  Future<File?> downloadAlbumCover(String albumId, Uri? uri) async {
    if (uri == null) return null;
    await DownloadPaths.init();
    final path = DownloadPaths.coverPath(albumId);
    if (path == null) return null;

    final file = File(path);
    if (file.existsSync() && file.lengthSync() > 0) return file;

    final httpClient = HttpClient();
    try {
      final response = await (await httpClient.getUrl(uri)).close();
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return null;
      }
      await file.parent.create(recursive: true);
      await response.pipe(file.openWrite());
      return file;
    } on Object catch (error) {
      debugPrint('[Download] cover for $albumId failed: $error');
      if (file.existsSync()) await file.delete();
      return null;
    } finally {
      httpClient.close(force: true);
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

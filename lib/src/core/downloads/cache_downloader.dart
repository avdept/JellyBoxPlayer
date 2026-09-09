import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;

abstract class CacheDownloader {
  Future<String> directoryPath();

  Future<String?> fetch({
    required String id,
    required String url,
    required String fileName,
  });

  Future<void> cancel(String id);
}

class BackgroundCacheDownloader implements CacheDownloader {
  static const _group = 'queue-cache';
  static const _directory = 'Caches/queue_cache';
  static const bd.BaseDirectory _baseDirectory =
      bd.BaseDirectory.applicationLibrary;

  @visibleForTesting
  static String taskIdFor(String songId) => 'queue-cache-$songId';

  @override
  Future<String> directoryPath() async => p.join(
    await bd.Task.baseDirectoryPath(_baseDirectory),
    _directory,
  );

  @override
  Future<String?> fetch({
    required String id,
    required String url,
    required String fileName,
  }) async {
    final task = bd.DownloadTask(
      taskId: taskIdFor(id),
      url: url,
      filename: fileName,
      directory: _directory,
      baseDirectory: _baseDirectory,
      group: _group,
      retries: 3,
      priority: 8,
    );
    final result = await bd.FileDownloader().download(task);
    if (result.status != bd.TaskStatus.complete) return null;
    return task.filePath();
  }

  @override
  Future<void> cancel(String id) =>
      bd.FileDownloader().cancelTasksWithIds([taskIdFor(id)]);
}

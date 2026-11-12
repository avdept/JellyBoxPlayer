import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/core/enums/download_status.dart';
import 'package:jplayer/src/domain/models/library_item/audio_source_info.dart';

part 'download_task.freezed.dart';

@freezed
abstract class DownloadTask with _$DownloadTask {
  factory DownloadTask({
    required String id,
    required String name,
    required String url,
    required String destination,
  }) = _DownloadTask;

  DownloadTask._();

  @override
  final ValueNotifier<DownloadStatus> status = ValueNotifier(
    DownloadStatus.pending,
  );

  @override
  final ValueNotifier<double?> progress = ValueNotifier(0);

  AudioSourceInfo? delivered;

  bool get isDownloadingNow => const {
    DownloadStatus.downloading,
    DownloadStatus.paused,
  }.contains(status.value);

  void dispose() {
    status.dispose();
    progress.dispose();
  }
}

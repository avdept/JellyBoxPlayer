import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jplayer/src/core/enums/download_status.dart';

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
  final ValueNotifier<double> progress = ValueNotifier(0);

  void dispose() {
    status.dispose();
    progress.dispose();
  }
}

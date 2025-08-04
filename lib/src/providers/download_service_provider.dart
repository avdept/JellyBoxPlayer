import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/dio_provider.dart';
import 'package:jplayer/src/data/services/download_service.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(ref.watch(dioProvider));
});

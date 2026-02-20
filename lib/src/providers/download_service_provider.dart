import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/services/download_service.dart';

final downloadServiceProvider = ChangeNotifierProvider<DownloadService>((ref) {
  return DownloadService();
});

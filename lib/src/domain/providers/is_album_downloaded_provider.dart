import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';

final isAlbumDownloadedProvider = FutureProviderFamily<bool, LibraryItem>(
  (ref, arg) {
    ref.listen(downloadManagerProvider, (prev, now) {
      if (prev?.value != now.value) ref.invalidateSelf();
    });
    return ref.read(downloadManagerProvider.notifier).isAlbumDownloaded(arg.id);
  },
);

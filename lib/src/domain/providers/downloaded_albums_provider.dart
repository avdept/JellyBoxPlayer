import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';

final downloadedAlbumsProvider = FutureProvider<List<DownloadedAlbum>>(
  (ref) {
    ref.listen(downloadManagerProvider, (prev, now) {
      if (prev?.value != now.value) ref.invalidateSelf();
    });
    return ref.read(downloadManagerProvider.notifier).getDownloadedAlbums();
  },
);

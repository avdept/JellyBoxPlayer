import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/providers.dart';

extension RefreshHomeSections on WidgetRef {
  void refreshHomeSections() {
    invalidate(recentlyAddedAlbumsProvider);
    invalidate(recentlyUpdatedPlaylistsProvider);
    invalidate(frequentlyPlayedAlbumsProvider);
    if (!read(settingProvider(AppSetting.recentlyPlayedHidden))) {
      invalidate(recentlyPlayedAlbumsProvider);
    }
    if (!read(settingProvider(AppSetting.favouritesHidden))) {
      invalidate(favouriteAlbumsProvider);
    }
    if (!read(settingProvider(AppSetting.generatedPlaylistsDisabled))) {
      read(currentDayProvider.notifier).check();
    }
  }
}

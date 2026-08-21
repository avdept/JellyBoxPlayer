import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/providers/shared_preferences_provider.dart';
import 'package:jplayer/src/domain/providers/studio_mode_provider.dart';

final generatedPlaylistsDisabledProvider =
    StateNotifierProvider<BoolPrefNotifier, bool>(
      (ref) => BoolPrefNotifier(
        ref.watch(sharedPreferencesProvider).valueOrNull,
        key: 'disable_generated_playlists',
      ),
    );

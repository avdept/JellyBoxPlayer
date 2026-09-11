import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/app_settings_provider.dart';

final effectiveArtistScopeProvider = Provider<ArtistScope>((ref) {
  final supported = ref.watch(serverCapabilitiesProvider).artistScopes;
  final selected = ref.watch(artistBrowseScopeProvider);
  if (supported.contains(selected)) return selected;
  return supported.isEmpty ? ArtistScope.albumArtists : supported.first;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/discord/discord_artwork.dart';
import 'package:jplayer/src/core/http/user_agent.dart';
import 'package:jplayer/src/core/musicbrainz/cover_art_finder.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/providers/musicbrainz_provider.dart';

final discordArtworkProvider = Provider<DiscordArtwork>((ref) {
  final finder = CoverArtFinder(
    musicBrainz: ref.watch(musicBrainzClientProvider),
    userAgent: jellyboxUserAgent(),
  );
  return DiscordArtwork(
    find: finder.find,
    cache: ref.watch(catalogCacheDatabaseProvider),
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/http/user_agent.dart';
import 'package:jplayer/src/core/musicbrainz/musicbrainz_client.dart';
import 'package:jplayer/src/core/musicbrainz/musicbrainz_models.dart';
import 'package:jplayer/src/data/providers/providers.dart';

typedef BarcodeLookup = ({String barcode, String? artistName});

final musicBrainzClientProvider = Provider<MusicBrainzClient>(
  (ref) => MusicBrainzClient(
    userAgent: jellyboxUserAgent(),
    cache: ref.watch(catalogCacheDatabaseProvider),
  ),
);

final AutoDisposeFutureProviderFamily<MusicBrainzReleaseMatch?, BarcodeLookup>
musicBrainzBarcodeMatchProvider = FutureProvider.autoDispose
    .family<MusicBrainzReleaseMatch?, BarcodeLookup>(
      (ref, key) => ref
          .watch(musicBrainzClientProvider)
          .resolveBarcode(key.barcode, artistName: key.artistName),
    );

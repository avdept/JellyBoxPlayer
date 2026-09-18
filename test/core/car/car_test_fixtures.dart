import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/enums/enums.dart';
import 'package:jplayer/src/data/backend/library_query.dart';
import 'package:jplayer/src/data/backend/media_server_capabilities.dart';
import 'package:jplayer/src/data/backend/media_server_client.dart';
import 'package:jplayer/src/data/providers/providers.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/artist_scope_provider.dart';
import 'package:jplayer/src/domain/providers/current_library_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/domain/providers/download_manager_provider.dart';
import 'package:jplayer/src/domain/providers/downloaded_albums_provider.dart';
import 'package:jplayer/src/domain/providers/favourites_provider.dart';
import 'package:jplayer/src/domain/providers/playback_provider.dart';
import 'package:jplayer/src/domain/providers/set_playback_provider.dart';
import 'package:jplayer/src/domain/providers/todays_playlists_provider.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/player_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../provider_container.dart';

class MockMediaServerClient extends Mock implements MediaServerClient {}

class MockAudioPlayer extends Mock implements AudioPlayer {}

class FakeAuthNotifier extends AuthNotifier {
  @override
  FutureOr<bool?> build() => true;
}

class FakeLibraryNotifier extends CurrentLibraryNotifier {
  @override
  FutureOr<LibraryItem?> build() => null;
}

class FakeTodaysPlaylists extends TodaysPlaylistsNotifier {
  FakeTodaysPlaylists(this.playlists);

  final List<GeneratedPlaylist> playlists;

  @override
  FutureOr<List<GeneratedPlaylist>> build() => playlists;
}

class FakeDownloadManager extends DownloadManagerNotifier {
  FakeDownloadManager(this.albums);

  final List<DownloadedAlbum> albums;

  @override
  FutureOr<List<DownloadedSong>> build() => const [];

  @override
  Future<List<DownloadedAlbum>> getDownloadedAlbums() async => albums;
}

class FakeSetPlayback extends StateNotifier<String?>
    with Mock
    implements SetPlaybackNotifier {
  FakeSetPlayback() : super(null);
}

class FakePlaybackNotifier extends StateNotifier<PlaybackState>
    with Mock
    implements PlaybackNotifier {
  FakePlaybackNotifier(super.state);
}

LibraryItem album(String id, {String artist = 'Artist'}) => LibraryItem(
  id: id,
  name: 'Album $id',
  kind: ItemKind.album,
  albumArtist: artist,
);

LibraryItem artist(String id) =>
    LibraryItem(id: id, name: 'Artist $id', kind: ItemKind.artist);

LibraryItem playlist(String id) =>
    LibraryItem(id: id, name: 'Playlist $id', kind: ItemKind.playlist);

LibraryItem song(String id, {String albumId = 'album-1'}) => LibraryItem(
  id: id,
  name: 'Song $id',
  kind: ItemKind.song,
  albumId: albumId,
  albumName: 'Album $albumId',
  albumArtist: 'Artist',
  duration: const Duration(minutes: 3),
);

List<LibraryItem> albums(int count) =>
    List.generate(count, (i) => album('album-$i'));

PlaybackState playbackState(List<LibraryItem> songs, int? index) =>
    PlaybackState(
      album: null,
      songs: songs,
      status: PlaybackStatus.playing,
      position: Duration.zero,
      cacheProgress: Duration.zero,
      currentMediaIndex: index,
    );

class CarTestEnv {
  CarTestEnv({
    bool signedIn = true,
    bool offline = false,
    List<GeneratedPlaylist> mixes = const [],
    List<LibraryItem> favouriteSongs = const [],
    List<LibraryItem> favouriteAlbums = const [],
    List<DownloadedAlbum> downloads = const [],
    PlaybackState? playback,
  }) {
    SharedPreferences.setMockInitialValues({});
    offlineState = StateProvider<bool>((_) => offline);
    registerFallbackValue(const LibraryQuery());
    registerFallbackValue(const SearchQuery(term: ''));
    registerFallbackValue(album('fallback'));
    registerFallbackValue(ItemKind.album);
    registerFallbackValue(LoopMode.off);
    when(() => client.capabilities).thenReturn(const MediaServerCapabilities());
    when(() => setPlayback.playAlbum(any())).thenAnswer(_started);
    when(() => setPlayback.playArtist(any())).thenAnswer(_started);
    when(() => setPlayback.playPlaylist(any())).thenAnswer(_started);
    when(() => setPlayback.playGeneratedPlaylist(any())).thenAnswer(_started);
    when(() => setPlayback.playFavouriteSongs(any())).thenAnswer(_started);
    when(() => setPlayback.albumSongs(any())).thenAnswer((_) async => const []);
    when(
      () => setPlayback.playlistSongs(any()),
    ).thenAnswer((_) async => const []);
    when(setPlayback.favouriteSongs).thenAnswer((_) async => const []);
    when(
      () => setPlayback.generatedPlaylistSongs(any()),
    ).thenAnswer((_) async => const []);
    playbackNotifier = FakePlaybackNotifier(
      playback ?? playbackState(const [], null),
    );
    _stubPlayback();

    container = createProviderContainer(
      overrides: [
        mediaServerClientProvider.overrideWithValue(client),
        authProvider.overrideWith(FakeAuthNotifier.new),
        currentLibraryProvider.overrideWith(FakeLibraryNotifier.new),
        currentUserProvider.overrideWith(
          (_) => signedIn ? const User(userId: 'user-1', token: 't') : null,
        ),
        isOfflineProvider.overrideWith((ref) => ref.watch(offlineState)),
        effectiveArtistScopeProvider.overrideWithValue(
          ArtistScope.albumArtists,
        ),
        todaysPlaylistsProvider.overrideWith(() => FakeTodaysPlaylists(mixes)),
        favouriteSongsProvider.overrideWith(
          (_) async => LibraryPage(items: favouriteSongs),
        ),
        likedSongsCoversProvider.overrideWithValue(const []),
        favouriteAlbumsProvider.overrideWith((_) async => favouriteAlbums),
        downloadManagerProvider.overrideWith(
          () => FakeDownloadManager(downloads),
        ),
        downloadedAlbumsProvider.overrideWith((_) async => downloads),
        setPlaybackProvider.overrideWith((_) => setPlayback),
        playbackProvider.overrideWith((_) => playbackNotifier),
        playerProvider.overrideWithValue(player),
      ],
    );
  }

  final client = MockMediaServerClient();
  late final StateProvider<bool> offlineState;
  final player = MockAudioPlayer();
  final setPlayback = FakeSetPlayback();
  late FakePlaybackNotifier playbackNotifier;
  late final ProviderContainer container;

  void _stubPlayback() {
    when(
      () => playbackNotifier.play(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(() => playbackNotifier.resume()).thenAnswer((_) async {});
    when(
      () => playbackNotifier.setShuffle(enabled: any(named: 'enabled')),
    ).thenAnswer((_) async {});
    when(() => player.loopMode).thenReturn(LoopMode.off);
    when(
      () => client.setFavorite(any(), favorite: any(named: 'favorite')),
    ).thenAnswer((_) async {});
    when(() => playbackNotifier.updateSong(any())).thenReturn(null);
    when(() => player.setLoopMode(any())).thenAnswer((_) async {});
    when(
      () => playbackNotifier.skipTo(any(), autoPlay: any(named: 'autoPlay')),
    ).thenAnswer((_) async {});
  }

  static Future<SetPlaybackResult> _started(Invocation _) async =>
      SetPlaybackResult.started;

  void setOffline(bool value) =>
      container.read(offlineState.notifier).state = value;

  void stubAlbums(List<LibraryItem> items) => when(
    () => client.getAlbums(any()),
  ).thenAnswer((_) async => LibraryPage(items: items));

  void stubLatestAlbums(List<LibraryItem> items) => when(
    () => client.getLatestAlbums(
      libraryId: any(named: 'libraryId'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer((_) async => items);

  void stubArtists(List<LibraryItem> items) => when(
    () => client.getArtists(any()),
  ).thenAnswer((_) async => LibraryPage(items: items));

  void stubPlaylists(List<LibraryItem> items) => when(
    () => client.getPlaylists(any()),
  ).thenAnswer((_) async => LibraryPage(items: items));

  void stubSearch({
    List<LibraryItem> albums = const [],
    List<LibraryItem> artists = const [],
    List<LibraryItem> playlists = const [],
    List<LibraryItem> songs = const [],
  }) {
    when(
      () => client.searchAlbums(any()),
    ).thenAnswer((_) async => LibraryPage(items: albums));
    when(
      () => client.searchArtists(any()),
    ).thenAnswer((_) async => LibraryPage(items: artists));
    when(
      () => client.searchPlaylists(any()),
    ).thenAnswer((_) async => LibraryPage(items: playlists));
    when(
      () => client.searchSongs(any()),
    ).thenAnswer((_) async => LibraryPage(items: songs));
  }
}

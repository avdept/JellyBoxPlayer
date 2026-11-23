import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/core/platform/tv_home_channel.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/widgets.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';

class TvMainPage extends ConsumerStatefulWidget {
  const TvMainPage({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<TvMainPage> createState() => _TvMainPageState();
}

class _TvMainPageState extends ConsumerState<TvMainPage> {
  static const _browseBranch = 1;
  static const _settingsBranch = 2;

  final _homeNode = FocusNode(debugLabel: 'rail:Home');
  final _signOutNode = FocusNode(debugLabel: 'rail:Sign out');
  final _contentNode = FocusScopeNode(debugLabel: 'tv-content');
  final _playerNode = FocusScopeNode(debugLabel: 'tv-mini-player');
  FocusNode? _lastContentFocus;
  bool _railFocused = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_trackContentFocus);
    TvHomeChannel.listen((albumId) => unawaited(_openAlbum(albumId)));
    unawaited(_openPendingAlbum());
    unawaited(Future.microtask(_restoreLyrics));
    ref
      ..listenManual<int>(playbackArrivedProvider, (_, _) => _showNowPlaying())
      ..listenManual<bool>(isOfflineProvider, (_, offline) {
        if (!offline) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_railFocused) _homeNode.requestFocus();
        });
      }, fireImmediately: true);
  }

  void _showNowPlaying() {
    if (!mounted) return;
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.path;
    if (location == Routes.nowPlaying.path) return;
    unawaited(context.pushNamed(Routes.nowPlaying.name));
  }

  Future<void> _openPendingAlbum() async {
    final albumId = await TvHomeChannel.takePendingAlbum();
    if (albumId != null) await _openAlbum(albumId);
  }

  Future<void> _openAlbum(String albumId) async {
    final LibraryItem album;
    try {
      album = await ref
          .read(mediaServerClientProvider)
          .getItem(albumId, kind: ItemKind.album);
    } on Object catch (error) {
      debugPrint('[TvMainPage] could not open album $albumId: $error');
      return;
    }
    if (!mounted) return;
    widget.shell.goBranch(0);
    unawaited(
      context.pushNamed(Routes.homeAlbum.name, extra: {'album': album}),
    );
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_trackContentFocus);
    TvHomeChannel.stopListening();
    _homeNode.dispose();
    _signOutNode.dispose();
    _contentNode.dispose();
    _playerNode.dispose();
    super.dispose();
  }

  void _trackContentFocus() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || focus == _contentNode) return;
    if (focus.ancestors.contains(_contentNode)) _lastContentFocus = focus;
  }

  void _focusContent() {
    final last = _lastContentFocus;
    if (last != null && last.canRequestFocus && last.context != null) {
      last.requestFocus();
      return;
    }
    _contentNode.traversalDescendants.firstOrNull?.requestFocus();
  }

  bool _focusPlayer() {
    final target = _playerNode.traversalDescendants.firstOrNull;
    if (target == null) return false;
    target.requestFocus();
    return true;
  }

  void _onRailExit(TraversalDirection direction) {
    switch (direction) {
      case TraversalDirection.right:
        _focusContent();
      case TraversalDirection.down:
        _focusPlayer();
      case TraversalDirection.up || TraversalDirection.left:
        break;
    }
  }

  // Rail, page and mini player are separate focus scopes; hops between them
  // are routed here.
  KeyEventResult _onContentKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
      LogicalKeyboardKey.arrowRight => TraversalDirection.right,
      LogicalKeyboardKey.arrowUp => TraversalDirection.up,
      LogicalKeyboardKey.arrowDown => TraversalDirection.down,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return KeyEventResult.ignored;
    if (focus.focusInDirection(direction)) return KeyEventResult.handled;
    switch (direction) {
      case TraversalDirection.left:
        _homeNode.requestFocus();
      case TraversalDirection.down:
        _focusPlayer();
      case TraversalDirection.up || TraversalDirection.right:
        break;
    }
    return KeyEventResult.handled;
  }

  KeyEventResult _onPlayerKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _focusContent();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      final direction = key == LogicalKeyboardKey.arrowLeft
          ? TraversalDirection.left
          : TraversalDirection.right;
      final focus = FocusManager.instance.primaryFocus;
      if (focus != null && focus.focusInDirection(direction)) {
        return KeyEventResult.handled;
      }
      if (direction == TraversalDirection.left) _signOutNode.requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) return KeyEventResult.handled;
    return KeyEventResult.ignored;
  }

  void _restoreLyrics() {
    if (!mounted) return;
    ref.read(lyricsVisibleProvider.notifier).state = _savedLyricsShown();
  }

  bool _savedLyricsShown() {
    final settings = ref.read(appSettingsProvider.notifier);
    return settings.isEnabled(AppSetting.tvRememberLyrics) &&
        settings.isEnabled(AppSetting.tvLyricsShown);
  }

  void _goHome() {
    ref.read(lyricsVisibleProvider.notifier).state = _savedLyricsShown();
    widget.shell.goBranch(0, initialLocation: widget.shell.currentIndex == 0);
  }

  void _onBack(bool didPop, Object? result) {
    if (didPop) return;
    if (_railFocused) {
      unawaited(SystemNavigator.pop());
    } else {
      _homeNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TvNavigationRail(
              onFocusChange: (focused) => _railFocused = focused,
              onExit: _onRailExit,
              items: [
                TvRailItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  selected: widget.shell.currentIndex == 0,
                  focusNode: _homeNode,
                  onSelect: _goHome,
                ),
                TvRailItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Browse',
                  selected: widget.shell.currentIndex == _browseBranch,
                  onSelect: () => widget.shell.goBranch(
                    _browseBranch,
                    initialLocation: widget.shell.currentIndex == _browseBranch,
                  ),
                ),
                TvRailItem(
                  icon: JPlayer.play_circle_outlined,
                  label: 'Now playing',
                  onSelect: () => context.pushNamed(Routes.nowPlaying.name),
                ),
              ],
              footer: [
                TvRailItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  selected: widget.shell.currentIndex == _settingsBranch,
                  onSelect: () => widget.shell.goBranch(_settingsBranch),
                ),
                TvRailItem(
                  icon: JPlayer.log_out,
                  label: 'Sign out',
                  focusNode: _signOutNode,
                  onSelect: () =>
                      unawaited(ref.read(authProvider.notifier).logout()),
                ),
              ],
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ExcludeFocus(
                          excluding: isOffline,
                          child: FocusScope(
                            node: _contentNode,
                            onKeyEvent: _onContentKey,
                            child: widget.shell,
                          ),
                        ),
                        if (isOffline) const _OfflineScreen(),
                      ],
                    ),
                  ),
                  if (ref.watch(settingProvider(AppSetting.tvMiniPlayer)))
                    FocusScope(
                      node: _playerNode,
                      onKeyEvent: _onPlayerKey,
                      child: const TvMiniPlayer(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineScreen extends StatelessWidget {
  const _OfflineScreen();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: TvTokens.pageBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: Colors.white54),
            SizedBox(height: 20),
            Text("You're offline", style: TvTokens.title),
            SizedBox(height: 8),
            Text(
              'JellyBox will reconnect when your server is reachable.',
              style: TextStyle(fontSize: 15, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

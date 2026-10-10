import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jplayer/resources/j_player_icons.dart';
import 'package:jplayer/resources/resources.dart';
import 'package:jplayer/src/config/routes.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/widgets.dart';
import 'package:jplayer/src/presentation/widgets/offline_notice.dart';
import 'package:jplayer/src/presentation/widgets/shimmer.dart';
import 'package:jplayer/src/providers/auth_provider.dart';
import 'package:jplayer/src/providers/connectivity_provider.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class TvLibraryPage extends ConsumerStatefulWidget {
  const TvLibraryPage({super.key});

  @override
  ConsumerState<TvLibraryPage> createState() => _TvLibraryPageState();
}

class _TvLibraryPageState extends ConsumerState<TvLibraryPage> {
  bool _autoSelected = false;

  Future<void> _select(LibraryItem library) async {
    await ref.read(currentLibraryProvider.notifier).setLibrary(library);
    if (mounted) context.goNamed(Routes.home.name);
  }

  void _autoSelectSingle(LibraryItem library) {
    if (_autoSelected) return;
    _autoSelected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_select(library));
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraries = ref.watch(librariesProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TvTokens.pagePaddingH,
          vertical: TvTokens.pagePaddingV,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Choose a library', style: TvTokens.title),
                const Spacer(),
                TvButton(
                  label: 'Sign out',
                  icon: JPlayer.log_out,
                  onSelect: () =>
                      unawaited(ref.read(authProvider.notifier).logout()),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Expanded(
              child: libraries.when(
                data: (list) {
                  if (list.length == 1) {
                    _autoSelectSingle(list.first);
                    return _loading();
                  }
                  if (list.isEmpty) {
                    return const Center(
                      child: Text(
                        'No music libraries found on this server',
                        style: TvTokens.body,
                      ),
                    );
                  }
                  return _grid(list);
                },
                loading: _loading,
                error: (_, _) => Center(
                  child: OfflineNotice(
                    message: ref.watch(isOfflineProvider)
                        ? "You're offline, so your libraries can't be loaded."
                        : 'Could not load your libraries.',
                    onRetry: () => ref.invalidate(librariesProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<LibraryItem> list) {
    final images = ref.read(imageServiceProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        children: [
          for (final (index, library) in list.indexed)
            _LibraryCard(
              library: library,
              image: images.itemImage(
                library,
                size: 600,
                fallback: Images.librarySample,
              ),
              autofocus: index == 0,
              onSelect: () => unawaited(_select(library)),
            ),
        ],
      ),
    );
  }

  Widget _loading() => Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        for (var i = 0; i < 3; i++)
          const ShimmerBox(
            width: TvTokens.libraryCardWidth,
            height: TvTokens.libraryCardHeight,
            radius: 10,
          ),
      ],
    ),
  );
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({
    required this.library,
    required this.image,
    required this.onSelect,
    this.autofocus = false,
  });

  final LibraryItem library;
  final ImageProvider image;
  final VoidCallback onSelect;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onSelect: onSelect,
      autofocus: autofocus,
      debugLabel: 'library:${library.name}',
      builder: (context, focused) => TvFocusFrame(
        focused: focused,
        child: SizedBox(
          width: TvTokens.libraryCardWidth,
          height: TvTokens.libraryCardHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(image: image, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.4, 1],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Text(
                  library.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_focusable.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_options_dialog.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class TvLibrarySelector extends ConsumerWidget {
  const TvLibrarySelector({super.key});

  Future<void> _choose(BuildContext context, WidgetRef ref) async {
    final List<LibraryItem> libraries;
    try {
      libraries = await ref.read(librariesProvider.future);
    } on Object catch (error) {
      debugPrint('[TvLibrarySelector] could not load libraries: $error');
      return;
    }
    if (!context.mounted || libraries.isEmpty) return;
    final currentId = ref.read(currentLibraryProvider).valueOrNull?.id;
    final chosen = await showDialog<LibraryItem>(
      context: context,
      builder: (context) => _LibraryDialog(
        libraries: libraries,
        currentId: currentId,
      ),
    );
    if (chosen == null || chosen.id == currentId) return;
    await ref.read(currentLibraryProvider.notifier).setLibrary(chosen);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentLibraryProvider).valueOrNull;
    final library =
        ref
            .watch(librariesProvider)
            .valueOrNull
            ?.firstWhereOrNull((candidate) => candidate.id == current?.id) ??
        current;

    return TvFocusable(
      onSelect: () => unawaited(_choose(context, ref)),
      scrollOnFocus: false,
      debugLabel: 'library-selector',
      builder: (context, focused) {
        final foreground = focused ? Colors.black : Colors.white;
        return AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
          decoration: BoxDecoration(
            color: focused ? Colors.white : Colors.transparent,
            borderRadius: TvTokens.cardRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TvLibraryAvatar(library: library, size: 28),
              const SizedBox(width: 10),
              Text(
                library?.name ?? 'Library',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded, size: 22, color: foreground),
            ],
          ),
        );
      },
    );
  }
}

class _LibraryDialog extends StatelessWidget {
  const _LibraryDialog({required this.libraries, required this.currentId});

  final List<LibraryItem> libraries;
  final String? currentId;

  @override
  Widget build(BuildContext context) {
    final hasCurrent = libraries.any((library) => library.id == currentId);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 440),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Library',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (index, library) in libraries.indexed)
                        TvOptionRow(
                          icon: TvLibraryAvatar(library: library, size: 32),
                          label: Text(library.name),
                          autofocus: hasCurrent
                              ? library.id == currentId
                              : index == 0,
                          trailing: library.id == currentId
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onSelect: () => Navigator.of(context).pop(library),
                        ),
                    ],
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

class TvLibraryAvatar extends ConsumerWidget {
  const TvLibraryAvatar({required this.library, required this.size, super.key});

  final LibraryItem? library;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = this.library;
    final image = library == null
        ? null
        : ref
              .read(imageServiceProvider)
              .itemImageOrNull(library, size: (size * 3).round());
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: TvTokens.surfaceRaised(context),
      backgroundImage: image,
      onBackgroundImageError: image == null ? null : (_, _) {},
      child: image == null
          ? Icon(Icons.library_music, size: size / 2, color: Colors.white)
          : null,
    );
  }
}

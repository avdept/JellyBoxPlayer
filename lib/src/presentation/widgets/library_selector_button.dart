import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/domain/providers/providers.dart';
import 'package:jplayer/src/providers/image_service_provider.dart';

class LibrarySelectorButton extends ConsumerWidget {
  const LibrarySelectorButton({
    required this.size,
    this.showName = false,
    this.maxNameWidth = 180,
    super.key,
  });

  final double size;
  final bool showName;
  final double maxNameWidth;

  Widget _avatar(
    WidgetRef ref,
    ThemeData theme,
    LibraryItem? library,
    double size,
  ) {
    final tag = library?.images.primary;
    final image = (tag != null)
        ? ref.read(imageServiceProvider).albumIP(tagId: tag, id: library!.id)
        : null;
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: theme.colorScheme.surface,
      backgroundImage: image,
      child: image == null ? Icon(Icons.library_music, size: size / 2) : null,
    );
  }

  Widget _customButton(WidgetRef ref, ThemeData theme, LibraryItem? library) {
    final avatar = _avatar(ref, theme, library, size);
    final name = library?.name;
    if (!showName || name == null || name.isEmpty) return avatar;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(width: 10),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxNameWidth),
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size >= 40 ? 18 : 16,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = ref.watch(currentLibraryProvider).valueOrNull;
    final libraries =
        ref.watch(librariesProvider).valueOrNull ?? const <LibraryItem>[];

    // The library restored from prefs carries no imageTags, so resolve the
    // full DTO from librariesProvider (by id) to show the real cover image.
    final selected = libraries.cast<LibraryItem?>().firstWhere(
      (l) => l?.id == current?.id,
      orElse: () => null,
    );

    return DropdownButtonHideUnderline(
      child: DropdownButton2<LibraryItem>(
        customButton: _customButton(ref, theme, selected ?? current),
        buttonStyleData: const ButtonStyleData(
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
        dropdownStyleData: DropdownStyleData(
          width: 220,
          padding: const EdgeInsets.all(8),
          offset: const Offset(0, -8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
        ),
        items: [
          for (final lib in libraries)
            DropdownMenuItem<LibraryItem>(
              value: lib,
              child: Row(
                children: [
                  _avatar(ref, theme, lib, 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lib.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        color: (lib.id == current?.id)
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        value: selected,
        onChanged: (lib) {
          if (lib != null) {
            ref.read(currentLibraryProvider.notifier).setLibrary(lib);
          }
        },
      ),
    );
  }
}

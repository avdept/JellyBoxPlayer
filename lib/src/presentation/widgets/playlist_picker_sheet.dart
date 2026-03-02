import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/dto/item/item_dto.dart';
import 'package:jplayer/src/domain/providers/providers.dart';

class PlaylistPickerSheet extends ConsumerWidget {
  const PlaylistPickerSheet({required this.isDesktop, super.key});

  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final data = ref.watch(playlistsProvider);
    final formKey = GlobalKey<FormState>();

    if (data.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(isDesktop ? 6 : 0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: isDesktop ? 380 : double.infinity,
          child: Flex(
            mainAxisSize: MainAxisSize.min,
            direction: Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Add to playlist',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Form(
                key: formKey,
                child: DropdownButtonFormField<ItemDTO>(
                  onSaved: (value) => Navigator.of(context).pop(value),
                  hint: const Text(
                    'Select a playlist',
                    style: TextStyle(fontSize: 14),
                  ),
                  onChanged: (_) {},
                  items: data.value?.items
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name),
                        ),
                      )
                      .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 36),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();
                        }
                      },
                      child: const Text('Add to playlist'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<ItemDTO?> showPlaylistPicker(
  BuildContext context, {
  required bool isDesktop,
}) {
  if (isDesktop) {
    return showAdaptiveDialog<ItemDTO>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const PlaylistPickerSheet(isDesktop: true),
      ),
    );
  }
  return showModalBottomSheet<ItemDTO>(
    backgroundColor: Colors.grey[800],
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
    ),
    context: context,
    useRootNavigator: true,
    clipBehavior: Clip.antiAlias,
    builder: (context) => const PlaylistPickerSheet(isDesktop: false),
  );
}

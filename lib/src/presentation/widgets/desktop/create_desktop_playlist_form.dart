import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/jellyfin_api_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/presentation/widgets/widgets.dart';

class CreateDesktopPlaylistForm extends ConsumerStatefulWidget {
  const CreateDesktopPlaylistForm({
    this.controller,
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    this.onCreated,
    super.key,
  });

  final PersistentBottomSheetController? controller;
  final EdgeInsets padding;
  final VoidCallback? onCreated;

  @override
  ConsumerState<CreateDesktopPlaylistForm> createState() => _CreatePlaylistBottomSheetState();
}

class _CreatePlaylistBottomSheetState extends ConsumerState<CreateDesktopPlaylistForm> {
  final _inputController = TextEditingController(text: 'My new playlist');
  var _isPublicPlaylist = true;

  Future<void> _onCreatePressed() async {
    await ref.read(jellyfinApiProvider).createPlaylist(
      values: PlaylistData(
        name: _inputController.text.trim(),
        userId: ref.read(currentUserProvider)!.userId,
        isPublic: _isPublicPlaylist,
      ),
    );
    widget.onCreated?.call();
    _onCloseBottomSheet();
  }

  void _onCloseBottomSheet() {
    if (mounted) (widget.controller?.close ?? Navigator.of(context).pop).call();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LabeledTextField(
            controller: _inputController,
            placeholder: 'Playlist name',
            keyboardType: TextInputType.text,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StatefulBuilder(
                builder: (context, setState) => Checkbox(
                  value: _isPublicPlaylist,
                  onChanged: (value) => setState(() {
                    _isPublicPlaylist = value!;
                  }),
                ),
              ),
              const Text('Is public'),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => {Navigator.of(context).pop()},
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: _onCreatePressed,
                style: TextButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Create playlist'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }
}

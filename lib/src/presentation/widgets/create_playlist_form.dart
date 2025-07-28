import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/jellyfin_api_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';

class CreatePlaylistForm extends ConsumerStatefulWidget {
  const CreatePlaylistForm({
    this.controller,
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    this.onCreated,
    super.key,
  });

  final PersistentBottomSheetController? controller;
  final EdgeInsets padding;
  final VoidCallback? onCreated;

  @override
  ConsumerState<CreatePlaylistForm> createState() => _CreatePlaylistBottomSheetState();
}

class _CreatePlaylistBottomSheetState extends ConsumerState<CreatePlaylistForm> {
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
          const Text(
            'Name your playlist',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
          const Padding(padding: EdgeInsets.only(top: 36)),
          TextField(
            controller: _inputController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(width: 2, color: Colors.grey[600]!)),
              border: UnderlineInputBorder(
                borderSide: BorderSide(width: 2, color: Colors.grey[700]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              hintText: 'Playlist name',
              hintStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
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
            ],
          ),
          const SizedBox(height: 72),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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

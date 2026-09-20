import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/data/params/params.dart';
import 'package:jplayer/src/data/providers/media_server_client_provider.dart';
import 'package:jplayer/src/domain/providers/current_user_provider.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/labeled_text_field.dart';

class CreatePlaylistForm extends ConsumerStatefulWidget {
  const CreatePlaylistForm({
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    this.onCreated,
    super.key,
  });

  final EdgeInsets padding;
  final VoidCallback? onCreated;

  @override
  ConsumerState<CreatePlaylistForm> createState() => _CreatePlaylistFormState();
}

class _CreatePlaylistFormState extends ConsumerState<CreatePlaylistForm> {
  final _nameController = TextEditingController(text: 'My new playlist');
  var _isPublic = true;
  var _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (_submitting || name.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(mediaServerClientProvider)
          .createPlaylist(
            PlaylistData(
              name: name,
              userId: ref.read(currentUserProvider)!.userId,
              isPublic: _isPublic,
            ),
          );
      widget.onCreated?.call();
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Could not create the playlist';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      minimum: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModalFormHeader('New playlist'),
          const SizedBox(height: 16),
          LabeledTextField(
            controller: _nameController,
            placeholder: 'Playlist name',
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            autofocus: true,
          ),
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _isPublic,
                onChanged: (value) =>
                    setState(() => _isPublic = value ?? _isPublic),
              ),
              const Text('Is public'),
            ],
          ),
          const SizedBox(height: 16),
          ModalFormActions(
            submitLabel: 'Create playlist',
            onSubmit: () => unawaited(_submit()),
            busy: _submitting,
          ),
        ],
      ),
    );
  }
}

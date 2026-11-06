import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/core/lastfm/lastfm_client.dart';
import 'package:jplayer/src/domain/providers/lastfm_account_provider.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/labeled_text_field.dart';
import 'package:url_launcher/url_launcher.dart';

class LastFmConnectForm extends ConsumerStatefulWidget {
  const LastFmConnectForm({
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    super.key,
  });

  final EdgeInsets padding;

  @override
  ConsumerState<LastFmConnectForm> createState() => _LastFmConnectFormState();
}

class _LastFmConnectFormState extends ConsumerState<LastFmConnectForm> {
  late final _apiKeyController = TextEditingController(
    text: ref.read(lastFmAccountProvider).credentials?.apiKey,
  );
  late final _apiSecretController = TextEditingController(
    text: ref.read(lastFmAccountProvider).credentials?.apiSecret,
  );
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final url = await ref
        .read(lastFmAccountProvider.notifier)
        .beginAuthorization(
          apiKey: _apiKeyController.text,
          apiSecret: _apiSecretController.text,
        );
    if (url != null) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = ref.read(lastFmAccountProvider).error;
    });
  }

  Future<void> _done() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final connected = await ref
        .read(lastFmAccountProvider.notifier)
        .completeAuthorization();
    if (!mounted) return;
    if (connected) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = ref.read(lastFmAccountProvider).error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);
    final authorizing = ref.watch(
      lastFmAccountProvider.select((account) => account.isAuthorizing),
    );
    return SafeArea(
      top: false,
      minimum: widget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModalFormHeader('Connect Last.fm'),
          const SizedBox(height: 8),
          Text(
            authorizing
                ? 'Allow JellyBox on the Last.fm page that opened, then come back and press Done.'
                : 'Enter the API key and shared secret of your Last.fm API account. When creating it, leave the callback URL and application homepage empty. JellyBox then opens last.fm so you can allow it to scrobble.',
            style: TextStyle(fontSize: 14, color: muted),
          ),
          if (!authorizing) ...[
            const SizedBox(height: 16),
            LabeledTextField(
              controller: _apiKeyController,
              label: 'API key',
              placeholder: 'API key',
              autofocus: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            LabeledTextField(
              controller: _apiSecretController,
              label: 'Shared secret',
              placeholder: 'Shared secret',
              obscureText: true,
              textInputAction: TextInputAction.done,
            ),
          ],
          if (_error case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: TextStyle(fontSize: 13, color: theme.colorScheme.error),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: authorizing
                    ? (_busy ? null : () => unawaited(_open()))
                    : () => unawaited(
                        launchUrl(
                          LastFmClient.apiAccountUri,
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                style: ModalFormActions.buttonStyle(context),
                child: Text(
                  authorizing
                      ? 'Open last.fm again'
                      : 'Create an API account on last.fm',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ModalFormActions(
            submitLabel: authorizing ? 'Done' : 'Open last.fm',
            onSubmit: () => unawaited(authorizing ? _done() : _open()),
            busy: _busy,
          ),
        ],
      ),
    );
  }
}

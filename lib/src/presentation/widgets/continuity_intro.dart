import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:url_launcher/url_launcher.dart';

class ContinuityIntro extends StatelessWidget {
  const ContinuityIntro({super.key});

  static final Uri discordUri = Uri.parse('https://discord.gg/vttezPMvKh');
  static final Uri issuesUri = Uri.parse(
    'https://github.com/avdept/JellyBoxPlayer/issues',
  );

  static Future<void> show(BuildContext context) => showFormModal<void>(
    context,
    builder: (context) => const ContinuityIntro(),
  );

  static const _whatItDoes =
      'Thanks for trying the continuity feature. This feature allows you to '
      'transfer playback between your connected devices - phones, desktops, '
      'etc.';
  static const _remoteControl =
      'This feature also allows you to remotely control your other connected '
      'devices - playback, position, queue, volume.';
  static const _privacy =
      'NO data is shared with 3rd parties. Your content stays on your '
      'devices, and this tool just orchestrates which device plays now and '
      'sends Item IDs between devices.';
  static const _experimental =
      'This feature is currently experimental, so there might be bugs, '
      'issues, delays.';
  static const _notYet =
      "What's not working currently - you can't wake up a sleeping phone. If "
      'your phone plays music - you can control it even if the phone is in '
      "locked mode, but if you paused playback or the app wasn't running at "
      "all - currently there's no way to turn it on and start playback. This "
      'will be added in upcoming releases.';
  static const _report =
      'Please report any issues in Discord or via GitHub issues.';

  static const List<String> _paragraphs = [
    _whatItDoes,
    _remoteControl,
    _privacy,
    _experimental,
    _notYet,
    _report,
  ];

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onPrimary.withValues(
      alpha: 0.7,
    );

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModalFormHeader('Jellybox Cloud'),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final paragraph in _paragraphs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        paragraph,
                        style: TextStyle(fontSize: 14, color: muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _link(context, 'Discord', discordUri),
              const SizedBox(width: 8),
              _link(context, 'GitHub', issuesUri),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ModalFormActions.buttonStyle(context, primary: true),
                child: const Text('Got it'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _link(BuildContext context, String label, Uri uri) => TextButton(
    onPressed: () =>
        unawaited(launchUrl(uri, mode: LaunchMode.externalApplication)),
    style: ModalFormActions.buttonStyle(context),
    child: Text(label),
  );
}

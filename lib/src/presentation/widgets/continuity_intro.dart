import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jplayer/generated/l10n.dart';
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

  static List<String> _paragraphs(BuildContext context) => [
    S.of(context).continuityWhatItDoes,
    S.of(context).continuityRemoteControl,
    S.of(context).continuityPrivacy,
    S.of(context).continuityExperimental,
    S.of(context).continuityNotYet,
    S.of(context).continuityReport,
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
                  for (final paragraph in _paragraphs(context))
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
                child: Text(S.of(context).gotIt),
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

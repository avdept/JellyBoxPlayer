import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';

class LinkPrivacySheet extends StatelessWidget {
  const LinkPrivacySheet({super.key});

  static Future<void> show(BuildContext context) => showFormModal<void>(
    context,
    width: 640,
    builder: (context) => const LinkPrivacySheet(),
  );

  static const List<(String, List<String>)> _sections = [
    (
      'Continuity and remote control',
      [
        'The playing session is shared between your devices: item ids from your server, the queue position, the play position, playing or paused, shuffle, repeat and volume.',
        'Item ids mean nothing outside your server. Song titles, artists, covers and audio never go through Link. Each device looks the ids up on your own server.',
        'Link keeps the latest session so a device that reconnects can pick it up.',
      ],
    ),
    (
      'Remote access through the relay',
      [
        'The connection is encrypted end to end between this app and the JellyBox Relay plugin on your server. The relay forwards encrypted bytes and cannot read requests, logins, song names or audio.',
        'This is why you need to be on the same network as your server for the first connection: the app and your server exchange encryption keys there, and the relay never learns anything about them. Sorry for the inconvenience, but I care a lot about security and privacy.',
        'The server owner can switch on diagnostics in the plugin to get help with a problem. That shares request counts, status codes, timings and bytes per stream. It never shares content, item ids, user names, tokens or listener IP addresses, and it is off by default.',
      ],
    ),
    (
      'Artwork lookups',
      [
        "fanart.tv artist backgrounds are fetched through Link with the artist's MusicBrainz id only.",
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onPrimary.withValues(alpha: 0.7);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ModalFormHeader('What Link sees'),
          const SizedBox(height: 8),
          for (final (title, lines) in _sections) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        '•  ',
                        style: TextStyle(fontSize: 14, color: muted),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.3,
                          color: muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ModalFormActions.buttonStyle(context, primary: true),
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    );
  }
}

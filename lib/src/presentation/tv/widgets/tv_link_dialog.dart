import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_button.dart';

class TvLinkDialog extends ConsumerStatefulWidget {
  const TvLinkDialog({super.key});

  static Future<bool> show(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => const TvLinkDialog(),
      ) ??
      false;

  @override
  ConsumerState<TvLinkDialog> createState() => _TvLinkDialogState();
}

class _TvLinkDialogState extends ConsumerState<TvLinkDialog> {
  String? _code;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void dispose() {
    ref.read(cloudProvider.notifier).cancelDeviceLink();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _code = null;
      _failed = false;
    });
    final linked = await ref
        .read(cloudProvider.notifier)
        .linkDevice(
          address: ref.read(conductorUrlProvider),
          onCode: (start) {
            if (mounted) setState(() => _code = start.code);
          },
        );
    if (!mounted) return;
    if (linked) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(cloudProvider.select((state) => state.error));
    final accent = Theme.of(context).colorScheme.primary;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Connect to Jellybox Link',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'On your phone or computer, open Settings → Connection, '
                'click "Link a TV" and type this code.',
                style: TvTokens.body,
              ),
              const SizedBox(height: 20),
              Center(
                child: _failed
                    ? Text(
                        error ?? 'Could not get a code.',
                        textAlign: TextAlign.center,
                        style: TvTokens.body,
                      )
                    : Text(
                        _code ?? '····-····',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 4,
                          color: _code == null ? Colors.white38 : accent,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              if (!_failed)
                const Center(
                  child: Text(
                    'The code works for 10 minutes.',
                    style: TvTokens.caption,
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_failed) ...[
                    TvButton(
                      label: 'Try again',
                      icon: Icons.refresh,
                      primary: true,
                      autofocus: true,
                      onSelect: () => unawaited(_start()),
                    ),
                    const SizedBox(width: 10),
                  ],
                  TvButton(
                    label: 'Cancel',
                    autofocus: !_failed,
                    onSelect: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

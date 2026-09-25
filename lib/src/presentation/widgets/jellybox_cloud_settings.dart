import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/providers/cloud_provider.dart';
import 'package:jplayer/src/presentation/widgets/continuity_intro.dart';
import 'package:jplayer/src/presentation/widgets/form_modal.dart';
import 'package:jplayer/src/presentation/widgets/jellybox_cloud_connect_form.dart';

Future<void> connectJellyboxCloud(BuildContext context) async {
  final signedIn = await showFormModal<bool>(
    context,
    builder: (context) => const JellyboxCloudConnectForm(),
  );
  if (signedIn == true && context.mounted) {
    await ContinuityIntro.show(context);
  }
}

class JellyboxCloudSettings extends ConsumerWidget {
  const JellyboxCloudSettings({super.key});

  static final ButtonStyle _buttonStyle = TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(cloudProvider).account;

    return TextButton.icon(
      onPressed: () => unawaited(connectJellyboxCloud(context)),
      style: _buttonStyle,
      icon: Icon(account == null ? Icons.cloud_outlined : Icons.cloud_done),
      label: Text(
        account == null ? 'Connect' : 'Connected as ${account.email}',
      ),
    );
  }
}

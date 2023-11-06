import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/providers/player_provider.dart';

class RemainingDuration extends ConsumerWidget {
  const RemainingDuration({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Duration?>(
      builder: (context, durationSnapshot) {
        return StreamBuilder<Duration>(
          stream: ref.read(playerProvider).positionStream,
          builder: (context, positionSnapshot) {
            final remaining = durationSnapshot.data == null ? Duration.zero : durationSnapshot.data! - positionSnapshot.data!;
            return Text(RegExp(r'((^0*[1-9]\d*:)?\d{2}:\d{2})\.\d+$').firstMatch('$remaining')?.group(1) ?? '$remaining',
                style: Theme.of(context).textTheme.bodySmall);
          },
        );
      },
      stream: ref.read(playerProvider).durationStream,
    );


  }
}

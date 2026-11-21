import 'package:flutter/material.dart';
import 'package:jplayer/src/presentation/widgets/adaptive_dialog_action.dart';

class MissingDefaultDialog extends StatelessWidget {
  const MissingDefaultDialog({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) => AlertDialog.adaptive(
    title: Text('$name was not found'),
    content: Text(
      'Your default speaker was not found. You can pause, or play on your '
      'internal speakers. Playing here also stops using $name as your '
      'default speaker.',
    ),
    actions: [
      AdaptiveDialogAction(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Pause'),
      ),
      AdaptiveDialogAction(
        onPressed: () => Navigator.pop(context, true),
        isDefaultAction: true,
        child: const Text('Use internal speakers'),
      ),
    ],
  );
}

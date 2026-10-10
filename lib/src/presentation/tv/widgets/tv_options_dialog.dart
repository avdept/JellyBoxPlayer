import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jplayer/src/domain/models/models.dart';
import 'package:jplayer/src/presentation/tv/tv_tokens.dart';
import 'package:jplayer/src/presentation/tv/widgets/tv_focusable.dart';
import 'package:jplayer/src/presentation/widgets/context_menu.dart';

const tvContextMenuEntries = <ContextMenuEntry>{
  ContextMenuEntry.play,
  ContextMenuEntry.playNext,
  ContextMenuEntry.addToQueue,
  ContextMenuEntry.like,
  ContextMenuEntry.goToAlbum,
};

Future<void> showTvItemOptions(
  BuildContext context,
  WidgetRef ref,
  LibraryItem item, {
  required ContextMenuScope scope,
  Future<void> Function(LibraryItem item)? onLike,
}) async {
  final actions = contextMenuActions(
    context,
    ref,
    item,
    scope: scope,
    onLike: onLike,
  ).where((a) => tvContextMenuEntries.contains(a.entry) && a.run != null);
  if (actions.isEmpty) return;

  final chosen = await showDialog<ContextMenuAction>(
    context: context,
    builder: (context) => TvOptionsDialog(
      title: item.name,
      subtitle: item.artistLabel,
      actions: actions.toList(),
    ),
  );
  if (chosen != null) await chosen.run!();
}

class TvOptionsDialog extends StatelessWidget {
  const TvOptionsDialog({
    required this.title,
    required this.actions,
    this.subtitle,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<ContextMenuAction> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TvTokens.caption,
                ),
              const SizedBox(height: 14),
              for (final (index, action) in actions.indexed)
                _OptionRow(
                  action: action,
                  autofocus: index == 0,
                  onSelect: () => Navigator.of(context).pop(action),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.action,
    required this.onSelect,
    this.autofocus = false,
  });

  final ContextMenuAction action;
  final VoidCallback onSelect;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onSelect: onSelect,
      autofocus: autofocus,
      scrollOnFocus: false,
      builder: (context, focused) {
        final foreground = focused ? Colors.black : Colors.white;
        return AnimatedContainer(
          duration: TvTokens.focusDuration,
          curve: TvTokens.focusCurve,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: focused ? Colors.white : Colors.transparent,
            borderRadius: TvTokens.cardRadius,
          ),
          child: Row(
            children: [
              IconTheme.merge(
                data: IconThemeData(size: 20, color: foreground),
                child: action.icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: TextStyle(fontSize: 15, color: foreground),
                  child: action.label,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
